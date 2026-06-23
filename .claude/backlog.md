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



- [ ] STORY-000 — Bootstrap platform infrastructure and onboard all external APIs
  - Scope: Establish the TypeScript project structure, CI/CD pipeline, and test framework with 95% line and branch coverage gates enforced in CI. Provision India data-residency hosting (RBI-compliant). Onboard every external API required by Phase 1 stories: WhatsApp Business API access and Flows developer environment (including Meta approval of at least one test template); US KYC provider (credit bureau database); Aadhaar eKYC API; Plaid (bank-link and ACH); card payment gateway; ACH processor; US-side and India-side settlement partner APIs; sanctions/PEP screening service. Deploy observability stack: structured logging with correlation IDs, metrics, and alerting. Does not implement any product feature.
  - Acceptance criteria:
    - CI/CD pipeline runs build, lint, type-check, unit tests, and integration tests on every commit; gate blocks merge on failure or coverage below 95%.
    - WhatsApp Business API credentials are provisioned, Flows developer access is confirmed, and at least one test transactional message template is Meta-approved.
    - All external API sandboxes (KYC provider, Aadhaar eKYC, Plaid, card gateway, ACH processor, US settlement partner, India settlement partner, sanctions/PEP service) are reachable and return expected responses in the staging environment.
    - India data-residency infrastructure is provisioned and confirmed to store no payment data outside India-region boundaries.
    - Observability stack emits structured logs with correlation IDs and at least one platform health metric to the alerting system.
  - Depends on: none
  - Source: discovery/drava-project-specification.md (cross-cutting prerequisite — all Phase 1 stories depend on this)

- [ ] STORY-001 — Establish GTM compliance and identity foundation
  - Scope: Define and implement the Phase 1 identity, onboarding, KYC, sanctions, PEP, watchlist, recipient onboarding, and multilingual onboarding foundation. Does not implement transfers or merchant collections.
  - Acceptance criteria:
    - WhatsApp number signup and companion app registration flows are represented in the domain model.
    - US sender KYC, Aadhaar recipient eKYC, document/selfie fallback, risk tiers, bank-link verification, and sanctions screening have testable acceptance paths.
    - KYC tiers enforce: Tier 1 (Aadhaar eKYC only) ≤$2,999/tx ≤$9,999/30-day; Tier 2 (US database + Aadhaar) ≤$9,999/tx; CTR event fires at $10,000; all bands configurable without code deployment.
    - Compliance events are auditable and observable.
  - Depends on: STORY-000
  - Source: discovery/drava-project-specification.md#module-1--identity-onboarding--kyc

- [ ] STORY-011 — Harden security, compliance, and platform foundations
  - Scope: Implement E2E encryption for WhatsApp Flows payloads (card and personal data unreadable to Meta), PCI-DSS compliant card-data handling, 2FA/MFA for sensitive actions (SIM-swap resistant), transaction signing/confirmation before any transfer executes, India data-residency infrastructure (RBI localization), fraud velocity and pattern rules, rate limiting and DDoS protection, tamper-evident audit logging, and pre-launch penetration-test gate. Does not include DR/failover (Phase 2) or stablecoin rails.
  - Acceptance criteria:
    - WhatsApp Flows payloads carrying card and personal data are E2E encrypted and unreadable to intermediaries including Meta.
    - Card data handling passes PCI-DSS boundary validation; no raw PAN stored outside compliant zones.
    - 2FA/MFA is enforced on all sensitive account actions and is resistant to SIM-swap attacks.
    - Every transfer requires explicit transaction signing/confirmation before funds move; non-repudiation is testable.
    - India-side payment data is stored exclusively on India-resident infrastructure (RBI data-localization compliance).
    - Fraud velocity and pattern rules are configurable, testable, and covered by integration tests.
    - Rate limiting and DDoS controls are present and verified under simulated load.
    - Audit log is tamper-evident and captures all significant system and operator actions with actor, timestamp, and detail.
    - A penetration-test gate is defined, documented, and tracked as a pre-launch blocker with acceptance sign-off criteria.
  - Depends on: STORY-000, STORY-001
  - Source: discovery/drava-project-specification.md#module-8--security-compliance--platform

