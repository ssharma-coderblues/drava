# Standard — SOLID

Universal (spec §13.1). Language-agnostic; the language packs translate these into linting
and structure conventions. Read by the architect during review and by the execution runtime
during autonomous work.

## The bar

All production code applies the five SOLID principles:

- **Single Responsibility** — a class/module has one reason to change. If you describe it
  with "and", split it.
- **Open/Closed** — extend behavior by adding new types, not by editing existing ones. New
  variants should not require touching a working class.
- **Liskov Substitution** — a subtype is usable anywhere its base is, honoring the base's
  contract (no strengthened preconditions, no weakened postconditions, no surprise throws).
- **Interface Segregation** — clients depend only on the methods they use. Prefer several
  small, role-specific interfaces over one fat one.
- **Dependency Inversion** — depend on abstractions, not concretes. High-level policy does
  not import low-level detail; both depend on an interface. This is what makes code testable
  (see TESTABILITY.md) — dependencies are injected, so they can be substituted in tests.

## Applied in review

The architect flags SRP violations (god classes), inheritance used where composition fits
(LSP/OCP risk), and concrete dependencies that should be inverted. SOLID risks specific to a
story are surfaced in the per-story reasoning step (spec §10.2).

## Applied in autonomous execution

When implementing a story, prefer composition over inheritance, inject dependencies at the
boundary, and keep each unit single-purpose. Dependency inversion is not optional — it is the
prerequisite for the unit tests TESTABILITY.md requires.

## Enforcement

Language packs select lint rules that discourage anti-patterns (e.g. the Python pack's ruff
`B`, `SIM`, `PL`, `A` rule groups). Linting cannot prove SOLID, so the architect review and
the design embedded in each story carry the rest. Related: GOF_PATTERNS.md (patterns that
realize these principles), TESTABILITY.md (why DI matters).
