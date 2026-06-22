# Standard — Security Baseline

Universal (spec §13.10). Language-agnostic; the language pack's gate includes security
linting. Read by the architect during review and by the execution runtime during autonomous
work.

## The bar

- **No secrets in code.** Credentials, tokens, and keys never appear in source, tests,
  fixtures, logs, the manifest, or commits. They come from the environment or a vault. (The
  rendered `.gitignore` excludes `.env*`, `*.pem`, `*.key`.)
- **Inputs validated at boundaries.** Every external input (HTTP body, query param, message,
  file) is validated/parsed at the boundary before use. Trust nothing from outside.
- **Parameterized queries only.** All SQL uses parameterized queries / bound parameters —
  never string-concatenated SQL. (Overlaps PERSISTENCE_HARDENING.md.)
- **Dependencies scanned for known CVEs.** Project dependencies are scanned; a known-vulnerable
  dependency is a blocker until updated or explicitly risk-accepted by the architect.
- **Never log secrets or PII.** Observability (OBSERVABILITY.md) must not leak sensitive data
  into logs/metrics.

## Applied in review

The architect checks that stories handling credentials read them from env/vault, that
boundary inputs are validated, and that any data store uses parameterized access. Stories
introducing new dependencies are checked for CVE exposure.

## Applied in autonomous execution

The loop reads secrets from the environment (never hard-codes them), validates inputs at
boundaries with tested error paths (see TESTABILITY.md), uses parameterized queries, and does
not log sensitive values. A security-lint finding is a gate failure to be fixed, not waived.

## Enforcement

The language pack's gate runs a security linter (e.g. the Python pack's ruff `S`/bandit rule
group, with the optional `bandit` tool) and the dependency posture is reviewed. Secret-in-code
is caught by lint + the `.gitignore` baseline + review. Related: PERSISTENCE_HARDENING.md
(parameterized queries), OBSERVABILITY.md (don't log secrets).
