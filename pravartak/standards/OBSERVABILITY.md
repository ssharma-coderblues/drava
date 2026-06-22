# Standard — Observability

Universal (spec §13.9). Language-agnostic. Read by the architect during review and by the
execution runtime during autonomous work.

## The bar

- **Structured logs with correlation IDs.** Production code emits structured (key/value or
  JSON) logs, and every request/operation carries a correlation ID that threads through all
  logs for that unit of work — including across async boundaries (see ASYNC_FIRST.md).
- **At least one metric per story.** Every story emits at least one Prometheus metric (or the
  project's equivalent metrics stack) — a counter, gauge, or histogram capturing the
  behavior the story adds.
- **No silent failures.** Errors are logged with context and surfaced (metric, raised error,
  or alert signal). Swallowing an exception without a log/metric is forbidden — a failure
  that leaves no trace is a defect.

## Applied in review

The architect checks that a story's acceptance criteria name the log events and the metric it
will emit, and that error paths are observable (not silently caught).

## Applied in autonomous execution

The loop adds structured logging with the correlation ID, emits the story's metric, and
ensures every caught error is logged/measured before being handled. Observability code is
covered by the story's tests where practical (e.g. asserting a metric increments on the error
path — see TESTABILITY.md).

## Enforcement

Mostly upheld by review and by the error-path tests (TESTABILITY.md); some packs lint for
bare excepts / swallowed errors. The "≥1 metric per story" and "correlation ID present" bars
are review checks. Related: ASYNC_FIRST.md, SECURITY_BASELINE.md (never log secrets — see
that file).