- [ ] STORY-002 — Build WhatsApp-native consumer remittance flow
  - Scope: Implement the core send-money journey for WhatsApp Flows and companion app including recipient selection, amount entry, funding choice, FX quote with 30-minute rate lock, transparent fee display, confirmation, real-time transfer status, and saved beneficiaries for repeat transfers. Does not implement merchant collections.
  - Acceptance criteria:
    - A sender can progress through amount, recipient, funding, FX quote, fee display, and confirmation without browser redirect assumptions.
    - FX quote and 30-minute rate-lock rules are explicit and testable.
    - Transfer status milestones are emitted for WhatsApp-first notifications.
    - Saved beneficiary profiles persist across sessions; a sender can initiate a repeat transfer to a saved recipient without re-entering payout destination details.
  - Depends on: STORY-001, STORY-011
  - Source: discovery/drava-project-specification.md#module-2--core-transfer-engine-consumer-remittance

- [ ] STORY-003 — Implement funding and payout orchestration
  - Scope: Model non-custodial partner settlement, card funding, ACH funding, ACH risk holds, India payout routing, payment-gateway integration, and FX spread engine.
  - Acceptance criteria:
    - The platform never holds customer funds in Phase 1 flows.
    - Card, ACH, and payout partner states are idempotent and auditable.
    - ACH risk-hold enforces: new/low-trust users wait 3 business days; established users (account age ≥60 days AND ≥3 successful ACH transfers AND zero reversals) receive instant payout release; all parameters configurable without code deployment and covered by integration tests.
    - FX spread rules are configurable and covered by tests.
  - Depends on: STORY-002, STORY-011
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
    - Disputes valued at ≤$50 are resolved autonomously by the AI without human approval; disputes valued at >$50 require a human approval gate before any resolution action executes.
    - Phase 2 graduation path is defined and auditable: a dispute category achieving ≥95% consistent human-approved outcome over 500 resolved cases qualifies for autonomous promotion.
  - Depends on: STORY-002
  - Source: discovery/drava-project-specification.md#module-4--ai-engine-customer-service--disputes

- [ ] STORY-006 — Create regulated operations admin console
  - Scope: Implement the full GTM web admin: operations dashboard; transaction monitoring and intervention; KYC/AML review queue; dispute management console; user management; live FX rate/spread and fee/limit configuration; fraud monitoring and case management; SAR/CTR compliance report export; AI engine configuration (prompts, thresholds, escalation rules); knowledge-base/FAQ CMS; role-based access control; audit log and activity trail.
  - Acceptance criteria:
    - Operators can inspect platform health and transaction state, and intervene on stuck or failed transfers.
    - Human approval gates for KYC/dispute/risk actions are represented and audited.
    - SAR and CTR compliance report exports are generated from transaction data and cover all required regulatory fields.
    - Operators can adjust AI engine prompts, thresholds, and escalation rules without a code deployment.
    - Knowledge-base and FAQ content can be authored and updated by non-technical staff without engineering involvement.
    - Role-based access control enforces least-privilege: compliance, operations, and engineering duties are segregated; every privileged action is audited.
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
    - Custodial transition trigger is defined as $10M monthly GMV; the design document captures the licensing prerequisites, regulatory requirements, and architectural changes triggered at this milestone.
    - Liquidity pool controls and reconciliation requirements are captured.
    - Phase 2 work remains gated from GTM launch scope.
  - Depends on: STORY-003, STORY-006
  - Source: discovery/drava-project-specification.md#foundational-decisions-locked

- [ ] STORY-010 — Plan Phase 2 full SMB and corridor expansion
  - Scope: Capture full SMB suite, multi-currency support, analytics, subscriptions, in-chat catalog, corridor expansion, and UPI exportable-rail strategy as reviewed Phase 2 scope.
  - Acceptance criteria:
    - Phase 2 SMB capabilities are separated from GTM light-SMB scope.
    - Corridor expansion design confirms the GTM rail abstraction layer (UPI adapter pattern) makes each new corridor a configuration change; Gulf and SEA adapters are not pre-built but the interface they would implement is specified.
    - Analytics requirements are traced to business decisions.
  - Depends on: STORY-004, STORY-009
  - Source: discovery/drava-project-specification.md#upinative-architecture--a-gtm-pillar

