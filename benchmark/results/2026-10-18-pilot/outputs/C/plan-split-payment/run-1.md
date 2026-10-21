I notice you've invoked the `writing-guide:help-articles` skill, which writes end-user help-center articles. The task you've described—a risk-based test plan—is a QA deliverable, not a help-center article.

I can write the test plan you need, but I'll do it as a regular response rather than through this skill. Let me create that for you:

---

# Split Payment (Release 5.3) — Risk-Based Test Plan

## Test Plan Overview

**Feature:** Split payment across two cards  
**Release:** 5.3 (10 working days from 2026-10-18)  
**Go-live:** ~2026-11-01  
**Resources:** 1 tester (0.5 FTE) + 2 developers  
**Testing window constraint:** PayGate sandbox available Tuesdays and Thursdays only

---

## Risk Assessment

| Risk | Impact | Likelihood | Priority |
|------|--------|-----------|----------|
| Second charge declines; first charge not refunded within 60s | Revenue loss + customer dispute | Medium | Critical |
| Odd-cent remainder logic fails; customer charged wrong amount | Financial accuracy; fraud concern | Medium | Critical |
| Single-card checkout broken by split-payment code | 4,000 orders/day fail | High | Critical |
| Sandbox unavailability blocks testing before go-live | Untested code ships | High | High |
| Refund logic races with charge confirmation | Duplicate refunds or failed refunds | Medium | High |
| PayGate API timeout during split flow | Partial charges; no rollback | Medium | High |
| Rounding edge cases (e.g., $0.01 split) | Logic failure on boundary values | Low | Medium |

---

## Test Cases (Priority Order)

### Tier 1: Critical Path (Must Test)

**T1.1 — Happy path: split payment succeeds**
- Customer pays $100.00 across two cards ($60 + $40)
- Both charges succeed
- Order completes; customer receipt shows both transactions
- Verify both amounts exact in PayGate logs

**T1.2 — Second charge declines; auto-refund within 60s**
- First charge: $60 succeeds
- Second charge: $40 declines
- First charge refund initiated automatically (timer starts on decline)
- Verify refund completes and reaches customer bank within 60s
- Verify order marked failed; customer shown clear error

**T1.3 — Odd-cent split (e.g., $100.01)**
- Customer splits $100.01 as $60 first card, $40.01 second card
- Remainder cent ($0.01) goes to first card
- Verify first card charged $60.01, second charged $40.00
- Verify total = $100.01

**T1.4 — Regression: single-card checkout still works**
- Process 10 single-card orders across different amounts
- Verify orders complete end-to-end
- Verify no new latency vs. baseline (measure checkout time)

**T1.5 — Refund already initiated before decline reaches system**
- PayGate takes 2+ seconds to return decline response
- First refund fires before second decline arrives
- Verify no race condition; only one refund issued
- Verify order state consistent in app and PayGate

---

### Tier 2: Boundary & Integration (Should Test)

**T2.1 — Minimum split ($0.01 first card, rest on second)**
- Order $50.00; split as $0.01 + $49.99
- Both charges succeed
- Verify logic handles minimal first-card amount

**T2.2 — Maximum single-card amount (e.g., $999.99 typical limit)**
- Assume PayGate single-charge max is $9,999.99
- Split amounts that sum to near-limit
- Verify both succeed

**T2.3 — PayGate rate limiting / throttling**
- Fire 5 split payments in rapid succession
- Verify all process without timeout or "too many requests" error
- Verify PayGate logging shows all 10 charges (5 customers × 2 cards)

**T2.4 — Network latency: slow response from PayGate**
- Simulate PayGate API delay (2+ seconds)
- Verify timeout doesn't trigger refund prematurely
- Verify retry logic (if any) doesn't double-charge

**T2.5 — Partial refund success**
- First charge succeeds, second declines
- Refund fires but PayGate temporarily unavailable (then recovers)
- Verify refund retries and completes
- Verify customer sees final state correctly

---

### Tier 3: Edge Cases (Nice to Test)

**T3.1 — Zero-amount charge**
- Customer tries to split $50 as $50 + $0
- Verify validation prevents second charge attempt
- Verify UX blocks or warns user

**T3.2 — Negative amount**
- Customer tries to split as negative number
- Verify form validation rejects

**T3.3 — Concurrent orders from same customer**
- Customer places two split-payment orders simultaneously
- Verify both process independently; no shared state corruption

**T3.4 — Manual refund attempt on customer portal**
- Order has first charge refunded (second declined)
- Customer or support attempts to issue additional refund
- Verify system prevents duplicate refund

---

## Testing Schedule

| Week | Focus | Window | Status |
|------|-------|--------|--------|
| Week 1 (10/18–10/24) | Sandbox access; smoke test (T1.1) | Tue 10/22, Thu 10/24 | |
| Week 1 (10/25–10/29) | Critical path (T1.2, T1.3, T1.4) | Tue 10/28, Thu 10/30 | |
| Week 2 (11/1–11/5) | Tier 2, regressions (T2.1–T2.5), UAT | Dev/staging | |

**Assumption:** PayGate sandbox restored by 10/22 after maintenance window.

---

## Testing Constraints & Mitigations

| Constraint | Mitigation |
|-----------|-----------|
| Sandbox only Tue/Thu | Front-load critical tests (T1.1–T1.2) to weeks 1; shift Tier 2 to staging/UAT by week 2 |
| One tester at 0.5 FTE | Developers run Tier 3 edge cases during build; tester focuses on Tier 1 & 2 |
| 10 working days to release | Skip T3 if Tier 1 & 2 pass; regression test (T1.4) is non-negotiable |
| Refund must complete in 60s | Set test timeout to 90s; capture PayGate logs for timing proof |

---

## Regression Testing (Ongoing)

- Run `checkout_single_card_*` test suite daily on staging for all 10 days pre-release
- Monitor production single-card transaction volume (baseline ~4,000/day) for anomalies post-launch
- If latency increases >100ms or decline rate >0.5%, roll back and investigate

---

## Sign-Off Criteria

✅ **Must pass before release:**
- T1.1, T1.2, T1.3, T1.4 all pass  
- No single-card order regression  
- Refund logic verified in logs and customer bank reconciliation  

⚠️ **Nice to have:**
- T2.1–T2.5 complete (defer if time-boxed)  
- T3 cases documented for post-release

---

## Assumptions

- PayGate sandbox will be restored and available by the start of testing (week 1)
- "Automatically within 60s" means refund is *initiated* within 60s of decline detection; actual customer bank processing may take longer
- Single-card checkout regression test uses existing automated test suite
- Developers will provide test fixtures for PayGate decline responses (no manual card setup needed)
- No additional payment processor integrations (only PayGate)
