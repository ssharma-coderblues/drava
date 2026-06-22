#!/usr/bin/env bash
#
# TypeScript quality gate (Pravartak TypeScript language pack).
#
# This script becomes the project's .claude/scripts/gate.sh. It is BOTH:
#   1. The directly-runnable quality gate (smoke test, autonomous loop): `gate.sh`
#   2. The PreToolUse commit hook: `gate.sh --hook` (reads the tool call on stdin,
#      gates only `git commit`, exits 0 to allow / 2 to block).
#
# Stack: pnpm workspaces + turbo + biome (lint+format) + tsc (typecheck) + vitest (test+cov)
# + prisma. Mirrors the Python pack's contract and behavior, translated to this stack.
#
# Encoded lessons (CashApp2 §-refs are the spec's; GAN-refs are Gandiva's Wave-0 lessons):
#   §14.1  Tools are invoked from the project-local node_modules/.bin by ABSOLUTE path
#          (computed at runtime from this script's location). No reliance on a global pnpm
#          or on shell PATH state. Portable across clones/machines. pnpm itself is invoked
#          via `corepack pnpm` when available so the pinned packageManager version is used.
#   §14.2  An empty project (no src/ in any package) passes vacuously — the smoke test
#          relies on this. vitest "no test files" is treated as SUCCESS for empty stages,
#          the TypeScript analogue of pytest exit 5 (early sprints have no tests).
#   GAN-34 "Exit 0" is not "verification passed": a no-op gate is worse than no gate. This
#          script asserts that lint/typecheck/test actually RAN (turbo reports >0 tasks, or
#          the step is explicitly marked vacuous) rather than trusting a bare exit 0.
#   GAN-37 Secrets come from a literal gitignored .env (no op:// indirection). Integration
#          tests that need secrets run via ./scripts/dev.sh, which loads .env. Unit/lint/
#          typecheck do NOT need secrets and run directly.
#   GAN-38 Brownfield coverage: the gate enforces coverage on CHANGED files only (delta
#          coverage against the integration branch), so pre-existing sub-threshold code does
#          not deadlock the first story. Whole-repo absolute coverage is NOT enforced here.
#
# Coverage threshold is single-sourced in vitest.config.ts (coverage.thresholds), read by
# the delta-coverage step below via COVERAGE_THRESHOLD; default 95 if unset.

set -euo pipefail

# Project root = two levels up from .claude/scripts/gate.sh
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Coverage threshold: single-sourced. Read from env if the loop exported it; else 95.
COVERAGE_THRESHOLD="${COVERAGE_THRESHOLD:-95}"
# Integration branch to diff against for delta coverage (GAN-38). The loop sets this; else
# fall back to the default branch, then to HEAD~1.
INTEGRATION_BRANCH="${INTEGRATION_BRANCH:-integration}"

c_ok()   { printf '\033[32m  PASS\033[0m %s\n' "$1"; }
c_skip() { printf '\033[33m  SKIP\033[0m %s\n' "$1"; }
c_bad()  { printf '\033[31m  FAIL\033[0m %s\n' "$1"; }

# Resolve pnpm: prefer corepack (honors the repo's pinned packageManager), else a pnpm on
# PATH. We do NOT install pnpm here — a missing pnpm is a setup failure, surfaced clearly.
pnpm_bin() {
  if command -v corepack >/dev/null 2>&1; then
    printf 'corepack pnpm'
  elif command -v pnpm >/dev/null 2>&1; then
    printf 'pnpm'
  else
    return 1
  fi
}

