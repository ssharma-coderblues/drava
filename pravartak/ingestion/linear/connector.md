# Connector — Linear

How the `linear` ingestion procedure connects to Linear, and how the optional status
write-back updates Linear issues. Read this before running `INGESTION.md`. The connector
enumerates and fetches issues (read) and, when `tracker_sync: on`, updates issue state
(write); it does not decide scope or decompose stories.

By default ingestion is **read-only** — Pravartak imports from Linear and Linear remains the
system of record (spec §17). The only write path is the opt-in status write-back (§write-back),
which updates the project's own issues' workflow state and nothing else.

## Connection methods (in order of preference)

### 1. Linear MCP server (preferred, if connected)

If a Linear MCP server is connected to the session, use it — it carries the user's own
authenticated Linear access, so Pravartak handles no credentials. Load tool schemas on demand
via tool search (issue search, issue fetch, issue update). Interactively-authenticated MCP
servers may be **absent in headless/cron runs** — if absent, fall back to the GraphQL API
(method 2).

### 2. Linear GraphQL API (fallback / default)

Linear exposes a single GraphQL endpoint. Configuration comes from the environment — never
hard-coded, never committed:

- `LINEAR_API_KEY` — a personal API key (Linear → Settings → API) or an OAuth access token.
- `LINEAR_API_URL` — defaults to `https://api.linear.app/graphql`.

Auth header: send the personal API key as the `Authorization` header value (Linear accepts the
raw key), or `Authorization: Bearer <token>` for OAuth.

Representative queries (shape, not exhaustive).

**Resolve scope** — issues by team/project/filter, paginated:

```graphql
query($after: String) {
  issues(first: 100, after: $after, filter: { team: { key: { eq: "ENG" } },
                                              project: { name: { eq: "Settlement" } } }) {
    pageInfo { hasNextPage endCursor }
    nodes { id identifier title description priority
            state { name type }
            team { key } project { name } parent { identifier }
            labels { nodes { name } } }
  }
}
```

**Workflow states for a team** (to resolve the done-state id for write-back):

```graphql
query { team(id: "ENG") { states { nodes { id name type } } } }
```

Paginate to completion via `pageInfo.endCursor`; never silently cap the result set. Order
deterministically (e.g. by `createdAt`) so re-runs are stable.

## The filter (scope selection)

The Q4 source location supplies the in-scope filter, as one of:

- A **project** → `filter: { project: { name: { eq: "<project>" } } }`
- An **initiative** → resolve its projects, then their issues.
- A **saved view / filter id** → resolve to the view's filter.
- A **raw GraphQL filter** → used in the `issues(filter: …)` argument verbatim.

Always scope to the given **team key** as well, and paginate fully.

## Credential handling

- **Read credentials from the environment or a vault only.** Never write the API key to
  `discovery/`, the inventory, `PRAVARTAK.md`, the manifest, or any commit.
- The scaffold wizard validates connectivity **before** ingestion runs: one query of the
  target team/project confirming auth works. On failure the scaffold stops with a message
  naming the missing/invalid variable; it does not proceed with partial access.
- A **read-only** key is sufficient for ingestion. The opt-in write-back (§write-back)
  additionally requires a key with write scope; if `tracker_sync: on` but the key is
  read-only, the loop treats write-back as unavailable and escalates rather than failing
  silently.

## Rate limits and resilience

- Linear rate-limits by complexity; request only the fields needed and paginate with bounded
  page sizes. Respect rate-limit responses and back off.
- Treat a partial fetch as a hard failure — if any in-scope issue cannot be fetched, report
  exactly which identifiers and stop, so the backlog is never quietly incomplete.

## Write-back (opt-in status sync, 0.3.0)

Enabled only when `tracker_sync: on` (see INGESTION.md §6 and PRAVARTAK.md). On completing a
story, the autonomous loop (SKILL.md §6.6) updates the corresponding Linear issue to the done
state:

1. Resolve the issue id from the story's `[ENG-xxx]` identifier via the correlation table in
   `discovery/README.md` (or query `issues(filter: { number / team })`).
2. Resolve the target workflow-state id: the team's first state of `type: "completed"`, or the
   state named by `tracker_done_state` if set.
3. Apply the `issueUpdate` mutation (below).
4. Confirm `success: true`; record the new state in the run log. If the update fails (auth,
   permissions, unknown state), **halt and escalate** (honest-halt) rather than reporting the
   story's tracker as synced.

```graphql
mutation($id: String!, $stateId: String!) {
  issueUpdate(id: $id, input: { stateId: $stateId }) { success issue { identifier state { name } } }
}
```

Write-back targets **only the project's own Linear workspace** and is authorized solely by the
explicit `tracker_sync: on` opt-in — consistent with the irreversible/outward-action stop
condition (spec §11.4). It never touches another team's workspace.
