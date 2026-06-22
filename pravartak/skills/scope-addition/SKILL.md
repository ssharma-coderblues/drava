---
name: scope-addition
description: >
  Bring a new external system into a project's scope. The architect points the active
  review runtime at a repo and/or docs; it reads to the requested depth, asks clarifying
  questions, recommends an integration path (with options where there is genuine choice),
  identifies doc impact, and proposes draft stories — capturing nothing to
  scope_additions.md until the architect approves. Backs /add-scope and the inline
  "add-scope: …" sub-flow of architect review.
---

# Skill: scope-addition

## 1. Purpose

During (or outside) architect review, the architect realizes the project must integrate
with another system — a sibling service, a shared library, a third-party API. This skill
turns that realization into reviewed, approved draft stories without polluting the backlog
prematurely. It reads the new system, builds shared understanding, proposes an integration
path and stories, and only writes to `scope_additions.md` after the architect approves.

Like architect-review, this skill **never** writes production code. Its output is draft
stories and an integration proposal, not implementation.

## 2. When to invoke

- **`/add-scope`** — standalone. `$ARGUMENTS` may carry an initial hint (e.g. a system
  name or path); treat it as the starting point and still run the full procedure.
- **Inline from architect-review** — when the architect says `add-scope: …` mid-story.
  In this case, on completion, return control to the calling review so it can continue the
  current story.

Precondition: the project is scaffolded. This skill appends to
`.claude/architect_review/scope_additions.md`, which the scaffold created.

## 3. Inputs (gathered from the architect)

Ask for these up front; do not assume them:

1. **The new system's location** — repo path(s) and/or doc path(s) (local paths, URLs, or
   Confluence/Jira references the architect supplies).
2. **Read depth** — how deeply to read:
   - *skim* — READMEs, public interfaces, top-level structure only.
   - *interfaces* — the above plus all public APIs/contracts/schemas.
   - *deep* — the above plus implementation details relevant to integration.
3. **Integration intent** — in one or two sentences, what the project needs from this
   system (consume an API? emit events to it? share a data model? embed a library?).

## 4. Procedure

### 4.1 Read the source material

Read the provided repos/docs to the requested depth. Prefer breadth-first: structure and
public surface before internals. Capture, as you go:

- What the system does and its boundaries.
- Its public interface relevant to the integration (endpoints, events, schemas, library
  APIs).
- Operational facts that affect integration (auth model, sync vs. async, idempotency
  guarantees, error semantics, rate limits, data ownership).

If the source is large, summarize rather than quoting wholesale, and note what you did
**not** read (so the architect knows the bounds of the analysis).

### 4.2 Ask clarifying questions

Before proposing anything, ask the architect the questions the source material left open —
genuine ambiguities only, not questions answered by the docs. Typical: direction of data
flow, ownership of shared entities, consistency/latency requirements, failure-handling
expectations, versioning/compatibility constraints.

Wait for answers before continuing.

### 4.3 Synthesize understanding

Present a concise synthesis back to the architect: what the system is, how it would relate
to this project, and the integration surface. Confirm the synthesis is correct before
proposing stories — a wrong synthesis produces wrong stories.

### 4.4 Recommend an integration path

Propose an integration approach. **Where there is genuine architectural choice, present
multiple options** with trade-offs (e.g. synchronous API call vs. event-driven; shared
library vs. service boundary; anti-corruption layer vs. direct model reuse). Make a
recommendation and say why. Where there is only one sensible path, say so and don't
manufacture false choices.

Tie the recommendation to the standards in `pravartak/standards/` (async-first,
integration tests required for external integrations, security baseline for credentials).

### 4.5 Identify documentation impact

List which `discovery/` documents and other spec files the new scope touches or
contradicts. This feeds the architect's decision and any later change-impact analysis in
architect-review.

### 4.6 Propose draft stories

Draft stories that implement the chosen integration. Each draft story has the same shape
as a backlog story: a proposed id (use a clearly-draft prefix, e.g. `STORY-SCOPE-<area>-N`),
title, scope, acceptance criteria (including the integration tests the standards require),
dependencies, and a source pointer to the new system's docs. Present them for review.

### 4.7 Capture only after approval

**Do not write to `scope_additions.md` until the architect approves.** On approval, append
to `.claude/architect_review/scope_additions.md`:

- A short integration record: the system, the chosen path (and rejected options, briefly),
  the doc-impact list.
- The approved draft stories, verbatim.

If the architect rejects or defers, capture nothing (or capture only a one-line note if
the architect explicitly asks to remember the idea).

### 4.8 Commit and return

Commit the change:

```text
scope: add <system-name> integration — <N> draft stories

- Integration path: <chosen approach>
- Doc impact: <files>
- Draft stories: <ids> (awaiting promotion to backlog)
```

If invoked inline from architect-review, return control so the current story's review
continues. If invoked standalone, remind the architect that draft stories live in
`scope_additions.md` and are promoted to `backlog.md` by the architect (not automatically),
the same way corrective stories are.

## 5. Guardrails

- **Capture nothing without approval.** No writes to `scope_additions.md` before the
  architect approves the draft stories.
- **Never** add stories directly to `.claude/backlog.md`. Promotion from
  `scope_additions.md` to the backlog is the architect's manual step.
- **Never** write production code or modify `src/`.
- **Present real choices, not false ones.** Offer multiple options only where genuine
  architectural choice exists; otherwise recommend the single sensible path.
- **State the bounds of your reading.** If you skimmed or skipped parts, say so.

## 6. Outputs

- A clarified, architect-confirmed synthesis of the new system.
- An integration proposal with options/trade-offs where applicable and a recommendation.
- A documentation-impact list.
- Approved draft stories appended to `scope_additions.md` (awaiting promotion).
- One commit recording the scope addition.
