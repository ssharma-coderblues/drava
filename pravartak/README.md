# Pravartak

**Version:** 0.5.0
**What it is:** A library that turns any repository into a runtime-neutral agentic project.

Pravartak (Sanskrit: *initiator, the one who sets things in motion*) does not write code.
It establishes the operating environment in which an agent runtime — Claude, Codex, or a
future adapter — does the work, with architect review, quality gates, drift management, and
resumable workflows.

Drop the `pravartak/` directory into a repo, run scaffold through your chosen interactive
runtime, and the repository becomes structured for architect-reviewed,
autonomously-executed development.

## Read this first

The operations manual is **[PLAYBOOK.md](PLAYBOOK.md)**. It is the source of truth for
daily use. This README is only a pointer.

## The five-phase pipeline

Every Pravartak-managed project follows the same pipeline; what fills each phase varies
by archetype:

1. **Ingestion** — pull authoritative source material into a normalized `discovery/`. Seven
   archetypes: greenfield-markdown, reverse-engineer-code, confluence, jira, **linear**,
   **brownfield-adopt**, loose-docs.
2. **Decomposition** — break it into a flat backlog of executable stories.
3. **Architect Review** — a standalone, human-gated walkthrough of every story.
4. **Autonomous Execution** — the assigned runtime runs stories one at a time, TDD + quality
   gates, merging each to the integration branch. The loop **never touches `main`**;
   promotion to `main` is a separate, gated **promotion phase** (`external` or
   `pravartak-gated` — see PLAYBOOK).
5. **Drift Management** — keep specs and code aligned as both evolve.

## Quick start

```bash
# Manual copy (canonical)
git clone https://github.com/vesta-platform/pravartak.git /tmp/pravartak-lib
cp -r /tmp/pravartak-lib/pravartak ./your-project/
cd your-project

# Then choose an interactive runtime:
#   Claude: /scaffold
#   Codex or another runtime: read pravartak/skills/scaffold/SKILL.md and execute it
```

Or the curl convenience wrapper:

```bash
cd your-project
curl -sSL https://pravartak.vesta-platform.dev/install.sh | bash
```

After scaffolding, begin architect review with the runtime assigned to review. **Do not
launch autonomous execution until architect review is complete.**

## Directory map

| Path | Purpose |
| --- | --- |
| `PLAYBOOK.md` | Operations manual — read this |
| `VERSION` | Library semantic version |
| `MANIFEST_SCHEMA.json` | Schema for generated `.pravartak/manifest.json` |
| `skills/` | The seven universal, language-agnostic skills |
| `commands/` | Universal slash-command definitions |
| `ingestion/` | Archetype-specific ingestion procedures |
| `language-packs/` | Language-specific quality gates and tooling |
| `standards/` | Universal engineering standards |
| `templates/` | Files copied/rendered during scaffold |
| `scaffold/` | The `/scaffold` procedure |
| `install.sh` | Curl-installable wrapper |
| `adr/` | Design notes and architecture decisions |
| `examples/` | Worked examples |

## What Pravartak is not

Not a build system, not a CI/CD tool, not a project-management tool, not a code generator,
not language-specific. See PLAYBOOK.md §"Scope" for the boundaries.

## Ownership rule

`pravartak/` is owned by the library — versioned, not edited. Everything the scaffold
generates (`PRAVARTAK.md`, runtime adapter docs, `.claude/` compatibility surfaces, state
files) is owned by the project and edited freely. Upgrades reconcile the two through the
provenance manifest.

---

Vesta Platform Engineering · Generalized from the CashApp2 autonomous workflow.
