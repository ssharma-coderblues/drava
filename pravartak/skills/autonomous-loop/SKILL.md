---
name: autonomous-loop
description: >
  The development execution protocol (Phase 4). Reads .claude/backlog.md and processes
  stories one at a time with TDD, runs quality gates with retries, and — on a clean gate
  pass — merges each story's feature branch back into the repo's INTEGRATION branch. The
  loop never touches `main`/the default branch (integration→main is a downstream DevOps
  step). It halts honestly on stop conditions, including a repo-ownership boundary and any
  unauthorized irreversible/outward action. Fully resumable. NOT invoked by a human
  directly — invoked by a runtime adapter launcher or explicit runtime prompt. Assumes
  architect review is complete; it reads the backlog as-is.
---

# Skill: autonomous-loop

## 1. Purpose

This is the autonomous development loop. Given a reviewed backlog, it implements stories one
at a time — each on its own feature branch cut from the repo's **integration branch**,
test-first, behind quality gates — and on a clean gate pass merges the feature branch **back
into the integration branch**. It continues until the backlog is empty or a stop condition
fires. It is resumable across context resets because all state lives in plain files.

**The Git model is integration branch + feature-branch-per-story (spec §11.2, §14.9).** Each
repo has one integration branch, created off `main` (the default branch) the first time the
repo is touched. The loop **never touches `main`** — merging integration→`main` is a separate,
explicitly-gated **promotion phase** (spec §11.6, skill `promotion` / `/promote`), out of the
loop's scope. That phase has two modes: `external` (a downstream actor/DevOps merges, typically
after a production deploy) and `pravartak-gated` (Pravartak runs a human- and CI-gated
promotion). **In neither mode does the unattended per-story loop merge to `main`.** The
per-story merge into the integration branch on a passing gate **is** the autonomous
approval: gate-pass = approval. The loop does not ask a human per merge (that would defeat
autonomous execution) and does not open a PR to `main`.

**Honest halt over forced completion (spec §14.10).** A real backlog to a 95%-coverage /
integration-test bar is multi-session work; one run will not honestly finish a large backlog.
The loop reports partial/HALTED with true per-story status rather than fabricate a passing
gate or report COMPLETE for unbuilt work. Escalation and honest partial reporting are
expected, first-class outcomes — a HALTED report covering three real, tested stories is a
success, not a shortfall.

## 2. Invocation

Autonomous execution is launched explicitly by an operator, never by a `/`-command and never
by this skill itself.

Canonical inputs for every runtime:

- `PRAVARTAK.md`
- the assigned runtime's adapter guide
- this file

Claude's verified launcher is documented in `docs/agent-runtimes/claude.md`. Codex uses the
explicit prompt documented in `docs/agent-runtimes/codex.md`.

On launch:

1. Read `PRAVARTAK.md` for the project's standards, protocol, runtime assignments, and
   configuration (§3).
2. Read the assigned runtime's adapter guide (`docs/agent-runtimes/claude.md` or
   `docs/agent-runtimes/codex.md`).
3. Read this file (`pravartak/skills/autonomous-loop/SKILL.md`) for the execution procedure.
4. Read the standards under `pravartak/standards/` that the project's stories touch.
5. Run the repo-ownership pre-check (§6.0) and the resume check (§5).
6. Start at the first unchecked story in `.claude/backlog.md` whose dependencies are complete.
7. Continue until the backlog is empty or a stop condition fires (§7).

**Precondition — review is complete.** This loop reads `.claude/backlog.md` as-is and assumes
architect review (Phase 3) finished. It does not review, does not edit specs, and does not
propagate intent — that is architect-review territory. If the project skipped review, the loop
still runs, but the result may not match architect intent (spec §14.8).

## 3. Configuration (read from `PRAVARTAK.md`, in prose)

`PRAVARTAK.md` is plain prose. Honor these knobs if present; otherwise use the defaults:

| Knob | Default | Effect |
| --- | --- | --- |
| `autonomous_runtime` | `claude` | Runtime assigned to run this loop. |
| `implementation_runtime` | `claude` | Runtime expected to implement stories during this phase. |
| `integration_branch` | `integration` | The repo's integration branch. The loop cuts feature branches from it and merges back into it. Created off the default branch on first touch. |
| `git_workflow` | `auto-merge` | `auto-merge`: on a clean gate pass, merge feature → integration branch directly (gate-pass IS the approval). `pr-based`: open a PR via `gh pr create` targeting the **integration branch** (human reviews the merge). `local-only`: no remote operations. **No mode ever targets `main`.** |
| `coverage_threshold` | `95` | Coverage percentage the gate enforces. |
| `gate_strictness` | `strict` | `strict`: block on any warning. `lenient`: allow warnings, block on errors. |
| `sprint_cadence` | by story batch | `weekly` (or other): produce sprint tags on that cadence regardless of story count. |
| `branch_pattern` | `feature/<project>-<story-id>-<slug>` | Feature-branch naming. |
| `tracker_sync` | `off` | `on`: for issue-tracker archetypes (`jira`/`linear`), update the corresponding tracker issue to its done state when a story completes (§6.6), via the archetype's `connector.md`. Opt-in; the project's own tracker only. |
| `tracker_done_state` | archetype default | The target tracker status/state for write-back (e.g. `Done`) when not the tracker's default completed state. |

