# Standard — Test-Driven Development & Coverage

Universal (spec §13.3). Language-agnostic; the language pack's gate enforces the threshold.
Read by the architect during review and — critically — by the execution runtime during
autonomous work (the per-story loop cites this file directly, autonomous-loop SKILL.md §6.2).

## The bar

**Test-first, always.** For each acceptance criterion:

1. **Red** — write a test that asserts the criterion and fails for the right reason.
2. **Green** — implement the minimum to make it pass.
3. **Refactor** — clean up with the tests green.

Repeat until every acceptance criterion is covered. Production code is never written before
the test that justifies it.

**Coverage:** maintain **95% line coverage AND 95% branch coverage** on production code
(the default `coverage_threshold`; a project may lower it in `PRAVARTAK.md`, spec §18). Branch
coverage matters as much as line coverage — a line can be covered while a branch through it
is not.

## Applied in review

The architect confirms each story's acceptance criteria are phrased so a test can prove them
(see TESTABILITY.md). Criteria that cannot be tested are sent back for refinement before the
loop touches them.

## Applied in autonomous execution

The loop implements strictly red-green-refactor and does not mark a story complete unless the
full gate — including the coverage threshold — passes. Honest completion (autonomous-loop
SKILL.md §1, spec §14.10): a story that cannot reach the coverage bar is escalated, never
faked. Stub code cannot pass a real coverage gate, which is exactly why the gate is the
backstop against forced completion.

## Enforcement

The language pack configures the test runner to fail under the threshold (e.g. the Python
pack's `[tool.coverage.report] fail_under = {{COVERAGE_THRESHOLD}}` with `--cov-branch`). The
gate runs unit + integration + contract + error-path tests (see TESTABILITY.md). Note the
empty-project exception: "no tests collected" is treated as pass so the first commit is not
deadlocked (spec §14.2) — that exception applies only to a project with no production code
yet, never to a story that added code.

Related: TESTABILITY.md, ASYNC_FIRST.md (cancellation must be tested),
PERSISTENCE_HARDENING.md (invariants proven by tests).
