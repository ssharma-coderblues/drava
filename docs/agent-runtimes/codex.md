<!-- pravartak: template=codex-runtime.md.template version=0.5.0 generated=2026-06-24T00:11:34Z -->
# Codex Runtime Adapter

This document is the Codex-specific operating surface for `drava`.

Codex support in Pravartak is explicit and non-speculative: use these prompts and the
canonical `PRAVARTAK.md` guide rather than assuming a Codex-specific settings file or slash
command surface.

Read order for any Codex session:

1. `PRAVARTAK.md`
2. This file
3. The relevant `pravartak/skills/<skill>/SKILL.md` or `pravartak/commands/status.md`

## Codex-only workflow

Use an interactive Codex session rooted at the repository and give it one of these prompts.

### Scaffold

```text
Read PRAVARTAK.md if it exists, then read pravartak/skills/scaffold/SKILL.md and pravartak/scaffold/SCAFFOLD.md. Execute the scaffold procedure interactively for this repository.
```

### Architect review

```text
Read PRAVARTAK.md, this Codex adapter guide, and pravartak/skills/architect-review/SKILL.md. Review all pending stories in .claude/backlog.md and update the standard Pravartak review state files.
```

### Autonomous execution

```text
Read PRAVARTAK.md, this Codex adapter guide, and pravartak/skills/autonomous-loop/SKILL.md. Act as the autonomous_runtime for this project. Resume from the standard Pravartak state files, implement the next eligible reviewed story, and continue until the backlog is empty or a stop condition fires.
```

Recommended launch command:

```bash
MAX_STORIES_PER_DAY=10 PRAVARTAK_NO_DELETES=1 \
codex exec --dangerously-bypass-approvals-and-sandbox "<Pravartak autonomous prompt>"
```

The generated helper wraps that command, adds the persisted daily budget/preflight checks,
and defaults to Codex's promptless unattended flag for this installed CLI:

```bash
MAX_STORIES_PER_DAY=10 PRAVARTAK_NO_DELETES=1 scripts/codex-auto.sh
```

Set `CODEX_UNATTENDED_FLAGS=` only when intentionally running an attended/sandboxed session;
the default is chosen so autonomous runs do not pause for human approval prompts.

Codex must run `scripts/codex-auto.sh --check-budget` before selecting each story and must
run `scripts/no-delete-guard.sh --check-diff` before commits and after integration. If the
budget is exhausted, exit cleanly with `BUDGET_EXHAUSTED`. If any delete or rename is
required, stop with `BLOCKED_DELETION_REQUIRED`.

Before starting an unattended batch, Codex must run `scripts/autonomous-preflight.sh`. If it
reports `PREFLIGHT_BLOCKED`, stop and use `.pravartak/preflight-report.md` as the consolidated
blocker report instead of discovering blockers one story at a time.

If `git_workflow: pr-based`, Codex must run `scripts/codex-auto.sh --check-pr-access` before
selecting work. If it reports `GH_PR_ACCESS_REQUIRED`, stop before implementation and fix
GitHub CLI auth or switch unattended runs to `git_workflow: auto-merge`.

## Codex implement + Claude review

This is the recommended mixed-runtime workflow when you want Codex to build and Claude to
review:

1. Set `implementation_runtime: codex` in `PRAVARTAK.md`.
2. Set `review_runtime: claude` in `PRAVARTAK.md`.
3. Set or keep `review_before_completion: required`.
4. Run architect review with Claude using `docs/agent-runtimes/claude.md`.
5. Run implementation with the Codex autonomous or implementation prompt above.
6. Capture Claude's story review in `.claude/reviews/<STORY-ID>.md` after the implementation
   commit and before merging to the integration branch. If `scripts/claude-review.sh` exists,
   run `scripts/claude-review.sh <STORY-ID> integration` for this handoff instead of invoking
   Claude directly.
7. If Claude returns findings, fix them on the feature branch, rerun the gate, recommit, and
   rerun Claude review until the durable review file contains `Verdict: APPROVED` or
   `Recommendation: APPROVED/PASS`.
8. For unattended batches, prefer `git_workflow: auto-merge`: merge the approved feature
   branch into the integration branch, rerun the no-delete guard and full gate, then push the
   integration branch.
9. Do not run `scripts/codex-auto.sh --record-completed <STORY-ID>` until the durable review
   file is approved and the configured integration/push step has succeeded.
10. If the wrapper writes `Verdict: REVIEW_UNAVAILABLE`, halt with the durable review file and
   escalation context; do not retry indefinitely inside the autonomous session.
11. Keep promotion and any Claude slash-command work on the Claude adapter surface.

## Status and other non-command tasks

Codex has no Pravartak slash-command surface in this release. For status, drift, promotion,
or other procedures, instruct Codex to read the corresponding skill or command markdown
directly and execute it.
