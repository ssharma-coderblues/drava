# SCAFFOLD — The Scaffolding Procedure

This is the mechanical, step-by-step procedure executed by the `scaffold` skill (read by
`/scaffold`). The skill contract is in `pravartak/skills/scaffold/SKILL.md`; this document
is authoritative for *how*. Execute the phases in order. Do not skip the smoke test, and do
not commit if it fails.

Run this **interactively only** — never under `--permission-mode auto`.

---

## Phase 0 — Preflight

1. Confirm `pravartak/` exists in the project root (the library is present).
2. Confirm the project is **not already scaffolded**: if `.pravartak/manifest.json` exists,
   stop. Tell the architect the project is already Pravartak-managed and suggest
   `/pravartak-upgrade` if they meant to change versions.
3. Read `pravartak/VERSION` → `PRAVARTAK_VERSION`.
4. Determine the current UTC timestamp → `SCAFFOLD_DATE` (ISO 8601, e.g.
   `2026-06-08T10:00:00Z`). Use one timestamp for the whole scaffold run.
5. Detect the default branch (`git symbolic-ref --short HEAD`, fallback `main`) →
   `DEFAULT_BRANCH`.

---

## Phase 1 — Wizard

Read `pravartak/scaffold/wizard-questions.md` and ask the five questions (plus the remote
decision), one at a time, validating each answer. Collect the answers.

---

## Phase 2 — Derive placeholder values

From the validated answers, compute the full placeholder set used by template rendering
(Phase 3). These are the placeholders from spec §7.3:

| Placeholder | Source |
| --- | --- |
| `{{PROJECT_NAME}}` | Q1 verbatim |
| `{{PROJECT_NAME_SLUG}}` | Q1 → kebab-case |
| `{{PROJECT_NAME_PYTHON}}` | Q1 → snake_case |
| `{{LANGUAGE}}` | Q3 |
| `{{LANGUAGE_VERSION}}` | Q3 follow-up (production target) |
| `{{LANGUAGE_VERSION_LOCAL}}` | Q3 follow-up (local dev; defaults to production) |
| `{{ARCHETYPE}}` | Q2 |
| `{{QUALITY_GATE_COMMAND}}` | from the language pack's `PACK.md` |
| `{{COVERAGE_THRESHOLD}}` | default `95`, or override from Q5 |
| `{{PRAVARTAK_VERSION}}` | `pravartak/VERSION` |
| `{{SCAFFOLD_DATE}}` | Phase 0 timestamp |
| `{{ARCHITECT_OVERRIDES}}` | Q5 verbatim (empty string if none) |
| `{{SOURCE_LOCATION_DESCRIPTION}}` | Q4 human-readable summary |
| `{{DEFAULT_BRANCH}}` | Phase 0 detection |
| `{{INTERACTIVE_RUNTIME}}` | default `claude`, unless overridden in Q5 |
| `{{AUTONOMOUS_RUNTIME}}` | default `claude`, unless overridden in Q5 |
| `{{IMPLEMENTATION_RUNTIME}}` | default `claude`, unless overridden in Q5 |
| `{{REVIEW_RUNTIME}}` | default `claude`, unless overridden in Q5 |

Keep this map for Phases 3, 5, 8, and 9.

---

## Phase 3 — Ingestion

1. Read `pravartak/ingestion/<ARCHETYPE>/INGESTION.md` and execute its procedure against the
   Q4 source location.
2. Ingestion produces:
   - a populated `discovery/` with normalized markdown,
   - `discovery/README.md` (source inventory: what was ingested, when, and which discovery
     docs map to which sources),
   - a draft `.claude/backlog.md` of decomposed stories,
   - for `reverse-engineer-code`: `discovery/AS_IS_ANALYSIS.md`,
   - for `loose-docs`: `discovery/CONTRADICTIONS.md`,
   - for `jira`/`linear`: a backlog↔tracker correlation table in `discovery/README.md`
     (issue ids preserved in story titles); status write-back to the tracker happens later in
     the loop only if `tracker_sync: on`.
3. If the archetype produced `CONTRADICTIONS.md` with unresolved items, note that the
   architect must resolve them before `/review-all` (do not block scaffolding itself).

Ingestion output is project data, not template-rendered; it is created by the ingestion
procedure, not by Phase 4 rendering. (`backlog.md` is the exception — see Phase 6.)

---

## Phase 4 — Template rendering

For each `*.template` in `pravartak/templates/`, render it and write it to its target
(targets are listed in `pravartak/templates/` headers and in spec §6.3). Rendering =
substitute every `{{PLACEHOLDER}}` from the Phase 2 map.

### 4.1 Provenance headers (spec §9.1)

Every rendered file that supports comments gets an inline header **as the first content**,
using the file type's comment syntax:

- **Markdown:**
  `<!-- pravartak: template=<NAME>.template version=<PRAVARTAK_VERSION> generated=<SCAFFOLD_DATE> -->`
