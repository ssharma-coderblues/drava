---
name: drift-detection
description: >
  Periodic check that specs and code remain aligned. Greps discovery/ for the concepts the
  spec describes, compares to what src/ actually does, and surfaces divergences ("spec says
  X, code does Y"). The architect decides which side is canonical; the other is updated —
  spec edits applied directly, code corrections queued as corrective stories. Backs
  /drift-check. Read-only until the architect decides.
---

# Skill: drift-detection

## 1. Purpose

Specs and code drift apart over time: a story is implemented, the spec later changes, or
the implementation quietly diverges from intent. This skill detects that divergence and
presents it for an architect decision. It does not decide canonicity itself, and it does
not edit code — it reports, then routes the architect's decision to the right channel.

## 2. When to invoke

- **`/drift-check`** — run periodically (Phase 5) or on demand. `$ARGUMENTS` may scope the
  check to an area (a subsystem name, a story id, or a path under `discovery/`/`src/`); if
  empty, check the whole project.

Precondition: the project is scaffolded and has produced code (`src/` is non-empty).
On an empty `src/` there is nothing to compare; report "no code yet" and stop.

## 3. Inputs

- `discovery/**` — the authoritative spec material (the "should").
- `src/**`, `tests/**` — the implementation (the "is").
- `.claude/completed.md` — which stories have been implemented (so drift can be tied to a
  story).

## 4. Procedure

### 4.1 Extract spec concepts

Build a list of the concepts the spec describes: domain entities, operations/endpoints,
invariants and rules (e.g. idempotency, two-sided journals, money as integer minor units),
external integrations, and named behaviors. Use grep/file search across `discovery/`.
Prefer concrete, checkable concepts over vague ones.

### 4.2 Locate each concept in the code

For each concept, search `src/` and `tests/` for the corresponding implementation. Classify
each concept as:

- **Aligned** — spec and code agree.
- **Spec-only** — described in the spec, absent from code (unimplemented, or removed from
  code without a spec update).
- **Code-only** — present in code, absent from (or contradicted by) the spec (undocumented
  behavior, or behavior that outran the spec).
- **Conflicting** — both describe it, but differently ("spec says X, code does Y").

For the standards-driven invariants in `pravartak/standards/` (persistence hardening,
async-first, security baseline, observability), specifically check whether the code honors
them where the spec requires them; violations are drift.

### 4.3 Present the drift report

Present findings grouped by classification, each with: the concept, the spec location
(file + line, quoted), the code location (file + line, quoted), the linked story id if
known, and a one-line characterization of the divergence. Distinguish **likely-intentional**
drift (newer code) from **likely-accidental** drift (looks like a mistake) where you can,
but flag this as a guess — the architect decides.

Do not modify anything yet. The report is read-only.

### 4.4 Route the architect's decision

For each drift item, the architect declares which side is canonical:

- **Spec is canonical, code is wrong** → the code must change. Do **not** edit `src/`
  here. Queue a corrective story `STORY-CORR-<N>` in
  `.claude/architect_review/scope_additions.md` (same mechanism as architect-review §8),
  describing the required alignment and its acceptance criteria. The architect promotes it
  to the backlog; the autonomous loop implements it.
- **Code is canonical, spec is wrong** → the spec must change. Run a change-impact analysis
  (list every affected `discovery/` doc and other spec file, confirm with the architect),
  apply the spec edit consistently, and log it to
  `.claude/architect_review/spec_amendments.md`.
- **Both acceptable / accept the drift** → record the decision so the same item isn't
  re-flagged as a surprise next run (a short note in the drift log, §5).
- **Defer** → leave it; it will surface again next run.

### 4.5 Commit

Commit the outcome:

```text
drift: <area> — <N> items (<spec-edits> spec edits, <corr> corrective stories queued)

- Spec amendments: <files | none> (see spec_amendments.md)
- Corrective stories queued: <ids | none> (see scope_additions.md)
- Accepted/deferred: <count>
```

If the run found no drift, still commit a short record (or report cleanly without a commit
if nothing changed — prefer a one-line "no drift" report).

## 5. Drift log

Maintain `.claude/drift-reports/<date>.md` (create the directory if absent) with each run's
full report and the architect's decisions. This gives Phase 5 a history and prevents
re-litigating already-accepted drift.

## 6. Guardrails

- **Read-only until decision.** Detect and report first; change nothing before the
  architect declares canonicity.
- **Never edit `src/` to fix code drift.** Code corrections always go through corrective
  stories and the autonomous loop — never hand-patched here.
- **Spec edits go through change-impact analysis** — never patch one doc and leave others
  inconsistent.
- **Don't guess canonicity.** Offer a hint about likely intent, but the architect decides.

## 7. Outputs

- A drift report (grouped, with quoted spec/code locations) saved to
  `.claude/drift-reports/<date>.md`.
- For spec-canonical items: corrective stories in `scope_additions.md`.
- For code-canonical items: consistent spec edits + `spec_amendments.md` entries.
- A commit recording the run's outcome.
