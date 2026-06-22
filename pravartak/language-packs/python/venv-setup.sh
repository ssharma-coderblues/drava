#!/usr/bin/env bash
#
# Python isolation setup (Pravartak Python language pack).
#
# Creates a project-local .venv/ and installs dev dependencies into it. The quality gate
# (gate.sh) invokes tools from this .venv by absolute path — no activation required. This
# is lesson §14.1: never install into a shared/pyenv interpreter where sibling projects
# collide.
#
# Usage:  ./venv-setup.sh [path-to-python]
#   path-to-python defaults to the locally-installed `python3` (the dev interpreter, which
#   may differ from the production target — lesson §14.6). Pass an explicit interpreter to
#   pin it, e.g.  ./venv-setup.sh "$(pyenv which python3.11)"

set -euo pipefail

# The project root is the current working directory: SCAFFOLD.md Phase 5 always invokes the
# pack from the project root (the gate likewise derives the .venv path as the project root).
# This must not depend on whether pyproject.toml has been rendered yet, so the venv lands in
# the project regardless of language-pack step ordering.
PROJECT_ROOT="${PRAVARTAK_PROJECT_ROOT:-$PWD}"
if [ ! -f "$PROJECT_ROOT/pyproject.toml" ]; then
  echo "Note: no pyproject.toml at $PROJECT_ROOT yet — creating the venv anyway;" \
       "the editable install is skipped until the project is rendered."
fi

PYTHON_BIN="${1:-python3}"
VENV="$PROJECT_ROOT/.venv"

if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
  echo "ERROR: python interpreter '$PYTHON_BIN' not found." >&2
  echo "Install Python or pass an explicit interpreter path as the first argument." >&2
  exit 1
fi

echo "Creating project-local virtualenv at $VENV"
echo "  using interpreter: $("$PYTHON_BIN" --version 2>&1) ($PYTHON_BIN)"

"$PYTHON_BIN" -m venv "$VENV"

# Upgrade pip tooling inside the venv (absolute path; no activation).
"$VENV/bin/python" -m pip install --upgrade pip setuptools wheel >/dev/null

# Required dev tools (spec §12.3). Pinning is left to pyproject.toml's dev extras when
# present; here we ensure the gate's tools exist.
REQUIRED=(ruff mypy pytest pytest-cov pytest-asyncio)
# Optional tools the standards recommend (integration tests, security).
OPTIONAL=(testcontainers bandit)

echo "Installing required dev tools: ${REQUIRED[*]}"
"$VENV/bin/python" -m pip install "${REQUIRED[@]}"

# If the project declares dev dependencies, install the project (editable) with them.
if [ -f "$PROJECT_ROOT/pyproject.toml" ]; then
  echo "Installing project (editable) with dev extras if defined"
  "$VENV/bin/python" -m pip install -e "${PROJECT_ROOT}[dev]" 2>/dev/null \
    || "$VENV/bin/python" -m pip install -e "$PROJECT_ROOT" 2>/dev/null \
    || echo "  (no installable project yet — skipping editable install)"
fi

echo "Installing optional tools (best-effort): ${OPTIONAL[*]}"
"$VENV/bin/python" -m pip install "${OPTIONAL[@]}" 2>/dev/null \
  || echo "  (optional tools skipped — install manually if needed)"

echo
echo "Done. Tools available by absolute path under $VENV/bin/"
"$VENV/bin/ruff" --version 2>/dev/null || true
"$VENV/bin/mypy" --version 2>/dev/null || true
"$VENV/bin/pytest" --version 2>/dev/null || true
