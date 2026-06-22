# Standard — Async-First

Universal (spec §13.8). Language-agnostic; the language pack lints synchronous I/O out of
production paths. Read by the architect during review and by the execution runtime during
autonomous work.

## The bar

- **All I/O is async.** No synchronous blocking calls (network, disk, DB, sleep) in
  production code paths. Blocking work that cannot be made async is offloaded explicitly
  (thread/process pool), never run inline on the async path.
- **Concurrency is structured.** Use structured concurrency (e.g. a TaskGroup/nursery or the
  language's equivalent) so child tasks have a clear lifetime and errors propagate — no
  orphaned fire-and-forget tasks.
- **Concurrency is bounded.** External calls run under a semaphore or pool with an explicit
  limit; unbounded fan-out against a downstream is forbidden.
- **Cancellation is handled and tested.** Tasks respond to cancellation, clean up resources,
  and do not swallow cancellation signals. A cancellation test is part of the story (see
  TDD_AND_COVERAGE.md).

## Applied in review

The architect flags any story whose design implies synchronous I/O on a hot path, unbounded
concurrency against an external system, or fire-and-forget tasks without a parent scope.

## Applied in autonomous execution

The loop implements I/O asynchronously, wraps concurrent work in a structured scope, bounds
external calls, and writes the cancellation test. If a required library is sync-only, the
loop offloads it explicitly rather than blocking the event loop.

## Enforcement

The language pack's linter rejects synchronous I/O in production paths (e.g. the Python
pack's ruff `ASYNC` rule group, with `pytest-asyncio` in `asyncio_mode = "auto"` so async
tests run). Cancellation behavior is proven by tests, not lint. Related: OBSERVABILITY.md
(structured concurrency still emits correlation IDs), TESTABILITY.md.
