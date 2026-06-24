#!/usr/bin/env bash
# pravartak: template=autonomous-preflight.sh.template version=0.5.0 generated=2026-06-24T00:11:34Z
#
# Consolidated preflight for Pravartak autonomous runs.

set -euo pipefail

ROOT="${PRAVARTAK_PROJECT_ROOT:-}"
if [ -z "$ROOT" ]; then
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi

REPORT="${PRAVARTAK_PREFLIGHT_REPORT:-$ROOT/.pravartak/preflight-report.md}"
REVIEW_HEALTH_TIMEOUT="${PRAVARTAK_REVIEW_HEALTH_TIMEOUT_SECONDS:-15}"
block_count=0
warn_count=0

mkdir -p "$(dirname "$REPORT")"

write_header() {
  {
    printf '# Pravartak Autonomous Preflight\n\n'
    printf '%s\n' "- Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf '%s\n' "- Branch: $(git -C "$ROOT" branch --show-current 2>/dev/null || printf unknown)"
    printf '%s\n\n' "- Root: \`$ROOT\`"
  } > "$REPORT"
}

record_pass() {
  printf 'PASS: %s\n' "$1"
  printf '%s\n' "- PASS: $1" >> "$REPORT"
}

record_warn() {
  warn_count=$((warn_count + 1))
  printf 'WARN: %s\n' "$1"
  printf '%s\n' "- WARN: $1" >> "$REPORT"
}

record_block() {
  block_count=$((block_count + 1))
  printf 'BLOCK: %s\n' "$1"
  printf '%s\n' "- BLOCK: $1" >> "$REPORT"
}

append_output() {
  local title="$1"
  local file="$2"
  [ -s "$file" ] || return 0
  {
    printf '\n<details><summary>%s</summary>\n\n```text\n' "$title"
    sed -n '1,160p' "$file"
    printf '\n```\n</details>\n'
  } >> "$REPORT"
}

run_probe() {
  local label="$1"
  shift
  local out
  out="$(mktemp "${TMPDIR:-/tmp}/pravartak-preflight.XXXXXX")"
  if "$@" > "$out" 2>&1; then
    record_pass "$label"
  else
    record_block "$label"
    append_output "$label output" "$out"
  fi
}

config_value() {
  local key="$1"
  grep -Eio "$key:[[:space:]]*[[:alnum:]_-]+" "$ROOT/PRAVARTAK.md" 2>/dev/null |
    head -n 1 |
    awk -F: '{gsub(/[ `]/, "", $2); print tolower($2)}'
}

review_required() {
  [ -f "$ROOT/PRAVARTAK.md" ] || return 1
  if grep -Eiq 'review_before_completion:[[:space:]]*(required|true|yes|on)' "$ROOT/PRAVARTAK.md"; then
    return 0
  fi
  local implementation_runtime review_runtime
  implementation_runtime="$(config_value implementation_runtime)"
  review_runtime="$(config_value review_runtime)"
  [ -n "$implementation_runtime" ] &&
    [ -n "$review_runtime" ] &&
    [ "$implementation_runtime" != "$review_runtime" ]
}

open_escalations_present() {
  [ -f "$ROOT/.claude/escalations.md" ] || return 1
  awk '
    /^## Open escalations/ { in_open=1; next }
    /^## Resolved escalations/ { in_open=0 }
    in_open && /^<!--/ { in_comment=1; next }
    in_open && /-->/ { in_comment=0; next }
    in_open && !in_comment && /^### / { found=1 }
    END { exit found ? 0 : 1 }
  ' "$ROOT/.claude/escalations.md"
}

current_story() {
  [ -f "$ROOT/.claude/current_story.md" ] || return 0
  awk '
    /^## In flight/ { in_section=1; next }
    in_section && /^<!--/ { exit }
    in_section && $0 ~ /^_None\._$/ { next }
    in_section && NF { print; exit }
  ' "$ROOT/.claude/current_story.md"
}

write_header

if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  record_pass "Git working tree is available"
else
  record_block "Not inside a Git working tree"
fi

if [ -n "$(git -C "$ROOT" status --porcelain)" ]; then
  record_warn "Working tree has uncommitted changes; autonomous runs should start from a committed protocol/state"
else
  record_pass "Working tree is clean"
fi

if open_escalations_present; then
  record_block "Open escalation exists; resolve or intentionally resume it before starting another autonomous story"
else
  record_pass "No open escalations"
fi

story="$(current_story)"
if [ -n "$story" ]; then
  record_warn "Current story is in flight: $story"
else
  record_pass "No current story in flight"
fi

if [ -x "$ROOT/scripts/no-delete-guard.sh" ]; then
  run_probe "No-delete guard" "$ROOT/scripts/no-delete-guard.sh" --check-diff
else
  record_block "Missing executable scripts/no-delete-guard.sh"
fi

if [ -x "$ROOT/scripts/codex-auto.sh" ]; then
  run_probe "Daily story budget" "$ROOT/scripts/codex-auto.sh" --check-budget
  run_probe "PR workflow access" "$ROOT/scripts/codex-auto.sh" --check-pr-access
else
  record_block "Missing executable scripts/codex-auto.sh"
fi

if command -v "${CODEX_BIN:-codex}" >/dev/null 2>&1; then
  record_pass "Codex CLI is on PATH"
else
  record_warn "Codex CLI is not on this shell PATH; set CODEX_BIN when launching outside this shell"
fi

if review_required; then
  review_runtime="$(config_value review_runtime)"
  if [ "$review_runtime" = "claude" ]; then
    if [ -x "$ROOT/scripts/claude-review.sh" ]; then
      run_probe "Claude review runtime health check" env \
        PRAVARTAK_REVIEW_HEALTH_TIMEOUT_SECONDS="$REVIEW_HEALTH_TIMEOUT" \
        "$ROOT/scripts/claude-review.sh" --health-check
    else
      record_block "Review is required but scripts/claude-review.sh is missing or not executable"
    fi
  else
    record_warn "Review is required with unsupported preflight runtime: $review_runtime"
  fi
else
  record_pass "No separate story review runtime is required"
fi

if [ "${PRAVARTAK_PREFLIGHT_RUN_GATE:-0}" = "1" ]; then
  if [ -x "$ROOT/.claude/scripts/gate.sh" ]; then
    run_probe "Full quality gate" "$ROOT/.claude/scripts/gate.sh"
  else
    record_block "Full gate requested but .claude/scripts/gate.sh is missing or not executable"
  fi
else
  record_warn "Full quality gate not run; set PRAVARTAK_PREFLIGHT_RUN_GATE=1 to include it"
fi

{
  printf '\n## Summary\n\n'
  printf '%s\n' "- Blocks: $block_count"
  printf '%s\n' "- Warnings: $warn_count"
} >> "$REPORT"

if [ "$block_count" -gt 0 ]; then
  printf 'PREFLIGHT_BLOCKED: %s block(s), %s warning(s). Report: %s\n' "$block_count" "$warn_count" "$REPORT" >&2
  exit 68
fi

printf 'PREFLIGHT_READY: %s warning(s). Report: %s\n' "$warn_count" "$REPORT"
