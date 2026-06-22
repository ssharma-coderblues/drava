# Pravartak Playbook

**The operations manual. Read this before using Pravartak.**

Version: 0.5.0 · Audience: architects and operators of Pravartak-managed projects.

This is the daily-use distillation of the full specification. Where this Playbook
and the specification disagree, the specification is authoritative — but for getting
work done, this is the document you want open.

---

## 1. Mental model

Pravartak turns a repository into a runtime-neutral agentic project. It does **not**
write code. It establishes the operating environment — directory structure, quality
gates, state files, skills, and standards — in which an assigned runtime does the work.
Claude and Codex are first-class adapters in this release. Claude retains its current
interactive and auto-mode surfaces; Codex is supported through explicit prompts and
runtime docs rather than speculative settings-file conventions.

The discipline Pravartak encodes:

- Separate **spec** from **code**.
- Separate **architect review** (human-gated intent) from **execution** (autonomous).
- Separate **language-specific** concerns (packs) from **universal** ones (skills, standards).
- Track **provenance** so the library can be upgraded without clobbering your edits.
- **Version** the library and learn from each project.

### 1.1 The ownership boundary — the one rule that matters most

```text
your-project/
├── pravartak/      ← OWNED BY THE LIBRARY. Versioned. Do not edit. Replaced on upgrade.
├── .pravartak/     ← Provenance manifest. Managed by skills, not hand-edited.
├── .claude/        ← OWNED BY THE PROJECT. Claude adapter compatibility surface.
├── PRAVARTAK.md    ← OWNED BY THE PROJECT. Canonical runtime-neutral operating guide.
├── CLAUDE.md       ← OWNED BY THE PROJECT. Claude adapter wrapper.
├── docs/agent-runtimes/
│   ├── claude.md   ← OWNED BY THE PROJECT. Verified Claude launch/integration notes.
│   └── codex.md    ← OWNED BY THE PROJECT. Explicit Codex prompts and procedures.
├── discovery/      ← OWNED BY THE PROJECT. Normalized source material.
└── src/ tests/ ... ← OWNED BY THE PROJECT. Written by the autonomous loop.
```

If you want to change Pravartak's behavior, you change `pravartak/` (and contribute it
back) — but never as part of a project. Within a project, you only ever edit the
project-owned files. Upgrades reconcile the two through the manifest (§10).

---

## 2. The five-phase pipeline

Every Pravartak-managed project runs the same pipeline. What fills each phase varies by
archetype (§3); the phases themselves are universal.

| Phase | Name | Who drives | Output |
| --- | --- | --- | --- |
| 1 | Ingestion | `/scaffold` | Normalized `discovery/` + draft backlog |
| 2 | Decomposition | `/scaffold` (during ingestion) | `.claude/backlog.md` of stories |
| 3 | Architect Review | **You** (`/review-all`) | Reviewed backlog, scope additions |
| 4 | Autonomous Execution | Assigned autonomous runtime | Code, tests, merges |
| 5 | Drift Management | You + `/drift-check` | Specs and code kept aligned |

Phases 1–2 are one-time at project start (re-runnable when source material changes).
Phases 3–5 are continuous.

**The hard rule:** auto-mode (Phase 4) does not start until architect review (Phase 3)
is complete. Skipping review produces code that may not match intent. See §14.8 of the
spec; this Playbook is emphatic about it too.

---

## 3. Archetypes (quick reference)

The archetype determines which ingestion procedure runs in Phase 1. All other phases are
archetype-independent.

| Archetype | Source material | Complexity | Notes |
| --- | --- | --- | --- |
| `greenfield-markdown` | Markdown design docs | Low | Simplest. Normalize → decompose. |
| `reverse-engineer-code` | An existing codebase | High | Produces `discovery/AS_IS_ANALYSIS.md`; review the synthesis carefully. |
| `confluence` | Confluence pages | Medium | Pull-once (recommended) or live-sync. |
| `jira` | Jira backlog | Medium | Preserves Jira IDs; review carries more weight (stories lack architecture). |
| `linear` | Linear backlog | Medium | Parallel to Jira: preserves Linear IDs + project/initiative links; review-heavy; opt-in status write-back. |
| `brownfield-adopt` | A partly-built project (code + specs + optional tracker) | High | Adopts existing specs in place; partitions DONE/REMAINING/AMBIGUOUS; builds only what's left. May overlay `linear`/`jira`. |
| `loose-docs` | Mixed-format docs | High | Produces `discovery/CONTRADICTIONS.md`; resolve all before review. |

