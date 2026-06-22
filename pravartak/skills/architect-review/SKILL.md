---
name: architect-review
description: >
  Standalone, human-gated walkthrough of the story backlog. For each story, present
  the story, its linked requirements, and the review runtime's reasoning; capture the
  architect's decision; propagate approved spec changes consistently across all docs;
  commit per story. Resumable. Backs the /review-all and /review-story commands. This is
  Phase 3 of the pipeline and is NOT autonomous execution — it never writes production code.
---

# Skill: architect-review

## 1. Purpose

Architect review is the one phase that is fully human-gated. The architect walks the
backlog story by story, validates each against its linked requirements, and either
approves it or drives a change. Approved spec changes are propagated consistently across
every affected document. Nothing in the backlog is considered ready for the autonomous
loop until it has been REVIEWED (or explicitly SKIPPED) here.

This skill **never** writes production code, never edits `src/`, and never launches
auto-mode. It operates only on `discovery/`, `.claude/backlog.md`, and the review state
files. See §9 (Guardrails).

## 2. When to invoke

Backs two commands:

- **`/review-all`** — sequential walkthrough of every story in `.claude/backlog.md`,
  supporting pause/resume. Invoke with no arguments.
- **`/review-story <STORY-ID>`** — ad-hoc review of a single story. `$ARGUMENTS` carries
  the story id.

Determine mode from `$ARGUMENTS`: empty → review-all; a story id → review-story.

Precondition: the project has been scaffolded (a populated `.claude/backlog.md` and a
`discovery/` directory exist). If `.claude/backlog.md` is missing or empty, stop and tell
the architect to run `/scaffold` (and the relevant ingestion) first.

For the `loose-docs` archetype: if `discovery/CONTRADICTIONS.md` lists unresolved
contradictions, refuse to start review and ask the architect to resolve them first.

## 3. Inputs

- `.claude/backlog.md` — the flat list of stories (id, title, scope, acceptance criteria,
  dependencies, source pointer).
- `discovery/**` — normalized source material; the authority a story is validated against.
- Optional: sibling Pravartak-managed projects the architect names, for reference patterns.

## 4. State files this skill owns

All under `.claude/architect_review/` unless noted:

| File | Role |
| --- | --- |
| `progress.md` | One row per story: `PENDING` / `REVIEWED` / `SKIPPED`, with timestamp. The source of truth for what's done. |
| `session.md` | The in-progress session: which story is current, where the architect paused, free-form session notes. Empty when no session is active. |
| `spec_amendments.md` | Log of every approved spec change, with the change-impact analysis and the list of files touched. |
| `scope_additions.md` | Draft stories from scope additions (§7) and corrective stories `STORY-CORR-N` (§8). The architect later promotes these into `backlog.md`. |
| `findings/` | Per-story finding notes (one file per story id) when a review produces detail worth preserving beyond the commit message. |
| `reviews/` | (project root `.claude/reviews/`) Per-story review records — the durable artifact of each story's review. |
| `SUMMARY.md` | Written at completion (§6). |

These are project-owned files initialized by the scaffold from templates. This skill reads
and appends to them; it does not recreate them.

## 5. Procedure

### 5.0 Resume or start

1. Read `session.md`. If a session is in progress (a current story is recorded and not yet
   resolved), tell the architect where the last session paused and offer:
   **continue from here** or **restart the session**.
2. Read `progress.md` to know which stories are `PENDING`.
3. In **review-all** mode, build the work list = stories that are `PENDING`, in backlog
   order. In **review-story** mode, the work list is the single requested story (review it
   even if already `REVIEWED`; note the re-review in its record).

### 5.1 Per-story procedure

For each story in the work list, perform these six steps. This is the generalized
CashApp2 rhythm (spec §10.2).

1. **Present the story.** Quote from `.claude/backlog.md`: id, title, scope, acceptance
   criteria, dependencies, and the source pointer into `discovery/`.

2. **Present linked requirements.**
   - Quote the source document **verbatim** at the pointer.
   - Search all of `discovery/` for cross-references to the same concept and list them
     (use grep/file search; show file + line).
   - If the architect named sibling Pravartak-managed projects, surface relevant reference
     patterns from them.

3. **Present the review runtime's reasoning.** Concisely:
   - How the story implements the requirement.
   - Which GoF patterns fit (name them) and which would be forcing it.
   - SOLID risks specific to this story.
   - What tests will be needed (unit / integration / contract / error-path) per the
     standards in `pravartak/standards/`.
   - Edge cases that matter and risks an architect should flag.

