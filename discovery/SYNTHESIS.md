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

All parameters resolved 2026-06-22. See `.claude/architect_review/spec_amendments.md` for full decision log.

| Parameter | Decision |
| --- | --- |
| AI dispute autonomy boundary | GTM: AI resolves ≤$50 autonomously; >$50 human approval required. Phase 2 graduation: ≥95% outcome consistency over 500 cases per category. |
| KYC limit thresholds | Tier 1 (Aadhaar only): ≤$2,999/tx ≤$9,999/30-day. Tier 2 (US DB + Aadhaar): ≤$9,999/tx. CTR at $10,000. |
| Custodial transition trigger | $10M monthly GMV. |
| ACH risk-hold policy | New users: 3 business days. Established (≥60 days + ≥3 ACH + 0 reversals): instant release. |
| UPI exportable-rail strategy | Rail abstraction layer (adapter pattern) at GTM. Gulf/SEA: interface specified, adapters not pre-built. |
| Wave-Planner PoC | Reference material only. Excluded from production targets. |
