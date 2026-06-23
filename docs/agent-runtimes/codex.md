<!-- pravartak: template=codex-runtime.md.template version=0.5.0 generated=2026-06-23T01:44:35Z -->
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
MAX_STORIES_PER_DAY=10 PRAVARTAK_NO_DELETES=1 codex exec --sandbox danger-full-access --ask-for-approval never "<Pravartak autonomous prompt>"
```

The generated helper wraps that command and adds the persisted daily budget preflight:

```bash
MAX_STORIES_PER_DAY=10 PRAVARTAK_NO_DELETES=1 scripts/codex-auto.sh
```

Codex must run `scripts/codex-auto.sh --check-budget` before selecting each story and must
run `scripts/no-delete-guard.sh --check-diff` before commits and after integration. If the
budget is exhausted, exit cleanly with `BUDGET_EXHAUSTED`. If any delete or rename is
required, stop with `BLOCKED_DELETION_REQUIRED`.

## Codex implement + Claude review

This is the recommended mixed-runtime workflow when you want Codex to build and Claude to
review:

1. Set `implementation_runtime: codex` in `PRAVARTAK.md`.
2. Set `review_runtime: claude` in `PRAVARTAK.md`.
3. Run architect review with Claude using `docs/agent-runtimes/claude.md`.
4. Run implementation with the Codex autonomous or implementation prompt above.
5. Keep review, promotion, and any Claude slash-command work on the Claude adapter surface.

## Status and other non-command tasks

Codex has no Pravartak slash-command surface in this release. For status, drift, promotion,
or other procedures, instruct Codex to read the corresponding skill or command markdown
directly and execute it.
