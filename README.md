# Drava

This workspace is now decoupled from the previous external-orchestrator spike.

## Current orchestration direction

- Pravartak is installed in [`pravartak/`](pravartak/), copied from `https://github.com/coder-blues/pravartak`.
- Pravartak is a repo-local library/playbook, not a daemon process. Use its scaffold and autonomous-loop workflow instead of AO session spawning.
- The remaining Wave-Planner PoC in [`poc-wave-planner/`](poc-wave-planner/) computes dependency/collision-safe execution waves and emits Pravartak handoff instructions.

## Removed legacy orchestrator artifacts

- `integration-spike/`
- historical analysis reports under `reports/`

Those artifacts were removed so local Drava work no longer depends on a vendored orchestrator checkout, daemon-specific config, or spawn/status assumptions from the previous approach.

## Next step

Run Pravartak scaffold for the target Drava code repository when ready:

```text
Codex/other runtime: read pravartak/skills/scaffold/SKILL.md and execute it
Claude: /scaffold
```