v0.5.0 ships ingestion for all seven archetypes. `confluence`, `jira`, and `linear` require a
configured connector (`pravartak/ingestion/<archetype>/connector.md`) and credentials;
`brownfield-adopt` optionally overlays a `linear`/`jira` tracker (then it uses that connector
too).

---

## 4. Adopting Pravartak

### 4.1 Install (manual copy — canonical)

```bash
git clone https://github.com/vesta-platform/pravartak.git /tmp/pravartak-lib
cp -r /tmp/pravartak-lib/pravartak ./your-project/
cd your-project
```

### 4.2 Install (curl — convenience)

```bash
cd your-project
curl -sSL https://pravartak.vesta-platform.dev/install.sh | bash
```

The install script does exactly what the manual copy does: download the archive, extract
it, place `pravartak/` in the current directory. No daemons, no global config, no shell
hooks. It accepts an optional version argument; defaults to `latest`.

### 4.3 Scaffold

Open the project in an **interactive** runtime session and scaffold it:

```text
Claude: /scaffold
Codex/other runtime: read pravartak/skills/scaffold/SKILL.md and execute it
```

This runs the wizard (§5), executes ingestion, renders templates, applies the language
pack, wires the skills, initializes state, runs a smoke test, writes the manifest, and
commits. When it finishes you'll see `PRAVARTAK_SCAFFOLD_COMPLETE` and a recommended next
step (`/review-all`).

---

## 5. The scaffold wizard

`/scaffold` asks five questions:

1. **Project name** — filesystem-friendly identifier, e.g. `cashapp2`.
2. **Archetype** — one of the seven in §3.
3. **Language pack** — `python` / `typescript` / `go` / `java` / `rust` / `multiple` / `custom`.
4. **Source material location** — where the existing specs or code live.
5. **Overrides** — free-form notes captured verbatim into `PRAVARTAK.md`.

Two scaffold-time decisions worth knowing in advance:

- **Remote vs. local-only.** If you give the wizard an `origin` URL it uses it; if not, it
  generates a local-only protocol variant so the autonomous loop's `git push` never fails
  on a missing remote (spec §14.5).
- **Custom language pack.** If your language has no built-in pack, choose `custom` and
  the interactive runtime walks you through assembling a `gate.sh` from your
  linter/formatter/type-checker/test-runner/coverage commands
  (`pravartak/language-packs/_custom/PACK.md`).

After scaffolding, the project layout is as documented in spec §6.3.

---

## 6. Skills and commands (quick reference)

Skills live in `pravartak/skills/<skill>/SKILL.md` (library-owned). The scaffold creates
thin **pointer** commands in `.claude/commands/` for the Claude adapter surface. Other
runtimes read the same skill files directly. This is the **hybrid reference** model:
upgrade the library, and the commands automatically pick up new behavior.

| Command | Skill | What it does |
| --- | --- | --- |
| `/scaffold` | `scaffold` | Set up the project (wizard → ingestion → render → wire → smoke → manifest → commit). |
| `/review-all` | `architect-review` | Sequential walkthrough of every story; pause/resume. |
| `/review-story <ID>` | `architect-review` | Ad-hoc review of one story. |
| `/add-scope` | `scope-addition` | Bring a new external system into scope; propose draft stories. |
| `/retrospect` | `retrospective` | Capture lessons after a sprint or at project end. |
| `/drift-check` | `drift-detection` | Detect where specs and code have diverged. |
| `/pravartak-upgrade` | `upgrade` | Migrate to a new Pravartak version via the manifest. |
| `/promote` | `promotion` | Run the gated integration→`main` promotion phase (`external` or `pravartak-gated`). |
| `/status` | — | Report current pipeline state from the state files. |