- [ ] STORY-012 — Implement Phase 2 identity re-verification and business KYB
  - Scope: Periodic re-KYC / refresh: scheduled risk-based re-verification of existing users as accounts age. Business KYB (know-your-business) verification: verifies business registration, beneficial ownership, and AML standing for SMB accounts, unlocking the full Phase 2 SMB suite. Does not modify GTM KYC tiers defined in STORY-001.
  - Acceptance criteria:
    - Re-KYC schedule is risk-based and configurable; re-verification events are auditable and observable.
    - Users who fail re-KYC are suspended with a configurable grace period and WhatsApp notification before suspension.
    - Business KYB covers company registration, beneficial ownership, and AML screening; KYB-verified merchants gain access to Phase 2 SMB features.
    - Re-KYC and KYB events integrate with the admin KYC/AML review queue (STORY-006).
  - Depends on: STORY-001, STORY-009
  - Source: discovery/drava-project-specification.md#module-1--phase-2

- [ ] STORY-013 — Build Phase 2 scheduled transfers and cash-pickup payout
  - Scope: Scheduled / recurring transfers: automated repeating sends on user-defined schedules with configurable frequency and end conditions. Cash-pickup payout: recipients collect cash at partner agent locations, expanding the serviceable market to unbanked recipients. Does not include instant-transfer premium (covered in STORY-015, which requires custodial pools). Bulk / split transfers (P2+) are out of scope.
  - Acceptance criteria:
    - A sender can schedule a recurring transfer with start date, frequency, and end condition; transfers execute automatically per schedule.
    - Recurring transfers emit WhatsApp notifications on execution, on scheduling changes, and on failure with retry guidance.
    - Cash-pickup payout routes to partner agent network; recipient receives a collection code and instructions via WhatsApp.
    - Scheduled transfer state (next run, history, cancellation) is visible in the companion app and on WhatsApp on demand.
  - Depends on: STORY-002, STORY-003
  - Source: discovery/drava-project-specification.md#module-2--phase-2

- [ ] STORY-014 — Evolve AI engine to Phase 2 autonomy and proactivity
  - Scope: Self-updating knowledge base: learns from resolved cases to keep support content current automatically. Graduated autonomous dispute resolution: autonomously resolves dispute categories that have met the 95%/500-case graduation threshold defined in STORY-005; operator sign-off required per category promotion. AI proactive notifications: contextual nudges (e.g., favorable-rate alerts, send-anniversary reminders) respecting opt-in/opt-out. Voice-based AI support (P2+) is out of scope for this story.
  - Acceptance criteria:
    - Knowledge base measurably improves answer accuracy after incorporating learnings from at least 100 resolved cases; improvement is reportable.
    - Dispute categories meeting the 95%/500-case threshold can be promoted to autonomous resolution via admin approval; all autonomous decisions are logged with rationale.
    - Proactive notifications fire within 5 minutes of trigger conditions (e.g., rate target reached) and honor opt-out immediately.
    - The admin AI engine configuration panel (STORY-006) controls autonomous promotion thresholds.
  - Depends on: STORY-005, STORY-008
  - Source: discovery/drava-project-specification.md#module-4--phase-2

- [ ] STORY-015 — Implement Phase 2 custodial wallet, liquidity pools, multi-currency, and instant-transfer premium
  - Scope: Custodial wallet / stored balance: users store value and send instantly; requires completion of licensing prerequisites triggered at $10M monthly GMV (STORY-009). Pre-funded bilateral liquidity pools: matches opposing flows against pre-funded pools rather than moving money per transaction. Multi-currency wallet: users hold and convert balances across supported currencies. Treasury / liquidity dashboard for operator control. Instant-transfer premium: minutes-not-hours delivery at 1.5% premium, enabled by custodial pools. Stablecoin settlement rail (P2+) is out of scope.
  - Acceptance criteria:
    - Custodial wallet holds stored balances; float revenue is tracked separately from transaction fee revenue.
    - Liquidity pool matching reduces per-transaction settlement cost versus Phase 1 non-custodial baseline (benchmarked and reportable).
    - Pre-funded pool levels are monitored; alerts fire when pool depth falls below configurable thresholds.
    - Multi-currency wallet allows users to hold and convert across at least two supported currencies.
    - Treasury dashboard gives operators real-time visibility into all liquidity positions and pool health.
    - Instant-transfer premium option is surfaced in the send flow at 1.5% and delivers settlement within the SLA (to be defined in HLD); only activates when custodial pool has sufficient liquidity.
  - Depends on: STORY-003, STORY-009
  - Source: discovery/drava-project-specification.md#module-5--phase-2

