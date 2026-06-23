#!/usr/bin/env bash
# pravartak: template=codex-auto.sh.template version=0.5.0 generated=2026-06-23T01:44:35Z
#
# Codex autonomous launcher and daily-session state helper.

# shellcheck disable=SC2016

set -euo pipefail

ROOT="${PRAVARTAK_PROJECT_ROOT:-}"
if [ -z "$ROOT" ]; then
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi

STATE_FILE="${PRAVARTAK_SESSION_STATE:-$ROOT/.pravartak/session-state.json}"
NO_DELETE_GUARD="$ROOT/scripts/no-delete-guard.sh"
DEFAULT_MAX=10

need_jq() {
  command -v jq >/dev/null 2>&1 || {
    printf 'codex-auto: jq is required for .pravartak/session-state.json\n' >&2
    exit 64
  }
}

today() {
  if [ -n "${PRAVARTAK_TODAY:-}" ]; then
    printf '%s' "$PRAVARTAK_TODAY"
  else
    date -u +%F
  fi
}

ensure_state_file() {
  mkdir -p "$(dirname "$STATE_FILE")"
  if [ ! -f "$STATE_FILE" ]; then
    jq -n --arg date "$(today)" --argjson max "${MAX_STORIES_PER_DAY:-$DEFAULT_MAX}" \
      '{date: $date, completedToday: 0, maxStoriesPerDay: $max, lastStartedStory: null, lastCompletedStory: null}' \
      > "$STATE_FILE"
  fi
}

rewrite_state_with() {
  local tmp="$STATE_FILE.tmp"
  jq "$@" "$STATE_FILE" > "$tmp"
  cp "$tmp" "$STATE_FILE"
}

normalize_state() {
  need_jq
  ensure_state_file
  local current_date max
  current_date="$(today)"
  max="${MAX_STORIES_PER_DAY:-$(jq -r '.maxStoriesPerDay // 10' "$STATE_FILE")}"
  rewrite_state_with --arg date "$current_date" --argjson max "$max" '
    .maxStoriesPerDay = $max
    | if .date != $date
      then .date = $date | .completedToday = 0
      else .
      end
  '
}

check_budget() {
  normalize_state
  local completed max
  completed="$(jq -r '.completedToday // 0' "$STATE_FILE")"
  max="$(jq -r '.maxStoriesPerDay // 10' "$STATE_FILE")"
  if [ "$completed" -ge "$max" ]; then
    printf 'BUDGET_EXHAUSTED: completedToday=%s maxStoriesPerDay=%s date=%s\n' \
      "$completed" "$max" "$(jq -r '.date' "$STATE_FILE")"
    exit 20
  fi
}

mark_started() {
  local story_id="$1"
  check_budget
  rewrite_state_with --arg story "$story_id" '.lastStartedStory = $story'
}

record_completed() {
  local story_id="$1"
  normalize_state
  rewrite_state_with --arg story "$story_id" '
    .completedToday = ((.completedToday // 0) + 1)
    | .lastCompletedStory = $story
  '
}

complete_after_success() {
  local story_id="$1"
  shift
  [ "${1:-}" = "--" ] && shift
  [ "$#" -gt 0 ] || {
    printf 'codex-auto: --complete-after-success requires a commit+push command after --\n' >&2
    exit 64
  }
  "$@"
  record_completed "$story_id"
}

autonomous_prompt() {
  cat <<'EOF'
Read PRAVARTAK.md, docs/agent-runtimes/codex.md, and pravartak/skills/autonomous-loop/SKILL.md. Act as the autonomous_runtime for this project.

Before selecting each new story, run scripts/codex-auto.sh --check-budget. After selecting the story, run scripts/codex-auto.sh --mark-started <STORY-ID>.

Autonomous mode has a hard no-delete policy. Run scripts/no-delete-guard.sh --check-diff before every commit and after every merge. Never run rm, rmdir, unlink, git clean, git reset --hard, git checkout --, git restore, destructive mv, or equivalent cleanup. If a story requires deleting or renaming a file, stop and report BLOCKED_DELETION_REQUIRED.

Only after a story has been committed and pushed successfully, run scripts/codex-auto.sh --record-completed <STORY-ID>. Continue until the backlog is empty, a stop condition fires, or scripts/codex-auto.sh --check-budget reports BUDGET_EXHAUSTED.
EOF
}

launch_codex() {
  check_budget
  if [ -x "$NO_DELETE_GUARD" ]; then
    "$NO_DELETE_GUARD" --check-diff
  fi
  if [ "${PRAVARTAK_DRY_RUN:-0}" = "1" ]; then
    autonomous_prompt
    return 0
  fi
  PRAVARTAK_NO_DELETES=1 MAX_STORIES_PER_DAY="${MAX_STORIES_PER_DAY:-$DEFAULT_MAX}" \
    codex exec --sandbox danger-full-access --ask-for-approval never "$(autonomous_prompt)"
}

usage() {
  cat <<'EOF'
Usage:
  scripts/codex-auto.sh
  scripts/codex-auto.sh --check-budget
  scripts/codex-auto.sh --mark-started <STORY-ID>
  scripts/codex-auto.sh --record-completed <STORY-ID>
  scripts/codex-auto.sh --complete-after-success <STORY-ID> -- <commit-and-push-command>

Environment:
  MAX_STORIES_PER_DAY     Override the persisted daily max. Default: 10.
  PRAVARTAK_TODAY         Test hook for date reset behavior, YYYY-MM-DD.
  PRAVARTAK_DRY_RUN       Print the Codex prompt instead of launching Codex.
EOF
}

case "${1:-}" in
  "")
    launch_codex
    ;;
  --check-budget)
    check_budget
    ;;
  --mark-started)
    [ -n "${2:-}" ] || { usage >&2; exit 64; }
    mark_started "$2"
    ;;
  --record-completed)
    [ -n "${2:-}" ] || { usage >&2; exit 64; }
    record_completed "$2"
    ;;
  --complete-after-success)
    [ -n "${2:-}" ] || { usage >&2; exit 64; }
    story="$2"
    shift 2
    complete_after_success "$story" "$@"
    ;;
  -h|--help)
    usage
    ;;
  *)
    usage >&2
    exit 64
    ;;
esac
