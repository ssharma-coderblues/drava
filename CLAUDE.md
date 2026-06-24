<!-- pravartak: template=CLAUDE.md.template version=0.5.0 generated=2026-06-23T01:44:35Z -->
# drava — Claude Adapter Guide

This file preserves **Claude compatibility** for a Pravartak-managed project. The canonical,
runtime-neutral operating guide is `PRAVARTAK.md`. Keep this file because Claude adapter
surfaces in this release still include `CLAUDE.md`, `.claude/settings.json`, and
`.claude/commands/`.

For every Claude session:

1. Read `PRAVARTAK.md`.
2. Read `docs/agent-runtimes/claude.md`.
3. Use the relevant command pointer in `.claude/commands/` or the relevant
   `pravartak/skills/<skill>/SKILL.md`.

## Claude adapter notes

- The project is scaffolded with `interactive_runtime: codex`,
  `autonomous_runtime: codex`, `implementation_runtime:
  codex`, and `review_runtime: claude`.
- Claude owns story review and promotion review. For unattended Codex handoffs, review files
  are written through `scripts/claude-review.sh <STORY-ID> integration` to
  `.claude/reviews/<STORY-ID>.md`; Codex may only record completion after an approved verdict.
- Claude-specific permissions and the commit-time gate hook live in `.claude/settings.json`.
- `.claude/commands/` is the Claude adapter command surface. Other runtimes invoke the same
  skills directly rather than through slash commands.

## Claude autonomous launch

Use the verified Claude adapter launcher from `docs/agent-runtimes/claude.md`:

```bash
MAX_STORIES_PER_DAY=10 PRAVARTAK_NO_DELETES=1 \
claude --permission-mode auto --effort xhigh --max-budget-usd <N> \
  -p "Read PRAVARTAK.md, docs/agent-runtimes/claude.md, and pravartak/skills/autonomous-loop/SKILL.md. Execute the autonomous workflow protocol for this repository."
```

## Architect overrides

- Codex is the primary runtime for scaffold, implementation, and autonomous execution.
- Claude is the required review runtime for story review and promotion review.
- Wave-Planner PoC (`poc-wave-planner/`) is reference material only (decided 2026-06-22). Excluded from production build targets. No engineering time allocated to productionizing it.
- Treat `docs/Drava_Project_Specification.docx` and `docs/Drava_Executive_Summary.docx` as authoritative source material snapshots.
- `promotion: external` until CI and branch-protection policy are explicitly configured.
- `tracker_sync: off` until a Linear connector/filter is configured and reviewed.