# Run the full gate. Returns 0 on pass, 1 on fail.
run_gate() {
  local pnpm rc
  printf '\n=== TypeScript quality gate (%s) ===\n\n' "$(basename "$ROOT")"

  if ! pnpm="$(pnpm_bin)"; then
    c_bad "pnpm not found (need corepack or a pnpm on PATH)"
    printf '  Enable with: corepack enable && corepack prepare pnpm@latest --activate\n'
    return 1
  fi

  # node_modules must exist (frozen install run by venv-setup analogue / scaffold). If the
  # workspace was never installed, that is a setup failure, not a code failure.
  if [ ! -d "$ROOT/node_modules" ]; then
    c_bad "node_modules missing — run: $pnpm install --frozen-lockfile"
    return 1
  fi

  # Detect whether the project has any source yet. An empty project (no package exposes a
  # src/) passes vacuously — the smoke test depends on this (§14.2). turbo with no matching
  # tasks is the analogue of pytest exit 5.
  local has_src="no"
  if find "$ROOT/packages" "$ROOT/apps" -type d -name src 2>/dev/null | grep -q .; then
    has_src="yes"
  elif [ -d "$ROOT/src" ]; then
    has_src="yes"
  fi
  if [ "$has_src" = "no" ]; then
    c_skip "no package src/ yet — gate passes vacuously (empty project, §14.2)"
    printf '\n\033[32m=== GATE PASSED ===\033[0m\n\n'
    return 0
  fi

  # 1. Install integrity — frozen lockfile must be consistent with package.json (§14: no
  #    silent dependency drift). Fast when already installed.
  set +e
  $pnpm install --frozen-lockfile >/tmp/gate-install.log 2>&1
  rc=$?
  set -e
  if [ "$rc" -ne 0 ]; then
    c_bad "pnpm install --frozen-lockfile (lockfile drift?)"
    tail -20 /tmp/gate-install.log
    return 1
  fi
  c_ok "pnpm install --frozen-lockfile"

  # 2. Lint + format — biome via turbo. GAN-34: assert the task actually ran. `turbo run
  #    lint` exits 0 if zero packages define a lint task; we reject that as a no-op gate.
  set +e
  local lint_out
  lint_out="$($pnpm turbo run lint --output-logs=new-only 2>&1)"
  rc=$?
  set -e
  printf '%s\n' "$lint_out"
  if [ "$rc" -ne 0 ]; then
    c_bad "turbo run lint (biome)"
    return 1
  fi
  # GAN-34 no-op guard: turbo prints a tasks summary; "0 successful, 0 total" means no
  # package wired a lint script — that is the no-op-lint trap, treat as FAIL not pass.
  if printf '%s' "$lint_out" | grep -qiE 'No tasks were executed|0 total'; then
    c_bad "turbo run lint ran 0 tasks — no package defines a 'lint' script (GAN-34 no-op gate)"
    printf '  Wire biome into each package: \"lint\": \"biome check src\" (see PACK.md).\n'
    return 1
  fi
  c_ok "turbo run lint (biome check + format)"

  # 3. Type check — tsc --strict via turbo. Same no-op guard.
  set +e
  local tc_out
  tc_out="$($pnpm turbo run typecheck --output-logs=new-only 2>&1)"
  rc=$?
  set -e
  printf '%s\n' "$tc_out"
  if [ "$rc" -ne 0 ]; then
    c_bad "turbo run typecheck (tsc --strict)"
    return 1
  fi
  if printf '%s' "$tc_out" | grep -qiE 'No tasks were executed|0 total'; then
    c_bad "turbo run typecheck ran 0 tasks — no package defines a 'typecheck' script"
    return 1
  fi
  c_ok "turbo run typecheck (tsc --strict)"

  # 4. Unit tests + coverage — vitest via turbo. These do NOT need secrets, so run directly.
  #    vitest exits non-zero with "No test files found" only if configured to; we treat the
  #    no-tests case as vacuous-pass for empty stages (§14.2 analogue) by checking output.
  set +e
  local test_out
  test_out="$($pnpm turbo run test --output-logs=new-only 2>&1)"
  rc=$?
  set -e
  printf '%s\n' "$test_out"
  if printf '%s' "$test_out" | grep -qiE 'No test files found|no tests'; then
    c_skip "vitest: no test files yet — treated as pass for empty stage (§14.2)"
  elif [ "$rc" -ne 0 ]; then
    c_bad "turbo run test (vitest)"
    return 1
  else
    c_ok "turbo run test (vitest unit)"
  fi

  # 5. Delta coverage (GAN-38) — enforce COVERAGE_THRESHOLD on CHANGED files only, against
  #    the integration branch. Pre-existing untouched code is grandfathered. Whole-repo
  #    absolute coverage is intentionally NOT enforced (brownfield calibration). This relies
  #    on vitest having emitted coverage-final.json (configured in vitest.config.ts).
  if [ -f "$ROOT/coverage/coverage-final.json" ]; then
    local base="$INTEGRATION_BRANCH"
    git -C "$ROOT" rev-parse --verify "$base" >/dev/null 2>&1 || base="HEAD~1"
    set +e
    node "$(dirname "${BASH_SOURCE[0]}")/delta-coverage.mjs" \
      --coverage "$ROOT/coverage/coverage-final.json" \
      --base "$base" \
      --threshold "$COVERAGE_THRESHOLD"
    rc=$?
    set -e
    if [ "$rc" -eq 0 ]; then
      c_ok "delta coverage ≥ ${COVERAGE_THRESHOLD}% on changed files (GAN-38)"
    elif [ "$rc" -eq 5 ]; then
      c_skip "delta coverage: no changed production files to measure — pass"
    else
      c_bad "delta coverage below ${COVERAGE_THRESHOLD}% on changed files"
      return 1
    fi
  else
    c_skip "no coverage report (coverage/coverage-final.json) — coverage not enforced this run"
  fi

  # 6. Integration tests (GAN-37) — these NEED secrets, so run through ./scripts/dev.sh,
  #    which loads the gitignored .env. Only run if the project defines the script and an
  #    integration test target exists. Skipped vacuously when absent.
  if [ -x "$ROOT/scripts/dev.sh" ] && grep -q '"test:integration"' "$ROOT"/package.json 2>/dev/null; then
    set +e
    "$ROOT/scripts/dev.sh" pnpm test:integration
    rc=$?
    set -e
    if [ "$rc" -eq 0 ]; then
      c_ok "integration tests (via scripts/dev.sh — .env loaded)"
    else
      c_bad "integration tests (exit $rc)"
      return 1
    fi
  else
    c_skip "no scripts/dev.sh or test:integration target — integration tests skipped"
  fi

  # 7. Secret scan (GAN-37) — literal .env means defense-in-depth at the boundary. Block the
  #    commit if a secret is staged. Runs only if gitleaks is available; absence is a SKIP
  #    (the PreToolUse environment may differ), surfaced loudly so it is not silently lost.
  if command -v gitleaks >/dev/null 2>&1; then
    set +e
    gitleaks protect --staged --no-banner --redact 2>/tmp/gate-gitleaks.log
    rc=$?
    set -e
    if [ "$rc" -eq 0 ]; then
      c_ok "gitleaks protect --staged (no secrets staged)"
    else
      c_bad "gitleaks detected staged secrets — scrub before committing"
      cat /tmp/gate-gitleaks.log
      return 1
    fi
  else
    c_skip "gitleaks not installed — staged-secret scan skipped (install: brew install gitleaks)"
  fi

  printf '\n\033[32m=== GATE PASSED ===\033[0m\n\n'
  return 0
}

# --- Entry point: hook mode vs direct mode ------------------------------------

if [ "${1:-}" = "--hook" ]; then
  # PreToolUse hook contract: tool call arrives as JSON on stdin. Gate only git commits.
  payload="$(cat)"
  command_str="$(printf '%s' "$payload" | jq -r '.tool_input.command // ""' 2>/dev/null || printf '')"
  case "$command_str" in
    *"git commit"*) ;;
    *) exit 0 ;;  # not a commit — allow the tool call
  esac
  if run_gate; then
    exit 0
  else
    echo "TypeScript quality gate failed — commit blocked. Fix the issues above and retry." >&2
    exit 2
  fi
else
  # Direct invocation (smoke test, autonomous loop, manual run).
  if run_gate; then exit 0; else exit 1; fi
fi
