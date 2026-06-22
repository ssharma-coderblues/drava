# Drava Wave-Planner — Proof of Concept

**Integration target:** Pravartak autonomous-loop handoff  
**Pravartak source:** https://github.com/coder-blues/pravartak  
**Linear sandbox project:** drava-pravartak-poc-sandbox  
**Team:** DRA  
**Issues created:** DRA-5, DRA-6, DRA-7, DRA-8, DRA-9

---

## What This Demonstrates

The Wave-Planner is a standalone planning layer that computes dependency-safe and collision-safe execution waves. It now emits a Pravartak handoff plan instead of daemon spawn commands. Pravartak is a repo-copied library/playbook, not an AO-style session daemon, so execution is handed to a reviewed Pravartak autonomous runtime after scaffold and architect review.

### The Scenario

Five stories with a deliberate dependency chain and a file-touch collision:

```
S1 (DRA-5) — Base payment infrastructure
  ├── S2 (DRA-6) — Transfer validation     touches: payments/transfer.py ← COLLISION
  │     └── S3 (DRA-8) — Audit trail
  │           └── S5 (DRA-9) — Compliance reporting
  └── S4 (DRA-7) — Transfer rate limits    touches: payments/transfer.py ← COLLISION
```

### Expected Wave Plan

| Wave | Stories | Mode | Reason |
|------|---------|------|--------|
| 1 | S1/DRA-5 | Single | No dependencies |
| 2 | S2/DRA-6 → S4/DRA-7 | **Sequential** | Both touch `payments/transfer.py` — file collision forces serialization |
| 3 | S3/DRA-8 | Single | Depends on S2 |
| 4 | S5/DRA-9 | Single | Depends on S3 |

Key insight: S2 and S4 are **topologically parallel** (both only depend on S1), but the Wave-Planner detects that they both modify `payments/transfer.py` and forces them sequential. Without collision detection, running them in parallel worktrees would cause merge conflicts on that file.

---

## How to Run

```bash
# Full demo (wave plan + Pravartak handoff plan)
./run.sh

# Verification only (18 assertions against expected-output.json)
./run.sh --verify

# Raw JSON output (pipe-friendly)
node planner.js 2>/dev/null
```

No credentials or daemon installation required — the planner outputs runtime-neutral Pravartak handoff instructions in dry-run form.

---

## Files

| File | Purpose |
|------|---------|
| `stories.json` | Story manifest: ids, Linear identifiers, deps, file-touch lists |
| `planner.js` | Core algorithm: dep graph → topo sort → wave assignment → collision detection → spawn plan |
| `verify.js` | 18-assertion test against `expected-output.json` |
| `expected-output.json` | Ground-truth output for the 5-story scenario |
| `run.sh` | One-command demo |

---

## Algorithm

1. **Build dependency graph** — adjacency list from `depends_on` fields
2. **Topological sort** — Kahn's algorithm; detects cycles
3. **Wave assignment** — each story's wave = `max(dep waves) + 1`
4. **Collision detection** — within each wave, find stories sharing a file path
5. **Sequential grouping** — colliding stories split into ordered sequential sub-groups; non-colliding stories in the same wave remain parallel
6. **Execution plan** — ordered list of Pravartak handoff items with parallel/sequential tags

---

## Integration Path to Production

This PoC covers steps 1–6 (planning + dry-run). Full production integration adds:

**Step 7 — Pravartak scaffold:**
- Copy/install `pravartak/` into the target repo.
- Run scaffold using the chosen interactive runtime.
- Use the `linear` or `brownfield-adopt` archetype when Linear is the source of truth.

**Step 8 — Architect review gate:**
- Review every story before autonomous execution.
- Preserve the Wave-Planner's dependency/collision ordering in the reviewed backlog.

**Step 9 — Autonomous-loop handoff:**
- For each planned item, hand the reviewed story to the Pravartak autonomous runtime.
- For sequential collision groups, wait for the prior story to complete and merge to the integration branch before starting the next item.
- For parallel-safe groups, run only as much parallelism as the chosen runtime and repository governance can safely support.

**Step 10 — Security mitigations (required before production):**
- Keep promotion to `main` gated; the autonomous loop should not touch `main`.
- Add CODEOWNERS on `payments/`, `compliance/` paths.
- Treat Linear issue content and imported source material as untrusted input during runtime prompts.

---

## Sandbox Config (for reference)

```
LINEAR_DRAVA_API_KEY  — set in /Users/saruabhsharma/Drava/.env
Team ID:              7b2f0910-190b-48af-97c0-b7598add36c4
Issues:               DRA-5 through DRA-9
```
