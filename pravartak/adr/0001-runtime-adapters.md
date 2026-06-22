# ADR 0001 — Runtime-Neutral Core with Adapter Surfaces

## Status

Accepted

## Context

Pravartak's protocol is broader than any single agent runtime, but v0.5.0 expressed the
project almost entirely through Claude-facing surfaces:

- `CLAUDE.md` was the only canonical operating guide.
- Generated state, commands, and settings lived under `.claude/`.
- The Playbook and scaffold flow assumed Claude Code interactive sessions and Claude
  auto-mode launch flags.

That coupling made the library feel Claude-only even though the real protocol is about:

- ingestion,
- backlog and state management,
- architect review,
- autonomous execution,
- quality gates,
- promotion and drift handling.

We also want a supported mixed workflow where one runtime implements code and another
reviews it.

## Decision

Pravartak now separates its **runtime-neutral core** from **runtime adapter surfaces**.

### Core

The core protocol remains the source of truth for:

- `PRAVARTAK.md` as the canonical project operating guide,
- backlog and workflow state,
- skills, standards, and review/execution semantics,
- quality gates and promotion rules,
- runtime-role assignment (`interactive`, `autonomous`, `implementation`, `review`).

### Adapters

Runtime-specific integration details live in adapter surfaces:

- **Claude adapter**
  - `CLAUDE.md` as a compatibility wrapper that points to `PRAVARTAK.md`
  - `.claude/settings.json`
  - `.claude/commands/`
  - `docs/agent-runtimes/claude.md`
- **Codex adapter**
  - `docs/agent-runtimes/codex.md`
  - explicit prompts and procedures rather than speculative Codex-only settings files or
    slash-command conventions

## Consequences

### Positive

- Pravartak's protocol is documented as runtime-agnostic.
- Existing Claude-first projects keep working because `.claude/*` and `CLAUDE.md` remain.
- Codex becomes a first-class supported runtime through concrete repo artifacts.
- Mixed-runtime workflows become configurable without changing the protocol.

### Tradeoffs

- `.claude/*` still exists in this release. That is intentional: it is the Claude adapter
  compatibility layer, not the protocol itself.
- Workflow state still lives under `.claude/` for backward compatibility. The Playbook now
  documents those files as protocol state on a legacy path.
- Codex support is prompt- and doc-driven until a stable Codex-native command/settings
  surface exists in the repo and can be verified locally.

## Migration Guidance

- New scaffolds generate `PRAVARTAK.md` plus runtime adapter docs.
- `CLAUDE.md` remains generated, but only as a Claude adapter wrapper.
- Existing Claude-first projects do not need a big-bang rename. They can adopt the new
  canonical guide and Codex runtime docs on their next upgrade.