Determine the default branch once at startup (the branch the integration branch is cut from,
e.g. `main`). Determine remote mode once: if `git_workflow: local-only` is set, or the repo
has no `origin` remote (`git remote get-url origin` fails), operate in **local-only mode**
(§6.5) — never attempt a push or any remote operation.

## 4. State files

| File | Role |
| --- | --- |
| `.claude/backlog.md` | The stories. Unchecked `[ ]` = not done; checked `[x]` = done. Source of work order. |
| `.claude/current_story.md` | The story currently in progress (for resume). |
| `.claude/completed.md` | Append-only log of completed stories. |
| `.claude/blocked.md` | Stories that could not proceed (with reason). |
| `.claude/escalations.md` | Stop-condition context written on halt (§7). |
| `.claude/commit_log.txt` | Running log of commits made by the loop. |
| `docs/sprint-reports/sprint-<n>.md` | Per-sprint summaries (§8). |

## 5. Resume check (run first, every launch)

Before starting any new story:

1. Read `.claude/escalations.md`. If it contains an **unresolved** escalation, stop and report
   it — do not blindly resume past a halt the architect hasn't cleared.
2. Read `.claude/current_story.md`. If a story is mid-flight (feature branch exists, partial
   work), resume **that** story from where it stopped rather than starting a new one. Inspect
   the working tree and the feature branch to determine progress.
3. Read `.claude/blocked.md` so you don't re-attempt a story known to be blocked unless its
   blocker is resolved.
4. Otherwise, select the first unchecked story in `.claude/backlog.md` whose dependencies are
   all complete.

Never double-process a story already checked `[x]` in the backlog or present in `completed.md`.

## 6. Per-story loop

### 6.0 Repo-ownership pre-check (before any branch/commit/push — spec §14.11)

Autonomous execution is safe **only in a repository the session owns a real working checkout
of.** Before the loop writes to, branches on, or pushes to *any* repository — the project repo
or any repo a story references — confirm ownership of that exact repo:

1. **It is a real, full working checkout you control.** Reject shallow/analysis clones:
   `git -C <repo> rev-parse --is-shallow-repository` returning `true` → **not owned**. A repo
   present only for read-only analysis is not a build target.
2. **It is the project's own repo** (the checkout auto-mode was launched in — `CLAUDE_PROJECT_DIR`
   / the cwd git root), not a sibling directory or another team's repository.
3. **You are authorized to push to it for this run.** The project repo is authorized by
   construction; any *other* repo is not, absent explicit authorization in `PRAVARTAK.md` or
   the run instructions.

If a story requires writing to / branching on / pushing to / opening a PR against a repo that
fails any check → **halt and escalate** (§7), naming exactly which repo and which action, for
the assigned review runtime or a human to perform in a proper checkout with the owning team
aware. **Reading** another repo's code for context is fine; **writing** to it is not. The clean
rule (spec §14.11): the autonomous/developer boundary IS the repo-ownership boundary — the
loop builds what you own; anything touching other teams' repos is human-driven developer work.

### 6.1 Begin

1. Confirm the story's dependencies are complete (check `completed.md`). If a dependency is
   incomplete, escalate (`story depends on incomplete prior work`, §7).
2. Confirm acceptance criteria are inferable from the spec. If not, escalate
   (`acceptance criteria cannot be inferred`, §7).
3. Record the story in `.claude/current_story.md`.
4. **Ensure the integration branch exists.** If `integration_branch` does not exist yet,
   create it off the default branch on this first touch
   (`git checkout <default-branch> && git checkout -b <integration_branch>`), and push it in
   remote modes. Otherwise check it out and fast-forward it to its remote tip.
5. **Cut the feature branch from the integration branch** (not from the default branch), using
   `branch_pattern`: `git checkout -b feature/<project>-<story-id>-<slug> <integration_branch>`.

### 6.2 Implement with TDD

Follow `pravartak/standards/TDD_AND_COVERAGE.md`:

