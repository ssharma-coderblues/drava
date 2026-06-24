<!-- pravartak: template=PRAVARTAK.md.template version=0.5.0 generated=2026-06-22T22:45:10Z -->
# drava — Pravartak Operating Guide

This project is **Pravartak-managed** (library version 0.5.0, scaffolded
2026-06-22T22:45:10Z). This file is the **canonical, runtime-neutral operating guide** for the
project. Every runtime — Claude, Codex, or a future adapter — reads this file first.

This file is owned by the project. Edit it freely.

## Runtime assignments

- `interactive_runtime: codex`
- `autonomous_runtime: codex`
- `implementation_runtime: codex`
- `review_runtime: claude`

These assignments are intentional for Drava: Codex runs implementation/autonomous work, while
Claude owns story review and promotion review.

## Adapter surfaces

- **Claude adapter:** `CLAUDE.md`, `.claude/settings.json`, `.claude/commands/`,
  `docs/agent-runtimes/claude.md`
- **Codex adapter:** `docs/agent-runtimes/codex.md`

Workflow state continues to live under `.claude/` in this release for backward
compatibility. Treat those files as Pravartak protocol state, not as Claude-only semantics.

## Project facts

- **Name:** drava
- **Archetype:** loose-docs
- **Language:** typescript — production target 20, local dev
  24.15.0
- **Quality gate:** `.claude/scripts/gate.sh` (`.claude/scripts/gate.sh`)
- **No-delete guard:** `scripts/no-delete-guard.sh`
- **Autonomous preflight:** `scripts/autonomous-preflight.sh`
- **Story review helper:** `scripts/claude-review.sh`
- **Daily autonomous state:** `.pravartak/session-state.json`
- **Coverage threshold:** 95%
- **Default branch:** main
- **Source material:** docs/ — Drava executive summary and project specification Word documents

## Configuration (prose — edit to change behavior)

These are read as natural-language instructions by the autonomous loop and the skills.
Defaults are shown; change a line to change behavior.

- `interactive_runtime: codex` — runtime used for scaffold, review, drift-check, status,
  and other attended work unless a more specific role overrides it.
- `autonomous_runtime: codex` — runtime used to run the Phase 4 autonomous loop.
- `implementation_runtime: codex` — runtime expected to implement reviewed backlog stories.
- `review_runtime: claude` — runtime expected to lead architect review, story review, and promotion review.
- `integration_branch: integration` — the repo's integration branch. The loop cuts each
  story's feature branch from it and, on a clean gate pass, merges back into it. Created off
  `main` the first time the repo is touched. **The loop never touches
  `main`** — merging `integration`→`main` is the separate, gated
  promotion phase, out of the loop's scope.
- `promotion: external` — how integration→`main` happens, as a phase distinct
  from the per-story loop. `external` (default): a downstream actor/DevOps merges; Pravartak
  does nothing to `main`. `pravartak-gated`: `/promote` opens an
  integration→`main` PR, runs CI on it, **pauses for explicit human approval**,
  and merges only on human approval AND green CI. `merge_style: squash` squashes the
  promotion PR. In neither mode does the unattended loop merge to `main`.
- `git_workflow: auto-merge` — unattended runs merge approved, gated feature branches directly
  into the integration branch and push that branch. Set `pr-based` only for attended sessions
  where `gh pr create` access has been preflighted; otherwise GitHub API auth becomes a
  story-level stop condition. Set `local-only` for no remote operations. In no mode does the
  loop target `main`.
- `coverage_threshold: 95` — the gate enforces this; also set in the
  language config.
- `gate_strictness: strict` — block on any warning. Set `lenient` to allow warnings, block
  on errors.
- `review_before_completion: required` — because `implementation_runtime` is Codex and
  `review_runtime` is Claude, every story must have an approved durable review in
  `.claude/reviews/<STORY-ID>.md` before Codex may integrate or record completion.
- `sprint_cadence: by-story-batch` — sprint tags on story-batch boundaries. Set `weekly`
  (or other) for time-based tags.
- `branch_pattern: feature/drava-<story-id>-<slug>` — feature branch naming.
- `max_stories_per_day: 10` — autonomous mode reads `.pravartak/session-state.json` before
  selecting the next story. Override a run with `MAX_STORIES_PER_DAY=<N>`. If
  `completedToday >= maxStoriesPerDay`, the loop exits cleanly with `BUDGET_EXHAUSTED`.
- `preflight_required: true` — unattended runs must pass `scripts/autonomous-preflight.sh`
  before starting a batch. It writes `.pravartak/preflight-report.md` and reports consolidated
  blockers with `PREFLIGHT_BLOCKED`.
- `tracker_sync: off` — for `jira`/`linear` archetypes only. Set `on` to transition the
  corresponding tracker issue to its done state when a story completes. `tracker_done_state:
  <state>` overrides the target state if it is not the tracker's default completed state.

## Engineering standards

