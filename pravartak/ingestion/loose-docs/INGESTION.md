# Ingestion — Loose Requirement Documents

Archetype: `loose-docs`. The hardest archetype (spec §4.5). The source is whatever the team
has: PDFs, Word docs, emails, slide decks, scraps of notes — inconsistent, partial, and
sometimes contradictory. This procedure normalizes everything to markdown, classifies what
is authoritative versus notes versus ideas, synthesizes a consolidated spec, and — crucially
— surfaces every contradiction in `discovery/CONTRADICTIONS.md`. **The architect must resolve
all contradictions before `/review-all` can begin.**

Executed by `pravartak/scaffold/SCAFFOLD.md` Phase 3, given the Q4 source location (a
directory of documents in mixed formats).

## Inputs

- **Source location** (Q4): a path to a directory of documents in mixed formats (`.pdf`,
  `.docx`, `.pptx`, `.md`, `.txt`, `.eml`, `.html`, …). Validated by the wizard to exist and
  be readable.

## Outputs

- A populated `discovery/` with every source normalized to faithful markdown, each tagged by
  authority class (authoritative / notes / ideas).
- `discovery/SYNTHESIS.md` — the consolidated spec synthesized across all sources, with
  provenance and confidence on every consolidated statement.
- `discovery/CONTRADICTIONS.md` — every place sources disagree, **with a required resolution
  field the architect fills in**. Mandatory; an empty one means "none found," stated explicitly.
- `discovery/README.md` — the source inventory and authority classification.
- A draft `.claude/backlog.md` of decomposed stories — **gated**: not finalized until
  contradictions are resolved (see step 6).

## The cardinal rule

**Synthesis is a hypothesis; the architect resolves conflicts, not Pravartak.** This
procedure does not pick a winner when sources disagree, does not quietly drop the loser, and
does not average them. It surfaces the disagreement faithfully and waits. Forcing a resolution
here is the failure mode this archetype exists to prevent.

## Procedure

### 1. Inventory and convert everything to markdown

List every file at the source (recurse). For each, convert to faithful markdown:

- **PDF / Word / slides / email / HTML → markdown**, mechanically. Preserve tables, headings,
  and lists; footnote images/diagrams that do not convert (`> [diagram: settlement-flow.png
  — not transcribed]`).
- **Content is preserved faithfully** — no rewriting, summarizing, or improving. Conversion
  is structural.
- If a format cannot be converted (scanned image, proprietary binary), record it in the
  inventory as **un-ingested** with a note, rather than guessing its contents.

### 2. Classify authority

For each normalized document, assign an **authority class** and tag it at the top of the file:

- **authoritative** — signed-off specs, approved designs, contracts. The intended source of
  truth.
- **notes** — meeting notes, working docs, partial drafts. Useful context, not binding.
- **ideas** — brainstorms, proposals, "what if" emails. Candidate scope, explicitly not
  committed.

When a document's class is unclear, mark it **authoritative?** and add it to the questions for
the architect. Classification drives synthesis weighting and is itself reviewable.

### 3. Synthesize the consolidated spec → `discovery/SYNTHESIS.md`

Build a single coherent spec from the authoritative sources (with notes/ideas as supporting
context, clearly subordinate). Every consolidated statement carries provenance and confidence:

```markdown
# Synthesis — <project>

Archetype: loose-docs
Synthesized: <SCAFFOLD_DATE>   Source: <directory>
> Synthesized across mixed sources. Inferred where marked; validate against the originals.

## <Topic>
- Settlement posts a two-sided journal entry. [authoritative: settlement-spec.md §3] (High)
- Reconciliation runs nightly at 02:00 UTC. [notes: standup-2026-05.md] (Low — notes only)
- Idea: support intraday reconciliation. [ideas: email-cfo.md] (candidate scope, not committed)

## Open questions for the architect
- <every place the synthesis had to choose an interpretation, every unclassifiable doc>
```

Confidence reflects source authority and agreement, not your certainty about the world. A
claim resting only on `notes`/`ideas` is Low regardless of how plausible it is.

### 4. Surface contradictions → `discovery/CONTRADICTIONS.md`

