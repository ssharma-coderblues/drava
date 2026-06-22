# Connector — Jira

How the `jira` ingestion procedure connects to Jira. Read this before running
`INGESTION.md`. The connector enumerates and fetches issues (read) and, when
`tracker_sync: on`, transitions issue status (write); it does not decide scope or decompose
stories. By default ingestion is **read-only** — Pravartak imports from Jira and Jira remains
the system of record (spec §17). The only write path is the opt-in status write-back
(§write-back, new in 0.3.0), which transitions the project's own issues and nothing else.

## Connection methods (in order of preference)

### 1. Atlassian MCP server (preferred)

If an Atlassian MCP server is connected to the session, use it — it carries the user's own
authenticated Jira access, so Pravartak handles no credentials. Relevant tools (load schemas
on demand via tool search):

| Need | MCP tool |
| --- | --- |
| Confirm access / list sites | `getAccessibleAtlassianResources` |
| List visible projects | `getVisibleJiraProjects` |
| Run the in-scope filter | `searchJiraIssuesUsingJql` |
| Fetch one issue in full | `getJiraIssue` |
| Resolve issue links / hierarchy | `getJiraIssueRemoteIssueLinks`, fields on `getJiraIssue` |
| Discover fields/AC field id | `getJiraProjectIssueTypesMetadata`, `getJiraIssueTypeMetaWithFields` |

The MCP path is the default for interactive scaffolding. Interactively-authenticated MCP
servers may be **absent in headless/cron runs** — if the tools are not present, fall back to
the REST API (method 2).

### 2. Jira REST API (fallback)

When MCP is unavailable, use the Jira Cloud REST API v3. Configuration comes from the
environment — never hard-coded, never committed:

- `JIRA_BASE_URL` — e.g. `https://your-org.atlassian.net`
- `JIRA_EMAIL` — the account email
- `JIRA_API_TOKEN` — an API token, used as the password in HTTP Basic auth alongside the email

Representative endpoints:

- Search by JQL: `GET /rest/api/3/search?jql=<jql>&fields=...&maxResults=100` (paginate with
  `startAt` until `total` is reached)
- Get one issue: `GET /rest/api/3/issue/{key}?fields=*all&expand=names`
- Field metadata (to find the acceptance-criteria custom field id): `GET /rest/api/3/field`

Descriptions and AC fields come back as ADF (Atlassian Document Format) JSON — render to
markdown in the ingestion procedure. Resolve the epic/initiative parent via the issue's
parent field (and `Epic Link` custom field on older instances).

## The filter (scope selection)

The Q4 source location supplies the in-scope filter, as one of:

- An **epic/initiative key** → `JQL: parent = CASH-42 OR "Epic Link" = CASH-42`
- A **saved filter id** → `JQL: filter = 10234`
- A **raw JQL query** → used verbatim

Always order results stably (`ORDER BY key ASC`) so re-runs are deterministic, and
**paginate to completion** — never silently cap the result set.

## Credential handling

- **Read credentials from the environment or a vault only.** Never write tokens to
  `discovery/`, the inventory, `PRAVARTAK.md`, the manifest, or any commit.
- The scaffold wizard validates connectivity **before** ingestion runs: one read of the
  target project or a single-issue fetch confirming auth works. On failure the scaffold stops
  with a message naming the missing/invalid variable; it does not proceed with partial access.
- A **read-only** token is sufficient and preferred — ingestion never needs write scope.

## Rate limits and resilience

- Paginate with bounded page sizes; respect `Retry-After` on HTTP 429.
- Treat a partial fetch as a hard failure — if any in-scope issue cannot be fetched, report
  exactly which keys and stop, so the backlog is never quietly incomplete.
- Record each issue's `key`, `status`, and parent at fetch time; these populate the inventory
  hierarchy and the per-story Jira cross-references.

## Write-back (opt-in status sync, 0.3.0)

Enabled only when `tracker_sync: on` (see INGESTION.md §6 and PRAVARTAK.md). On completing a
story, the autonomous loop (SKILL.md §6.6) transitions the corresponding Jira issue to the
done status:

1. Resolve the issue from the story's `[CASH-xxx]` key.
2. Resolve the transition: read available transitions (MCP `getTransitionsForJiraIssue`, or
   REST `GET /rest/api/3/issue/{key}/transitions`) and pick the one reaching the done status
   (or the status named by `tracker_done_state` if set).
3. Apply it (MCP `transitionJiraIssue`, or REST `POST /rest/api/3/issue/{key}/transitions`
   with the transition id).
4. Confirm success and record the new status in the run log. If the transition fails (auth,
   permissions, no matching transition), **halt and escalate** (honest-halt) rather than
   reporting the story's tracker as synced.

Write-back targets **only the project's own Jira project** and is authorized solely by the
explicit `tracker_sync: on` opt-in — consistent with the irreversible/outward-action stop
condition (spec §11.4). It never touches another team's project. Write-back requires a token
with transition permission; a read-only token makes write-back unavailable (the loop escalates
rather than failing silently).
