<!-- pravartak: template=backlog.md.template version=0.5.0 generated=2026-06-22T22:45:10Z -->
# drava — Backlog

The flat list of executable stories. Populated by ingestion (a draft), validated by
architect review (`/review-all`), and executed by the autonomous loop. The loop reads
`[ ]` (not done) vs `[x]` (done); do not change that convention.

**Story block format** (every story uses exactly this shape so ingestion, architect-review,
and the autonomous loop can all parse it):

```markdown
- [ ] STORY-NNN — <concise imperative title>
  - Scope: <what this story does and explicitly does not do>
  - Acceptance criteria:
    - <criterion 1, testable>
    - <criterion 2, testable>
  - Depends on: <STORY-0xx, … | none>
  - Source: discovery/<file>.md#<section>
```

(The `STORY-NNN` above is the format example, not a real story; real stories begin at
`STORY-001` under **## Stories** below.)

Story ids are stable `STORY-NNN` (never renumbered). Scope and corrective stories promoted
from `.claude/architect_review/scope_additions.md` keep their own ids
(`STORY-SCOPE-…`, `STORY-CORR-…`).

---

## Stories

<!-- Drafted by loose-docs ingestion. Architect review must validate scope, sequencing, and story boundaries before autonomous execution. -->



- [ ] STORY-001 — Establish GTM compliance and identity foundation
  - Scope: Define and implement the Phase 1 identity, onboarding, KYC, sanctions, PEP, watchlist, recipient onboarding, and multilingual onboarding foundation. Does not implement transfers or merchant collections.
  - Acceptance criteria:
    - WhatsApp number signup and companion app registration flows are represented in the domain model.
    - US sender KYC, Aadhaar recipient eKYC, document/selfie fallback, risk tiers, bank-link verification, and sanctions screening have testable acceptance paths.
    - Compliance events are auditable and observable.
  - Depends on: none
  - Source: discovery/drava-project-specification.md#module-1--identity-onboarding--kyc

- [ ] STORY-002 — Build WhatsApp-native consumer remittance flow
  - Scope: Implement the core send-money journey for WhatsApp Flows and companion app including recipient, amount, funding, confirmation, transparent fees, and transfer status. Does not implement merchant collections.
  - Acceptance criteria:
    - A sender can progress through amount, recipient, funding, FX quote, fee display, and confirmation without browser redirect assumptions.
    - FX quote and 30-minute rate-lock rules are explicit and testable.
    - Transfer status milestones are emitted for WhatsApp-first notifications.
  - Depends on: STORY-001
  - Source: discovery/drava-project-specification.md#module-2--core-transfer-engine-consumer-remittance

- [ ] STORY-003 — Implement funding and payout orchestration
  - Scope: Model non-custodial partner settlement, card funding, ACH funding, ACH risk holds, India payout routing, payment-gateway integration, and FX spread engine.
  - Acceptance criteria:
    - The platform never holds customer funds in Phase 1 flows.
    - Card, ACH, and payout partner states are idempotent and auditable.
    - ACH risk-hold and FX spread rules are configurable and covered by tests.
  - Depends on: STORY-002
  - Source: discovery/drava-project-specification.md#module-5--payments-wallet--treasury

- [ ] STORY-004 — Add light SMB merchant collections
  - Scope: Implement payment links, static/dynamic QR collection, merchant notifications, receipts, transaction history, merchant payout, and GST-compliant tax invoicing for GTM.
  - Acceptance criteria:
    - Merchants can generate payment links and QR collections with compliant receipts.
    - GST invoice numbering and tax breakdown rules are testable.
    - Merchant history and payout states reconcile with transaction records.
  - Depends on: STORY-003
  - Source: discovery/drava-project-specification.md#module-3--smb--merchant-collections

- [ ] STORY-005 — Build AI customer service and dispute pipeline
  - Scope: Implement autonomous customer-service bot, intent routing, escalation, dispute intake/classification, evidence assembly, draft resolution, human approval gate, and sentiment/fraud signals.
  - Acceptance criteria:
    - Routine support intents can be resolved without human intervention.
    - Sensitive or complex intents escalate with full context.
    - Dispute resolutions require human approval at GTM.
  - Depends on: STORY-002
  - Source: discovery/drava-project-specification.md#module-4--ai-engine-customer-service--disputes

- [ ] STORY-006 — Create regulated operations admin console
  - Scope: Implement the GTM web admin capabilities for operations dashboards, transaction monitoring/intervention, KYC review, dispute review, risk review, and partner operations.
  - Acceptance criteria:
    - Operators can inspect platform health and transaction state.
    - Human approval gates for KYC/dispute/risk actions are represented and audited.
    - Admin actions are permissioned and observable.
  - Depends on: STORY-001, STORY-003, STORY-005
  - Source: discovery/drava-project-specification.md#module-6--web-admin-console

- [ ] STORY-007 — Implement WhatsApp-first notification and receipt architecture
  - Scope: Ensure transaction milestones, receipts, support interactions, fallback SMS/email, and companion app notification behavior follow the WhatsApp-first design principle.
  - Acceptance criteria:
    - Every transaction milestone has a WhatsApp notification path.
    - SMS/email are fallback-only surfaces.
    - Receipts and support interactions are correlated to transaction/user context.
  - Depends on: STORY-002, STORY-004, STORY-005
  - Source: discovery/drava-project-specification.md#core-design-principle

- [ ] STORY-008 — Add referral and growth loop
  - Scope: Implement the GTM referral engine and related tracking needed for low-CAC WhatsApp-native acquisition.
  - Acceptance criteria:
    - Referral attribution and reward eligibility rules are explicit.
    - Fraud/risk controls prevent referral abuse.
    - Referral events are measurable for acquisition analytics.
  - Depends on: STORY-002
  - Source: discovery/drava-executive-summary.md#delivery-approach

- [ ] STORY-009 — Plan Phase 2 custody and liquidity transition
  - Scope: Capture Phase 2 custodial wallet, pre-funded liquidity pools, instant-transfer premium, and volume-gated transition triggers as reviewed design work before implementation.
  - Acceptance criteria:
    - Custody transition trigger is documented and testable.
    - Liquidity pool controls and reconciliation requirements are captured.
    - Phase 2 work remains gated from GTM launch scope.
  - Depends on: STORY-003, STORY-006
  - Source: discovery/drava-project-specification.md#foundational-decisions-locked

- [ ] STORY-010 — Plan Phase 2 full SMB and corridor expansion
  - Scope: Capture full SMB suite, multi-currency support, analytics, subscriptions, in-chat catalog, corridor expansion, and UPI exportable-rail strategy as reviewed Phase 2 scope.
  - Acceptance criteria:
    - Phase 2 SMB capabilities are separated from GTM light-SMB scope.
    - Corridor expansion assumptions distinguish architecture readiness from external UPI rollout dependency.
    - Analytics requirements are traced to business decisions.
  - Depends on: STORY-004, STORY-009
  - Source: discovery/drava-project-specification.md#upinative-architecture--a-gtm-pillar
