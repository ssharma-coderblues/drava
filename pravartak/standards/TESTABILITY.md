# Standard — Testability (Every API & Every Story)

Universal (spec §13.4, §13.5, §13.6). Language-agnostic. Read by the architect during review
and by the execution runtime during autonomous work.

## The bar

**Every public API surface is testable and tested.** For every HTTP endpoint, library
function, or service class, provide:

- a **unit test** (dependencies mocked/substituted — enabled by Dependency Inversion, see
  SOLID.md),
- an **integration test** against **real backing services** (testcontainers or equivalent
  ephemeral resource) for any external integration point — **no mock-only stories for
  integration points** (spec §13.6),
- a **contract test** (schema/shape validation of inputs and outputs),
- **error-path tests** (failure modes, not just the happy path).

**Every story is testable.** A story is not complete unless its implementation includes the
tests that prove its acceptance criteria. Every commit that modifies production code adds or
modifies tests.

## Applied in review

The architect validates, per story, that acceptance criteria are phrased testably and that
the story names the test classes it will need (this is part of the §10.2 reasoning step). A
story touching an external integration must call for integration tests, not mocks.

## Applied in autonomous execution

The loop writes all required test classes for the story (unit, integration, contract,
error-path) as part of red-green-refactor (see TDD_AND_COVERAGE.md). Integration points get
real backing services; if the environment cannot provide one (no container runtime, no
credentials), that is a blocker/escalation — not a license to fall back to mocks and call it
done (honest completion, spec §14.10).

## Enforcement

The language pack supplies the integration-test tooling (e.g. the Python pack ships
`testcontainers`) and the coverage gate (TDD_AND_COVERAGE.md) which fails if tests are thin.
Contract and error-path coverage are upheld by the coverage threshold plus review.

Related: SOLID.md (DI makes unit testing possible), TDD_AND_COVERAGE.md (the threshold),
PERSISTENCE_HARDENING.md / SECURITY_BASELINE.md (domain-specific tests these require).