4. **Open the floor.** The architect responds with one of:
   - **approve** — accept as-is.
   - **skip** — defer; mark `SKIPPED`.
   - **pause** — stop the session, preserving state (§5.4).
   - **add-scope: …** — invoke the scope-addition sub-flow inline (§7).
   - **free-form feedback** — anything else; if it implies a spec change, go to §5.2.

5. **Apply approved changes** (only if feedback implies a spec change) — see §5.2.

6. **Commit per story** (§5.3) — every story produces a commit, even no-change approvals.

### 5.2 Change-impact analysis (when feedback implies a spec change)

Spec changes must be consistent across every document. Never patch one file and leave
others stale.

1. **Determine whether the story is already implemented.** Check `.claude/completed.md`
   (and git history) for the story id.
   - If **already implemented**: do **not** edit `src/`. Instead, queue a corrective story
     in `scope_additions.md` (see §8) and record the spec change for the spec docs only.
   - If **not yet implemented**: proceed to edit the spec docs.
2. **List affected files.** Search `discovery/`, `.claude/backlog.md`, and any other spec
   docs for every place the changed concept appears. Present the full list.
3. **Get explicit confirmation** of the file list and the exact change before editing.
4. **Apply consistently** across all listed files.
5. **Log it** in `spec_amendments.md`: the story id, the change, the file list, and the
   timestamp.

### 5.3 Commit per story

After resolving a story:

1. Update `progress.md`: set the story to `REVIEWED` or `SKIPPED` with a timestamp.
2. Write/append the story's review record under `.claude/reviews/<STORY-ID>.md`
   (decision, rationale, any change-impact summary). For detailed findings, also write
   `.claude/architect_review/findings/<STORY-ID>.md`.
3. Stage and commit. Suggested message:

   ```text
   review(<STORY-ID>): <approve|skip|amend> — <one-line summary>

   - Decision: <approve|skip|amend>
   - Spec changes: <none | files touched, see spec_amendments.md>
   - Scope/corrective stories queued: <none | ids>
   ```

   No-change approvals still commit (granular audit history is the point).

### 5.4 Pause and resume

On **pause**, write to `session.md`: the current story id, the work-list position, and any
free-form notes, then stop cleanly. Do not mark the current story resolved. On the next
`/review-all`, §5.0 detects the in-progress session and offers continue/restart.

## 6. Completion

Review is complete when every story in `progress.md` is `REVIEWED` or `SKIPPED`. Then:

1. Generate `.claude/architect_review/SUMMARY.md`: counts (reviewed / skipped / amended),
   the list of spec amendments, the list of queued scope and corrective stories, and the
   recommended next action.
2. Clear the active session in `session.md`.
3. Remind the architect to **promote** scope additions and corrective stories from
   `scope_additions.md` into `.claude/backlog.md`, and that autonomous execution should be
   launched **only after** promotion is done.

In **review-story** mode there is no completion summary; the skill ends after the single
story's commit.

## 7. Scope-addition sub-flow

When the architect says `add-scope: …` (or runs `/add-scope` standalone), hand off to the
scope-addition skill: read `pravartak/skills/scope-addition/SKILL.md` and execute its
procedure. It captures draft stories to `scope_additions.md` only after the architect
approves. On return, continue the current story's review where it left off.

## 8. Spec/code drift — corrective stories

If a spec change affects a story that auto-mode has already implemented (§5.2), do not edit
the code. Append a corrective story to `scope_additions.md`:

```text
### STORY-CORR-<N> — Align <area> with amended spec for <STORY-ID>
- Source: spec amendment <date> (see spec_amendments.md)
- Scope: bring the existing implementation of <STORY-ID> into line with the amended spec.
- Acceptance criteria: <derived from the amended spec>
- Depends on: <STORY-ID> (already implemented)
```

Corrective stories are promoted to the backlog by the architect, where the autonomous loop
picks them up. Spec changes are immediate; code alignment is queued. This keeps review
focused on intent rather than implementation.

## 9. Guardrails

- **Never** write or edit production code (`src/`, `tests/`) — that is the autonomous
  loop's job. This skill edits only `discovery/`, the review state files, and `backlog.md`
  metadata (status), never application source.
- **Never** launch autonomous execution or suggest doing so before review is complete.
- **Never** apply a spec change without first presenting the affected-files list and
  getting explicit confirmation.
- **Never** silently overwrite an already-implemented story's code — queue a corrective
  story instead.
- Commit per story; do not batch multiple stories into one commit.

## 10. Outputs

- Updated `progress.md` (every story REVIEWED/SKIPPED).
- Per-story review records in `.claude/reviews/` (and findings where warranted).
- `spec_amendments.md` reflecting all approved spec changes, applied consistently.
- `scope_additions.md` with draft scope stories and corrective stories awaiting promotion.
- One commit per story.
- `SUMMARY.md` at completion (review-all mode).
