# TypeScript Language Pack

The TypeScript/Node language pack. It encapsulates everything TypeScript-specific: the
quality gate, configuration templates, and project-local isolation. The scaffold applies it
during Phase 5 (see `pravartak/scaffold/SCAFFOLD.md`). Authored to mirror the Python pack's
contract exactly, translated to a pnpm + turbo + biome + tsc + vitest monorepo.

## What this pack provides

| File | Role |
| --- | --- |
| `PACK.md` | This document — what the pack does and how the scaffold applies it. |
| `gate.sh` | The quality gate. Becomes `.claude/scripts/gate.sh` on the Claude compatibility path. Dual-mode: direct run and `--hook`. |
| `delta-coverage.mjs` | Coverage enforcer on **changed files only** (brownfield calibration, GAN-38). Becomes `.claude/scripts/delta-coverage.mjs`; the gate calls it. |
| `node-setup.sh` | Verifies pnpm, installs the workspace, confirms gate tools resolve. The Node analogue of Python's `venv-setup.sh`. |
| `package.json.template` | Root-workspace metadata: pinned pnpm, turbo, biome, vitest, root scripts. |
| `tsconfig.json.template` | Strict base TS config the project packages extend. |

## Tool expectations

- **Required:** `pnpm` (via corepack, version pinned in `package.json` `packageManager`),
  `turbo`, `@biomejs/biome`, `typescript` (`tsc`), `vitest`, `@vitest/coverage-v8`. All are
  workspace dev dependencies resolved from the project's own `node_modules` — never global.
- **Required system tool:** `node` (≥ 20, ships corepack), `jq` (for the `--hook` stdin
  contract), `git`.
- **Recommended system tool:** `gitleaks` — the gate runs `gitleaks protect --staged` as a
  defense-in-depth secret scan (GAN-37, because secrets live in a literal gitignored `.env`).
  If absent, the gate SKIPs that step loudly rather than failing.
- **Per-stack, project-supplied:** `prisma` / `@prisma/client` where the project uses them;
  the gate does not assume Prisma but the integration-test step (via `scripts/dev.sh`) will
  exercise it when present.

## Node version expectations

- **Production target** (`{{LANGUAGE_VERSION}}`): drives the `engines.node` field and the
  `@tsconfig` / `target` lib level. The version the code must run on in production.
- **Local dev** (`{{LANGUAGE_VERSION_LOCAL}}`): whatever Node is installed locally; used to
  run the gate. May differ from the production target; unlike Python's ruff/mypy split
  (§14.6), TypeScript tooling rarely lags Node versions, so no target step-down is needed —
  but record both for clarity.

## Isolation strategy (lesson §14.1)

pnpm gives **project-local isolation natively** — `node_modules/` is per-project, and with
workspaces the dependency tree is hoisted within the repo, never shared globally. The gate
invokes tools via `pnpm exec` / `pnpm turbo` so they resolve from the project's own
`node_modules/.bin`, not a global install. pnpm itself is invoked through `corepack pnpm`
when available, so the **pinned `packageManager` version** in `package.json` is used rather
than whatever pnpm happens to be on PATH. No activation, no shell-state dependence — the gate
works across clones and machines.

## Application procedure (followed by SCAFFOLD.md Phase 5)

1. **Establish isolation.** From the project root, run `node-setup.sh`:

   ```bash
   pravartak/language-packs/typescript/node-setup.sh
   ```

   This enables corepack, installs the workspace (frozen lockfile if one exists, else an
   initial install that creates it), and verifies biome / tsc / vitest resolve from the
   workspace. It fails early with a clear message if a required tool is missing (spec §7.4).

2. **Render templates** to the project root with provenance headers:
   - `package.json.template` → `package.json` (only if the project has no root
     `package.json` yet; for a brownfield adoption that already has one, **do not overwrite**
     — instead merge the required `scripts` and `devDependencies`, and record the merge in
     the manifest as `ownership: project`, `upgrade_strategy: diff-and-prompt`).
   - `tsconfig.json.template` → `tsconfig.base.json` (the strict base packages extend).

3. **Install the gate.** Copy `gate.sh` to `.claude/scripts/gate.sh` **and**
   `delta-coverage.mjs` to `.claude/scripts/delta-coverage.mjs`, add provenance headers, and
   `chmod +x .claude/scripts/gate.sh`. The gate needs no placeholder rendering — the coverage
   threshold is read from the environment (`COVERAGE_THRESHOLD`, default 95) or single-sourced
   in `vitest.config.ts`, and tool paths resolve at runtime via pnpm.

