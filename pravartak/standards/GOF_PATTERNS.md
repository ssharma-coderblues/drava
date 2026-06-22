# Standard — Gang of Four Patterns

Universal (spec §13.2). Language-agnostic. Read by the architect during review and by the
execution runtime during autonomous work.

## The bar

Apply Gang of Four design patterns **where they genuinely fit** — and not where they don't.
A forced pattern is worse than none: it adds indirection without buying anything.

- When a pattern is applied, **name it** in the class/module docstring or header comment
  (e.g. "Strategy: pluggable settlement algorithms"). Naming makes intent reviewable and
  helps the next reader.
- Reach for a pattern to solve a real problem (varying behavior, decoupling construction,
  isolating an external system), not to decorate code.

## Patterns most common in Pravartak-managed projects

| Pattern | Use when |
| --- | --- |
| **Strategy** | A behavior varies and is selected at runtime (favors Open/Closed). |
| **Factory** | Construction logic is non-trivial or should be decoupled from use. |
| **Repository** | Persistence is abstracted behind a collection-like interface. |
| **Adapter** | An external system's interface must be bent to fit ours (anti-corruption). |
| **Command** | An action is reified for queuing, logging, undo, or retry. |
| **Chain of Responsibility** | A request flows through ordered, optional handlers. |
| **Observer** | State changes must notify decoupled subscribers. |

## Applied in review

In the per-story reasoning step (spec §10.2), the active review runtime names which patterns
fit and which would be forcing it. The architect validates that choice — over-patterning is a
review smell just as much as under-structuring.

## Applied in autonomous execution

Use a pattern only when the story's design calls for it; document it by name where used.
Patterns realize SOLID (see SOLID.md) — e.g. Strategy/Factory serve Open/Closed, Adapter and
Repository serve Dependency Inversion. Do not introduce a pattern a story does not need.

## Enforcement

Not lint-enforceable — this is a design standard upheld by review and by honest docstrings.
Related: SOLID.md.
