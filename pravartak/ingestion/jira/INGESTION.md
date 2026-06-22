# Ingestion — Specs in Jira

Archetype: `jira`. Medium complexity (spec §4.4). The "spec" is a backlog of Jira issues.
This procedure imports them — preserving Jira keys and epic/initiative parent links — into
`discovery/` and a draft `.claude/backlog.md`. Connection details (MCP tools, credentials,
REST fallback) are in `connector.md` — read it first.

Jira stories often lack architectural context (they describe *what* a user wants, rarely
*how* the system should be built). **Architect review carries more weight in this archetype
than any other** — the gap-filling during `/review-all` is the real work. Ingestion's job is
a faithful, well-linked import, not invention.

Executed by `pravartak/scaffold/SCAFFOLD.md` Phase 3, given the Q4 source location (a Jira
project key plus a filter — e.g. all issues under epic `CASH-42`, or a JQL query).

## Inputs

- **Source location** (Q4): a Jira project key (e.g. `CASH`) and a filter selecting the
  in-scope issues — an epic/initiative key, a saved filter ID, or a raw JQL query.
- **Credentials**: configured per `connector.md`. The wizard validates connectivity before
  this procedure runs.

## Outputs

- A populated `discovery/` containing one normalized markdown document per imported issue (or
  grouped by epic), each preserving the Jira key, type, parent link, status, and a faithful
  rendering of the description and acceptance criteria.
- `discovery/README.md` — the source inventory mapping each discovery document and each
  backlog story to its Jira key, with the epic/initiative hierarchy recorded.
- A draft `.claude/backlog.md` of stories, each cross-referenced to its Jira key.

## Procedure

### 1. Connect and select issues

Following `connector.md`, run the filter and resolve the in-scope issue set. For each issue
record: key, issue type (Epic / Story / Task / Bug / Sub-task), summary, status, parent link
(epic/initiative), priority, labels/components, and the description + acceptance-criteria
fields. Preserve the **hierarchy**: initiative → epic → story → sub-task. Confirm the issue
count with the architect if it is surprising.

### 2. Normalize issues into `discovery/`

For each issue, write a faithful markdown document (or a section within an epic's document):

- **Preserve the Jira fields verbatim** — summary, description, acceptance criteria,
  status, parent. Render Jira markup / ADF to markdown mechanically; do not rewrite intent.
- **Keep the key prominent** — the Jira key (`CASH-118`) is the issue's stable identity and
  must appear at the top of its document and in every cross-reference.
- **Record the hierarchy** — each story document notes its parent epic/initiative key and
  links to that epic's discovery document.
- **Footnote what does not convert** — attachments, embedded images, and inter-issue links
  are footnoted (`> [Jira link: blocks CASH-90]`) rather than dropped.
- Group documents by epic where that aids navigation (e.g.
  `discovery/epic-cash-42-settlement.md` containing its child stories), or one file per
  issue for large epics. Record the chosen grouping in the inventory.

### 3. Write `discovery/README.md`

```markdown
# Discovery — Source Inventory

Archetype: jira
Ingested: <SCAFFOLD_DATE>
Source: Jira project <KEY>, filter <epic/JQL/filter-id>

## Issue hierarchy
- Initiative CASH-1 — Cash App v2
  - Epic CASH-42 — Settlement
    - Story CASH-118 — Post settlement journal entry
    - Story CASH-119 — Reconcile against bank file

| Discovery document | Jira key(s) | Type | Parent | Status |
| --- | --- | --- | --- | --- |
| epic-cash-42-settlement.md | CASH-42 (+118,119) | Epic | CASH-1 | In Progress |

Note: Jira stories typically lack architectural context — architect review (/review-all)
is where this backlog gains design intent. Many acceptance criteria below are DERIVED and
must be validated.
```

### 4. Decompose into a draft backlog

Map Jira issues to backlog stories. Unlike other archetypes, the decomposition is mostly
1:1 (one Jira Story → one backlog story); split a Jira story only when it is genuinely
several units of work, and record the split. Use the standard block format
(`backlog.md.template`), with one addition — the **Jira key is preserved as the source
pointer and in the title** so traceability to Jira is never lost:

```markdown
- [ ] STORY-001 — [CASH-118] Post settlement journal entry
  - Scope: <what this story does and explicitly does not do>
  - Acceptance criteria:
    - <criterion 1, testable — from the Jira AC field, or DERIVED and flagged>
    - <criterion 2, testable>
  - Depends on: <STORY-0xx (CASH-1xx), … | none>
  - Source: discovery/epic-cash-42-settlement.md#cash-118 (Jira: CASH-118)
```

- **Preserve Jira keys** in the title (`[CASH-118]`) and the source pointer. The internal
  `STORY-NNN` id is what the loop and review use; the Jira key is the link back to the
  system of record.
- **Acceptance criteria are usually thin** — Jira AC fields are often empty or vague. Derive
  testable criteria from the summary/description and **mark every derived criterion** so the
  architect knows exactly what to validate. Do not silently invent firm criteria.
- **Dependencies** map from Jira `blocks`/`is blocked by` links where present; otherwise
  infer conservatively and flag for review.
- **No invented scope** — if a Jira story is too vague to decompose, capture it as a story
  with an explicit "needs architect clarification" note rather than guessing the design.

### 5. Handoff

Report to SCAFFOLD.md: discovery-document count and story count (for
`PRAVARTAK_SCAFFOLD_COMPLETE`), and **explicitly flag that this archetype relies heavily on
architect review** — many criteria are derived and the stories lack architectural context.
Add a line to the report recommending a thorough `/review-all`. The backlog is a **draft**;
do not review or implement here.

### 6. Status write-back (opt-in, 0.3.0)

Like the `linear` archetype, Jira supports keeping the tracker in sync with build progress,
**off by default**. When the project sets `tracker_sync: on` in `PRAVARTAK.md` (and
`tracker_done_state` if the target status is not the project's default "Done"), the
autonomous loop — on completing a story — transitions the corresponding Jira issue to the
done status via the connector (`connector.md` §write-back). The loop resolves the issue from
the story's `[CASH-xxx]` key.

Write-back is an **outward action on the project's own Jira project**; the `tracker_sync`
opt-in is its explicit authorization (see autonomous-loop SKILL.md §6.6 and the
irreversible/outward-action stop condition §11.4). It is never enabled implicitly and never
touches another team's project. (Until 0.3.0 this archetype was strictly read-only; write-back
is new and opt-in, so the default behavior is unchanged.)

## Guardrails

- **Faithful import** — preserve Jira fields and keys verbatim; render markup mechanically,
  never rewrite intent.
- **Keys are sacred** — every story and discovery doc retains its Jira key; the link to the
  system of record must survive ingestion.
- **Flag derived criteria** — Jira AC is often missing; mark what you derived so review knows
  what to scrutinize. This archetype is review-heavy by design (spec §4.4).
- **Secrets never land in the repo** — credentials handled per `connector.md`
  (environment/vault only).
- **Draft only · no invented scope · traceability** — as for every archetype.
