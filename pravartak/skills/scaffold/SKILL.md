---
name: scaffold
description: >
  Set up a freshly-added Pravartak library into a working, managed project. Runs the
  five-question wizard, executes the archetype's ingestion, renders the canonical guide and
  runtime adapter templates, applies the language pack, wires the Claude command pointers,
  initializes state, runs a smoke test, generates the provenance manifest, and commits.
  Backs /scaffold. Invoked once, interactively, immediately after Pravartak is copied into a
  project.
---

# Skill: scaffold

## 1. Purpose

`scaffold` is the bootstrapping skill. It transforms a repo that merely *contains*
`pravartak/` into a fully Pravartak-managed project: ingested source material, a quality
gate, rendered config, wired commands, initialized state, a passing smoke test, and a
provenance manifest — committed and ready for architect review.

This SKILL.md is the **contract** (what scaffold does, its inputs, phases, guardrails, and
outputs). The detailed, mechanical step-by-step lives in
**`pravartak/scaffold/SCAFFOLD.md`**, with the wizard questions in
`pravartak/scaffold/wizard-questions.md` and the smoke test in
`pravartak/scaffold/post-scaffold-smoke-test.md`.

## 2. When to invoke

- **`/scaffold`** — once, in an **interactive** runtime session (never autonomous mode),
  immediately after `pravartak/` is copied/installed into the project. The Claude adapter
  exposes `/scaffold`; other runtimes invoke this skill directly.

Preconditions:

- `pravartak/` exists in the project root (the library is present).
- The project has **not** already been scaffolded. If `.pravartak/manifest.json` already
  exists, stop and tell the architect the project is already scaffolded (suggest
  `/pravartak-upgrade` if they meant to change versions).

## 3. Execution

Read **`pravartak/scaffold/SCAFFOLD.md`** and execute its procedure end to end. That
document is authoritative for the mechanics; the phases below are the contract it fulfills.

## 4. Phases (spec §7)

1. **Wizard** — ask the five questions from `pravartak/scaffold/wizard-questions.md`
   (project name, archetype, language pack, source location, overrides) and validate each
   answer. Includes the remote-vs-local-only decision and the custom-pack path.
2. **Ingestion** — read `pravartak/ingestion/<archetype>/INGESTION.md` and execute it,
   producing `discovery/`, a `discovery/README.md`, and a draft `.claude/backlog.md`
   (plus `AS_IS_ANALYSIS.md` for reverse-engineer, `CONTRADICTIONS.md` for loose-docs).
3. **Template rendering** — render every `pravartak/templates/*.template` with the
   project's values, writing each to its target with an inline provenance header (where the
   file type supports comments). This includes `PRAVARTAK.md`, the Claude compatibility
   wrapper, explicit Claude/Codex runtime docs, `scripts/no-delete-guard.sh`,
   `scripts/autonomous-preflight.sh`, `scripts/codex-auto.sh`, `scripts/claude-review.sh`,
   and `.pravartak/session-state.json`.
4. **Language pack application** — read `pravartak/language-packs/<lang>/PACK.md` and follow
   it: install the gate, copy language templates, set up isolation, verify required tools.
   Fail early with a clear message if a required tool is missing.
5. **Skills wiring** — for each universal command in `pravartak/commands/`, create a thin
   pointer in `.claude/commands/` (the Claude adapter's hybrid-reference model) that reads
   the corresponding `pravartak/skills/<skill>/SKILL.md` and executes with `$ARGUMENTS`.
6. **State initialization** — create the initial state files from templates (backlog,
   architect_review/progress + session, completed, blocked, escalations, current_story,
   commit_log, sprint-reports README).
7. **Smoke test** — run the quality gate against the empty project per
   `pravartak/scaffold/post-scaffold-smoke-test.md`. It must pass (pytest exit 5 /
   no-tests-collected counts as pass). On failure, surface it and stop — do not commit.
8. **Manifest generation** — write `.pravartak/manifest.json` recording every generated
   file's provenance, validated against `pravartak/MANIFEST_SCHEMA.json`.
9. **Commit** — commit the scaffold result; push to the default branch unless local-only.
10. **Output** — print the `PRAVARTAK_SCAFFOLD_COMPLETE` report with counts and the
    recommended next step (`/review-all`).

## 5. Guardrails

- **Interactive only.** Never run scaffold under `--permission-mode auto`.
- **Idempotency / no double-scaffold.** Refuse if `.pravartak/manifest.json` already exists.
- **Smoke test gates the commit.** Do not commit or push if the smoke test fails (spec §7.7)
  — a failed smoke test means a misconfigured language pack; fix it first.
- **Fail early on missing tools.** If the language pack's required tools are absent, stop
  with a clear install message rather than producing a broken project.
- **Provenance on everything generated.** Every generated file gets an inline header (where
  comments are supported) and a manifest entry; library-owned pointer files are marked
  `ownership: library`, project files `ownership: project` (spec §9).
- **Do not start review or auto-mode.** Scaffold ends at the report; architect review is the
  next, separate step.

## 6. Outputs

- A populated `discovery/`, a draft `.claude/backlog.md`, and the full `.claude/` layout.
- Rendered `PRAVARTAK.md`, `CLAUDE.md`, runtime adapter docs, `.claude/settings.json`,
  `.claude/scripts/gate.sh`, `scripts/no-delete-guard.sh`, `scripts/autonomous-preflight.sh`,
  `scripts/codex-auto.sh`, `scripts/claude-review.sh`, `.pravartak/session-state.json`,
  and language config.
- Command pointers in `.claude/commands/` for every universal command.
- Initialized state files; a passing smoke test.
- `.pravartak/manifest.json` (schema-valid).
- A scaffold commit (pushed unless local-only) and the `PRAVARTAK_SCAFFOLD_COMPLETE` report.