The autonomous loop (`autonomous-loop` skill) has no slash command — it is invoked by
auto-mode (§8), not by a human. `/promote` is the build-completion step, run deliberately
after the loop finishes — never inside the loop (§8.6).

---

## 7. Architect review (Phase 3)

This is the only phase that is fully human-gated, and the highest-leverage thing you do.

### 7.1 Run it

```text
/review-all                 # walk the whole backlog, resumable
/review-story PROJ-012      # review one story ad-hoc
```

### 7.2 Per-story rhythm

For each story the review runtime presents: the story (id/title/scope/acceptance/deps/source
pointer), the linked requirements (verbatim quote + cross-references across `discovery/`),
and its own reasoning (how it implements the requirement, which GoF patterns fit, SOLID
risks, tests needed, edge cases, risks to flag). Then it opens the floor. You respond with:

- **approve** — accept as-is.
- **skip** — defer; story stays unreviewed-but-skipped.
- **pause** — stop the session; resume later with `/review-all`.
- **add-scope: …** — invoke the scope-addition sub-flow inline (§7.4).
- **free-form feedback** — anything else. If it implies a spec change, the review runtime
  runs a change-impact analysis, confirms the affected files with you, and applies the
  change consistently across all docs.

Every story review produces a commit — even no-change reviews — for granular audit history.

### 7.3 Resumability

State lives in `.claude/architect_review/session.md` and `progress.md`. Pause any time;
`/review-all` offers to continue from the paused point or restart.

### 7.4 Scope addition

Say `add-scope: …` during a review, or run `/add-scope` standalone. You provide the new
system's repo path + doc paths and say how deep to read. The active review runtime reads
it, asks clarifying questions, proposes an integration path (with options where there is
genuine choice), identifies doc impact, and proposes draft stories — capturing nothing to
`scope_additions.md` until you approve.

### 7.5 Spec/code drift during review

If you change the spec for a story that autonomous execution has **already implemented**,
the review runtime does **not** edit the code. It queues a corrective story
(`STORY-CORR-N`) in `scope_additions.md`. You later promote corrective stories to the
backlog, where autonomous execution picks them up. Spec changes are immediate; code
alignment is queued. This keeps review focused on intent.

### 7.6 Finishing review

Review ends when every story in `progress.md` is REVIEWED or SKIPPED. The review runtime
writes `.claude/architect_review/SUMMARY.md`. Then you promote scope additions and
corrective stories from `scope_additions.md` into `backlog.md`. **Only after promotion do
you launch autonomous execution.**

---

## 8. Autonomous execution (Phase 4)

### 8.1 Launch

Every autonomous run reads `PRAVARTAK.md`, the runtime adapter guide, and
`pravartak/skills/autonomous-loop/SKILL.md`.

Claude example:

```bash
claude --permission-mode auto --effort xhigh --max-budget-usd 100 \
  -p "Read PRAVARTAK.md, docs/agent-runtimes/claude.md, and pravartak/skills/autonomous-loop/SKILL.md. Execute the autonomous workflow protocol for this repository."
```

Codex example:

```text
Read PRAVARTAK.md, docs/agent-runtimes/codex.md, and pravartak/skills/autonomous-loop/SKILL.md. Act as the autonomous_runtime for this project. Resume from the standard Pravartak state files and continue until the backlog is empty or a stop condition fires.
```

### 8.2 Per-story loop

The Git model is **integration branch + feature-branch-per-story** (spec §11.2, §14.9).
Each repo has one integration branch (cut from `main` the first time the repo is touched).
A story is built on its own feature branch off that integration branch, and on a clean gate
pass is merged **back into the integration branch** by the loop itself. **The loop never
touches `main`** — merging integration→`main` is a separate, downstream DevOps step (after a
production deploy), out of the loop's scope.

