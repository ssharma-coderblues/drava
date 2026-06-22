# Ingestion — Brownfield Adoption

Archetype: `brownfield-adopt`. High complexity (spec §4.7, added in 0.5.0). The project is
**already partway built** — it has shipped code, design documents written before Pravartak,
and (often) a tracker backlog with some issues already Done. This procedure adopts such a
project mid-flight: it imports the existing specs as authoritative `discovery/`, partitions
all work into DONE / REMAINING / AMBIGUOUS, decomposes **only the remaining work** into a
draft backlog, and pre-populates `completed.md` with what already shipped — so the autonomous
loop never re-builds finished work.

This is distinct from `reverse-engineer-code` (§4.2), which assumes **no** formal spec and
synthesizes one from code. Brownfield adoption assumes the specs **exist and are
authoritative**; the work is reconciling three sources of truth (shipped code, existing specs,
tracker backlog) and carving out what's left to build — not re-deriving the design.

Executed by `pravartak/scaffold/SCAFFOLD.md` Phase 3, given the Q4 source location (the
existing project's own repo root, plus the locations of its design docs, plus — optionally —
a tracker filter when overlaying `linear`/`jira`).

## When to choose this archetype

Pick `brownfield-adopt` when **two or more** of these hold:

- The repo already has substantial source with passing tests.
- Design docs (HLD, LLD, seams documents, ADRs) exist, authored before Pravartak.
- A tracker (Linear/Jira) already has issues, some marked Done.
- An existing `PRAVARTAK.md`, `CLAUDE.md`, or equivalent governance file is present.
- The team is switching to Pravartak from another methodology mid-project.

If the project has code but **no** spec, use `reverse-engineer-code`. If it has specs but **no**
code, use `greenfield-markdown` (or `linear`/`jira`/`confluence` per where the spec lives).

## Inputs

- **Source location** (Q4): the existing project repo root (a real, full working checkout —
  the scaffold runs inside it), plus the in-repo paths to the authoritative design docs
  (e.g. `docs/HLD.md`, `docs/seams/`, `docs/adr/`).
- **Tracker overlay** (optional): if the project's backlog lives in Linear/Jira and the
  architect wants tracker correlation, supply the tracker filter as in the `linear`/`jira`
  archetypes; this procedure then also follows that archetype's `connector.md` for the
  import and (opt-in) write-back. Without a tracker overlay, the backlog partition is derived
  from code + specs alone.

## Outputs

- A populated `discovery/` that **adopts the existing design docs in place** (not
  re-synthesized) plus three analysis files: `INVENTORY.md`, `ADOPTION_DRIFT.md`,
  `ADOPTION_AMBIGUITIES.md`.
- `discovery/README.md` — the source inventory, including the DONE / REMAINING / AMBIGUOUS
  partition and (with a tracker overlay) the backlog ↔ tracker correlation table.
- A draft `.claude/backlog.md` containing **only REMAINING work** as PENDING stories, with the
  first sprint reserved for adoption cleanup.
- A pre-populated `.claude/completed.md` recording the DONE work so the loop never re-executes
  it.

## Procedure

### 1. Inventory what exists

Before reading specs, take inventory. Produce `discovery/INVENTORY.md`:

- **Code:** the package/module layout (e.g. for a pnpm monorepo, every `packages/*` and
  `apps/*`), with a one-line description of each.
- **Tests + current pass state:** run the project's existing test command; record the count
  and whether it passes today.
- **Coverage baseline (critical):** run the project's coverage command and record the current
  percentage. **This number calibrates the coverage gate** — see step 6 and the language
  pack's delta-coverage behavior. If coverage can't be measured yet, record that.
- **Existing governance docs:** every HLD/LLD/seams/ADR/PRAVARTAK.md/CLAUDE.md/README/PLAYBOOK
  path.
- **Tracker state (if overlaying):** every issue with its identifier and workflow state.

The inventory is read-only — it observes, it does not change the project.

### 2. Adopt existing design docs into `discovery/` (do NOT re-synthesize)