All production code follows the universal standards in `pravartak/standards/`. Summary
(authoritative detail is in those files):

- **SOLID** and **GoF patterns** where they genuinely fit.
- **TDD with 95% line and branch coverage** — failing test first.
- **Every API and every story is testable** — unit + integration + contract + error-path.
- **Integration tests against real backing services** for external integration points.
- **Persistence hardening** — idempotency via UNIQUE; integer minor units for money (no
  floats); UTC tz-aware timestamps; append-only where required; two-sided journals.
- **Async-first** — all I/O async; structured, bounded concurrency; cancellation tested.
- **Observability** — structured logs with correlation IDs; ≥1 metric per story; no silent
  failures.
- **Security baseline** — no secrets in code; inputs validated at boundaries; CVE scanning;
  parameterized SQL only.

## Architect overrides

- Codex is the primary runtime for scaffold, implementation, and autonomous execution.
- Claude is the required review runtime for story review and promotion review. Codex must use
  `scripts/claude-review.sh <STORY-ID> integration` for unattended story handoffs and must not
  record completion until the resulting `.claude/reviews/<STORY-ID>.md` contains an approved
  verdict.
- Wave-Planner PoC (`poc-wave-planner/`) is reference material only (decided 2026-06-22). Excluded from production build targets. No engineering time allocated to productionizing it.
- Treat `docs/Drava_Project_Specification.docx` and `docs/Drava_Executive_Summary.docx` as authoritative source material snapshots.
- `promotion: external` until CI and branch-protection policy are explicitly configured.
- `tracker_sync: off` until a Linear connector/filter is configured and reviewed.

## Autonomous workflow protocol

Launch the autonomous loop using the adapter instructions for `autonomous_runtime`. Every
runtime must follow the same protocol:

1. Read this file for project standards and configuration.
2. Read the adapter guide for the assigned runtime:
   `docs/agent-runtimes/claude.md` or `docs/agent-runtimes/codex.md`.
3. Read `pravartak/skills/autonomous-loop/SKILL.md` for the full execution procedure.
4. Run `scripts/autonomous-preflight.sh`, then `scripts/no-delete-guard.sh --check-diff` and
   `scripts/codex-auto.sh --check-budget`
   (or the same session-state logic for a non-Codex runtime) before selecting work. If the
   preflight reports `PREFLIGHT_BLOCKED`, stop with the consolidated
   `.pravartak/preflight-report.md`; if the budget is exhausted, stop with `BUDGET_EXHAUSTED`.
5. Run the resume check (escalations → current_story → blocked → backlog), then start at the
   first unchecked story in `.claude/backlog.md` whose dependencies are complete. Record that
   story in `.pravartak/session-state.json` as `lastStartedStory`.
6. If `git_workflow: pr-based`, preflight `gh pr create` access before implementation. For
   Codex, run `scripts/codex-auto.sh --check-pr-access`; if it reports
   `GH_PR_ACCESS_REQUIRED`, halt before selecting work.
7. Per story: ensure the integration branch exists → cut the feature branch → TDD → quality
   gates (3 retries each) → commit the feature branch → run the required Claude story review
   gate → integrate per `git_workflow` → re-gate the integration branch → push if authorized
   → mark complete → next.
8. After the story is committed, approved by the Claude review gate, integrated/pushed, and
   passed the post-integration gate, increment `completedToday` and record
   `lastCompletedStory`. Never increment for failed commits, failed pushes, partial work,
   unapproved/missing review, or local-only work that did not complete its configured
   integration step.
9. No deletes: autonomous mode may edit lines and add files, but must not delete or rename
   files. Block delete and rename/delete git diff statuses. Do not run `rm`, `rmdir`,
   `unlink`, `git clean`, `git reset --hard`, `git checkout --`, `git restore`, destructive
   `mv`, or equivalent cleanup. If a story truly requires a deletion or rename, halt and
   report `BLOCKED_DELETION_REQUIRED`.
10. Honor every stop condition: write `.claude/escalations.md` and halt rather than forcing
   completion or taking an unauthorized outward action.
11. Never edit specs or `discovery/` during implementation — spec changes belong to architect
   review.
12. Respect the assigned runtime roles. If `implementation_runtime` and `review_runtime`
   differ, the implementation runtime builds reviewed stories and the review runtime owns the
   story-review and promotion gates. Capture each story review in
   `.claude/reviews/<STORY-ID>.md` with `Verdict: APPROVED` or
   `Recommendation: APPROVED/PASS` before recording completion.

## Pipeline reminders

- Architect review is a separate, human-gated phase and must complete before autonomous
  execution starts.
- Use `/status` from the Claude adapter or ask another runtime to read `pravartak/commands/
  status.md` directly to inspect project state.
- Use `docs/agent-runtimes/codex.md` for Codex-only and mixed-runtime prompts.
- Use `docs/agent-runtimes/claude.md` for verified Claude launcher examples.
