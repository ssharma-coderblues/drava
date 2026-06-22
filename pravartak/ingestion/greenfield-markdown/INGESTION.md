# Ingestion — Greenfield with Markdown Specs

Archetype: `greenfield-markdown`. The simplest archetype (spec §4.1). You already have
markdown documents describing what to build; this procedure normalizes them into
`discovery/` and decomposes them into a draft backlog. No synthesis, no contradiction
resolution — the markdown is taken as authoritative.

Executed by `pravartak/scaffold/SCAFFOLD.md` Phase 3, given the Q4 source location (a
directory or file of markdown specs).

## Inputs

- **Source location** (Q4): a path to a directory of markdown files, or a single markdown
  file. Validated by the wizard to exist and be readable.

## Outputs

- A populated `discovery/` with normalized markdown.
- `discovery/README.md` — the source inventory (what was ingested, when, and which
  discovery document maps to which source).
- A draft `.claude/backlog.md` of decomposed stories.

## Procedure

### 1. Inventory the source

List every markdown file at the source location (recurse into subdirectories). Record for
each: original path, size, and a one-line description of what it covers (from its top
heading or first paragraph). Note any non-markdown files encountered and flag them — this
archetype expects markdown; substantial non-markdown content suggests `loose-docs` instead.

If the source is large or clearly multi-topic, group the files by topic before
normalizing.

### 2. Normalize into `discovery/`

For each source document, write a normalized copy into `discovery/` such that:

- **Content is preserved faithfully** — do not rewrite, summarize, or "improve" the spec.
  Normalization is structural, not editorial. The architect must be able to trust that
  `discovery/` says exactly what the source said.
- **Filenames are stable and descriptive** — kebab-case, topic-based (e.g.
  `settlement-architecture.md`, `event-contract.md`), not the source's incidental names.
- **Headings are consistent** — a single top-level `#` title per file; promote/demote
  heading levels only to fix obviously broken nesting, never to change meaning.
- **Light fixes only** — repair broken markdown (unclosed fences, tables), normalize
  line endings. Do not touch wording.

If a single source file mixes several distinct topics, you may split it into multiple
`discovery/` files — but record the split in the inventory so provenance is traceable.

### 3. Write `discovery/README.md`

Produce the source inventory:

```markdown
# Discovery — Source Inventory

Archetype: greenfield-markdown
Ingested: <SCAFFOLD_DATE>
Source: <Q4 source location>

| Discovery document | Source file(s) | Covers |
| --- | --- | --- |
| settlement-architecture.md | docs/settlement.md | Settlement flow and ledger model |
| event-contract.md | docs/events.md (§2-4) | Event schemas and delivery semantics |

Notes: <splits, merges, anything an architect should know about how sources map here>
```

### 4. Decompose into a draft backlog

Read the normalized `discovery/` and break the work into a flat list of executable stories.

**What becomes a story:** a unit of work small enough to implement test-first in one
autonomous-loop iteration, with acceptance criteria inferable from the spec. Prefer
vertical slices (a working capability) over horizontal layers.

**Story id scheme:** `STORY-NNN`, three-digit zero-padded, assigned in source/dependency
order (`STORY-001`, `STORY-002`, …). Ids are stable — never renumber later; new stories
get the next number, scope/corrective stories use their own prefixes.

**Each story** is written to `.claude/backlog.md` in this block format (it must match
`backlog.md.template` so architect-review and the autonomous loop can both parse it):

```markdown
- [ ] STORY-001 — <concise imperative title>
  - Scope: <what this story does and explicitly does not do>
  - Acceptance criteria:
    - <criterion 1, testable>
    - <criterion 2, testable>
  - Depends on: <STORY-0xx, … | none>
  - Source: discovery/<file>.md#<section-or-anchor>
```

Guidance:

- **Acceptance criteria must be testable** — phrase them so a test can prove them. If the
  spec does not state acceptance criteria, derive them from the described behavior and mark
  them as derived (the architect validates these in review).
- **Dependencies are real** — only list a dependency when the story genuinely cannot be
  built first. The autonomous loop honors these for ordering.
- **Source pointer is mandatory** — every story points back to the `discovery/` location
  it came from, so architect-review can quote the requirement verbatim.
- **Do not invent scope** — decompose only what the spec describes. Gaps become questions
  for architect review, not assumptions baked into stories.

Optionally group stories under sprint headings if the source implies phasing; otherwise a
flat ordered list is fine (the loop tags sprints by batch).

### 5. Handoff

Report to SCAFFOLD.md: the number of discovery documents produced and the number of stories
decomposed (these feed the `PRAVARTAK_SCAFFOLD_COMPLETE` report). The backlog is a **draft**
— architect review (`/review-all`) is where it is validated. Do not mark any story reviewed
or attempt to implement anything here.

## Guardrails

- **Faithful normalization** — never edit the meaning of the source; `discovery/` is the
  authority architect-review quotes against.
- **Draft only** — ingestion produces a draft backlog; it does not review or implement.
- **No invented scope** — decompose what exists; surface gaps for review rather than
  guessing.
- **Traceability** — every discovery doc maps to a source in the inventory; every story
  maps to a discovery location.
