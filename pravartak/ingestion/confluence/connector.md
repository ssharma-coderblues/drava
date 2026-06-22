# Connector — Confluence

How the `confluence` ingestion procedure connects to Confluence. Read this before running
`INGESTION.md`. The connector's only job is to enumerate, fetch, and (for `live-sync`) write
back pages; it does not decide scope or decompose stories.

## Connection methods (in order of preference)

### 1. Atlassian MCP server (preferred)

If an Atlassian MCP server is connected to the session, use it — it carries the user's own
authenticated Confluence access, so no credentials are handled by Pravartak at all. The
relevant tools (load their schemas on demand via tool search):

| Need | MCP tool |
| --- | --- |
| Confirm access / list sites | `getAccessibleAtlassianResources`, `getConfluenceSpaces` |
| Enumerate pages in a space | `getPagesInConfluenceSpace` |
| Walk a page tree | `getConfluencePageDescendants` |
| Fetch one page's body | `getConfluencePage` |
| Search by query | `searchConfluenceUsingCql` |
| Write back (live-sync only) | `updateConfluencePage` |

The MCP path is the default for interactive scaffolding. Note that interactively-authenticated
MCP servers may be **absent in headless/cron runs** — if the tools are not present, fall back
to the REST API (method 2).

### 2. Confluence REST API (fallback)

When MCP is unavailable, use the Confluence Cloud REST API v2. Configuration comes from the
environment — never hard-coded, never committed:

- `CONFLUENCE_BASE_URL` — e.g. `https://your-org.atlassian.net/wiki`
- `CONFLUENCE_EMAIL` — the account email
- `CONFLUENCE_API_TOKEN` — an API token (from id.atlassian.com), used as the password in
  HTTP Basic auth alongside the email

Representative endpoints (verify against your instance's API version):

- List space pages: `GET /api/v2/spaces/{id}/pages`
- Get page body: `GET /api/v2/pages/{id}?body-format=storage`
- Get descendants: `GET /api/v2/pages/{id}/descendants`
- Search: `GET /wiki/rest/api/content/search?cql=<cql>`
- Update (live-sync): `PUT /api/v2/pages/{id}` with the new body and an incremented version

Fetch the `storage` (XHTML) or ADF body format and convert to markdown in the ingestion
procedure. Page `version.number` is the field `live-sync` compares to detect upstream drift.

## Credential handling

- **Read credentials from the environment or a vault only.** Never write tokens to
  `discovery/`, the inventory, `PRAVARTAK.md`, the manifest, or any commit.
- The scaffold wizard validates connectivity **before** ingestion runs: a single read of one
  known page (or a space listing) confirming auth works. If it fails, the scaffold stops with
  a clear message naming the missing/invalid variable — it does not proceed with partial
  access.
- For `live-sync`, write-back requires the token's account to have edit permission on the
  target pages. Confirm this during validation; a read-only token must downgrade to
  `pull-once` rather than failing mid-review.

## Rate limits and resilience

- Batch enumeration; fetch page bodies with bounded concurrency (Confluence Cloud rate-limits
  aggressively). Respect `Retry-After` on HTTP 429.
- Treat a partial fetch as a hard failure, not a silent omission — if any in-scope page cannot
  be fetched, report exactly which and stop, so `discovery/` is never quietly incomplete.

## Sub-variant note

`pull-once` uses methods 1/2 read-only and never touches Confluence again. `live-sync`
additionally uses `updateConfluencePage` (MCP) or the `PUT` endpoint (REST) during architect
review; it is opt-in and flagged to the architect because it mutates the source of record.
