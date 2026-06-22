#!/usr/bin/env bash
# Drava Wave-Planner PoC — one-command demo
# Usage: ./run.sh [--verify]
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Drava Wave-Planner PoC"
echo "  Scenario: 5 stories, 1 file collision, 4 waves"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ "${1}" == "--verify" ]]; then
  echo ""
  echo "Running verification against expected output..."
  node verify.js
  echo ""
  echo "All checks passed. PoC output is correct."
else
  node planner.js
fi