For each unchecked story: check resume state → ensure the integration branch exists (create
off `main` on first touch) → cut the feature branch from it
(`feature/<project>-<story-id>-<slug>`) → TDD (failing test → minimal impl → refactor) →
quality gates (lint, format, type-check, unit, integration, coverage; up to 3 retries
each) → commit (the PreToolUse hook re-runs the gate) → **on a clean gate pass, merge the
feature branch into the integration branch (no-ff, story-id in the merge message) — the
passing gate IS the approval; no human ask, no PR to `main`** → re-run the gate against the
integration branch post-merge (undo the merge + escalate on failure) → push the integration
branch and the feature branch (for history) → mark complete → next story.

**Honest completion only.** A story is marked complete only if it genuinely passed the full
gate. The loop never merges partial work, never fabricates a passing gate, and never reports
COMPLETE for unbuilt or untested work — it escalates (§8.4) with the true partial state.

**Feature branches are not deleted by the loop.** Under the integration-branch model a
feature branch is kept until its work reaches `main` via the downstream integration→`main`
merge; cleanup of merged feature branches and `git remote prune origin` is a periodic
hygiene step run after integration→`main` lands, not part of the per-story loop (spec §14.7).

### 8.3 Sprint boundaries

After a sprint's last story: tag `sprint-<n>-complete`, push the tag, write
`docs/sprint-reports/sprint-<n>.md`, continue.

### 8.4 Stop conditions

Auto-mode writes context to `.claude/escalations.md` and halts on:

- 3 consecutive failures on the same gate after retries.
- 20 total denied operations in a session.
- Acceptance criteria cannot be inferred from the spec.
- A story depends on incomplete prior work.
- A required spec change surfaces mid-implementation (auto-mode never edits specs).
- The auto-mode classifier blocks an action with no safe alternative.
- **Repo-ownership boundary (spec §14.11).** A story requires writing to, branching on, or
  pushing to a repository the session does not own a real working checkout of — e.g. a
  read-only/shallow "analysis" clone or another team's repo. The loop must NOT push branches
  or open PRs there. It halts and surfaces exactly which repo and which action, for a human
  to do in a proper checkout with the owning team aware. The clean rule:
  **the autonomous/developer boundary is the repo-ownership boundary** — the loop builds what
  you own; anything touching other teams' repos is human-driven developer work.
- **Irreversible or outward-facing action without explicit authorization (spec §11.4).** Any
  push/PR to an external repo, any action on another team's live system, or any other
  outward, hard-to-reverse step not explicitly authorized for this run. The loop pauses and
  asks rather than assuming authorization — even if a literal reading of the instructions
  seems to permit it. Speed or convenience never licenses an unauthorized outward action.

**Escalation is a first-class, expected outcome, not a failure.** An honest halt with true
per-story state is always preferred over forcing completion or taking an unauthorized action.
A HALTED report covering three real, tested stories is a success, not a shortfall (spec §14.10).

### 8.5 Resumability

Fully resumable. State is in plain files (`escalations.md`, `blocked.md`,
`current_story.md`, `backlog.md`, `completed.md`). Restarting the loop picks up where it
stopped. Inspect the classifier with `claude auto-mode`.

### 8.6 The promotion phase (build completion)

The loop **never touches `main`**. When it finishes its assigned backlog/story-group it stops
at a green integration branch; getting integration→`main` is a **separate, explicitly-gated
phase** run via `/promote` (`promotion` skill), never inside the loop. Mode is set by the
`promotion` config (§14):

- **`external`** (default) — a downstream actor (DevOps) merges integration→`main`. Pravartak
  does nothing to `main`. This is the 0.2.0 behavior, unchanged.
- **`pravartak-gated`** — for solo-operator projects with no DevOps. `/promote` opens an
  integration→`main` PR, **CI runs on the PR (the only place CI runs)**, then it **pauses for
  explicit human approval** (hard gate) and squash-merges (if `merge_style: squash`) only on
  human approval **and** green CI — confirming post-merge CI is green. Red CI at any point →
  HALT and escalate (honest-halt); never merge.

In both modes the unattended per-story loop never merges to `main`. CI is deliberately gated
once, at promotion — not per-story — to keep the loop fast (spec §11.6, §14.12).

---

