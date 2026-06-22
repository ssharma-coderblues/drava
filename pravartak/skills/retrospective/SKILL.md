---
name: retrospective
description: >
  After a sprint or at project end, produce a structured retrospective. Reads the sprint
  reports, completed/blocked logs, escalations, and commit log, plus the architect's
  free-form notes, and writes a retrospective covering what went well, what didn't,
  library improvements to upstream to Pravartak, and project patterns worth keeping.
  Optionally files the library improvements as issues against the Pravartak repo. Backs
  /retrospect.
---

# Skill: retrospective

## 1. Purpose

A retrospective captures what was learned so the next sprint — and the next project —
benefits. Its most important output for the ecosystem is the list of **library
improvements to upstream to Pravartak**: the gotchas and patterns that should be baked into
the library so no future project rediscovers them (this is exactly how the §14 lessons
came to exist).

## 2. When to invoke

- **`/retrospect`** — at a sprint boundary or at project end. `$ARGUMENTS` selects scope:
  - a sprint number (e.g. `3`) → retrospective for that sprint.
  - empty or `project` → whole-project retrospective.

Precondition: there is something to reflect on — at least one entry in `completed.md` or at
least one sprint report. If the project has done nothing yet, say so and stop.

## 3. Inputs

Read all that exist (be robust to either sprint-report location — see §6):

- `docs/sprint-reports/sprint-*.md` and/or `.claude/sprint-reports/*` — sprint summaries.
- `.claude/completed.md` — what shipped.
- `.claude/blocked.md` — what stalled and why.
- `.claude/escalations.md` — where auto-mode halted and how it resolved.
- `.claude/commit_log.txt` and git history — pace and shape of the work.
- The architect's **free-form notes** — ask for them explicitly; they carry the qualitative
  signal the files don't.

## 4. Procedure

1. **Gather.** Read the inputs in §3 for the selected scope (one sprint, or all sprints for
   a project retro). Summarize the quantitative picture: stories completed, blocked, and
   escalated; sprint cadence; notable patterns in the commit log.
2. **Ask for the architect's notes.** Prompt for free-form input: what felt good, what was
   painful, surprises, near-misses. Wait for the response (a retrospective written only
   from files misses the point).
3. **Synthesize** the retrospective document (§5).
4. **Confirm** the draft with the architect; revise as asked.
5. **Write** the document to its target (§6) and **commit**.
6. **Offer to upstream** the library improvements as issues against the Pravartak repo
   (§7) — only with explicit approval.

## 5. Retrospective structure

Produce these sections:

- **Summary** — scope (which sprint / whole project), dates, the quantitative picture.
- **What went well** — concrete, attributed to causes, not platitudes.
- **What didn't** — concrete problems, with the evidence (blocked/escalation entries, slow
  stories), framed as causes not blame.
- **Library improvements to upstream to Pravartak** — the headline section. Each item:
  - the problem observed (with evidence),
  - the proposed change to the **library** (a skill, a language pack, a template, a
    standard, the PLAYBOOK, or a new encoded lesson),
  - which part of `pravartak/` it would touch.
  Phrase these as actionable changes, the way §14's lessons are phrased.
- **Project patterns worth keeping** — conventions, abstractions, or test approaches this
  project found that future projects should reuse (these may become standards or examples).
- **Follow-ups for this project** — anything to carry into the next sprint (distinct from
  library changes).

## 6. Output location

- Whole-project retro → `docs/retrospective.md`.
- Per-sprint retro → `docs/retrospective-sprint-<n>.md`.

Create `docs/` if it does not exist. Give the file an inline provenance-style header noting
it was produced by the retrospective skill, the Pravartak version, and the date.

Note on sprint reports: the autonomous loop writes them under `docs/sprint-reports/`
(spec §11.3) while the scaffold provisions `.claude/sprint-reports/` (spec §6.3). Read
whichever exists; do not fail if one is absent.

## 7. Upstreaming library improvements

After the document is committed, offer to file the **library improvements** as issues
against the Pravartak repository:

- Only with the architect's explicit approval.
- One issue per improvement, titled clearly, body = the problem + proposed library change +
  the `pravartak/` area it touches (copied from §5).
- Use `gh issue create --repo <pravartak-repo>` if `gh` is available and the architect
  supplies/confirms the repo; otherwise output the issue text for the architect to file
  manually.
- Record the filed issue URLs (or the manual-filing note) back in the retrospective
  document.

This closes the loop: project learnings become library improvements for the next minor
release (spec §16.6).

## 8. Guardrails

- **Do not write the document from files alone** — always incorporate the architect's
  notes.
- **Do not file issues without approval**, and never to a repo the architect hasn't
  confirmed.
- **Library improvements target the library, not this project** — keep them distinct from
  project follow-ups so they're actually upstreamable.
- This skill is reflective only: it does not change `src/`, specs, or the backlog.

## 9. Outputs

- `docs/retrospective.md` (or `docs/retrospective-sprint-<n>.md`), committed.
- A clearly separated list of library improvements to upstream.
- Optionally, filed Pravartak issues (URLs recorded in the document).
