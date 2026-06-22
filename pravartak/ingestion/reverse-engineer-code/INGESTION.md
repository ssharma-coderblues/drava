# Ingestion — Reverse-Engineer Existing Code

Archetype: `reverse-engineer-code`. High complexity (spec §4.2). You have a working
codebase but no formal spec; **the code is the source of truth**. This procedure reads the
code, synthesizes its structure and behavior into `discovery/AS_IS_ANALYSIS.md`, derives a
synthesized spec, and decomposes a draft backlog. The synthesis can be wrong — so it is
explicit about confidence and uncertainty, and the architect must validate it before review
proceeds.

Executed by `pravartak/scaffold/SCAFFOLD.md` Phase 3, given the Q4 source location (the
root of the existing codebase).

## Inputs

- **Source location** (Q4): the root of the existing codebase (any language). May or may
  not contain tests, docs, or build configuration.

## Outputs

- `discovery/AS_IS_ANALYSIS.md` — the synthesis of the existing system's structure and
  behavior, with confidence levels and an explicit unknowns/assumptions section.
- A synthesized spec in `discovery/` — derived, clearly-marked-as-inferred documents
  describing what the system does.
- `discovery/README.md` — inventory mapping each discovery document to the code area it was
  synthesized from.
- A draft `.claude/backlog.md` of stories (characterization / modernization work).

## The cardinal rule

**The code is authoritative; the synthesis is a hypothesis.** Everything this procedure
writes to `discovery/` is *inferred from* the code, not a ground-truth spec. Mark inference
as inference. Never present a guess as a fact. The architect validates the synthesis against
the code during review; a confidently-wrong synthesis is worse than an honestly-uncertain
one.

## Procedure

### 1. Survey the codebase

Breadth-first. Determine and record:

- **Languages and stack** — languages, frameworks, runtimes, major libraries.
- **Build and run** — build files, entry points, how the system starts, configuration.
- **Layout** — top-level structure; where the domain logic, I/O, and tests live.
- **Tests** — do they exist? They are the best evidence of intended behavior; read them.
- **External dependencies** — databases, message buses, HTTP services, third-party APIs.
- **Size and risk areas** — large/complex modules, anything that looks load-bearing.

Note the bounds of your survey — what you read versus what you sampled or skipped.

### 2. Synthesize structure and behavior

From the survey, infer how the system is built and what it does:

- **Components and responsibilities** — the main modules/services and what each owns.
- **Control and data flow** — how a request/event moves through the system.
- **Data model** — entities, persistence, schemas (read migrations/DDL if present).
- **External integrations** — each one's direction, protocol, and semantics.
- **Behaviors and rules** — observable behavior and domain invariants, with the evidence
  (file:line, or the test that demonstrates it).
- **Cross-cutting concerns** — error handling, concurrency, auth, observability as they
  actually appear in the code.

Use tests as behavioral evidence wherever they exist; prefer "the test asserts X" over "the
code looks like it does X."

### 3. Write `discovery/AS_IS_ANALYSIS.md`

This is the centerpiece. Structure it so the architect can validate it efficiently:

```markdown
# AS-IS Analysis — <system name>

Archetype: reverse-engineer-code
Synthesized: <SCAFFOLD_DATE>   Source: <codebase root>
Survey bounds: <what was read fully vs. sampled vs. skipped>

## Overview
<one-paragraph synthesis of what the system is and does>

## Architecture
<components, responsibilities, control/data flow — with file:line evidence>

## Data model
<entities, persistence, schemas — with evidence>

## External integrations
<each integration: direction, protocol, semantics — with evidence>

## Behaviors and invariants
| Behavior / invariant | Evidence (file:line or test) | Confidence |
| --- | --- | --- |
| Payments are idempotent on request id | tests/test_pay.py::test_dupe | High |
| Amounts stored as integer minor units | src/money.py:12 | High |
| Retries are unbounded | inferred from src/client.py:40 | Low |

## Unknowns and assumptions
<every place the synthesis is uncertain, every assumption made, every question for the
architect. Be exhaustive here — this is where reverse-engineering goes wrong.>
```

**Confidence levels are mandatory** on behaviors/invariants: High (proven by a test or
unambiguous code), Medium (strongly implied), Low (guessed). The Unknowns section is not
optional — an empty one is a red flag.

### 4. Derive the synthesized spec into `discovery/`

Split the analysis into topic documents the way the architect will reason about the system
(e.g. `discovery/payments.md`, `discovery/persistence.md`, `discovery/integrations.md`).
Each derived document:

- carries a banner at the top: `> Synthesized from code by reverse-engineering. Inferred,
  not authoritative. Validate against the source.`
- preserves the confidence/evidence markers from the analysis.

### 5. Write `discovery/README.md`

```markdown
# Discovery — Source Inventory

Archetype: reverse-engineer-code
Synthesized: <SCAFFOLD_DATE>
Source codebase: <root>

| Discovery document | Synthesized from (code area) | Confidence |
| --- | --- | --- |
| AS_IS_ANALYSIS.md | whole codebase | mixed (see doc) |
| payments.md | src/payments/** , tests/payments/** | High |
| integrations.md | src/clients/** | Medium |

Validation status: AS_IS_ANALYSIS.md must be reviewed by the architect before /review-all.
```

### 6. Decompose into a draft backlog

Reverse-engineer stories are usually **characterization + modernization** work. At ingestion
the target/modernized state is not yet known (the architect supplies modernization intent
during review), so frame stories around the system's observed capabilities:

```markdown
- [ ] STORY-001 — Characterize and re-establish <capability>
  - Scope: reproduce the observed behavior of <capability> under the new project's
    standards (tests-first), per AS_IS_ANALYSIS.md. Modernization deltas TBD in review.
  - Acceptance criteria:
    - Behavior matches AS_IS_ANALYSIS.md for <capability> (characterization tests pass)
    - <invariants from the analysis, e.g. idempotency, integer money>
  - Depends on: <STORY-0xx | none>
  - Source: discovery/AS_IS_ANALYSIS.md#<section>, discovery/<topic>.md
```

Guidance:

- **One story per coherent capability/component** — vertical slices, not layers.
- **Acceptance criteria reference the analysis** and its invariants; flag Low-confidence
  items so the architect resolves them before the loop touches them.
- **Modernization is a review-time decision** — do not bake in rewrites/replacements the
  architect hasn't approved. Stories capture "match observed behavior"; the architect adds
  the deltas (new tech, new design) during `/review-all`.
- Use the same `STORY-NNN` block format as `backlog.md.template`.

### 7. Handoff

Report to SCAFFOLD.md: discovery-document count, story count, and **explicitly flag that
`AS_IS_ANALYSIS.md` requires architect validation before `/review-all`**. Add a line to the
`PRAVARTAK_SCAFFOLD_COMPLETE` output to that effect.

## Guardrails

- **Code is authoritative; synthesis is a hypothesis** — mark inference as inference,
  always with confidence and evidence.
- **Never present a guess as a fact** — the Unknowns/assumptions section must be complete.
- **No unapproved modernization** — ingestion characterizes the as-is; modernization deltas
  are the architect's call during review.
- **Draft only** — produces a draft backlog and a synthesis to validate; does not review or
  implement.
- **Traceability** — every derived doc and story points back to specific code (file:line or
  test) it was synthesized from.