## 9. Drift management, retrospective (Phase 5)

- **`/drift-check`** — greps `discovery/` for concepts in the spec and compares to `src/`.
  Surfaces "spec says X, code does Y". You decide which is canonical; the other is updated
  (code corrections go through corrective stories, §7.5).
- **`/retrospect`** — after a sprint or at project end, reads `sprint-reports/`,
  `completed.md`, `blocked.md`, escalations, plus your free-form notes, and produces a
  structured retrospective (what went well, what didn't, **library improvements to upstream
  to Pravartak**, project patterns worth keeping). Upstream the library improvements as
  issues against the Pravartak repo.

---

## 10. Provenance and upgrades

### 10.1 Why

Versioned templates that auto-merge on upgrade require knowing which library version
generated which file and what it looked like then. Without that, upgrades either clobber
your edits or are too painful to do. The manifest is the discipline that prevents both.

### 10.2 Inline headers

Every generated file that supports comments gets a header, e.g.:

```text
<!-- pravartak: template=PRAVARTAK.md.template version=0.5.0 generated=2026-06-08T10:00:00Z -->
```

Headers are communication, not enforcement — humans may delete them. The manifest is
authoritative. JSON files (no comments) rely on the manifest alone.

### 10.3 The manifest

`.pravartak/manifest.json` (validated against `pravartak/MANIFEST_SCHEMA.json`) records,
per generated file: path, template source, generating version, timestamp, content hash at
generation, **ownership** (`project` | `library`), and **upgrade_strategy**:

| Strategy | Behavior |
| --- | --- |
| `always-replace` | Overwrite blindly (library-owned files like command pointers). |
| `diff-and-prompt` | Compare current vs. new template output; show diff and ask. |
| `merge-three-way` | Three-way merge between original, current, and new (advanced). |
| `preserve-on-conflict` | If edited since generation, leave it and warn; else update. |

### 10.4 Upgrade flow

```text
/pravartak-upgrade
```

Determines current version (from `pravartak/VERSION`), fetches the target, compares
manifests, hashes each current file against its `content_hash_at_generation` (unchanged →
safe re-render; changed → diff-and-prompt), renders new templates against your project's
values, builds an upgrade plan (safe-replace / diff-prompt / preserve-warn), presents it
for approval, applies, replaces `pravartak/`, updates the manifest, and commits.

Rollback: `git reset --hard` to the pre-upgrade commit. The manifest's version field tells
`/pravartak-upgrade` what's installed regardless of git state.

---

## 11. Language packs

A pack encapsulates everything language-specific: the quality gate, config templates, and
dependency/isolation setup. Each pack provides `PACK.md`, `gate.sh`, language templates,
and an isolation setup script. Every pack enforces the same universal standards (§12),
translated to the language's idioms.

- **Built-in (v0.4.0):** `python` (reference implementation), `typescript` (pnpm + turbo +
  biome + tsc + vitest).
- **Planned:** `go`, `java`, `rust`.
- **Custom:** `_custom/PACK.md` for languages without a built-in pack.
- **Multiple:** choose `multiple` in the wizard; the resulting `gate.sh` runs each pack's
  gate in sequence and fails if any fails.

See `pravartak/language-packs/python/PACK.md` for the worked example.

---

## 12. Engineering standards (universal)

These apply to every managed project regardless of language; packs translate them into
enforcement. Full text in `pravartak/standards/*.md`.

- **SOLID** — one reason to change; extend not modify; honor contracts; segregate
  interfaces; depend on abstractions.
- **GoF patterns** — apply where they genuinely fit; name them in the docstring; don't force.
- **TDD + 95% coverage** — failing test first; 95% line and branch coverage; gate enforces.
- **Every API testable** — unit + integration + contract + error-path tests.
- **Integration tests required** — real backing services (testcontainers etc.) for
  integration points; no mock-only.
- **Persistence hardening** — idempotency via UNIQUE; two-sided journals; integer minor
  units for money (no floats); UTC tz-aware timestamps; append-only where the domain needs it.