- **Shell:** after the shebang line:
  `# pravartak: template=<NAME>.template version=<PRAVARTAK_VERSION> generated=<SCAFFOLD_DATE>`
- **Python / TOML:**
  `# pravartak: template=<NAME>.template version=<PRAVARTAK_VERSION> generated=<SCAFFOLD_DATE>`
- **JSON:** no inline header (JSON has no comments) — provenance lives in the manifest only.

The header is communication, not enforcement; the manifest is authoritative.

### 4.2 Render targets

Render at least these (target ← template):

- `PRAVARTAK.md` ← `PRAVARTAK.md.template`
- `CLAUDE.md` ← `CLAUDE.md.template`
- `.claude/settings.json` ← `settings.json.template`
- `.gitignore` ← `gitignore.template`
- `docs/agent-runtimes/claude.md` ← `claude-runtime.md.template`
- `docs/agent-runtimes/codex.md` ← `codex-runtime.md.template`
- `.claude/backlog.md` ← `backlog.md.template` (then populated by ingestion, Phase 6)
- `.claude/architect_review/progress.md` ← `progress.md.template`
- `.claude/architect_review/session.md` ← `session.md.template`
- `.claude/architect_review/spec_amendments.md` ← `spec_amendments.md.template`
- `.claude/architect_review/scope_additions.md` ← `scope_additions.md.template`
- `.claude/completed.md` ← `completed.md.template`
- `.claude/blocked.md` ← `blocked.md.template`
- `.claude/escalations.md` ← `escalations.md.template`
- `.claude/current_story.md` ← `current_story.md.template`
- `.claude/reviews/README.md` ← `reviews-README.md.template`
- sprint-reports README ← `sprint-reports-README.md.template` (location per Phase 6 note)

Create parent directories as needed:
`.claude/{commands,scripts,architect_review/findings,reviews,sprint-reports}`,
`docs/agent-runtimes/`, and
`.pravartak/`.

---

## Phase 5 — Language pack application

Read `pravartak/language-packs/<LANGUAGE>/PACK.md` and follow it. Generally:

1. Install the gate. The gate is assembled as follows (this is the single source of truth
   for where `.claude/scripts/gate.sh` comes from — Phase 4 deliberately does **not** render
   it):
   - **Single built-in language** (e.g. `python`): copy the pack's `gate.sh` to
     `.claude/scripts/gate.sh`, add the shell provenance header, `chmod +x`. It is
     self-contained (direct + `--hook` modes). `gate.sh.template` is not used.
   - **Multiple languages**: copy each pack's `gate.sh` to `.claude/scripts/gate-<lang>.sh`
     (provenance header, `chmod +x`), then render `templates/gate.sh.template` to
     `.claude/scripts/gate.sh` as the composite entry point — it handles the `--hook`
     contract once and runs every `gate-*.sh` in sequence, failing if any fails (spec §12.5).
   - **Custom**: follow `pravartak/language-packs/_custom/PACK.md` to write
     `.claude/scripts/gate-custom.sh` from the architect's commands, then render
     `templates/gate.sh.template` as the entry point (as above).
2. Render the pack's language templates (e.g. `pyproject.toml.template`,
   `ruff.toml.template`) to the project root with provenance headers.
3. Run the pack's isolation setup (e.g. `venv-setup.sh`) to establish language isolation
   (`.venv/` for Python, etc.).
4. Verify the pack's required tools are installed and accessible. **If any required tool is
   missing, stop the scaffold with a clear message** naming the tool and how to install it
   (spec §7.4). The architect installs and re-runs, or chooses `custom`.

---

## Phase 6 — Skills wiring and state initialization

### 6.1 Command pointers (the hybrid-reference model, spec §7.5)

For each command definition in `pravartak/commands/`, create a thin pointer in
`.claude/commands/` by rendering `pravartak/templates/command-pointer.template` with that
command's metadata (`description`, `argument-hint`, `skill`) read from its frontmatter:

```markdown
<!-- pravartak: template=command-pointer.template version=<VER> generated=<TS> -->
---
description: <COMMAND_DESCRIPTION>
argument-hint: <COMMAND_ARGUMENT_HINT>
---

Read pravartak/skills/<SKILL_NAME>/SKILL.md and execute the documented procedure with
arguments: $ARGUMENTS.
```

The command catalog (`pravartak/commands/`) is:

| Pointer file | Skill | Argument hint |
| --- | --- | --- |
| `review-all.md` | `architect-review` | (none) |
| `review-story.md` | `architect-review` | `<STORY-ID>` |
| `add-scope.md` | `scope-addition` | (none) |
| `retrospect.md` | `retrospective` | `[sprint-number]` |
| `drift-check.md` | `drift-detection` | `[area]` |
| `pravartak-upgrade.md` | `upgrade` | `[version]` |
| `promote.md` | `promotion` | `[integration-branch]` |
| `status.md` | (self-contained — see `pravartak/commands/status.md`) | (none) |