- [ ] STORY-016 — Build Phase 2 full SMB suite
  - Scope: Reconciliation and settlement reports: accounting-grade settlement statements for merchants. In-chat catalog / product checkout: customers browse a catalog and complete checkout within WhatsApp without leaving the chat. Subscription / recurring billing: merchants bill customers on configurable repeating schedules with payment failure retry. Multi-user merchant accounts: team access with role-based permissions (owner, admin, viewer). Extends light SMB from STORY-004.
  - Acceptance criteria:
    - Settlement and reconciliation reports are accounting-grade, cover all merchant collections, and reconcile with STORY-004 GTM records.
    - In-chat catalog enables a customer to browse products and complete checkout without leaving WhatsApp.
    - Subscription billing executes automatically on schedule; failed payments retry per configurable policy with merchant and customer notification.
    - Multi-user merchant accounts support at least owner, admin, and viewer roles with enforced access control.
    - All SMB transactions remain GST-compliant (extending STORY-004 invoicing rules).
  - Depends on: STORY-004, STORY-010, STORY-015
  - Source: discovery/drava-project-specification.md#module-3--phase-2

- [ ] STORY-017 — Expand to multi-corridor via UPI adapter pattern
  - Scope: Activate Gulf (UAE/Saudi Arabia) and SEA corridors using the rail abstraction layer built at GTM (STORY-003). Each corridor requires: corridor-specific compliance configuration (local KYC/AML thresholds), payout rail mapping, FX spread configuration, and Meta-approved Flows templates in corridor languages. Corridor activation is gated by NPCI International rail availability in the target market. Does not pre-build adapters for markets without confirmed rail availability.
  - Acceptance criteria:
    - A new corridor can be activated by configuration change in the partner/rail management console without a code deployment (proven with at least one non-India production corridor).
    - Corridor-specific KYC thresholds, AML obligations, and payout rails are configurable per corridor.
    - FX spread and fee configuration are independent per corridor.
    - Corridor compliance events and transaction records are segregated and auditable per corridor.
  - Depends on: STORY-003, STORY-010, STORY-012
  - Source: discovery/drava-project-specification.md#upi-native-architecture--a-gtm-pillar

- [ ] STORY-018 — Add Phase 2 analytics, BI dashboards, and admin enhancements
  - Scope: Analytics and BI dashboards: cohort, corridor, and behavioral analytics refreshed at least daily, filterable by corridor, time period, and segment. Partner / rail management console: self-serve addition and configuration of payout rails and partners without engineering involvement. Graduated autonomous dispute promotion UI in the admin console (in conjunction with STORY-014). Does not cover marketing campaign tooling (STORY-019).
  - Acceptance criteria:
    - Analytics dashboards cover cohort retention, corridor volume, fee revenue, and conversion funnel at minimum.
    - Partner / rail management console allows operators to add, configure, and disable a payout rail or settlement partner without a code deployment.
    - All BI reports are filterable by corridor, time period, and user segment; data is traceable to source transactions.
    - Autonomous dispute promotion UI lets admins review graduation-eligible categories and approve/deny promotion with a documented rationale.
  - Depends on: STORY-006, STORY-010, STORY-014, STORY-017
  - Source: discovery/drava-project-specification.md#module-6--phase-2

- [ ] STORY-019 — Implement Phase 2 communications, DR/failover, and growth programs
  - Scope: Marketing / campaign messaging: outbound marketing campaigns with explicit opt-in, consent management, and immediate opt-out. Disaster recovery / failover: redundant systems and tested failover to maintain service during outages (critical once the platform holds custodial balances from STORY-015). Rate-alert / FX-watch: user-set exchange-rate alerts triggering WhatsApp notification within 5 minutes. Loyalty / fee-rebate program (P2+): rewards frequent senders with fee rebates — lower priority, implemented after unit economics are proven.
  - Acceptance criteria:
    - Marketing campaign messages are delivered only to opted-in users; opt-out is honored immediately and permanently.
    - DR/failover is documented with defined RPO and RTO targets; failover has been tested and the runbook is current.
    - Rate alerts fire a WhatsApp notification within 5 minutes of a target corridor rate being reached.
    - Loyalty program tracks qualifying transactions and issues rebates per configured rules; rules are configurable without code deployment (P2+ — detailed acceptance criteria refined at implementation time).
  - Depends on: STORY-007, STORY-008, STORY-015
  - Source: discovery/drava-project-specification.md#module-7--phase-2
