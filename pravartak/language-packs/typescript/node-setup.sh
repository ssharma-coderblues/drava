#!/usr/bin/env bash
#
# TypeScript isolation + tooling setup (Pravartak TypeScript language pack).
#
# The Node analogue of the Python pack's venv-setup.sh. Establishes project-local isolation
# (node_modules/ via pnpm, which is per-project by construction) and verifies the gate's
# required tools resolve. Mirrors §14.1's intent: never depend on globally-installed tools;
# everything the gate runs comes from the project's own node_modules/.bin or the pinned pnpm.
#
# Usage:  ./node-setup.sh
#   Run from the project root (SCAFFOLD.md Phase 5 invokes pack setup from the project root).
#
# Unlike Python's venv, pnpm gives per-project isolation natively (node_modules/ is local),
# so there is no environment to create — only to install into and verify. We pin the pnpm
# version via corepack from the repo's package.json "packageManager" field when present.

set -euo pipefail

PROJECT_ROOT="${PRAVARTAK_PROJECT_ROOT:-$PWD}"
cd "$PROJECT_ROOT"

echo "TypeScript pack setup for project at $PROJECT_ROOT"

# 1. Resolve pnpm via corepack (honors the pinned packageManager) or a pnpm on PATH.
if command -v corepack >/dev/null 2>&1; then
  echo "  Enabling corepack (uses the repo's pinned pnpm version if set)"
  corepack enable >/dev/null 2>&1 || true
  PNPM="corepack pnpm"
elif command -v pnpm >/dev/null 2>&1; then
  PNPM="pnpm"
else
  echo "ERROR: neither corepack nor pnpm found." >&2
  echo "  Install Node ≥ 20 (ships corepack), then: corepack enable" >&2
  echo "  Or install pnpm directly: npm i -g pnpm" >&2
  exit 1
fi
echo "  Using: $PNPM ($($PNPM --version 2>/dev/null || echo '?'))"

# 2. Install the workspace with a frozen lockfile if one exists; otherwise a normal install
#    (a fresh project has no lockfile yet — the first install creates it).
if [ -f "$PROJECT_ROOT/pnpm-lock.yaml" ]; then
  echo "  Installing workspace (frozen lockfile)"
  $PNPM install --frozen-lockfile
else
  echo "  No pnpm-lock.yaml yet — running an initial install to create it"
  $PNPM install
fi

# 3. Verify the gate's required tools resolve from the project (not globally). biome, tsc,
#    and vitest must be present as workspace dev dependencies. A missing tool is a setup
#    failure, surfaced clearly (spec §7.4), not a silent no-op (GAN-34).
MISSING=()
check_tool() {
  local name="$1" probe="$2"
  if $PNPM exec "$probe" --version >/dev/null 2>&1; then
    echo "    ok: $name"
  else
    MISSING+=("$name")
    echo "    MISSING: $name"
  fi
}

echo "  Verifying gate tools resolve from the workspace:"
check_tool "biome"  "biome"
check_tool "tsc"    "tsc"
check_tool "vitest" "vitest"

# gitleaks is a system tool (not an npm dep); check separately, warn-only (the gate SKIPs if
# absent rather than failing, but we want the operator to know at setup time — GAN-37).
if command -v gitleaks >/dev/null 2>&1; then
  echo "    ok: gitleaks ($(gitleaks version 2>/dev/null || echo present))"
else
  echo "    WARN: gitleaks not installed — staged-secret scan will be SKIPPED by the gate."
  echo "          Install with: brew install gitleaks"
fi

if [ "${#MISSING[@]}" -gt 0 ]; then
  echo "" >&2
  echo "ERROR: required gate tools are missing as workspace dev dependencies:" >&2
  printf '  - %s\n' "${MISSING[@]}" >&2
  echo "" >&2
  echo "Add them to the workspace, e.g. at the repo root:" >&2
  echo "  $PNPM add -Dw @biomejs/biome typescript vitest @vitest/coverage-v8" >&2
  echo "Then re-run this setup." >&2
  exit 1
fi

echo ""
echo "Done. Gate tools resolve from the project workspace."
echo "  Gate will run: pnpm install --frozen-lockfile → turbo lint → turbo typecheck →"
echo "                 turbo test → delta-coverage → integration (via scripts/dev.sh) →"
echo "                 gitleaks (staged)."
