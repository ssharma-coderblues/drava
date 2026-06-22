# Python Language Pack

The reference language pack. It encapsulates everything Python-specific: the quality gate,
configuration templates, and project-local isolation. The scaffold applies it during
Phase 5 (see `pravartak/scaffold/SCAFFOLD.md`).

## What this pack provides

| File | Role |
| --- | --- |
| `PACK.md` | This document — what the pack does and how the scaffold applies it. |
| `gate.sh` | The quality gate. Becomes `.claude/scripts/gate.sh` on the Claude compatibility path. Dual-mode: direct run and `--hook`. |
| `pyproject.toml.template` | Project metadata, mypy (strict), pytest, and coverage config. |
| `ruff.toml.template` | ruff lint + format config (authoritative for ruff). |
| `venv-setup.sh` | Creates the project-local `.venv/` and installs dev tools. |

## Tool expectations

- **Required:** `ruff`, `mypy`, `pytest`, `pytest-cov`, `pytest-asyncio`.
- **Optional (recommended by the standards):** `testcontainers` (integration tests, §13.6),
  `bandit` (security, §13.10).
- A Python interpreter for the **local dev** version (may differ from the production
  target — lesson §14.6).

## Python version expectations

- **Production target** (`{{LANGUAGE_VERSION}}`): drives `requires-python` and mypy
  `python_version`. This is the version the code must run on in production.
- **Local dev** (`{{LANGUAGE_VERSION_LOCAL}}`): whatever interpreter is installed locally;
  used to create the `.venv/`. May lag the production target (e.g. pyenv on 3.11 while
  production targets 3.14).

## Isolation strategy (lesson §14.1)

Always a **project-local `.venv/`**, never a shared or pyenv-global interpreter — sibling
projects collide otherwise. The gate invokes tools from `.venv/bin/*` by **absolute path**
computed at runtime, so **no activation is required** and the gate works regardless of
shell state. The absolute path is derived from the gate script's own location (two levels
up from `.claude/scripts/gate.sh`), so it remains correct across clones and machines.

## Application procedure (followed by SCAFFOLD.md Phase 5)

1. **Create isolation.** Run `venv-setup.sh`, passing the local dev interpreter if it
   differs from `python3`:

   ```bash
   pravartak/language-packs/python/venv-setup.sh "$(command -v python3)"
   ```

   This creates `.venv/` and installs the required (and best-effort optional) tools.

2. **Compute `{{RUFF_TARGET_VERSION}}` (lesson §14.6).** ruff may not yet support the
   production Python version. Determine the highest `pyXY` target the installed ruff
   accepts that is **at or below** the production target; if ruff does not support the
   production target yet, use the highest it does. A practical method:

   - Read ruff's supported targets from `.venv/bin/ruff rule --help` / its docs, or
   - Probe: try rendering `target-version = "py<XY>"` for the production `XY` and, if ruff
     rejects it, step down (`py314 → py313 → …`) until accepted.

   Set `{{RUFF_TARGET_VERSION}}` to that value. mypy `python_version` and `requires-python`
   stay at the production target — they are not stepped down.

3. **Render templates** to the project root with provenance headers:
   - `pyproject.toml.template` → `pyproject.toml`
   - `ruff.toml.template` → `ruff.toml`

4. **Install the gate.** Copy `gate.sh` to `.claude/scripts/gate.sh`, add the shell
   provenance header, and `chmod +x`. The gate needs no placeholder rendering — the
   coverage threshold lives in `pyproject.toml` and the venv path is computed at runtime.

5. **Register the commit hook.** The rendered Claude adapter settings file
   (`.claude/settings.json`) runs
   `.claude/scripts/gate.sh --hook` on `PreToolUse`/Bash (hooks live under the `"hooks"`
   key — lesson §14.4).

6. **Verify tools.** Confirm `.venv/bin/{ruff,mypy,pytest}` exist and run. If any required
   tool is missing, **fail the scaffold early** with a clear message (which tool, how to
   install) rather than producing a broken project (spec §7.4).

## The quality gate

`gate.sh` runs, against `src/` and `tests/` (whichever exist):

1. `ruff check` — lint.
2. `ruff format --check` — format check.
3. `mypy` — strict type check (config in `pyproject.toml`).
4. `pytest` — tests + coverage; the coverage threshold (`fail_under`) is enforced by
   `pyproject.toml`.

Key behaviors:

- **Empty project passes vacuously** — with no `src/`/`tests/`, the gate returns success.
  This is what the post-scaffold smoke test relies on.
- **pytest exit 5 (no tests collected) is success** (lesson §14.2). Real failures
  (exit 1-4) block.
- **Absolute-path venv tools** (lesson §14.1) — no activation.

## How this pack enforces the universal standards (§13)

| Standard | Enforcement in this pack |
| --- | --- |
| Type safety | `mypy --strict` via `[tool.mypy] strict = true`. |
| TDD + 95% coverage | `[tool.coverage.report] fail_under = {{COVERAGE_THRESHOLD}}`, `--cov-branch`. |
| Async-first (§13.8) | ruff `ASYNC` rules; `pytest-asyncio` with `asyncio_mode = "auto"`. |
| Security baseline (§13.10) | ruff `S` (bandit) rules; optional `bandit` tool. |
| SOLID / composition | ruff `B`, `SIM`, `PL`, `A` discourage anti-patterns. |
| Integration tests (§13.6) | `testcontainers` provided for real backing services. |

## Multi-language projects

When the wizard chooses `multiple`, this pack is one of several. The composite
`.claude/scripts/gate.sh` runs each pack's gate in sequence and fails if any fails
(spec §12.5).
