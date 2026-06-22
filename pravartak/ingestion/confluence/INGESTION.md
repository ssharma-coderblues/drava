# Ingestion — Specs in Confluence

Archetype: `confluence`. Medium complexity (spec §4.3). The authoritative spec lives in
Confluence pages. This procedure fetches them, converts them to faithful markdown, places
them in `discovery/`, and decomposes a draft backlog. Connection details (MCP tools,
credentials, REST fallback) are in `connector.md` — read it first.

Two sub-variants:

- **Pull-once snapshot (recommended, default).** Fetch once at scaffold time; the markdown
  in `discovery/` is authoritative thereafter. Confluence is no longer consulted.
- **Live sync (advanced).** Fetch on demand; spec changes made during architect review are
  written back to Confluence via the API. Only use this when the architect explicitly
  requests it and write-back credentials are configured (see `connector.md`).

Executed by `pravartak/scaffold/SCAFFOLD.md` Phase 3, given the Q4 source location (a
Confluence space key and/or a set of page IDs or paths).

## Inputs

- **Source location** (Q4): a Confluence space key (e.g. `CASH`) and/or an explicit list of
  page IDs or page paths. May include a root page whose descendants are all in scope.
- **Sub-variant**: `pull-once` (default) or `live-sync`. If not specified, use `pull-once`.
- **Credentials**: configured per `connector.md`. The wizard validates connectivity before
  this procedure runs.

## Outputs

- A populated `discovery/` with normalized markdown, one document per source page (or per
  logical topic where pages are split/merged).
- `discovery/README.md` — the source inventory mapping each discovery document to its
  Confluence page (page ID, title, space, last-modified, version) and the sub-variant used.
- A draft `.claude/backlog.md` of decomposed stories.

## Procedure

### 1. Connect and enumerate

Following `connector.md`, establish the connection and enumerate the in-scope pages:

- If given a space key, list its pages (or the descendants of a named root page).
- If given explicit page IDs/paths, resolve each to a page.
- Record for each page: page ID, title, space key, version number, last-modified
  timestamp, and the author. This metadata is the provenance you will write to the
  inventory; it is also how `live-sync` later detects upstream changes.

Confirm the resolved page set with the architect if the count is surprising (e.g. a space
with hundreds of pages when a handful were expected).

### 2. Fetch and convert to markdown

For each in-scope page, fetch its content and convert to faithful markdown:

- **Content is preserved faithfully** — do not rewrite, summarize, or "improve" the spec.
  Conversion is mechanical (Confluence storage format / ADF → markdown), not editorial.
- **Convert structure, not just text** — tables become markdown tables, panels/info-boxes
  become blockquotes with a label, code macros become fenced code blocks, status macros
  become inline text. Preserve heading hierarchy.
- **Resolve or footnote attachments and embeds** — images and attachments are referenced by
  a note (`> [Confluence attachment: diagram.png — not fetched]`) unless the architect asked
  to download them. Embedded Jira macros, draw.io diagrams, and the like are footnoted with
  what they were, since their content does not survive conversion.
- **Resolve internal links** — links between in-scope pages are rewritten to point at the
  corresponding `discovery/` file; links to out-of-scope pages are left as absolute
  Confluence URLs with a note.
- **Filenames are stable and descriptive** — kebab-case, topic-based, not the page's
  incidental title. One top-level `#` per file.

If a single large page covers several distinct topics, you may split it into multiple
`discovery/` files; if several tiny pages cover one topic, you may merge them. Record every
split/merge in the inventory so provenance stays traceable.

### 3. Write `discovery/README.md`

```markdown
# Discovery — Source Inventory

Archetype: confluence (<pull-once | live-sync>)
Ingested: <SCAFFOLD_DATE>
Source: Confluence space <KEY> / pages <ids>

| Discovery document | Confluence page (ID · title) | Space | Version | Last modified |
| --- | --- | --- | --- | --- |
| settlement-architecture.md | 12345 · Settlement Architecture | CASH | v7 | 2026-05-30 |
| event-contract.md | 12389 · Event Contract (§2-4) | CASH | v3 | 2026-06-02 |

Sub-variant: pull-once (Confluence not consulted after this snapshot).
Notes: <splits, merges, footnoted attachments, out-of-scope links, anything the architect
should know about how pages map here>
```

For `live-sync`, add a line recording that page versions above are the sync baseline and
that write-back is enabled.

### 4. Decompose into a draft backlog

Read the normalized `discovery/` and break the work into a flat list of executable stories,
using the same rules and block format as `greenfield-markdown` (must match
`backlog.md.template`):

```markdown
- [ ] STORY-001 — <concise imperative title>
  - Scope: <what this story does and explicitly does not do>
  - Acceptance criteria:
    - <criterion 1, testable>
    - <criterion 2, testable>
  - Depends on: <STORY-0xx, … | none>
  - Source: discovery/<file>.md#<section-or-anchor>
```

- **Acceptance criteria must be testable.** Confluence specs are often prose; where they do
  not state criteria, derive them from the described behavior and mark them as derived for
  architect validation.
- **Source pointer is mandatory** — point at the `discovery/` file (which itself records the
  originating Confluence page), so architect-review can quote the requirement verbatim.
- **No invented scope** — decompose what the pages describe; surface gaps as questions for
  review, not assumptions.

### 5. Handoff

Report to SCAFFOLD.md: discovery-document count and story count (for the
`PRAVARTAK_SCAFFOLD_COMPLETE` report), plus the sub-variant used. If `live-sync` is enabled,
flag that write-back to Confluence is active so the architect is aware their review edits
will propagate upstream. The backlog is a **draft** — `/review-all` validates it. Do not
review or implement here.

## Guardrails

- **Faithful conversion** — never edit the meaning of a page; `discovery/` is the authority
  architect-review quotes against.
- **Pull-once is the default** — only enable `live-sync` on explicit architect request with
  write-back credentials configured; flag it loudly because review edits then mutate the
  source of record.
- **Provenance is page-level** — every discovery doc records the Confluence page ID and
  version it came from, so upstream changes are detectable.
- **Secrets never land in the repo** — credentials are handled per `connector.md`
  (environment/vault only); no tokens in `discovery/`, the inventory, or commits.
- **Draft only · no invented scope · traceability** — as for every archetype.