1. Write a failing test for the next acceptance criterion.
2. Implement the minimum to make it pass.
3. Refactor with tests green.
4. Repeat until all acceptance criteria are covered, including the test classes the standards
   require (unit, integration against real backing services for integration points, contract,
   error-path) and the cross-cutting standards (async-first, persistence hardening,
   observability, security baseline).

Every file the loop creates gets the project's inline provenance header where the file type
supports comments (the loop generates project source; see the scaffold's manifest for the
header format).

### 6.3 Quality gates (local)

Run `.claude/scripts/gate.sh`. Honor `gate_strictness` and `coverage_threshold`. The gate runs,
in order: lint, format check, type check, unit tests, integration tests, coverage threshold.
**Retry a failing gate up to 3 times**, fixing the cause between attempts. Three consecutive
failures on the **same** gate → escalate (§7).

Note the gate already tolerates `pytest` exit code 5 (no tests collected) as success for empty
stages (spec §14.2); do not treat that as a failure.

### 6.4 Commit

Commit the work (one commit per story, story-id-prefixed message). The `PreToolUse` hook in
`.claude/settings.json` re-runs the gate as a final check at commit time (hooks live under the
`"hooks"` key — spec §14.4). If the hook blocks, treat it as a gate failure and return to §6.3.
Append the commit to `.claude/commit_log.txt`.

### 6.5 Integrate — merge into the integration branch (never `main`)

Integration happens only on a **clean gate pass**. Behavior depends on `git_workflow` (§3):

**auto-merge (default, remote present):**

1. Push the feature branch: `git push -u origin <feature-branch>` (preserves history).
2. Check out the integration branch and merge the feature branch into it with no fast-forward:
   `git checkout <integration_branch> && git merge --no-ff <feature-branch>` with a merge-commit
   message referencing the story id. **Gate-pass is the approval — do not ask a human per merge.**
3. **Re-run the gate against the integration branch post-merge.** If it fails, undo the merge
   (`git reset --hard` to the pre-merge commit on the integration branch) and escalate — never
   leave a broken integration branch.
4. Push the integration branch: `git push origin <integration_branch>`.
5. **Do not delete the feature branch** and **do not touch `main`** (spec §14.7, §14.9).
   Feature branches are kept until their work reaches `main` via the downstream
   integration→`main` merge; pruning is a periodic hygiene step outside this loop.

**pr-based (`git_workflow: pr-based`):**

1. Push the feature branch.
2. Open a PR **targeting the integration branch** (`gh pr create --base <integration_branch>`)
   with a title/body summarizing the story. Do **not** merge — human review owns the merge.
   Record the PR URL in `completed.md`'s entry and move on. (Never target `main`.)

**local-only (`git_workflow: local-only` or no origin):**

1. Do not push.
2. Check out the integration branch and merge the feature branch into it locally with `--no-ff`.
3. Re-run the gate against the integration branch; on failure, undo the merge and escalate.
4. Do not delete the feature branch; no remote operations.

### 6.6 Finish the story

A story is finished **only if it genuinely passed the full gate and integrated cleanly** (§1,
honest completion). Then:

1. Mark the story `[x]` in `.claude/backlog.md`.
2. Append the story to `.claude/completed.md` (id, title, feature branch, merge-commit/PR
   reference, timestamp).
