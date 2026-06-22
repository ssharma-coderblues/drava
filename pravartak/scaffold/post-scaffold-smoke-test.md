# Post-Scaffold Smoke Test

Run by SCAFFOLD.md Phase 7, after the language pack is applied and state is initialized but
**before** the manifest is generated and the scaffold is committed. Its job: prove the
generated quality gate runs cleanly against the empty project, catching a misconfigured
language pack before it is committed (spec §7.7).

## Procedure

1. **Locate the gate.** Confirm `.claude/scripts/gate.sh` exists and is executable.
2. **Run it** from the project root, the same way the autonomous loop and the commit hook
   will:

   ```bash
   .claude/scripts/gate.sh
   ```

3. **Interpret the result** against the empty-project expectations below.

## Expected outcomes (empty project)

The project has no production code or tests yet, so the gate must pass *vacuously*:

| Stage | Empty-project expectation |
| --- | --- |
| Lint | Pass (nothing to lint, or only generated config) |
| Format check | Pass |
| Type check | Pass (no sources) |
| Unit tests | **Pass via "no tests collected"** — pytest exit code 5 is treated as success (spec §14.2). The equivalent for other runners is treated the same way. |
| Integration tests | Pass / skipped (none defined) |
| Coverage threshold | Pass / not applicable (no code to cover yet) |

The key lesson encoded here: **"no tests collected" must not fail the gate.** Early sprints
have no tests; if exit 5 were treated as failure, the very first commit would deadlock
(spec §14.2). The language pack's `gate.sh` already handles this — the smoke test verifies
it actually does.

## On success

Report the gate passed and continue to SCAFFOLD.md Phase 8 (manifest generation).

## On failure

**Stop. Do not generate the manifest. Do not commit.** Surface:

- which stage failed and its output,
- the most likely cause (commonly: a required tool missing or on the wrong version, the
  `.venv/` absolute paths not resolving, or a template placeholder left unrendered in
  `gate.sh`),
- the remedy (install/upgrade the tool, re-run `venv-setup.sh`, or fix the pack).

A failing smoke test almost always means the language pack is misconfigured for this
machine. Fix the cause and re-run `/scaffold` (or just re-run the gate, then resume from
Phase 8 once it passes).