This is the centerpiece. Compare sources pairwise on every shared topic and record **every**
disagreement — factual conflicts, incompatible numbers, mutually exclusive requirements, and
authoritative-vs-notes conflicts. Do not resolve them.

```markdown
# Contradictions — <project>

Archetype: loose-docs
Identified: <SCAFFOLD_DATE>
Status: UNRESOLVED — the architect must resolve every entry before /review-all.

## C-001 — Reconciliation cadence
- Source A [authoritative: settlement-spec.md §4]: nightly at 02:00 UTC
- Source B [notes: standup-2026-05.md]: "we agreed on hourly"
- Affected synthesis: SYNTHESIS.md "Reconciliation runs nightly…"
- Affected draft stories: STORY-014
- **Resolution (architect):** _<blank — architect fills this in>_

## C-002 — Money representation
- Source A [authoritative: event-contract.pdf p.7]: integer minor units
- Source C [ideas: prototype-readme.md]: decimal strings
- Affected synthesis: SYNTHESIS.md "Amounts are integer minor units"
- Affected draft stories: STORY-003, STORY-021
- **Resolution (architect):** _<blank>_
```

If genuinely no contradictions exist, write the file with `Status: NONE FOUND` and an empty
list, explicitly — never omit the file.

### 5. Write `discovery/README.md`

```markdown
# Discovery — Source Inventory

Archetype: loose-docs
Ingested: <SCAFFOLD_DATE>
Source: <directory>

| Discovery document | Source file | Format | Authority | Notes |
| --- | --- | --- | --- | --- |
| settlement-spec.md | settlement.pdf | pdf | authoritative | converted; diagrams footnoted |
| standup-notes.md | standup-2026-05.docx | docx | notes | — |
| prototype-readme.md | proto/README | md | ideas | — |
| scan-contract.* | contract.png | image | UN-INGESTED | scanned; not transcribed |

Synthesis: discovery/SYNTHESIS.md
Contradictions: discovery/CONTRADICTIONS.md — Status: UNRESOLVED (N entries)
```

### 6. Decompose a draft backlog — gated on resolution

Decompose `SYNTHESIS.md` into stories using the standard block format
(`backlog.md.template`), sourcing each story to `discovery/SYNTHESIS.md` (and through it to
the originals). **But the backlog is provisional until contradictions are resolved:**

- Any story touched by an unresolved contradiction is marked
  `BLOCKED — see CONTRADICTIONS.md#C-0xx` in its scope line and is **not** counted as ready.
- Stories derived only from `ideas`-class sources are included but flagged
  `candidate scope — not committed` for the architect to confirm or drop.
- Acceptance criteria derived from `notes`/`ideas` are marked derived/low-confidence.

### 7. Handoff

Report to SCAFFOLD.md: discovery-document count, story count, and — prominently — the
**contradiction count and UNRESOLVED status**. Add a blocking line to
`PRAVARTAK_SCAFFOLD_COMPLETE`:

```text
  loose-docs: CONTRADICTIONS.md has N UNRESOLVED entries.
  Resolve all entries before running /review-all. Auto-mode must not start until then.
```

The scaffold still completes and commits (the discovery work is real and worth saving), but
the report makes clear the pipeline is **gated** at contradiction resolution. Do not review
or implement here, and do not resolve contradictions on the architect's behalf.

## Guardrails

- **Never resolve a contradiction yourself** — surface it; the architect decides. This is the
  whole point of the archetype (spec §4.5).
- **Faithful conversion, no improvement** — `discovery/` and its originals are the authority.
- **Authority classification is explicit** — every doc is authoritative / notes / ideas (or
  flagged unclear); synthesis weights accordingly and says so.
- **Provenance and confidence on every synthesized statement** — no claim without a source
  tag and a confidence level.
- **CONTRADICTIONS.md is mandatory** — even when empty (`Status: NONE FOUND`).
- **Backlog is gated** — stories under unresolved contradictions are BLOCKED; the pipeline
  does not advance to review until the architect resolves them.
- **Draft only · no invented scope · traceability** — as for every archetype.
