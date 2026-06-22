# Scaffold Wizard Questions

The `/scaffold` command asks these five questions interactively, in order, validating each
answer before moving on. This file is read by `pravartak/scaffold/SCAFFOLD.md` (the
scaffold procedure). Ask one question at a time; do not batch them.

For each question: state it, accept the answer, validate, and on invalid input explain why
and re-ask. Capture the final validated answers; SCAFFOLD.md §2 turns them into the
placeholder values used for rendering.

---

## Q1 — Project name

> What is the project name?

A short, filesystem-friendly identifier for the project, e.g. `cashapp2`,
`payments-modernization`.

**Validation:**

- Non-empty.
- Matches `^[a-z0-9][a-z0-9-_]*$` (lowercase letters, digits, hyphen, underscore; must
  start with a letter or digit). If the architect gives a name with spaces or capitals,
  offer a normalized suggestion and confirm.

**Derived values** (computed, not asked):

- `PROJECT_NAME` — the answer verbatim.
- `PROJECT_NAME_SLUG` — kebab-case (spaces/underscores → hyphens, lowercased).
- `PROJECT_NAME_PYTHON` — snake_case (hyphens/spaces → underscores, lowercased), for Python
  imports.

---

## Q2 — Archetype

> Which archetype best describes your source material?

One of exactly these seven:

| Value | Source material |
| --- | --- |
| `greenfield-markdown` | Markdown design docs you already have |
| `reverse-engineer-code` | An existing codebase, no formal spec |
| `confluence` | Spec lives in Confluence pages |
| `jira` | Spec is a backlog of Jira stories |
| `linear` | Spec is a backlog of Linear issues |
| `brownfield-adopt` | An existing partly-built project — shipped code + existing design docs + optional tracker backlog |
| `loose-docs` | Mixed-format docs (PDF/Word/slides/notes) |

**Validation:**

- Must be one of the seven recognized values.
- The ingestion procedure `pravartak/ingestion/<archetype>/INGESTION.md` must exist. v0.5.0
  ships all seven archetypes. `confluence`, `jira`, and `linear` additionally require a
  configured connector (see the archetype's `connector.md`) and credentials — validate those
  in Q4. If a chosen archetype's `INGESTION.md` is somehow absent, say it is unavailable in
  this Pravartak version and ask the architect to choose another (or upgrade).
- `brownfield-adopt` may optionally **overlay a `linear`/`jira` tracker** (when the existing
  project's backlog lives in one). If the architect supplies a tracker filter, it also uses
  that archetype's `connector.md` for the import and opt-in status write-back; without one,
  the work partition is derived from code + specs alone.

**Derived value:** `ARCHETYPE` — the chosen value.

---

## Q3 — Language pack

> Which language pack(s) should the quality gate use?

One of: `python` / `typescript` / `go` / `java` / `rust` / `multiple` / `custom`.

**Validation:**

- For a single language, `pravartak/language-packs/<lang>/PACK.md` must exist. In v0.4.0
  `python` and `typescript` ship; for `go`/`java`/`rust`, tell the architect the built-in
  pack is not yet available and offer `custom`.
- `multiple` — ask which languages, then validate each; the resulting gate runs each pack's
  gate in sequence (spec §12.5).
- `custom` — no built-in pack; SCAFFOLD.md follows `pravartak/language-packs/_custom/PACK.md`
  to assemble a gate from the architect's linter/formatter/type-checker/test-runner/
  coverage commands (spec §12.4).

**Follow-up sub-questions** (per chosen language):

- Production language version, e.g. Python `3.14`. → `LANGUAGE_VERSION`.
- Locally-installed dev version if different, e.g. `3.11.8`. → `LANGUAGE_VERSION_LOCAL`
  (defaults to `LANGUAGE_VERSION` if the architect says "same").

**Derived values:** `LANGUAGE`, `LANGUAGE_VERSION`, `LANGUAGE_VERSION_LOCAL`,
`QUALITY_GATE_COMMAND` (from the pack), and `COVERAGE_THRESHOLD` (default `95` unless the
architect overrides here or in Q5).

---

## Q4 — Source material location

> Where does the source material live?

The path or reference Pravartak ingests from. Its meaning depends on the archetype:

| Archetype | Expected location |
| --- | --- |
| `greenfield-markdown` | A directory (or file) of markdown specs |
| `reverse-engineer-code` | The root of the existing codebase |
| `confluence` | Space key + page IDs/paths (and configured credentials) |
| `jira` | Project key + filter/JQL (and configured credentials) |
| `linear` | Team key + project/view/filter (and configured credentials) |
| `brownfield-adopt` | The existing project's repo root + design-doc paths (+ optional tracker filter) |
| `loose-docs` | A directory of mixed-format documents |

**Validation:**

- For file/dir sources: the path must exist and be readable. If it doesn't exist, re-ask.
- For Confluence/Jira/Linear: the credentials/connector must be configured (see the
  archetype's `connector.md`); if not, explain what to configure and stop.

**Derived value:** `SOURCE_LOCATION_DESCRIPTION` — a human-readable summary of the source,
used in the scaffold commit message and manifest.

---

## Q5 — Project-specific overrides

> Any project-specific overrides or notes to capture in PRAVARTAK.md? (free-form, optional)

Free-form text the architect wants recorded verbatim in `PRAVARTAK.md`. Examples:

- "Production target Python 3.14, local dev 3.11.8 due to pyenv."
- "Use `git_workflow: pr-based`." / "`coverage_threshold: 90`." / "`gate_strictness:
  lenient`." / "`sprint_cadence: weekly`." / "`branch_pattern: …`."
- "`implementation_runtime: codex` and `review_runtime: claude`."
- For `jira`/`linear` projects: "`tracker_sync: on`" to write story completion back to the
  tracker (and "`tracker_done_state: Done`" if the target state differs from the default).
- Domain renames, deployment notes, anything the assigned runtimes should know.

**Validation:** none — captured verbatim.

**Derived value:** `ARCHITECT_OVERRIDES` — the text verbatim (empty string if none). If the
overrides mention config knobs (coverage threshold, workflow), reflect them in the
corresponding derived values too.

---

## The remote decision (asked during Q4/Q5 context)

Pravartak must know whether the project has a git remote, because the autonomous loop's
`git push` fails without one (spec §14.5). Ask:

> Should the autonomous loop push to a remote? If yes, what is the `origin` URL? If no, I'll
> set up a local-only workflow.

- If the architect supplies a URL and `origin` is not set, offer to add it.
- If the architect wants no remote, set `git_workflow: local-only` in the rendered
  `PRAVARTAK.md` so the loop never attempts remote operations.

**Derived values:** `DEFAULT_BRANCH` (detected, default `main`) and the remote mode
(`auto-merge` with a remote, or `local-only`).
