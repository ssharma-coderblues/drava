---
description: Report the current Pravartak pipeline state from the project's state files
argument-hint: ""
skill: ""
---

Report the project's current Pravartak pipeline state. This is a self-contained command (no
skill); read the state files below and print a concise report. Do not modify anything.

Read whichever of these exist and summarize:

- `.pravartak/manifest.json` — Pravartak version, archetype, language pack, scaffold date.
- `.claude/backlog.md` — total stories, completed (`[x]`) vs remaining (`[ ]`).
- `.claude/architect_review/progress.md` — review progress: PENDING / REVIEWED / SKIPPED counts.
- `.claude/architect_review/session.md` — whether a review session is paused mid-flight.
- `.claude/architect_review/scope_additions.md` — draft/corrective stories awaiting promotion.
- `.claude/current_story.md` — the story auto-mode is currently on (if any).
- `.claude/completed.md` — count of completed stories.
- `.claude/blocked.md` — blocked stories and reasons.
- `.claude/escalations.md` — any unresolved escalation halting auto-mode.
- `docs/sprint-reports/` — sprints completed.

Then print a report shaped like:

```text
PRAVARTAK_STATUS
  Project: <name>   Pravartak: <version>   Archetype: <archetype>   Lang: <pack>

  Phase: <Ingestion | Architect Review | Autonomous Execution | Drift Mgmt>
  Backlog: <completed>/<total> stories done
  Review:  <reviewed>/<total> (<skipped> skipped, <pending> pending)<, session paused on X>
  Pending promotion: <N scope/corrective stories>
  Auto-mode: <idle | on STORY-ID | HALTED: escalation>
  Blocked:   <N> (<reasons>)
  Sprints:   <N> complete

  Suggested next step: <derived from the above>
```

Derive "Suggested next step" from state: if review is incomplete → `/review-all`; if review
done but scope additions await promotion → promote then launch auto-mode; if an escalation
is unresolved → resolve it; if all stories done → `/retrospect`. If the project is not yet
scaffolded (no `.pravartak/manifest.json`), say so and suggest `/scaffold`.