- **Async-first** — all I/O async; structured + bounded concurrency; cancellation tested.
- **Observability** — structured logs with correlation IDs; ≥1 metric per story; no silent
  failures.
- **Security baseline** — no secrets in code; inputs validated at boundaries; CVE scanning;
  parameterized SQL only.

---

## 13. Verified Claude adapter CLI flags

Per spec §14.3: use only flags verified against `claude --help`. The set below is verified
against **Claude Code 2.1.168** (the library's release-time reference). Re-verify on upgrade.

| Flag | Purpose | Notes |
| --- | --- | --- |
| `-p, --print` | Headless: print response and exit | Required for budget/output-format flags. |
| `--permission-mode <mode>` | Session permission mode | Choices: `acceptEdits`, `auto`, `bypassPermissions`, `default`, `dontAsk`, `plan`. Auto-mode uses `auto`. |
| `--effort <level>` | Effort level | `low`, `medium`, `high`, `xhigh`, `max`. |
| `--max-budget-usd <amount>` | Cap API spend | Only with `--print`. |
| `--model <model>` | Model for the session | — |
| `-r, --resume [id]` | Resume a conversation by session ID | — |
| `-c, --continue` | Continue the most recent conversation | — |
| `--session-id <uuid>` | Use a specific session ID | — |
| `--settings <file-or-json>` | Settings file or inline JSON | — |
| `--mcp-config <configs...>` | Load MCP servers from JSON | — |
| `--add-dir <dirs...>` | Allow tool access to extra dirs | — |
| `--allowedTools` / `--disallowedTools` | Allow/deny tool lists | e.g. `"Bash(git *)" Edit`. |
| `--append-system-prompt <prompt>` | Append to system prompt | — |
| `--output-format <format>` | Output format | Only with `--print`. |
| `--fallback-model <model>` | Fallback when primary overloaded | Only with `--print`. |
| `--verbose` | Verbose mode | — |
| `claude auto-mode` | Inspect the auto-mode classifier | Subcommand, not a flag. |

**Flags that do NOT exist** (commonly hallucinated — do not use): `--pre-commit`,
`--post-commit` (hooks live in `settings.json`, §14.4), `--auto` (it is
`--permission-mode auto`), `--budget` (it is `--max-budget-usd`).

---

## 14. Configuration surface (`PRAVARTAK.md`, in prose)

Configuration is plain prose in `PRAVARTAK.md` — runtimes read it as natural-language
instructions. No YAML, no schema. Common knobs:

| Setting | Default | Effect |
| --- | --- | --- |
| `interactive_runtime: claude` | `claude` | Runtime used for scaffold and attended operations unless a more specific role overrides it. |
| `autonomous_runtime: claude` | `claude` | Runtime used for Phase 4 execution. |
| `implementation_runtime: claude` | `claude` | Runtime expected to implement reviewed backlog stories. |
| `review_runtime: claude` | `claude` | Runtime expected to lead architect review and promotion. |
| `git_workflow: pr-based` | merge to integration branch | Open a PR via `gh pr create` targeting the **integration branch** instead of merging directly. In neither mode does the loop target `main`. |
| `coverage_threshold: 90` | 95 | Lower the coverage gate. |
| `gate_strictness: lenient` | strict | Allow warnings; still block on errors. |
| `sprint_cadence: weekly` | by story batch | Weekly sprint tags regardless of story count. |
| `branch_pattern: …` | `feature/<project>-<story-id>-<slug>` | Customize branch naming. |
| `promotion: pravartak-gated` | `external` | How integration→`main` happens (a phase distinct from the loop, §8.6). `external`: a downstream actor merges. `pravartak-gated`: `/promote` opens a PR, runs CI, pauses for human approval, squash-merges only on approval + green CI. Neither lets the loop touch `main`. |
| `merge_style: squash` | `merge` | Squash-merge the promotion PR. |
| `tracker_sync: on` | `off` | `jira`/`linear` only: transition the tracker issue to done when a story completes (project's own tracker; opt-in authorizes it). `tracker_done_state: <state>` overrides the target. |

---

### 14.1 Migration notes for existing Claude-first projects

- `.claude/*` remains in this release as the Claude adapter compatibility layer.
- `CLAUDE.md` remains generated, but it now wraps the canonical `PRAVARTAK.md` guide.
- Existing projects do **not** need a big-bang rename to adopt Codex. Upgrade, add
  `PRAVARTAK.md` and the runtime docs, and keep using `.claude/commands/` where helpful.

## 15. Lessons learned (encoded gotchas)

These were discovered the hard way on CashApp2 and are baked into Pravartak's procedures.
When something breaks, check here first.

1. **Shared Python environments.** Never install into a shared/pyenv interpreter — the
   Python pack always creates a project-local `.venv/` and points the gate at `.venv/bin/*`
   by **absolute path** (no activation needed).
2. **pytest exit code 5.** No tests collected = exit 5. The gate treats exit 5 as success
   (with a log line) so the first commit of an empty project isn't deadlocked. Real
   failures (exit 1–4) still block.
3. **Fictional CLI flags.** Only flags in §13 are real. Re-verify on upgrade.
4. **Hooks live in `settings.json`.** Under the `"hooks"` key; events are `PreToolUse` /
   `PostToolUse` (not `PreCommit`/`PostCommit`). Pravartak generates the correct structure.
5. **`git push` without a remote.** If there's no `origin`, the loop's push fails as a gate
   failure. The scaffold either creates the remote (you supply a URL) or generates a
   local-only variant. Choose at wizard time.
6. **ruff vs. mypy versions.** They don't always support the same Python at the same time.
   The Python pack sets ruff `target-version` to the highest ruff supports while keeping
   mypy `python_version` and `requires-python` at the production target.
7. **Branch hygiene (integration-branch model).** The loop merges each story's feature
   branch into the **integration branch** on a clean gate pass and never touches `main` —
   integration→`main` is a downstream DevOps step. Feature branches are **not** auto-deleted
   after the integration merge (their traceability to the in-flight integration branch is
   useful); pruning merged feature branches and `git remote prune origin` is a periodic
   hygiene step run after integration→`main` lands (spec §14.7, §14.9).
8. **Architect review is not autonomous execution.** Review runs in a separate interactive
   session. The loop reads the backlog as-is and assumes review is done. Don't skip review.

---

## 16. Scope — what Pravartak does not solve

Not project management (it ingests from Jira/Linear/Notion, doesn't replace them). Not
CI/CD (local gates only; cloud CI is downstream). Not code review (auto-mode merges; human
review is separate, or set `git_workflow: pr-based`). Not deployment. Not multi-team /
multi-repo coordination (one repo, one Pravartak instance in v0.1).

---

## 17. Versioning

Semantic versioning of the library:

- **Major** — breaking changes needing architect intervention on upgrade (manifest schema
  changes, skill-API changes affecting command generation).
- **Minor** — new archetypes, packs, skills; safe upgrade via `/pravartak-upgrade`.
- **Patch** — bug/doc/template fixes; routine upgrade.

Versions are tagged on the library repo; each version's archive is published to a known
location. `install.sh` defaults to `latest`, accepts a version argument.

---

## 18. Quick command index

```text
/scaffold                 Set up the project (run once, interactively)
/review-all               Architect review of the whole backlog (resumable)
/review-story <ID>        Architect review of one story
/add-scope                Bring a new external system into scope
/drift-check              Detect spec/code divergence
/retrospect               Capture lessons (sprint end / project end)
/pravartak-upgrade        Migrate to a new library version
/promote                  Gated integration→main promotion (build completion)
/status                   Report current pipeline state

# Autonomous execution (Phase 4 — only after review is complete):
# Claude:
claude --permission-mode auto --effort xhigh --max-budget-usd <N> \
  -p "Read PRAVARTAK.md, docs/agent-runtimes/claude.md, and pravartak/skills/autonomous-loop/SKILL.md. Execute the autonomous workflow protocol for this repository."

# Codex:
Read PRAVARTAK.md, docs/agent-runtimes/codex.md, and pravartak/skills/autonomous-loop/SKILL.md. Act as the autonomous_runtime for this project.
```
