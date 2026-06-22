#!/usr/bin/env bash
#
# Python quality gate (Pravartak Python language pack).
#
# This script becomes the project's .claude/scripts/gate.sh. It is BOTH:
#   1. The directly-runnable quality gate (smoke test, autonomous loop): `gate.sh`
#   2. The PreToolUse commit hook: `gate.sh --hook` (reads the tool call on stdin,
#      gates only `git commit`, exits 0 to allow / 2 to block).
#
# Encoded CashApp2 lessons:
#   §14.1  Tools are invoked from the project-local .venv by ABSOLUTE path (computed at
#          runtime from this script's location). No activation, no reliance on shell state,
#          no collision with shared/pyenv interpreters. Portable across clones/machines.
#   §14.2  pytest exit code 5 (no tests collected) is treated as SUCCESS. Early sprints
#          have no tests; failing on exit 5 would deadlock the first commit. Real failures
#          (exit 1-4) still block.
#   §14.6  ruff/mypy Python-version mismatch is handled in ruff.toml / pyproject.toml
#          (target-version vs python_version), not here.
#
# Coverage threshold is single-sourced in pyproject.toml ([tool.coverage.report]
# fail_under), so this script needs no rendered placeholders and stays shellcheck-clean.

set -euo pipefail

# Project root = two levels up from .claude/scripts/gate.sh
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VENV="$ROOT/.venv"

c_ok()   { printf '\033[32m  PASS\033[0m %s\n' "$1"; }
c_skip() { printf '\033[33m  SKIP\033[0m %s\n' "$1"; }
c_bad()  { printf '\033[31m  FAIL\033[0m %s\n' "$1"; }

# Run the full gate. Returns 0 on pass, 1 on fail.
run_gate() {
  local ruff mypy pytest_bin rc
  ruff="$VENV/bin/ruff"
  mypy="$VENV/bin/mypy"
  pytest_bin="$VENV/bin/pytest"

  printf '\n=== Python quality gate ===\n\n'

  if [ ! -x "$ruff" ] || [ ! -x "$mypy" ] || [ ! -x "$pytest_bin" ]; then
    c_bad "project-local .venv is missing tools at $VENV/bin"
    printf '  Run the pack venv setup (venv-setup.sh) to create it.\n'
    return 1
  fi

  # Source targets: only lint/type-check directories that exist. An empty project
  # (no src/ or tests/) passes vacuously — this is what the smoke test relies on.
  local targets=()
  [ -d "$ROOT/src" ] && targets+=("src")
  [ -d "$ROOT/tests" ] && targets+=("tests")
  if [ "${#targets[@]}" -eq 0 ]; then
    c_skip "no src/ or tests/ yet — gate passes vacuously (empty project)"
    printf '\n\033[32m=== GATE PASSED ===\033[0m\n\n'
    return 0
  fi

  # 1. Lint
  if "$ruff" check "${targets[@]}"; then c_ok "ruff check"; else c_bad "ruff check"; return 1; fi

  # 2. Format check
  if "$ruff" format --check "${targets[@]}"; then c_ok "ruff format --check"; else c_bad "ruff format --check"; return 1; fi

  # 3. Type check (strict; configured in pyproject.toml)
  if "$mypy" "${targets[@]}"; then c_ok "mypy --strict"; else c_bad "mypy"; return 1; fi

  # 4. Tests + coverage (threshold enforced via pyproject.toml). Tolerate exit 5.
  set +e
  "$pytest_bin" "$ROOT"
  rc=$?
  set -e
  if [ "$rc" -eq 0 ]; then
    c_ok "pytest (+ coverage threshold)"
  elif [ "$rc" -eq 5 ]; then
    c_skip "pytest: no tests collected (exit 5) — treated as pass (lesson §14.2)"
  else
    c_bad "pytest (exit $rc)"
    return 1
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
    echo "Python quality gate failed — commit blocked. Fix the issues above and retry." >&2
    exit 2
  fi
else
  # Direct invocation (smoke test, autonomous loop, manual run).
  if run_gate; then exit 0; else exit 1; fi
fi
