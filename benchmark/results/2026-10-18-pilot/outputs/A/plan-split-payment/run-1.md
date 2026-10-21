# Risk-Based Test Plan: Split Payment (Release 5.3)

## Executive Summary

This plan prioritizes testing against financial and user experience risks using a risk-based approach. With 1 FTE tester (half-time), 2 developer-hours for test support, and a 10-working-day window, we focus testing on high-consequence scenarios while leveraging existing coverage for regression protection. PayGate sandbox availability (Tue/Thu only) constrains integration testing windows to 4 days before release.

## Assumptions

- Existing unit test suite covers single-card checkout at >80% code coverage
- Automated regression tests exist and run in CI for checkout flow
- Payment state is persisted in the application database with timestamps
- Refund automation is handled by the application, not PayGate
- Tester has write access to test payment cards and test order data
- "Within 60 seconds" refund requirement is a hard SLA
- Single-card checkout is considered production-stable with no known critical bugs
- Split payment UI is already built; testing is logic and integration focused
- PayGate sandbox responds with same error codes/latencies as production
- No PCI compliance audit is required before release (handled separately)

## Risk Assessment

| Risk | Severity | Probability | Impact | Mitigation |
|------|----------|-------------|--------|-----------|
| Both charges succeed; system records only one payment | Critical | Medium | Financial loss to customer; chargeback | *Prioritize: automated test with verification in payment logs* |
| First charge succeeds, second declines, first isn't refunded | Critical | Medium | Customer charged without order fulfillment | *Prioritize: automated refund SLA test; monitor logs for 60s latency* |
| Remainder-cent logic fails (loses/gains money) | High | Low | Systemic revenue loss on scale | *Prioritize: property-based test; code review split algorithm* |
| Existing single-card checkout breaks | High | Low | $160k/day revenue at risk (4k orders × $40 avg) | *Prioritize: full regression suite on CI; pre-release smoke test* |
| PayGate integration timeout during second charge | High | Medium | Hanging orders; unclear state | *Prioritize: network fault-injection test; timeout+refund flow* |
| Race condition: concurrent split payments from same user | High | Low | Duplicate charges or failed charges | *Unit test; manual concurrency scenario* |
| Refund call to PayGate fails (network/timeout) | High | Medium | First charge not refunded; user support issue | *Retry logic test; deadletter queue simulation* |
| Invalid split amounts accepted (negative, >100%, non-integer) | Medium | Medium | User error + support load | *Input validation unit tests* |
| UI doesn't make split amount clear; user confused | Medium | Medium | Disputes; support load | *Paired exploratory testing with a non-technical person* |
| PayGate sandbox down on Tue/Thu (integration test day blocked) | Medium | High | Integration tests slip to next week / after release | *Backup: mock PayGate for some scenarios; manual testing on production staging* |

## Test Strategy by Risk Tier

### Tier 1: Critical Path (Automated, Sandbox Required) — 5 working days
*Owner: Tester + 1 developer*

**Goal:** Verify payment split logic, refund SLA, and integration with PayGate.

| Test | Scenario | Execution | Pass Criteria |
|------|----------|-----------|---|
| Split succeeds both charges | User pays $50 on card A, $50 on card B for $100 order | PayGate sandbox; trace both charge IDs in logs | Both charges appear in order record within 5s; both invoiced to customer |
| Odd-cent remainder on card A | User pays $50.00 on card A for $100.01 order → card A charged $50.01, card B charged $50.00 | PayGate sandbox; inspect charge amounts | Amounts correct; total = order amount |
| Second charge declines; refund within SLA | Card A charged $50 ✓; Card B declined ✗ | PayGate sandbox; decline card B via gateway | Refund issued to card A within 60s; order marked failed; user sees error (no partial charge) |
| Second charge timeout; no duplicate retry | Second charge hangs >30s | Network fault injection / PayGate sandbox delay | First charge refunded within 60s; no retry to PayGate after 2 min |
| Refund call to PayGate fails; retry succeeds | First charge OK; second charge declined; refund API call fails 1st time | Mock PayGate to reject 1st refund, accept 2nd | Refund succeeds by 60s; order log shows retry |

**Schedule:** Tue 10/21, Thu 10/23 (PayGate sandbox windows); reserve Wed 10/22 for retests.

---

### Tier 2: Regression + Boundary (Mostly Automated, No Sandbox) — Continuous, final push 10/31
*Owner: Tester; developers run CI*

**Goal:** Ensure single-card checkout and edge cases remain stable.

| Test | Scenario | Execution | Pass Criteria |
|------|----------|-----------|---|
| Single-card checkout regression (smoke) | User pays $100 on 1 card | CI / staging; existing checkout test suite | All single-card tests pass; latency <2s vs. baseline |
| Remainder logic: 1 cent order | Split $0.01: $0.01 on card A, $0.00 on card B | Unit test; code review | Card A charged $0.01; card B skipped or charged $0 |
| Zero-remainder split | Split $100.00: $50.00 each | Unit test + sandbox | Both charges $50.00; total correct |
| Invalid splits blocked | User attempts $150 on $100 order; $-10 split; non-integer | Unit test + UI test | Validation error; no API call |
| Concurrent split requests same user | Two simultaneous split-payment requests | Load test tool (k6/JMeter); staging | Both succeed independently OR 2nd properly rejected; no race state |
| Concurrency: single-card + split-card same user | Concurrent single and split payments | Unit test; staging load | Both complete independently; no cross-contamination |

**Schedule:** Weeks of 10/14, 10/21, 10/28; final regression run 10/30.

---

### Tier 3: User Experience + Error Handling (Manual + Lightweight Automation) — 10/28–10/31
*Owner: Tester*