`scaffold.md` is special: the Claude adapter's `/scaffold` runs before `.claude/commands/`
exists, so it is not generated as a pointer here. It is made available at install time (see
`install.sh`) or by the architect copying `pravartak/commands/scaffold.md` into
`.claude/commands/`. Other runtimes invoke the scaffold skill directly. Do not overwrite a
`scaffold.md` the architect already has.

All command pointers are **library-owned** (`ownership: library`,
`upgrade_strategy: always-replace`) so upgrades pick up new skill behavior automatically.

### 6.2 State initialization

The state files were rendered in Phase 4 as empty stubs. Now populate the ones ingestion
produced content for:

- `.claude/backlog.md` — fill with the stories decomposed during ingestion.
- `.claude/architect_review/progress.md` — one row per story, all `PENDING`.
- `.claude/architect_review/session.md` — empty (no session in progress).
- `.claude/{completed,blocked,escalations,current_story}.md` — empty stubs.
- `.claude/commit_log.txt` — empty.
- sprint-reports README — placeholder.

**Sprint-reports location note:** spec §6.3 lists `.claude/sprint-reports/` while spec
§11.3 (the autonomous loop) writes `docs/sprint-reports/sprint-<n>.md`. Pravartak v0.5.0
treats `docs/sprint-reports/` as the canonical location for sprint summaries (it lives with
the code the loop produces) and provisions `.claude/sprint-reports/README.md` only as a
pointer to it. Create `docs/sprint-reports/` and place the README there; leave a one-line
pointer at `.claude/sprint-reports/README.md` if the template targets that path.

---

## Phase 7 — Smoke test

Run `pravartak/scaffold/post-scaffold-smoke-test.md`: execute the quality gate against the
empty project. Expected: all gates pass, with "no tests collected" (pytest exit 5) treated
as success for the empty project (spec §14.2).

**If the smoke test fails, surface the failure and stop. Do not generate the manifest, do
not commit.** A failed smoke test means a misconfigured language pack — fix it first.

---

## Phase 8 — Manifest generation

Write `.pravartak/manifest.json` recording every generated file, validated against
`pravartak/MANIFEST_SCHEMA.json`. Structure (spec §9.2):

```json
{
  "pravartak_version": "<PRAVARTAK_VERSION>",
  "scaffolded_at": "<SCAFFOLD_DATE>",
  "project": {
    "name": "<PROJECT_NAME>",
    "archetype": "<ARCHETYPE>",
    "language_pack": "<LANGUAGE>"
  },
  "files": [ /* one entry per generated file */ ]
}
```

Each `files[]` entry: `path`, `template` (the source template path under `pravartak/`),
`generated_by_version`, `generated_at`, `content_hash_at_generation`
(`sha256:<hex>` of the file as written), `ownership`, and `upgrade_strategy`.

Assign ownership and strategy as follows:

| File class | ownership | upgrade_strategy |
| --- | --- | --- |
| Command pointers (`.claude/commands/*.md`) | `library` | `always-replace` |
| `PRAVARTAK.md`, `CLAUDE.md`, runtime adapter docs, `.claude/settings.json`, `.claude/scripts/gate.sh`, language config (`pyproject.toml`, `ruff.toml`, …) | `project` | `diff-and-prompt` |
| Accumulating state files (`backlog.md`, `completed.md`, `blocked.md`, `escalations.md`, `current_story.md`, `progress.md`, `session.md`, `commit_log.txt`) | `project` | `preserve-on-conflict` |
| READMEs and other rendered docs | `project` | `diff-and-prompt` |

Compute each hash from the file exactly as written (including its provenance header).

---

## Phase 9 — Commit (and push)

```bash
git add -A
git commit -m "chore: pravartak scaffold

- Library version: <PRAVARTAK_VERSION>
- Archetype: <ARCHETYPE>
- Language pack: <LANGUAGE>
- Source: <SOURCE_LOCATION_DESCRIPTION>

This project is now Pravartak-managed.
Next step: /review-all to begin architect review."
```

Then push to the default branch **unless in local-only mode**:

```bash
git push origin <DEFAULT_BRANCH>
```

In local-only mode, skip the push and say so in the output.

---

## Phase 10 — Output report

Print the completion report:

```text
PRAVARTAK_SCAFFOLD_COMPLETE
  Project: <PROJECT_NAME>
  Archetype: <ARCHETYPE>
  Language pack: <LANGUAGE> (<LANGUAGE_VERSION> production, <LANGUAGE_VERSION_LOCAL> local)
  Pravartak version: <PRAVARTAK_VERSION>

  Stories in backlog: <N>
  Discovery documents: <M>
  Quality gate: PASS (smoke test)

  Recommended next step:
    Run `claude` interactively and invoke `/review-all` to begin architect review.
    Do not launch auto-mode until review is complete.
```

If `loose-docs` produced unresolved contradictions, add a line directing the architect to
resolve `discovery/CONTRADICTIONS.md` before `/review-all`.

Scaffolding ends here. Architect review takes over.
