---
name: promotion
description: >
  The promotion phase — promote the integration branch to main, as a separate, explicitly
  gated step DISTINCT from the autonomous per-story loop. Two modes (PRAVARTAK.md
  `promotion`):
  `external` (a downstream actor/DevOps merges integration→main; Pravartak does nothing) and
  `pravartak-gated` (Pravartak opens an integration→main PR, waits for CI, PAUSES for explicit
  human approval, and only then squash-merges — halting on red CI). Backs /promote. Invoked at
  build completion or manually, NEVER inside the per-story loop. The unattended loop never
  touches main in either mode.
---

# Skill: promotion

## 1. Purpose

The autonomous per-story loop (`autonomous-loop`) merges each passing story to the repo's
**integration branch** and **never touches `main`**. Getting integration → `main` is a
separate concern. This skill is that concern: the **promotion phase**, run at build completion
(when the loop has finished its assigned backlog / story-group) or manually — and **only** when
explicitly invoked. It is never part of the unattended loop.

**Principle (spec §11.6, §14.12).** The autonomous per-story loop never touches `main`.
Promotion to `main` is always a separate, explicitly-gated phase — either `external` (a
downstream actor) or `pravartak-gated` (human review + CI-green enforced by Pravartak). In
neither mode does the unattended per-story loop merge to `main`. This skill, invoked
deliberately, is the *only* place Pravartak itself ever merges to `main`, and it does so behind
a hard human gate and a green-CI gate.

## 2. When to invoke

- **`/promote`** — at build completion, or manually when the architect decides the integration
  branch is ready for `main`. `$ARGUMENTS` may name the integration branch / target if not the
  defaults.
- It is **not** invoked by the per-story loop and **not** run under unattended auto-mode as part
  of story execution. Promotion is a deliberate, attended step.

Precondition: the project is scaffolded and has an integration branch with completed,
gate-passing work to promote. If the integration branch is not green, stop and say so.

## 3. Configuration (read from `PRAVARTAK.md`, in prose)

| Knob | Default | Effect |
| --- | --- | --- |
| `promotion` | `external` | `external`: a downstream actor (DevOps) merges integration→`main`; this skill does nothing but report that. `pravartak-gated`: Pravartak runs the gated promotion flow (§5). |
| `merge_style` | `merge` | `squash`: squash-merge the integration→`main` PR. `merge`: standard merge commit. |
| `integration_branch` | `integration` | The branch promoted from (same knob the loop uses). |

The promotion target is `main` (the default branch).

## 4. `external` mode (the 0.2.0 default)

If `promotion: external`, this skill performs **no** git actions. It reports the current
integration-branch state (ahead-of-`main` commit count, gate status) and reminds the architect
that integration→`main` is owned by a downstream actor (DevOps, typically after a production
deploy). Nothing is merged, no PR is opened. This preserves the 0.2.0 behavior exactly.

## 5. `pravartak-gated` mode (the flow)

Run this flow only when `promotion: pravartak-gated`. It is the **only** place CI runs for the
project — the per-story loop runs local gates, not CI; CI is gated here, at promotion, by the
project's choice.

### 5.0 Repo-ownership pre-check