3. **Tracker write-back (opt-in).** If `tracker_sync: on` and the project uses an issue-tracker
   archetype (`jira`/`linear`), update the corresponding tracker issue to its done state via
   the archetype's `connector.md` write-back (resolve the issue from the story's `[KEY]`
   identifier). This is an outward action on the **project's own tracker**, authorized solely
   by the `tracker_sync` opt-in — never another team's tracker, and never enabled implicitly
   (consistent with §7's irreversible/outward-action stop condition). If the write-back fails
   (auth/permission/unknown state), escalate rather than reporting the tracker as synced. When
   `tracker_sync: off`, skip this step entirely.
4. Clear `.claude/current_story.md`.
5. Proceed to the next story (back to §5's selection, step 4).

If the story could not pass, do **not** mark it complete and do **not** merge partial work —
escalate (§7) or block (§7, soft) with the true state.

## 7. Stop conditions

When any of the following occurs, write context to `.claude/escalations.md` (the story id, what
happened, the relevant gate output or denial, and what the architect should decide) and **halt
the loop**:

- 3 consecutive failures on the same gate after retries.
- 20 total denied operations in the session.
- Acceptance criteria cannot be inferred from the spec.
- A story depends on incomplete prior work.
- A required spec change surfaces mid-implementation. The loop does **not** modify specs; record
  what change is needed and halt (architect-review will handle it, queuing a corrective story if
  needed).
- The auto-mode classifier blocks an action and no safe alternative exists.
- **Repo-ownership boundary (spec §14.11).** A story requires writing to, branching on, or
  pushing to a repository the session does not own a real working checkout of (a
  read-only/shallow analysis clone, or another team's repo — see §6.0). The loop must NOT push
  branches or open PRs there. Halt and surface exactly which repo and which action, for a human
  to perform in a proper checkout with the owning team aware.
- **Irreversible or outward-facing action without explicit authorization (spec §11.4).** Any
  push/PR to an external repository, any action on another team's live system, or any other
  outward, hard-to-reverse step not explicitly authorized for this run. **Pause and ask rather
  than assuming authorization — even when a literal reading of the instructions seems to permit
  it.** Speed or convenience never licenses an unauthorized outward action.

**Escalation is a first-class, expected outcome, not a failure (spec §14.10).** An honest halt
with true per-story state is always preferred over forcing completion or taking an unauthorized
action.

For a story that is blocked but does not warrant a hard halt (e.g. waiting on an external
dependency), record it in `.claude/blocked.md` with the reason and skip to the next eligible
story rather than halting the whole loop.

## 8. Sprint boundaries

After the last story of a sprint (by story batch, or by `sprint_cadence` if set):

1. Tag the commit on the integration branch: `git tag sprint-<n>-complete`.
2. Push the tag (skip in local-only mode).
3. Write a sprint summary to `docs/sprint-reports/sprint-<n>.md`: stories completed, notable
   decisions, escalations encountered and how they resolved, metrics.
4. Proceed to the next sprint's first story.

## 9. Resumability

The loop is fully resumable: all state is in plain files (§4). Restarting the loop runs the
repo-ownership pre-check (§6.0) and the resume check (§5) and continues from wherever it
stopped — mid-story if `current_story.md` points at an in-flight story, or at the next unchecked
backlog story otherwise. Never double-process a story already checked `[x]` in the backlog or
present in `completed.md`.

## 10. Guardrails

- **Never touch `main`/the default branch.** The loop merges into the integration branch only;
  integration→`main` happens only in the separate, explicitly-gated promotion phase (§12; spec
  §11.6) — never the unattended loop, in either promotion mode.
- **Build only what you own.** Honor the repo-ownership boundary (§6.0); never push, branch, or
  open a PR against a repo the session does not own a real working checkout of.
- **Never take an unauthorized outward/irreversible action.** Pause and ask; a literal reading
  of instructions does not grant authorization (spec §11.4).
- **Honest completion only.** Mark a story complete only if it genuinely passed the full gate;
  never fabricate a passing gate or report COMPLETE for unbuilt/untested work (spec §14.10).
- **Never leave a broken integration branch.** Always re-run the gate post-merge and undo on
  failure.
- **Never edit specs or `discovery/`.** Spec changes are architect-review's job; halt and
  escalate if one is needed.
- **Do not delete feature branches.** Cleanup is a downstream hygiene step after integration→
  `main`, not part of this loop (spec §14.7).
- **Never skip the pre-check or the resume check.** Double-processing a story corrupts state.
- **Respect the budget.** `--max-budget-usd` is a hard ceiling; if approaching it, finish the
  current story cleanly, record state, and stop rather than leaving work half-done.

## 11. Outputs

- Implemented stories merged into the **integration branch** (or PRs targeting it in pr-based
  mode), test-first and gated, each marked `[x]` in the backlog and logged in `completed.md`.
- Feature branches retained (not deleted) for traceability to the in-flight integration branch.
- Sprint tags and `docs/sprint-reports/sprint-<n>.md` summaries.
- `escalations.md` / `blocked.md` entries where the loop could not proceed — including honest
  HALTED reports with true per-story status, which are expected, first-class outcomes.
- `main`/the default branch is **never** modified by the loop.

## 12. Build completion → the promotion phase

When the loop finishes its assigned backlog / story-group (build complete), it **stops at the
integration branch**. It does **not** promote to `main`. Promotion is a separate, explicitly
invoked phase handled by the `promotion` skill (`/promote`), gated by the `promotion` config:

- `promotion: external` (default) — a downstream actor (DevOps) merges integration→`main`. The
  loop and Pravartak take no action on `main`.
- `promotion: pravartak-gated` — Pravartak opens an integration→`main` PR, runs CI on it (the
  only place CI runs), **pauses for explicit human approval**, and squash-merges only on human
  approval **and** green CI; it halts on red CI (honest-halt). See `promotion/SKILL.md`.

In both modes the **unattended per-story loop never merges to `main`** — promotion is always a
deliberate, attended, gated step run after the loop completes. The loop's job ends at a green
integration branch; `/promote` takes it from there.
