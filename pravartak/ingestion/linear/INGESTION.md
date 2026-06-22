# Ingestion — Specs in Linear

Archetype: `linear`. Medium complexity (spec §4.6). The "spec" is a set of Linear issues.
This procedure imports them — preserving Linear issue identifiers and team/project/initiative
parent links — into `discovery/` and a draft `.claude/backlog.md`, and keeps backlog ↔ Linear
correlated. Connection details (Linear GraphQL API, credentials, optional MCP) are in
`connector.md` — read it first.

This is the Linear parallel of the `jira` archetype (§4.4). Like Jira, Linear issues often
lack architectural context (they describe *what* a user wants, rarely *how* to build it), so
**architect review carries more weight in this archetype** — the gap-filling during
`/review-all` is the real work. Ingestion's job is a faithful, well-linked import, not
invention.

Executed by `pravartak/scaffold/SCAFFOLD.md` Phase 3, given the Q4 source location (a Linear
team key plus a filter — e.g. all issues in project `Settlement`, or a saved view / filter).

## Inputs

- **Source location** (Q4): a Linear team key (e.g. `ENG`) and a filter selecting the
  in-scope issues — a project, an initiative, a saved view/filter id, or a GraphQL filter.
- **Credentials**: configured per `connector.md`. The wizard validates connectivity before
  this procedure runs.

## Outputs

- A populated `discovery/` containing one normalized markdown document per imported issue (or
  grouped by project), each preserving the Linear identifier, parent links, workflow state,
  and a faithful rendering of the description and acceptance criteria.
- `discovery/README.md` — the source inventory mapping each discovery document and each
  backlog story to its Linear identifier, with the initiative/project hierarchy recorded and
  a correlation table (`STORY-NNN ↔ Linear identifier ↔ issue id`) that keeps backlog and
  Linear in sync (and is read by the loop's optional status write-back, §6).
- A draft `.claude/backlog.md` of stories, each cross-referenced to its Linear identifier.

## Procedure

### 1. Connect and select issues

Following `connector.md`, run the filter and resolve the in-scope issue set. For each issue
record: identifier (`ENG-123`), internal id (UUID, for API calls), title, workflow state
(Backlog / Todo / In Progress / In Review / Done / Canceled), team, project, initiative,
parent issue (for sub-issues), priority, labels, and the description + any acceptance-criteria
content. Preserve the **hierarchy**: initiative → project → issue → sub-issue. Confirm the
issue count with the architect if it is surprising.

### 2. Normalize issues into `discovery/`

For each issue, write a faithful markdown document (or a section within a project's document):

- **Preserve the Linear fields verbatim** — title, description, acceptance criteria, state,
  parent. Render Linear's markdown mechanically; do not rewrite intent.
- **Keep the identifier prominent** — the Linear identifier (`ENG-123`) is the issue's stable
  human-readable identity and must appear at the top of its document and in every
  cross-reference. Record the internal UUID alongside it (the write-back, §6, needs it).
- **Record the hierarchy** — each issue document notes its parent project/initiative and links
  to that project's discovery document.
- **Footnote what does not convert** — attachments, embedded images, and issue relations
  (`blocks`/`blocked-by`) are footnoted (`> [Linear relation: blocks ENG-90]`) rather than
  dropped.
- Group documents by project where that aids navigation (e.g.
  `discovery/project-settlement.md` containing its child issues), or one file per issue for
  large projects. Record the chosen grouping in the inventory.

### 3. Write `discovery/README.md`

```markdown
# Discovery — Source Inventory

Archetype: linear
Ingested: <SCAFFOLD_DATE>
Source: Linear team <KEY>, filter <project/view/filter-id>

## Issue hierarchy
- Initiative: Cash App v2
  - Project: Settlement
    - ENG-118 — Post settlement journal entry
    - ENG-119 — Reconcile against bank file

## Correlation (backlog ↔ Linear)
| STORY | Linear identifier | Linear id (UUID) | State |
| --- | --- | --- | --- |
| STORY-001 | ENG-118 | 1b2c… | Todo |
| STORY-002 | ENG-119 | 9f0a… | Backlog |

Note: Linear issues typically lack architectural context — architect review (/review-all)
is where this backlog gains design intent. Many acceptance criteria below are DERIVED and
must be validated. Status write-back to Linear is OFF unless `tracker_sync: on` (see
connector.md §write-back and PRAVARTAK.md).
```

### 4. Decompose into a draft backlog

Map Linear issues to backlog stories. As with Jira, the decomposition is mostly 1:1 (one
Linear issue → one backlog story); split an issue only when it is genuinely several units of
work, and record the split. Use the standard block format (`backlog.md.template`), with the
**Linear identifier preserved as the source pointer and in the title** so traceability to
Linear is never lost:

```markdown
- [ ] STORY-001 — [ENG-118] Post settlement journal entry
  - Scope: <what this story does and explicitly does not do>
  - Acceptance criteria:
    - <criterion 1, testable — from the issue, or DERIVED and flagged>
    - <criterion 2, testable>
  - Depends on: <STORY-0xx (ENG-1xx), … | none>
  - Source: discovery/project-settlement.md#eng-118 (Linear: ENG-118)
```

- **Preserve Linear identifiers** in the title (`[ENG-118]`) and the source pointer. The
  internal `STORY-NNN` id is what the loop and review use; the Linear identifier is the link
  back to the system of record, and the correlation table (§3) maps it to the UUID the API
  needs.
- **Acceptance criteria are usually thin** — derive testable criteria from the title and
  description and **mark every derived criterion** so the architect knows what to validate.
  Do not silently invent firm criteria.
- **Dependencies** map from Linear `blocks`/`blocked-by` relations where present; otherwise
  infer conservatively and flag for review.
- **No invented scope** — if an issue is too vague to decompose, capture it as a story with an
  explicit "needs architect clarification" note rather than guessing the design.

### 5. Handoff

Report to SCAFFOLD.md: discovery-document count and story count (for
`PRAVARTAK_SCAFFOLD_COMPLETE`), and **explicitly flag that this archetype relies heavily on
architect review** — many criteria are derived and the issues lack architectural context. The
backlog is a **draft**; do not review or implement here.

### 6. Status write-back (opt-in, 0.3.0)

This archetype supports keeping Linear in sync with build progress, **off by default**. When
the project sets `tracker_sync: on` in `PRAVARTAK.md` (and `tracker_done_state` if the
target workflow state is not the team's default completed state), the autonomous loop — on
completing a story — updates the corresponding Linear issue to the done state via the
connector's `issueUpdate` mutation (`connector.md` §write-back). The loop resolves the issue
from the story's `[ENG-xxx]` identifier and the correlation table (§3).

Write-back is an **outward action on the project's own Linear workspace**; the `tracker_sync`
opt-in is its explicit authorization (see autonomous-loop SKILL.md §6.6 and the
irreversible/outward-action stop condition §11.4). It is never enabled implicitly, and it
never touches another team's workspace.

## Guardrails

- **Faithful import** — preserve Linear fields and identifiers verbatim; render markup
  mechanically, never rewrite intent.
- **Identifiers are sacred** — every story and discovery doc retains its Linear identifier and
  the correlation to the issue UUID; the link to the system of record must survive ingestion.
- **Flag derived criteria** — Linear acceptance criteria are often missing; mark what you
  derived. This archetype is review-heavy by design (spec §4.6).
- **Write-back is opt-in** — status sync to Linear happens only with `tracker_sync: on`, only
  to the project's own workspace.
- **Secrets never land in the repo** — credentials handled per `connector.md`
  (environment/vault only).
- **Draft only · no invented scope · traceability** — as for every archetype.
