<!-- pravartak: template=spec_amendments.md.template version=0.5.0 generated=2026-06-22T22:45:10Z -->
# drava — Spec Amendments

Log of every approved spec change made during architect review or drift resolution. Each
entry records the change-impact analysis: which story prompted it, the change, and every
file touched (applied consistently — never patch one doc and leave others stale).

<!-- Entry format:
### <timestamp> — STORY-0xx — <one-line summary>
- Change: <what changed and why (architect feedback)>
- Files touched: discovery/<a>.md, discovery/<b>.md, .claude/backlog.md, ...
- Already-implemented? <no | yes → corrective story STORY-CORR-N queued>
-->

### 2026-06-22 — open-design-parameters — All six open design parameters resolved by architect

- Change: Six parameters carried from the project specification into HLD/LLD were formally decided by the architect in review session on 2026-06-22. Decisions are binding; story acceptance criteria updated to reflect concrete, testable values.
- Files touched: .claude/backlog.md (STORY-001, STORY-003, STORY-005, STORY-009, STORY-010), PRAVARTAK.md, discovery/SYNTHESIS.md
- Already-implemented? no

---

#### 01 — AI dispute autonomy boundary
- **Decision:** Partial autonomy at GTM — AI resolves disputes ≤$50 autonomously without human approval. Disputes >$50 require a human approval gate before any resolution action executes.
- **Phase 2 graduation trigger:** A dispute category achieving ≥95% consistent human-approved outcome over 500 resolved cases qualifies for promotion to autonomous resolution for that category. Graduation is logged and reportable.
- **Rejected option:** Zero autonomy at GTM (recommended but overridden — architect accepted some risk for faster support resolution on low-value disputes).
- **Story impact:** STORY-005 acceptance criteria updated.

#### 02 — KYC limit thresholds
- **Decision:** Progressive / Aadhaar-led tiers.
  - Tier 1 (Aadhaar eKYC only, no US database check): ≤$2,999 per transaction, ≤$9,999 per 30-day period.
  - Tier 2 (US credit-bureau database + Aadhaar): ≤$9,999 per transaction.
  - CTR (Currency Transaction Report) event fires at $10,000 — no single transaction may clear this threshold without enhanced due diligence.
  - All tier bands are configurable and auditable without code deployment.
- **Rationale:** Leverages Aadhaar as the primary trust signal for the corridor; higher limits with less friction vs. standard Remitly-tier banding.
- **Story impact:** STORY-001 acceptance criteria updated.

#### 03 — ACH risk-hold parameters
- **Decision:**
  - New / low-trust users: payout held **3 business days** after ACH initiates.
  - Established users (account age ≥60 days AND ≥3 successful ACH transfers AND zero ACH reversals): **instant payout release**.
  - Parameters (hold duration, trust criteria) are configurable without code deployment.
- **Story impact:** STORY-003 acceptance criteria updated.

#### 04 — Custodial transition trigger
- **Decision:** Begin custodial licensing and architecture transition work when the platform reaches **$10M monthly GMV**. At that scale, float revenue and per-transaction cost reduction from pre-funded liquidity pools materially outweigh the licensing and compliance investment.
- **Story impact:** STORY-009 acceptance criteria updated.

#### 05 — UPI exportable-rail investment depth
- **Decision:** Build a **rail abstraction layer (adapter pattern)** at GTM for the US→India corridor. The interface is defined such that each future corridor (Gulf, SEA) is a configuration change, not a rewrite. Gulf and SEA adapters are **not pre-built** — the interface they would implement is specified in the design, but no adapter code ships until NPCI International confirms the rail in a target market.
- **Story impact:** STORY-010 acceptance criteria updated.

#### 06 — Wave-Planner PoC disposition
- **Decision:** `poc-wave-planner/` is **reference material only**. It is explicitly excluded from production build targets and test runs. No engineering time is allocated to productionizing it. The Pravartak autonomous loop handles story sequencing.
- **Files touched:** PRAVARTAK.md architect overrides updated to reflect closed decision.