**Goal:** Catch usability gaps and unhandled error states.

| Test | Scenario | Execution | Pass Criteria |
|------|----------|-----------|---|
| Split-payment UI clarity | Non-technical person uses split UI for first time | Exploratory; screen recording | Tester can explain what each field does without help; no confusion on "which card is which" |
| Error messages are clear | Decline, timeout, gateway error, invalid input | Manual; staging | User knows why payment failed and next step (retry, new card, contact support) |
| Partially applied split + error recovery | User enters split, second charge declines, user retries | Manual; staging | Clear prompt to retry; prior payment refunded; no double-charge risk |
| Order status visibility during split | User checks order status while both charges pending | Manual; staging; check order page and email | Status is "processing" or "pending payment" (not "complete" until both succeed) |
| Refund receipt email | First charge refunded due to second decline | Manual; staging; check inbox | Email arrives within 2 min; references both charge IDs; clear explanation |

---

## Test Environment & Execution Plan

### Week 1 (10/14–10/18): Foundation
- **Unit tests:** Developers write and land split logic tests (input validation, remainder, charge order). Target: 100% coverage of payment calculation.
- **Regression suite:** Run full single-card checkout test suite daily in CI. Baseline latency and error rates.
- **Staging environment:** Deploy split-payment feature to staging (non-PayGate-connected mocks). Tester explores UI and data flows.
- **Outcome:** Unit tests passing; regression baseline stable; UI walkthrough recorded.

### Week 2 (10/21–10/25): Sandbox Integration
- **Tue 10/21 & Thu 10/23:** PayGate sandbox integration tests (Tier 1). Tester + 1 developer.
  - 2-hour block each day for scripting and execution.
  - Focus: successful split, odd-cent remainder, second decline + refund SLA, timeout scenarios.
- **Wed 10/22 (no sandbox):** Retests, fix bugs found, boundary/concurrency tests (Tier 2).
- **Fri 10/24:** Review sandbox results; document any PayGate quirks; prepare mock scenarios for next week.
- **Outcome:** Sandbox tests passing or root-cause documented with fix plan.

### Week 3 (10/28–10/31): Final Validation + Release Readiness
- **Mon 10/28:** Manual exploratory tests (Tier 3: UX, error messages, email). Concurrent load test (k6) on staging.
- **Tue 10/29:** Final regression run (all single-card + split scenarios). Sandbox re-test of any flaky scenarios. 60-second refund SLA audit in logs.
- **Wed 10/30:** Production readiness review: payment logs, refund success rate, no orphaned charges.
- **Thu 10/31 (release day):** Smoke test on production staging 2 hours pre-release. Monitor first 100 split payments live.
- **Outcome:** All Tier 1 & 2 tests passing; Tier 3 exploratory findings documented; release approved.

---

## Scope Boundaries

### In Scope
- Payment split logic (allocation and remainder).
- PayGate charge and refund integration.
- Refund SLA (60 seconds).
- Single-card checkout regression.
- Order state tracking during split.
- User-facing error messages and email.

### Out of Scope
- PCI compliance audit (owned by security team).
- Performance load testing beyond concurrency verification.
- Mobile app (if separate codebase; assume web-only or will be tested separately).
- PayGate infrastructure/uptime (trust their SLA).
- Localization (assume single language for MVP).

---

## Success Criteria

1. **No payment loss or double-charge:** All Tier 1 automated tests pass; zero orphaned charges in production logs after 48 hours.
2. **Refund SLA met:** Automated test verifies refund within 60 seconds in sandbox; production logs show 100% compliance in first 48 hours.
3. **Regression clean:** All existing single-card checkout tests pass; latency unchanged (±5%); error rate unchanged.
4. **User-safe:** Manual Tier 3 tests complete without findings that block release; UI is understandable to non-technical user.
5. **Deployable:** No critical bugs; medium bugs have documented workarounds or deferred to 5.4; all Tier 1 & 2 tests automated and repeatable.

---

## Risk Mitigation: PayGate Sandbox Availability

**Problem:** Sandbox only Tue/Thu; only 4 days (8 hours) before release.

**Mitigation plan:**
1. **Parallel mocking:** Developers build a mock PayGate (in code) for Tier 2 concurrency and timeout tests; no sandbox needed.
2. **Dry runs:** Wed/Fri use mocks to rehearse test scripts so sandbox time is efficient.
3. **Escalation:** If sandbox is down on a required day, run manual smoke tests in production staging (low volume, pre-release approval needed).
4. **Defer non-critical integration:** If sandbox time is exhausted, defer "PayGate quirk" tests (e.g., unusual error codes) to 5.3.1 post-release patch.

---

## Resource & Timeline Summary

| Role | Time | Allocation |
|------|------|-----------|
| **Tester** | 10 working days | 50% = 20 hours total |
| **Developer 1** | 10 working days | ~3 hours (unit test support, mock PayGate, debugging) |
| **Developer 2** | 10 working days | ~3 hours (integration assist, fix bugs found in testing) |

**Time breakdown:**
- Week 1: Unit test setup, regression baseline, UI walkthrough (4 hours tester, 2 dev).
- Week 2: Sandbox tests Tue/Thu, retests Wed, analysis Fri (10 hours tester, 2 dev).
- Week 3: Exploratory, final regression, load test, production readiness (6 hours tester, 2 dev).

---

## Handoff to Operations

Before release:
- **Runbook:** First-responder guide for "split payment failed" incidents (what to check in logs).
- **Monitoring alerts:** Payment double-charge detection; refund SLA breach; PayGate decline rate spikes.
- **Rollback plan:** Feature flag to disable split payments; single-card fallback must work.
- **Support FAQ:** Common split-payment errors and resolutions.