Promotion merges to `main` — the most outward, hard-to-reverse action in the pipeline. Confirm
the repo is one the session **owns a real working checkout of** (not a shallow/analysis clone,
not another team's repo — same check as autonomous-loop SKILL.md §6.0). If not, **halt and
escalate**; promotion of a repo you do not own is human-driven work in a proper checkout.

### 5.1 Preconditions

- The integration branch's assigned work is **complete** (build complete / story-group done).
- The integration branch is **green** on the local gate. If not, halt — do not promote unbuilt
  or failing work (honest-halt).
- The working tree is clean and the integration branch is pushed.

### 5.2 Open the integration→main PR

Open a PR from the integration branch targeting `main`:

```bash
gh pr create --base main --head <integration_branch> \
  --title "Promote <integration_branch> → main" \
  --body "<summary of the completed build: stories, sprint tags, notable decisions>"
```

If `merge_style: squash`, the eventual merge will squash (§5.5). Record the PR URL in
`.claude/promotion.md`.

### 5.3 CI runs on the PR (the only place CI runs)

Wait for the PR's CI checks to complete (e.g. `gh pr checks <pr> --watch`). This is the single
point where CI gates the project — per the project's choice to gate CI at promotion rather than
per-story (which keeps the per-story loop fast and unattended).

- **CI green** → proceed to the human gate (§5.4).
- **CI red** → **HALT and escalate** (§6). Do not merge. Record the failing checks in
  `.claude/promotion.md` and `.claude/escalations.md`.

### 5.4 PAUSE for human review and explicit approval (hard gate)

**Stop and wait for an explicit human approval.** This is a hard gate — promotion does not
proceed on CI-green alone. Present: the PR URL, the CI result, the diff summary, the stories
included. Require an unambiguous "approve promotion" from the human. Anything short of explicit
approval (silence, "looks fine", questions) is **not** approval — do not merge. The human may
reject or defer; capture that and stop.

### 5.5 Merge to main (only on human approval AND CI-green)

Only when **both** the human has explicitly approved **and** CI is green, perform the merge:

```bash
gh pr merge <pr> --squash   # if merge_style: squash; otherwise --merge
```

Then **confirm post-merge CI on `main` is green**. If post-merge CI goes red, halt and escalate
immediately (the promotion introduced a problem) — do not start another promotion on top of a
red `main`.

### 5.6 Record and finish

Update `.claude/promotion.md` with the outcome (PR, CI runs, approver, merge commit,
post-merge CI). Optionally tag the release. The integration branch is **not** deleted (the loop
continues to build on it for the next group; feature-branch/integration hygiene is unchanged,
spec §14.7).

## 6. Stop conditions (honest-halt)

Write context to `.claude/escalations.md` and halt — never merge — on:

- CI **red** on the PR, or **red** post-merge on `main`.
- No explicit human approval (or an explicit rejection/deferral) at §5.4.
- The integration branch not green on the local gate, or work incomplete, at §5.1.
- A **repo-ownership** failure (§5.0): promoting a repo the session does not own.
- Any inability to open the PR / observe CI / merge (auth, permissions, no remote).

Halting here is a **first-class, expected outcome** (spec §14.10) — an un-promoted but honest
integration branch is always preferred over an unreviewed or CI-red merge to `main`.

## 7. Resumability

Promotion state lives in `.claude/promotion.md` (PR URL, CI status, approval, merge result).
Re-running `/promote` reads it and resumes: if a PR is open and CI is pending, it resumes
waiting; if CI is green and awaiting approval, it re-presents the gate; if already merged, it
reports done. It never re-opens a PR for an already-merged promotion.

## 8. Guardrails

- **The per-story loop never touches `main`** — in either promotion mode. Promotion is a
  separate, explicitly-invoked phase; this skill is the only place Pravartak merges to `main`.
- **Both gates are mandatory in `pravartak-gated`** — human approval AND CI-green. Neither alone
  authorizes the merge.
- **Honest-halt on red CI** — never merge red, never report a promotion that did not happen.
- **`external` mode does nothing** — it preserves the 0.2.0 downstream-actor behavior; it must
  not open PRs or merge.
- **Own the repo** — never promote a repo without a real working checkout (spec §14.11).
- **Never invoked by the unattended loop** — promotion is attended by design.

## 9. Outputs

- `external` mode: a status report; no git changes.
- `pravartak-gated` mode: an integration→`main` PR; a CI result; on human approval + CI-green, a
  (squash-)merge to `main` with confirmed green post-merge CI; `.claude/promotion.md` recording
  the outcome. Or an honest HALTED escalation if any gate was not satisfied.
