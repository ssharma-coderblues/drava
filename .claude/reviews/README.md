<!-- pravartak: template=reviews-README.md.template version=0.5.0 generated=2026-06-22T22:45:10Z -->
# drava — Story Review Records

One file per story (`<STORY-ID>.md`), written by the `architect-review` skill when a story
is reviewed. Each record captures the decision (approve / skip / amend), the rationale, and
any change-impact summary — the durable, per-story audit trail of architect review.

Detailed findings (when a review produces more than a decision) live alongside in
`.claude/architect_review/findings/<STORY-ID>.md`.

This directory is empty until `/review-all` (or `/review-story`) runs.
