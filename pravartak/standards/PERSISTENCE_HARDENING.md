# Standard — Persistence Hardening

Universal (spec §13.7). Language-agnostic. Read by the architect during review and by the
execution runtime during autonomous work. Applies to any story that touches durable storage.

## The bar

Stories touching persistence enforce, and **test**, the following:

- **Idempotency keys via UNIQUE constraints.** Operations that can be retried carry an
  idempotency key backed by a database UNIQUE constraint. Tested with a duplicate-insert
  scenario that proves the second attempt is a no-op (or returns the original result), not a
  double-effect.
- **Two-sided journal entries (where applicable).** In ledger/accounting domains, postings
  are balanced — never a half-posting. Tested by asserting debits == credits for every
  transaction.
- **Integer minor units for money. No floats anywhere in the money path.** Store and compute
  money as integer minor units (cents, etc.); floats are forbidden end to end. Tested by
  type/representation assertions and round-trip checks.
- **Timezone-aware timestamps stored in UTC. No naive datetimes.** All persisted timestamps
  are tz-aware and normalized to UTC. Tested by rejecting naive datetimes at the boundary.
- **Append-only semantics where the domain requires it.** Where records must not mutate,
  enforce it (DB constraints/triggers or write-path guards) and test it by **attempting a
  forbidden mutation and asserting it fails**.

## Applied in review

The architect checks that any persistence-touching story names which of these invariants
apply and includes them in its acceptance criteria. Money-handling stories without an
integer-minor-units criterion are sent back.

## Applied in autonomous execution

The loop implements each applicable invariant with a test that proves it (duplicate-insert,
balanced-postings, no-float, no-naive-datetime, forbidden-mutation). These are integration
tests against a real database (see TESTABILITY.md), not mocks.

## Enforcement

Partly lint-able (some packs flag float-in-money or naive-datetime patterns), but mostly
proven by the required tests and confirmed in review. Related: TESTABILITY.md (real-DB
integration tests), SECURITY_BASELINE.md (parameterized queries).
