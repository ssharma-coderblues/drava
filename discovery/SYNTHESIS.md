<!-- pravartak: ingestion=loose-docs version=0.5.0 generated=2026-06-22T22:45:10Z -->
# Synthesis — drava

Archetype: loose-docs
Synthesized: 2026-06-22T22:45:10Z
Source: docs/
> Synthesized from the converted executive summary and project specification. Validate against the original `.docx` files during architect review.

## Product thesis
- Drava is a WhatsApp-native US → India remittance and SMB payments platform. [authoritative: drava-executive-summary.md] (High)
- WhatsApp is the primary relationship surface; companion app, SMS, and email are secondary/fallback surfaces. [authoritative: drava-project-specification.md] (High)
- GTM is non-custodial: licensed partners settle and hold funds while Drava orchestrates. [authoritative: drava-project-specification.md] (High)

## GTM scope
- Phase 1 delivers consumer remittance, light SMB collections, AI customer service/dispute pipeline, web admin console, and referral growth loop. [authoritative: drava-project-specification.md] (High)
- Lead corridor is US → India with UPI-native payout architecture. [authoritative: drava-project-specification.md] (High)

## Phase 2 scope
- Phase 2 covers custodial wallet transition, liquidity pools, premium instant transfer, full SMB suite, analytics, multi-currency, and corridor expansion. [authoritative: drava-executive-summary.md] (High)

## Open questions for architect review
- Confirm AI dispute autonomy boundary for GTM versus Phase 2.
- Confirm KYC limit thresholds and risk-tier ceilings.
- Confirm custodial transition trigger.
- Confirm ACH risk-hold policy and release criteria.
- Confirm whether the Wave-Planner PoC remains a planning tool or becomes production workflow code.
