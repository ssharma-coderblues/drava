<!-- pravartak: ingestion=loose-docs version=0.5.0 generated=2026-06-22T22:45:10Z -->
# Drava Project Specification

Authority: authoritative
Source: docs/Drava_Project_Specification.docx
Format: docx converted to plain-text markdown with macOS textutil

> Faithful mechanical conversion. Review the source `.docx` for formatting, tables, and diagrams not preserved by plain-text extraction.

```text
PROJECT SPECIFICATION
Drava
WhatsApp-Native Payments Platform
Phase-Wise Delivery Plan & Detailed Feature Specification
Drava (Sanskrit: “to flow; liquid”) — the platform carries value across borders the way liquid flows: instantly, cleanly, and without friction. This document defines the complete scope for the US → India remittance and SMB payments platform, organized by delivery phase, with each feature defined by what it is, what it does, and the business value it delivers.

Lead Corridor
US → India
Custody Model
Non-Custodial
Client Surface
WhatsApp + App
Phasing
GTM → Phase 2

Contents




---


01  
How to Read This Document

This specification is organized by delivery phase. It states what the platform delivers at Go-To-Market (Phase 1) and what it delivers in the complete-the-app stage (Phase 2). Within each phase, features are grouped by functional module so engineering structure remains clear.
Every feature is described across three dimensions: what it is (its definition), what it does on the platform (its function in the system), and its business value (why it earns a place in scope).
Foundational Decisions (Locked)
Lead corridor
US → India. Chosen for rail maturity (UPI), highest global remittance volume, high WhatsApp penetration on both ends, and a banked sender profile that clears digital KYC at high rates.
UPI-native core
Drava’s payment core is architected around UPI’s model from GTM. North-star goal: be the world’s best way to receive money from abroad into India via UPI. Not a domestic UPI app.
Custody model
Non-custodial at GTM. Licensed partners settle and hold funds; the platform orchestrates. Custodial wallet is a volume-gated Phase 2 decision.
Core product
Consumer remittance led (≈80%) with light SMB collections (≈20%) at GTM. Full SMB tooling in Phase 2.
Client surface
WhatsApp (Flows + bot) and a companion mobile app, both at GTM. WhatsApp is the primary relationship surface.
AI engine
Full build at GTM. Customer service autonomous; dispute resolution is a full pipeline with human-in-the-loop approval gates, graduating toward autonomy in Phase 2.
KYC approach
Progressive / digital-first. Full regional compliance (FinCEN CIP, RBI/PMLA) via automated database and Aadhaar verification, with document upload as the fallback only.


Core Design Principle
Design principle — WhatsApp-first communication architecture: every transaction milestone, receipt, and support interaction is delivered on WhatsApp as the primary channel. The companion app is a secondary surface; SMS and email are fallback only.

The Drava North Star
Drava’s GTM ambition is deliberately focused: to be the world’s best way to receive money from abroad into India via UPI — instant, transparent, best-FX, with the cleanest WhatsApp experience.
This is a niche the domestic UPI giants ignore and the remittance incumbents handle clumsily. It is narrow enough to win at launch, large enough to matter, and it makes every downstream decision easier by defining clearly what Drava builds first — and what it deliberately does not.

Explicit Non-Goals
Scope discipline — what Drava is NOT at GTM: not a domestic UPI app (no competing with PhonePe, Google Pay, or Paytm on India-to-India payments), and not a custodial wallet. Drava is the cross-border receiving layer on UPI. That focus is on the record.

How Drava Differs from Domestic Rails (Paytm, Pix, Interac)
Domestic number-to-number systems are sometimes mistaken for competitors. They are not — they are the local rails Drava rides on each end. The distinction is structural:
	•	Domestic islands vs. cross-border. Pix works inside Brazil, Interac inside Canada, Paytm inside India. None moves money across a border or currency. Drava exists precisely for the border — the FX, the corridor, the dual-sided compliance.
	•	Single-rail vs. rail-agnostic. Pix and Interac are rails. Drava is an orchestration layer above rails, routing across UPI, Pix, ACH, and more — the Stripe-to-Visa relationship, not a competitor to the rail.
	•	Their app vs. WhatsApp-native. They require their own app and identity. Drava lives in the conversation already happening on WhatsApp, inheriting distribution and trust instead of fighting for an install.
	•	Utility vs. relationship layer. Domestic rails are invisible plumbing with no customer relationship. Drava owns the sender, recipient, experience, FX transparency, and dispute resolution — the relationship is the moat, not the money movement.

UPI-Native Architecture — A GTM Pillar
Drava’s payment core is architected around UPI’s model from day one. This is a GTM design pillar, not a Phase 2 afterthought. UPI is the most advanced instant-payment design in existence — real-time, bank-to-bank, no stored value, near-zero cost, open API — and other rails (Pix, FedNow, SEPA Instant) are converging toward what it already does. Building the orchestration layer in UPI’s image means every future UPI-enabled corridor becomes configuration, not a rewrite.
The compounding payoff: NPCI International is exporting UPI into the UAE, Singapore, Sri Lanka, Nepal, France, and beyond, and interlinking it with local instant-payment systems. Because Drava speaks UPI natively from GTM, it is positioned to flip on each new corridor — including the high-margin Gulf → India route — as the rail lights up, while competitors re-architect. Drava’s leverage is not owning UPI but being the most fluent rider of the rail that is quietly becoming a global standard.

Strategic Caveat
Honest limit: UPI is sovereign infrastructure deployed government-to-government; Drava cannot “release” UPI in new markets itself. And UPI is near-zero-cost by design, so no rail margin can be extracted from the UPI leg — revenue comes from FX and the experience layer. The UPI-export vision is architecture Drava is ready for, not a dependency that gates GTM.


---


02  
Phase 1 — Go-To-Market Delivery

GTM
A functional, compliant, revenue-generating product
Native WhatsApp + app remittance on the US → India corridor, dual funding, multi-rail payout, light SMB collections, a full AI engine, a complete admin console, and a referral growth loop — everything required to launch and operate legally from day one.

Module 1 — Identity, Onboarding & KYC
KYC posture: Progressive / digital-first. Full verification always occurs; method depth escalates only on failure or risk signal.
Feature
What it is
What it does on the platform
Business value
WhatsApp number-based signup
Registration that uses the user’s WhatsApp phone number as the primary identity anchor.
Creates the account from within WhatsApp; no separate signup form or app download required to begin.
Removes the single biggest drop-off point in onboarding, lifting conversion at the top of the funnel.
Companion app registration
A standard account creation path (phone + email) for the mobile app surface.
Provisions an account for users who prefer the app, linked to the same identity as their WhatsApp profile.
Serves users who want a richer interface and provides a fallback if WhatsApp is unavailable.
Digital-first sender KYC (US)
Identity verification of the US sender against credit-bureau and identity databases.
Validates name, DOB, address and SSN instantly through a verification vendor; most users clear with no documents.
Meets FinCEN CIP obligations while keeping onboarding nearly frictionless — the Remitly-grade experience.
Aadhaar eKYC (India recipient)
OTP-based electronic verification of the India-side recipient using Aadhaar.
Confirms recipient identity in seconds with no paperwork via the Aadhaar eKYC API.
Satisfies RBI requirements and exploits India’s paperless KYC infrastructure as a corridor advantage.
Document + selfie fallback
Manual document upload with liveness selfie, used only when automated checks fail.
Triggers a guided capture flow when database or Aadhaar verification cannot confirm identity or risk flags fire.
Ensures no legitimate user is permanently blocked while keeping manual review the exception, not the norm.
Risk-based limit tiers
A tiering model where verification depth maps to transaction-limit ceilings.
Assigns each verified user a sending limit band consistent with FinCEN and RBI tier frameworks.
Balances regulatory caution with conversion — small transfers face less friction, large ones more scrutiny.
Bank-link identity verification
Identity confirmation achieved by linking a funding bank account (via Plaid).
Uses the bank-link step both to enable ACH funding and to corroborate the user’s identity in one action.
Collapses two onboarding steps into one, reducing friction while strengthening identity assurance.
Sanctions / PEP / watchlist screening
Automated screening against sanctions, politically-exposed-person and watchlists.
Checks every user at onboarding and screens transactions against updated lists continuously.
A non-negotiable AML control; failure to screen carries severe regulatory and reputational penalties.
Lightweight recipient onboarding
A minimal capture flow for the receiving party (name + payout destination).
Lets a sender add a recipient with only essential details; the recipient needs no full account or app.
Removes friction on the receive side, which would otherwise block transfers to less tech-engaged family members.
Multi-language onboarding
Onboarding presented in English and Hindi at GTM.
Renders all onboarding screens and prompts in the user’s chosen corridor language.
Matches the linguistic reality of the corridor and improves comprehension, trust and completion rates.
Module 2 — Core Transfer Engine (Consumer Remittance)
Feature
What it is
What it does on the platform
Business value
Send-money flow (WhatsApp Flows)
A fully native in-chat payment journey built on WhatsApp Flows.
Walks the user through amount, recipient, funding and confirmation entirely inside WhatsApp — no browser redirect.
The core product and primary differentiator versus Remitly; higher conversion through zero context-switching.
Send-money flow (companion app)
The same transfer journey delivered in the mobile app.
Provides a parallel surface for initiating and confirming transfers for app-preferring users.
Captures users who favor an app and reinforces the brand beyond the WhatsApp surface.
Real-time FX quote + 30-min rate lock
A live exchange-rate quote held for 30 minutes after initiation.
Fetches the current corridor rate, applies the spread, and freezes the receive-amount during confirmation.
Builds trust through certainty and protects platform margin from FX movement mid-transaction.
Transparent fee display
An explicit pre-confirmation breakdown of rate, fee and exact receive-amount.
Shows the recipient’s exact INR amount before the user commits, with no hidden charges.
The Wise-grade trust signal; transparency is a proven driver of conversion and retention in remittance.
Card funding (debit/credit)
Transaction funding via debit or credit card rails.
Charges the sender’s card instantly to fund the transfer.
Offers instant, familiar funding for urgency; broadens the addressable user base.
ACH bank funding
Transaction funding via ACH bank transfer.
Pulls funds from the sender’s linked bank account at low flat cost over a multi-day window.
Protects unit economics — ACH avoids the 1–3% interchange that can exceed the entire FX spread.
ACH risk-hold policy
A risk rule governing payout timing for ACH-funded transfers.
Holds payout until ACH clears for new or low-trust users and releases instantly for trusted ones.
Contains reversal and fraud loss on the multi-day ACH window without penalizing established users.
Multi-rail payout routing (India)
A routing layer offering bank transfer, UPI and wallet payout on the receive side.
Selects the optimal India-side payout rail per recipient preference and cost.
Maximizes delivery success and recipient convenience while optimizing per-transaction cost.
Real-time transfer status tracking
End-to-end visibility of a transfer’s state.
Surfaces initiated, funded, in-transit, delivered and failed states in real time, pushed to WhatsApp.
Directly addresses the highest-volume support query and reduces support load.
Saved beneficiaries
Stored recipient profiles for repeat transfers.
Lets users re-send to a saved recipient in a couple of taps without re-entering details.
Drives repeat usage and retention — the core economic engine of a remittance business.
Module 3 — SMB / Merchant Collections
Merchant compliance: Receipts cover baseline record-keeping; GST-compliant tax invoicing is included in GTM, sequenced after the core launch.
Feature
What it is
What it does on the platform
Business value
WhatsApp payment-link generation
A shareable payment link a merchant sends inside a chat.
Generates a unique link that opens a pre-filled payment flow for the merchant’s customer.
The simplest possible collection mechanism; lets merchants accept money with zero technical setup.
Static / dynamic collection QR
QR codes — fixed or amount-specific — for collecting payment.
Encodes the merchant’s payment destination so an in-person customer can scan and pay into the WhatsApp flow.
Bridges offline commerce into the platform, capturing physical point-of-sale moments.
Merchant payment notifications
Real-time alerts confirming funds received.
Notifies the merchant on WhatsApp the moment a customer payment settles.
Gives merchants immediate confidence and closes the sale loop without manual checking.
Basic compliant payment receipt
An auto-generated proof-of-payment document.
Issues a receipt (ID, amount, date, parties, reference) for every collection to both merchant and customer.
Satisfies baseline legal record-keeping for the merchant and provides customer proof of payment.
Merchant transaction history
A chronological record of the merchant’s collections.
Lists all received payments with status and reference in the merchant view.
Provides minimum viable bookkeeping so merchants can reconcile their takings.
Merchant payout to bank account
Withdrawal of collected balances to the merchant’s bank.
Transfers accumulated collections to the merchant’s linked account on a schedule or on demand.
Closes the loop — merchants must be able to access the money they collect.
GST-compliant tax invoicing
Formal tax invoices meeting GST formatting rules.
Generates sequentially-numbered invoices with tax breakdown for transactions that require them.
Enables merchants to meet statutory tax-invoicing obligations, unlocking compliant business use.
Module 4 — AI Engine (Customer Service & Disputes)
Feature
What it is
What it does on the platform
Business value
Autonomous AI customer-service bot
A multilingual conversational agent handling support in-chat.
Answers FAQs, reports transaction status, guides onboarding and resolves common issues without a human.
Deflects the majority of support volume at near-zero marginal cost, critical for thin remittance margins.
AI intent routing + escalation
A classifier that routes queries and escalates when needed.
Determines user intent, handles what it can, and hands off cleanly to a human agent for the rest.
Ensures complex or sensitive cases reach humans while routine load stays automated.
AI dispute intake + classification
An automated front door for disputes.
Captures dispute details and categorizes each case by type and severity.
Standardizes and accelerates dispute handling from the first moment, improving resolution time.
AI evidence gathering / case assembly
Automated compilation of the facts behind a dispute.
Pulls transaction records, timelines and communications into a structured case file.
Removes hours of manual case-building per dispute, improving operator efficiency and consistency.
AI draft resolution + approval gate
An AI-proposed resolution reviewed by a human before action.
Drafts a recommended outcome and routes it to an operator for approval in the admin console.
Combines AI speed with human accountability — safe dispute handling before autonomy is earned.
Sentiment / fraud-signal detection
Real-time analysis of conversation tone and risk indicators.
Flags distress, anger or fraud signals within chats for prioritization or intervention.
Protects vulnerable users and surfaces fraud early, reducing loss and reputational risk.
Module 5 — Payments, Wallet & Treasury
Feature
What it is
What it does on the platform
Business value
Non-custodial orchestration
The GTM money-movement model where the platform never holds funds.
Coordinates funding, FX and payout across licensed partners who hold and settle the money.
Enables launch in months rather than years by avoiding custodial licensing, with no float risk.
Partner settlement integration
Integrations with licensed settlement partners on both corridor ends.
Connects to US-side and India-side partners that execute the actual movement of funds.
Provides the regulated rails that make legal money transmission possible at GTM.
Payment-gateway integration
Connections to card and ACH funding gateways.
Processes inbound funding transactions and reports their status to the orchestration layer.
The mechanism by which senders’ money enters the system reliably and securely.
FX spread engine
The component that applies the platform’s margin to the exchange rate.
Layers a configurable spread on top of the partner’s mid-market rate per corridor.
The primary revenue mechanism of the remittance product, tunable by market conditions.
Module 6 — Web Admin Console
Operating a regulated money product demands substantial admin capability from day one; the bulk of this module is GTM.
Feature
What it is
What it does on the platform
Business value
Operations dashboard
A live operational view of the platform.
Displays real-time transaction volume, user counts and system health to operators.
Lets the team run the business with visibility rather than operating blind.
Transaction monitoring + intervention
Tools to inspect and act on individual transactions.
Allows operators to investigate, retry or manually resolve stuck and failed transfers.
Recovers revenue and protects user trust when transactions go wrong.
KYC / AML review queue
A workqueue for flagged identities and screening hits.
Routes verification edge-cases and AML alerts to compliance staff for human decision.
Provides the mandatory human-review backbone for regulated onboarding.
Dispute management console
The operator workspace for disputes.
Presents AI-assembled cases and draft resolutions for human approval and action.
Where the human-in-the-loop dispute policy is actually executed.
User management
Administrative control over user accounts.
Enables search, freeze, support and investigation actions on any account.
Essential for support, compliance and fraud response.
FX rate / spread configuration
Live control of exchange-rate spreads.
Lets operators adjust corridor spreads without a code deployment.
Allows pricing and margin to respond to market conditions in real time.
Fee / limit configuration
Live control of fees and transaction limits.
Adjusts fee schedules and risk limits operationally.
Tunes economics and risk posture without engineering cycles.
Fraud monitoring + case management
A surface for reviewing and actioning fraud.
Aggregates flagged transactions and supports investigation and resolution.
Limits financial loss and meets AML obligations to act on suspicious activity.
Compliance reporting (SAR/CTR)
Automated regulatory report generation.
Produces suspicious-activity and currency-transaction report exports from transaction data.
Meets mandatory filing obligations and reduces manual compliance risk and effort.
AI engine configuration
Controls governing AI behavior.
Lets operators tune prompts, thresholds and escalation rules for the AI engine.
Keeps AI behavior controllable and improvable without redeploying code.
Knowledge-base / FAQ CMS
A content system feeding the AI bot.
Lets staff author and update the knowledge the CS bot draws on.
Keeps automated support accurate and current as the product evolves.
Role-based admin access control
Permissioning across admin functions.
Restricts each operator’s access to the functions their role requires.
Enforces least-privilege security and segregation of compliance, ops and engineering duties.
Audit log / activity trail
A tamper-evident record of system and operator actions.
Logs every significant action with actor, time and detail.
Provides forensic evidence for compliance audits and security investigations.
Module 7 — Notifications & Communications
Feature
What it is
What it does on the platform
Business value
WhatsApp transactional messaging
Status messages delivered on WhatsApp.
Sends every transaction milestone as a WhatsApp message via approved templates.
Keeps users informed on the channel they already use — the platform’s primary face.
Companion app push notifications
Push alerts to the mobile app.
Notifies app users of status changes and relevant events.
Maintains engagement for app-surface users.
SMS / email fallback
Backup delivery channels.
Sends notifications via SMS or email only when WhatsApp delivery fails.
Guarantees critical messages reach users even when the primary channel is unavailable.
Multilingual message templates
Pre-approved templates in corridor languages.
Stores Meta-approved message templates in English and Hindi for transactional sends.
Ensures compliant, comprehensible messaging at the speed transactions require.
Module 8 — Security, Compliance & Platform
Feature
What it is
What it does on the platform
Business value
End-to-end encryption (Flows)
Encryption of sensitive Flows payloads.
Encrypts card and personal data so it is unreadable to intermediaries including Meta.
Protects sensitive data and is a precondition of PCI compliance.
PCI-DSS compliant card handling
Card-data handling meeting PCI-DSS.
Processes and stores card data within PCI-compliant boundaries.
A legal requirement wherever card data is touched; non-compliance forfeits the ability to process cards.
Fraud detection / velocity limits
Automated transaction-risk controls.
Applies velocity and pattern rules to detect and block suspicious activity.
Prevents financial loss and supports AML obligations.
2FA / MFA
Multi-factor authentication beyond WhatsApp identity.
Requires an additional authentication factor for sensitive actions.
Defends against SIM-swap account takeover, a real attack vector in the corridor.
Transaction signing / confirmation
Explicit authorization before money moves.
Requires the user to confirm and authorize each transfer.
Prevents accidental or unauthorized transactions and strengthens non-repudiation.
Data residency (India localization)
Storage of India payment data within India.
Keeps India-side payment data on infrastructure located in India.
Mandatory under RBI data-localization rules; a precondition of operating in the corridor.
Audit logging
Comprehensive system logging.
Records system events for forensic and compliance purposes.
Supports investigations, audits and regulatory inquiries.
Rate limiting / DDoS protection
Platform-hardening controls.
Throttles abusive traffic and absorbs denial-of-service attempts.
Protects availability and integrity of the service.
Pre-launch penetration testing
A security audit gate before go-live.
Subjects the platform to adversarial testing prior to launch.
Surfaces vulnerabilities before they reach production and real money.
Module 9 — Growth & Engagement
Feature
What it is
What it does on the platform
Business value
Referral / invite engine
A mechanism for users to invite others, with incentives.
Lets a user invite family and contacts via WhatsApp, tracking referrals and rewards.
The cheapest growth lever — remittance is community behavior, and one sender brings a network.


---


03  
Phase 2 — Complete-the-App Delivery

P2
Depth, scale, and the custodial transition
Builds on the GTM foundation with the move to holding balances, the full SMB suite, graduated AI autonomy, multi-currency support, advanced analytics, and the groundwork for corridor expansion. Items marked P2+ are lower priority or conditional.

Module 1 — Identity, Onboarding & KYC
Feature
What it is
What it does on the platform
Business value
Periodic re-KYC / refresh
Scheduled re-verification of existing users.
Re-runs verification on a risk-based cadence as accounts age.
Maintains compliance posture and data accuracy as the user base matures.
Business KYB verification
Full know-your-business verification for merchants.
Verifies business registration, ownership and legitimacy for SMB accounts.
Unlocks compliant onboarding of larger merchants for the full SMB suite.
Module 2 — Core Transfer Engine
Feature
What it is
What it does on the platform
Business value
Scheduled / recurring transfers
Automated transfers on a defined schedule.
Lets users set up repeating sends that execute automatically.
Captures predictable remittance behavior and increases retention.
Instant-transfer premium
A paid express-settlement option.
Offers minutes-not-hours delivery for a 1.5% premium, best served by custodial pools.
A high-margin revenue stream monetizing urgency.
Cash-pickup payout option
Payout via physical cash-pickup agents.
Enables recipients to collect cash at partner agent locations.
Reaches unbanked recipients, widening the serviceable market.
Bulk / split transfers
P2+ — sending to multiple recipients at once.
Allows a single instruction to fund several recipients.
Serves edge cases such as group support; lower GTM priority.
Module 3 — SMB / Merchant Collections
Feature
What it is
What it does on the platform
Business value
Reconciliation & settlement reports
Accounting-grade financial reporting for merchants.
Generates detailed settlement and reconciliation statements.
Meets the bookkeeping needs of larger, more sophisticated merchants.
In-chat catalog / product checkout
Conversational commerce inside WhatsApp.
Lets customers browse a catalog and check out within the chat.
Turns the platform into a full sales channel, deepening merchant dependence.
Subscription / recurring billing
Merchant-side recurring charges.
Enables merchants to bill customers on a repeating schedule.
Adds predictable revenue for merchants and stickiness for the platform.
Multi-user merchant accounts
Team access with roles for a merchant.
Allows multiple staff to operate one merchant account with permissions.
Supports larger businesses with multiple operators.
Module 4 — AI Engine
Feature
What it is
What it does on the platform
Business value
Self-updating knowledge base
An AI knowledge base that maintains itself.
Learns from resolved cases to keep support content current automatically.
Reduces manual content operations and improves answer quality over time.
Graduated autonomous dispute resolution
Progressive removal of human approval gates.
Allows the AI to resolve proven dispute types autonomously as reliability is demonstrated.
Scales dispute handling without proportional headcount once trust is earned.
AI proactive notifications
AI-initiated contextual nudges.
Sends timely, relevant prompts such as favorable-rate alerts.
Drives re-engagement and positions the platform as an active money tool.
Voice-based AI support
P2+ — spoken-language AI support.
Handles support interactions by voice for low-literacy users.
Improves accessibility for an underserved segment; high future value.
Module 5 — Payments, Wallet & Treasury
Feature
What it is
What it does on the platform
Business value
Custodial wallet / stored balance
A held balance users can keep on the platform.
Lets users store value, send instantly and receive into a wallet — requires licensing.
The major architectural shift; unlocks float revenue, instant transfers and stickiness.
Pre-funded liquidity pools
Held balances in both countries to net transfers.
Matches opposing flows against pre-funded pools rather than moving money per transaction.
Reduces per-transaction cost and settlement time at scale — the Wise model.
Multi-currency wallet
A wallet holding multiple currencies.
Lets users hold and convert balances across currencies.
Broadens utility and supports expansion into new corridors.
Treasury / liquidity dashboard
Internal tooling for managing pooled funds.
Gives operators visibility and control over liquidity positions.
Essential operational control once the platform holds balances.
Stablecoin settlement rail
P2+ — stablecoin-based cross-border settlement.
Uses stablecoins as an intermediate settlement layer between corridors.
Potentially lower-cost, faster settlement; emerging and evaluated cautiously.
Module 6 — Web Admin Console
Feature
What it is
What it does on the platform
Business value
Analytics & BI dashboards
Deep business-intelligence reporting.
Provides cohort, corridor and behavioral analytics to the team.
Informs strategy, pricing and growth decisions with data.
Partner / rail management console
Self-serve configuration of rails and partners.
Lets operators add and configure new payout rails and partners without engineering.
Accelerates corridor and partner expansion.
Module 7 — Notifications & Communications
Feature
What it is
What it does on the platform
Business value
Marketing / campaign messaging
Outbound marketing communications.
Sends campaign messages with opt-in and consent management.
A growth and re-engagement tool, gated on proper consent handling.
Module 8 — Security, Compliance & Platform
Feature
What it is
What it does on the platform
Business value
Disaster recovery / failover
Resilience and business-continuity infrastructure.
Provides redundant systems and failover to maintain service during outages.
Protects availability and trust as transaction volume and stakes grow.
Module 9 — Growth & Engagement
Feature
What it is
What it does on the platform
Business value
Rate-alert / FX-watch
User-set exchange-rate alerts.
Notifies users when a target corridor rate is reached.
Drives re-engagement and positions the platform as a money-management tool, not just a pipe.
Loyalty / fee-rebate program
P2+ — a retention rewards program.
Rewards frequent senders with fee rebates or perks.
Improves retention and lifetime value once unit economics are proven.


---


04  
Open Items Carried Into Design

Resolved in principle, these require specific parameters during High-Level and Low-Level Design and are recorded so none is lost.
	•	AI dispute autonomy boundary. Where the human approval gate sits at GTM, and the criteria that graduate a dispute type to autonomous resolution in Phase 2.
	•	KYC limit thresholds. The transaction-value bands mapping to each verification tier under FinCEN and RBI requirements.
	•	Custodial transition trigger. The volume or revenue milestone that justifies moving from non-custodial to holding balances — the largest architectural fork in the project.
	•	UPI exportable-rail strategy. How far to invest in reusable UPI integration competency ahead of NPCI International expansion into Gulf and SEA corridors.
	•	ACH risk-hold parameters. The clearing-hold duration and the trust criteria that release funds instantly for established users.


What Comes Next
Next deliverables: with this phase-wise specification approved, the program proceeds to High-Level Design (HLD) and Low-Level Design (LLD), beginning with the GTM scope. The locked foundational decisions and this feature inventory are the inputs to that design work.
```
