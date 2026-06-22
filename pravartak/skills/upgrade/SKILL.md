---
name: upgrade
description: >
  Migrate a project to a new Pravartak version. Diffs the installed pravartak/ against the
  target version, uses .pravartak/manifest.json to tell project-edited files from
  library-owned ones, hashes each generated file against its generation hash to decide
  safe-replace vs. diff-and-prompt, renders new templates against the project's values,
  presents an upgrade plan for approval, applies it, replaces pravartak/, updates the
  manifest, and commits. Backs /pravartak-upgrade.
---

# Skill: upgrade

## 1. Purpose

Upgrade is what makes versioned templates safe. Without provenance, every upgrade either
clobbers project customizations or is too painful to do, so projects stagnate on old
versions. This skill uses the manifest (`.pravartak/manifest.json`) to upgrade precisely:
library-owned files are replaced freely, project-owned files are reconciled per their
declared strategy, and the architect approves the plan before anything is written.

## 2. When to invoke

- **`/pravartak-upgrade`** — when a new Pravartak version is released. `$ARGUMENTS` may
  carry a target version (e.g. `0.2.0`); if empty, default to `latest`.

Precondition: the project was scaffolded by Pravartak (a `.pravartak/manifest.json` and a
`pravartak/` directory exist). If the manifest is missing, stop and explain that the
project predates provenance tracking and must be reconciled manually.

## 3. Inputs

- `pravartak/VERSION` — the currently installed version.
- `.pravartak/manifest.json` — the authoritative provenance record (schema:
  `pravartak/MANIFEST_SCHEMA.json`).
- The target version's library archive and its manifest/templates (fetched, §4.3).
- The project's current values (project name, language version, archetype, etc.) — read
  from the manifest's `project` block, `PRAVARTAK.md`, and any adapter wrapper the project
  still uses.

## 4. Procedure (spec §9.3)

### 4.1 Determine versions

1. Read the current installed version from `pravartak/VERSION` (cross-check the manifest's
   `pravartak_version`; the manifest wins if git state is ambiguous — spec §9.3).
2. Determine the target version: the architect's argument, or `latest`.
3. If current == target, report "already up to date" and stop.

### 4.2 Preflight

- Ensure the working tree is clean (or warn and let the architect decide). The upgrade
  commits at the end; a dirty tree muddies rollback.
- Note the current commit so the architect can `git reset --hard` to roll back (spec §9.3).

### 4.3 Fetch the target version

Download/extract the target version's library into a temporary location (e.g.
`.pravartak-dev/upgrade-<target>/`), the same way `install.sh` obtains the archive. Do not
touch the live `pravartak/` yet.

### 4.4 Compare manifests

Compare the current manifest to the target version's template set: what files are **new**
(target has, current lacks), **changed** (template changed between versions), and
**removed** (current has, target no longer ships). New skills, packs, and templates surface
here (e.g. a new `go` language pack in a future release).

### 4.5 Classify each current file

For each file in the current manifest:

1. Compute its current content hash.
2. Compare to `content_hash_at_generation`.
   - **Unchanged since generation** → candidate for safe re-render from the new template.
   - **Changed since generation** → the project edited it; candidate for diff-and-prompt.
3. Combine with the file's declared `ownership` and `upgrade_strategy` (spec §9.2):

   | ownership / strategy | unchanged since generation | changed since generation |
   | --- | --- | --- |
   | `library` / `always-replace` | replace | replace (it's library-owned; warn if somehow edited) |
   | `project` / `diff-and-prompt` | re-render (show diff if output differs) | show diff, ask |
   | `project` / `merge-three-way` | re-render | three-way merge (original, current, new); on conflict, ask |
   | `project` / `preserve-on-conflict` | update | preserve + warn (leave the project's version) |

### 4.6 Render new templates

Render the target version's templates against the project's current values (project name,
slug, language version, archetype, coverage threshold, etc.) so the comparison is
value-for-value, not template-vs-rendered.

### 4.7 Build the upgrade plan

Produce a categorized plan:

- **safe-replace** — library-owned and unchanged files to overwrite.
- **diff-prompt** — project-owned files whose new render differs; show the diff per file.
- **preserve-warn** — project-edited files under `preserve-on-conflict`, left as-is.
- **new** — files/skills/packs/templates the target adds.
- **removed** — files the target no longer ships (propose deletion or retention).
- **version bump** — `pravartak_version` current → target.

### 4.8 Present for approval

Show the plan to the architect. For diff-prompt items, walk the diffs and collect a
decision per file (accept new / keep current / merge). Nothing is written before approval.

### 4.9 Apply

Execute the approved plan: write safe-replaces, apply accepted diffs/merges, leave
preserved files, add new files, handle removals per the architect's choice.

### 4.10 Replace the library directory

Replace the live `pravartak/` with the target version (this is a library-owned directory —
it is versioned, not edited, so it is replaced wholesale).

### 4.11 Update the manifest

Rewrite `.pravartak/manifest.json`: bump `pravartak_version` to the target, update
`generated_by_version`, `generated_at`, and `content_hash_at_generation` for every file the
upgrade wrote, add entries for new files, and remove entries for deleted files. Validate
the result against the target version's `pravartak/MANIFEST_SCHEMA.json`.

### 4.12 Commit

```text
chore: upgrade Pravartak to <target>

- <safe-replace count> library files replaced
- <diff-prompt count> project files reconciled (see plan)
- <preserve count> project files preserved
- New: <skills/packs/templates added>
- Removed: <files dropped>
- Manifest: <current> -> <target>
```

Clean up the temporary extraction directory.

## 5. Rollback

If the architect wants to undo, `git reset --hard <pre-upgrade-commit>` restores the
previous `pravartak/` and files. The manifest's `pravartak_version` reflects whatever is
actually on disk after the reset, so a subsequent `/pravartak-upgrade` behaves correctly
regardless of git gymnastics (spec §9.3).

## 6. Guardrails

- **Never write before approval.** The plan is presented and approved first.
- **Never overwrite a project-edited file** classified `preserve-on-conflict`, or any
  `diff-and-prompt` file, without an explicit per-file decision.
- **The manifest is authoritative** for version and ownership — trust it over inline headers
  and over git state.
- **Validate the new manifest** against the target schema before committing.
- **Replace `pravartak/` wholesale** — do not cherry-pick library files, or the installed
  version becomes incoherent.

## 7. Outputs

- An upgraded `pravartak/` at the target version.
- Reconciled project files per the approved plan.
- An updated, schema-valid `.pravartak/manifest.json`.
- A single upgrade commit (rollback-able via `git reset --hard`).