4. **Register the commit hook.** The rendered Claude adapter settings file
   (`.claude/settings.json`) runs
   `.claude/scripts/gate.sh --hook` on `PreToolUse`/Bash (hooks live under the `"hooks"`
   key — lesson §14.4).

5. **Verify tools.** `node-setup.sh` already did this; re-confirm `pnpm exec biome
   --version`, `pnpm exec tsc --version`, `pnpm exec vitest --version` succeed. If any
   required tool is missing, **fail the scaffold early** (spec §7.4).

## The quality gate

`gate.sh` runs, in order (full detail in the script's header comments):

1. `pnpm install --frozen-lockfile` — install integrity / no dependency drift.
2. `turbo run lint` — biome check + format. **No-op guard (GAN-34):** fails if 0 tasks ran
   (i.e. no package wired a `lint` script), because a lint that lints nothing is worse than
   no lint.
3. `turbo run typecheck` — `tsc --strict`. Same no-op guard.
4. `turbo run test` — vitest unit tests. No-test-files for an empty stage is a vacuous pass
   (the §14.2 analogue of pytest exit 5).
5. **Delta coverage (GAN-38)** — `delta-coverage.mjs` enforces the threshold on **changed
   production files only**, against the integration branch. Pre-existing untouched code is
   grandfathered. Whole-repo absolute coverage is intentionally not enforced — this is what
   lets a brownfield adoption's first story pass without a coverage-remediation sprint first.
6. **Integration tests (GAN-37)** — run via `./scripts/dev.sh pnpm test:integration`, which
   loads the gitignored `.env` so integration tests get their secrets. Skipped vacuously if
   the project has no `dev.sh` or no `test:integration` target.
7. **Secret scan (GAN-37)** — `gitleaks protect --staged` blocks a commit that stages a
   secret. Defense-in-depth for the literal-`.env` secrets model. SKIPped loudly if gitleaks
   is not installed.

Key behaviors:

- **Empty project passes vacuously** — with no package `src/`, the gate returns success.
  The post-scaffold smoke test relies on this.
- **Vitest "no test files" is success** for empty stages (§14.2 analogue).
- **No-op steps FAIL, not pass** (GAN-34) — a lint/typecheck that ran 0 tasks is a
  misconfiguration, surfaced as a failure, never a silent green.
- **Workspace-resolved tools** (§14.1) — via `pnpm exec` / `corepack pnpm`, no global deps.

## How this pack enforces the universal standards (§13)

| Standard | Enforcement in this pack |
| --- | --- |
| Type safety | `tsc --strict` (the base tsconfig sets `strict: true` plus `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`). |
| TDD + coverage (§13.3) | vitest coverage with `@vitest/coverage-v8`; delta-coverage enforces `{{COVERAGE_THRESHOLD}}%` on changed files (brownfield calibration). |
| Async-first (§13.8) | biome rules flag floating promises / misused async; TS strict surfaces unhandled promise types. |
| Security baseline (§13.10) | `gitleaks protect --staged` in the gate; biome's `noDangerouslySetInnerHtml` / suspicious rules; parameterized queries enforced by review + Prisma. |
| SOLID / composition | biome's complexity and suspicious rule groups discourage the anti-patterns. |
| Integration tests (§13.6) | `test:integration` run via `scripts/dev.sh` against real backing services (Postgres/Redis/MinIO from docker compose). |

## Brownfield note (Gandiva)

This pack was authored alongside Gandiva's adoption — a brownfield project (`brownfield-adopt`
archetype). Two pack behaviors exist specifically for brownfield:

- **Delta coverage**, not whole-repo absolute (GAN-38) — pre-existing sub-threshold code does
  not deadlock the first story.
- **The no-op-lint guard** (GAN-34) — Gandiva shipped Wave 0 with `pnpm lint` silently
  running 0 tasks; this pack refuses to treat that as a pass.

For a greenfield TypeScript project, both behaviors are still correct (delta coverage on a
fresh repo measures all-new code = effectively whole-repo; the no-op guard ensures lint is
actually wired from story 1).

## Multi-language projects

When the wizard chooses `multiple`, this pack's `gate.sh` is copied to
`.claude/scripts/gate-typescript.sh` (not `gate.sh`), and the composite
`templates/gate.sh.template` becomes the `.claude/scripts/gate.sh` entry point, running each
language's sub-gate in sequence (spec §12.5).