The existing design docs are **already** the authoritative spec. Unlike
`reverse-engineer-code`, this archetype does not derive a spec from code — it adopts the docs
that exist:

- **Reference them in place** by recording their in-repo paths in `discovery/README.md`, OR
  copy normalized snapshots into `discovery/` if the project prefers a frozen snapshot. Record
  which approach was used. (In-place reference is preferred for a brownfield repo that will
  keep editing its docs; snapshot is for projects that want `discovery/` frozen at adoption.)
- **Do not rewrite, re-derive, summarize, or "improve" them.** They are the spec. Architect
  review (Phase 3, `/review-all`) is where they get scrutinized — ingestion does not edit
  intent. This is the brownfield analogue of greenfield-markdown's "content preserved
  faithfully" rule.
- Existing ADRs remain authoritative; existing seams documents remain the contract reference.
  Record their locations prominently — Wave/sprint stories will read them.

### 3. Reconcile code against specs — the drift snapshot

Run a one-time, read-only reconciliation (a lighter, point-in-time version of the
`drift-detection` skill). For each major component the specs describe, confirm it exists in
code and classify. Produce `discovery/ADOPTION_DRIFT.md`:

- **Spec says X, code has X** — aligned; no action.
- **Spec says X, code has Y** — drift; record both. The architect decides which is canonical
  during review (the other becomes a corrective story).
- **Spec says X, code missing X** — either unbuilt (→ a REMAINING story, step 4) or descoped
  (architect decides).
- **Code has Z, no spec for Z** — undocumented build; architect decides whether to spec it
  retroactively.

This is **not** a full reverse-engineering synthesis. It trusts the existing specs and only
flags where code diverged. Resolution is the architect's, in review — not ingestion's.

### 4. Partition into DONE / REMAINING / AMBIGUOUS

Cross-reference code, specs, and (if overlaying) the tracker. Partition all work:

- **DONE** — built, tested, merged, and (if tracked) marked Done. These go to
  `.claude/completed.md`, **never** to `backlog.md`. Recorded for history; never re-executed.
- **REMAINING** — designed but not yet built. These become PENDING stories in `backlog.md`
  (step 5).
- **AMBIGUOUS** — the three sources disagree (tracker Done but code absent; code present but
  tracker Backlog; spec describes something neither code nor tracker reflects). These go to
  `discovery/ADOPTION_AMBIGUITIES.md` and **must be resolved by the architect before
  `/review-all`** — a hard gate, exactly as `loose-docs` requires `CONTRADICTIONS.md`
  resolution before review.

**Cardinal rule:** never put DONE work in `backlog.md` as a PENDING story — the loop would
try to rebuild it. DONE work is recorded in `completed.md` only.

### 5. Decompose only the REMAINING work into a draft backlog

Apply the standard decomposition (as in greenfield-markdown step 4) but **only to the
REMAINING set.** Story id scheme, block format, and `backlog.md.template` conformance are
identical to the other archetypes. Brownfield specifics:

- **Dependencies may point at DONE work.** Record them (e.g. "depends on STORY-002, which is
  DONE"); since already satisfied, they are not blockers. This is how the loop knows a
  REMAINING story's prerequisites are met.
- **With a tracker overlay**, preserve the tracker identifier in the story title and source
  pointer exactly as the `linear`/`jira` archetypes do, and record the correlation table.
- **Front-load adoption cleanup as the first sprint** (step 7).

### 6. Calibrate the coverage gate to brownfield reality

The standard 95%-coverage gate (§13.3) assumes greenfield, where every line was written
test-first. Brownfield code predates the gate and may sit below threshold; enforcing
whole-repo absolute 95% from story one would deadlock on pre-existing code.

Record in `PRAVARTAK.md` (architect overrides) and rely on the language pack's
**delta-coverage** behavior: new and changed code must meet the threshold; pre-existing
untouched code is grandfathered at the `INVENTORY.md` baseline. (The TypeScript pack
implements this via `delta-coverage.mjs`; the Python pack project can request the
equivalent.) A separate optional "coverage remediation" sprint may be added if the architect
wants legacy code brought up over time — but it is not a precondition for the loop to run.

### 7. Front-load adoption cleanup as Sprint 1

Brownfield adoption usually carries tooling/tech-debt cleanup that should land before feature
work resumes under the new model. Make these the first sprint of REMAINING stories. Typical
adoption-cleanup stories:

- **Secrets/tooling migrations** the project decided on at adoption (e.g. moving from a vault
  indirection to a literal gitignored `.env` with a compensating secret-scan in the gate).
- **Removing old-methodology machinery** no longer used under Pravartak (e.g. bespoke tracking
  scripts, branch-orchestration helpers superseded by the autonomous loop).
- **Container-runtime / environment alignment** the project standardized on.
- **CI workflow** — note: if the project will use `promotion: pravartak-gated` (spec §11.6),
  CI is a **precondition** for promotion (CI runs at the promotion gate). Sequence the CI
  story early so the first promotion has CI to gate on.
- **Wiring real lint/typecheck/test tasks** if the existing ones are no-ops — a real brownfield
  trap (the gate's no-op guard will otherwise fail every commit, correctly).

Front-loading stabilizes the foundation before new features build on it.

### 8. Write `discovery/README.md`

```markdown
# Discovery — Source Inventory

Archetype: brownfield-adopt
Ingested: <SCAFFOLD_DATE>
Source: <repo root>; design docs at <paths>; tracker overlay: <linear team/filter | none>

## Adopted design docs (authoritative — referenced in place, not re-synthesized)
| Discovery reference | In-repo path | Governs |
| --- | --- | --- |
| HLD | docs/HLD.md | High-level design |
| Seams | docs/seams/ | Interface contracts |
| ADRs 0001-00NN | docs/adr/ | Architectural decisions |

## Work partition
- DONE (in completed.md, never re-executed): <count> — <id list or tracker-id list>
- REMAINING (in backlog.md as PENDING): <count>
- AMBIGUOUS (must resolve before /review-all): <count> — see ADOPTION_AMBIGUITIES.md

## Coverage baseline (calibrates the gate — step 6)
Current: <NN>% (delta-coverage enforces threshold on CHANGED files only).

## Correlation (backlog ↔ tracker)   [only with a tracker overlay]
| STORY | Tracker id | State |
| --- | --- | --- |
| STORY-005 | GAN-005 | Backlog |

Notes: <how sources map; anything the architect should know>
```

### 9. Handoff

Report to SCAFFOLD.md: the DONE/REMAINING/AMBIGUOUS counts, the remaining-story count and
discovery-document count (for `PRAVARTAK_SCAFFOLD_COMPLETE`), the coverage baseline, and —
**emphatically** — that `discovery/ADOPTION_AMBIGUITIES.md` must be resolved by the architect
before `/review-all`. The backlog is a **draft** of remaining work only; do not review or
implement here.

## Guardrails

- **Never re-decompose shipped work into PENDING stories.** DONE → `completed.md`, never
  `backlog.md`. This is the cardinal brownfield rule — violating it makes the loop rebuild
  finished work.
- **Adopt existing specs in place; never re-synthesize or edit them.** They are authoritative.
  Architect review scrutinizes; ingestion preserves. (Contrast `reverse-engineer-code`, which
  synthesizes because no spec exists.)
- **Resolve code/spec/tracker ambiguities before review** — `ADOPTION_AMBIGUITIES.md` is a
  hard gate, like `loose-docs` contradictions.
- **Calibrate coverage to current reality** (delta coverage), or the loop deadlocks on legacy
  code.
- **Front-load adoption cleanup as Sprint 1**, and sequence the CI story early if
  `promotion: pravartak-gated` is planned.
- **Read-only inventory.** Ingestion observes the project; it does not modify code, specs, or
  the tracker.
- **Draft only · no invented scope · traceability** — as for every archetype.
