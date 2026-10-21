# Split Payment (Release 5.3) – Risk-Based Test Plan

## Executive Summary

This plan prioritizes testing around critical payment flows and regression prevention, constrained by limited sandbox availability (Tue/Thu) and a tight 10-day release window with 1 half-time tester. Testing focuses on the highest financial and operational risk areas: correct payment splitting and refund logic, PayGate integration reliability, and regression on the existing single-card checkout. Edge case coverage and load testing are scoped by available time.

---

## Risk Assessment & Testing Priorities

| Risk | Severity | Likelihood | Test Focus | Approx. Effort |
|------|----------|-----------|-----------|---|
| Incorrect amount splitting (math errors, rounding) | Critical | Medium | Unit + integration tests | 4h |
| Refund fails or takes >60s after decline | Critical | Medium | Integration + chaos testing | 6h |
| Second charge declined but first not refunded | Critical | Low | Integration scenario testing | 4h |
| Existing single-card checkout regresses | High | Medium | Regression suite | 4h |
| PayGate integration timeout/error handling | High | Medium | Integration + error injection | 3h |
| Order state corruption (orphaned charges, duplicate refunds) | High | Low | Data integrity checks | 2h |
| User-facing error messages unclear | Medium | Low | UAT-style manual testing | 2h |
| Performance degrades with split-payment load | Medium | Low | Light load testing | 2h |
| Edge cases: $0.01 remainder, exact 50/50 split, >$1M order | Medium | Medium | Edge case test set | 2h |

**Total estimated effort: ~29 hours; available capacity: ~20 hours (1 tester × 10 working days × 4 actual working hours/day, accounting for holidays, context switching, and management overhead).**

---

## Test Scope

### In Scope
- Happy path: split payment succeeds on both cards
- Decline scenarios: second card declined → automatic refund of first charge within 60s
- Amount splitting logic: correct handling of cents, rounding, edge amounts
- PayGate integration: successful charges, error responses, timeouts
- Refund correctness: amount, timing, idempotency on retries
- Existing single-card checkout: smoke test + regression pack on critical flows
- Order data integrity: charges and refunds correctly recorded in database
- Error handling and user messaging (major flows only)

### Out of Scope
- Performance testing beyond smoke tests (no time for load ramp-up with PayGate sandbox constraints)
- Exhaustive UI testing (assumed designers validate UX)
- Accessibility testing (deferred)
- Internationalization of error messages (assumed single language for MVP)
- PayGate API response timing under load (external dependency; tested for happy path only)

---

## Detailed Test Cases

### Tier 1 (Must Test – Critical Path)

**TC-SP-001: Split payment succeeds, amounts correct**
- Setup: Customer places order for $100.00, chooses to split $60.00 on Card 1, $40.00 on Card 2
- Action: Complete checkout
- Expected: Both charges posted to PayGate; order record shows two transactions ($60.00, $40.00); customer receives confirmation
- Notes: Validate amounts in payment gateway records, not just UI

**TC-SP-002: Remainder cent goes to first card**
- Setup: Order $10.01, split $5.00 Card 1, $5.01 Card 2
- Action: Complete checkout
- Expected: First card charged $5.01, second charged $5.00 (reversal of input split); both charges succeed
- Notes: Validates rounding logic; test both directions (uneven splits)

**TC-SP-003: Second card declined, first charge auto-refunded**
- Setup: Order $100.00, split $60.00 / $40.00; second card is marked "decline" in PayGate sandbox
- Action: Complete checkout
- Expected: First charge ($60.00) posts successfully; second charge declined; first charge refunded within 60 seconds; order status = "refunded"; customer notified
- Notes: Critical for user trust; timing is enforced (use time-sync'd test harness if needed)

**TC-SP-004: Both charges decline**
- Setup: Both cards marked "decline" in PayGate sandbox
- Action: Attempt checkout
- Expected: First charge declined; order rejected immediately (second card not attempted); clear error message; no charges posted
- Notes: Verify no partial charges occur

**TC-SP-005: Existing single-card checkout still works**
- Setup: Customer places order using legacy single-card flow
- Action: Complete checkout with one card
- Expected: Charge posts; order confirmed; no reference to split payment in order data
- Notes: Regression check; must verify no side effects from new code (database schema, middleware, payment processing)

**TC-SP-006: Order data integrity after split payment**
- Setup: Run TC-SP-001
- Action: Query database for order record
- Expected: Order contains exactly two charge records (linked by order ID); both marked as "part of split"; no duplicate entries; audit log shows creation timestamps
- Notes: Prevents orphaned charges; validates data model

**TC-SP-007: Refund is idempotent**
- Setup: Trigger TC-SP-003 (second charge declines, first refunds)
- Action: Call refund API again (simulate retry)
- Expected: No double-refund; system responds "already refunded"; amount returned once
- Notes: PayGate may retry callbacks; must handle gracefully

### Tier 2 (High-Value / Medium Effort)

**TC-SP-008: Edge case – $0.01 order (split 0.005 / 0.005)**
- Setup: Place $0.01 order, attempt to split
- Action: Complete checkout
- Expected: System handles rounding (first card gets $0.01, second gets $0.00 OR system rejects as invalid); documented behavior
- Assumption: Splitting a $0.01 order may not be allowed; if allowed, first card absorbs remainder

**TC-SP-009: PayGate timeout on first charge**
- Setup: PayGate sandbox configured to timeout
- Action: Attempt split payment
- Expected: First charge times out; second charge not attempted; order marked "pending"; user can retry; no orphaned charges
- Notes: Timeout window likely 30s; validate no ghost charges in PayGate after retry

**TC-SP-010: Network interruption during refund flow**
- Setup: First charge succeeds; second charge declined; network cut during refund
- Action: Simulate network loss midway through refund call to PayGate
- Expected: System retries refund automatically; completes within 60s OR escalates to manual queue if timeout exceeded
- Notes: May require test doubles for PayGate if integration testing is not possible on sandbox

**TC-SP-011: Large order – split $500,000.00**
- Setup: Order for $500,000.00, split $300,000 / $200,000
- Action: Complete checkout
- Expected: Charges succeed; amounts are accurate; no overflow errors in database (validate column types support this range)
- Notes: Validates that system doesn't assume max order size; edge case for financial data

**TC-SP-012: Exact 50/50 split**
- Setup: Order $100.00, split $50.00 / $50.00
- Action: Complete checkout
- Expected: Both charges exactly $50.00; no rounding artifacts
- Notes: Ensures rounding logic doesn't introduce bias

**TC-SP-013: Regression – existing 4K/day load baseline**
- Setup: Simulate 4,000 single-card orders/day (from existing checkout)
- Action: Run load test over 1 hour (166 orders/min) using production-like data
- Expected: All orders complete successfully; latency remains <5s p99; no errors
- Notes: Validates new code doesn't degrade baseline performance; if time is short, reduce to 1,000 orders

### Tier 3 (Best Effort / Nice-to-Have)

**TC-SP-014: Split payment via mobile app**
- Setup: Access checkout on mobile device
- Action: Complete split payment
- Expected: UI renders correctly; split input accepts valid amounts; submission works
- Notes: Assumed responsive design already tested; this is smoke test only

**TC-SP-015: Refund success confirmation email**
- Setup: Trigger TC-SP-003
- Action: Observe customer email
- Expected: Email received within 2 minutes, accurate refund amount, refund reference number included
- Notes: Low priority if email service is third-party; validate integration only

**TC-SP-016: PayGate rate-limit handling**
- Setup: Flood PayGate with 100 simultaneous split-payment requests
- Action: Complete test run
- Expected: Requests queue gracefully; none fail; system respects PayGate rate limits (if any)
- Notes: Only if time permits; PayGate SLA should define limits

---

## Test Environment & Timeline

### Sandbox Availability Constraint
- PayGate sandbox available: **Tue 10/21, Thu 10/23, Tue 10/28, Thu 10/30** (4 days in the 10-day window)
- Testing strategy:
  - **Mon 10/20**: Unit tests run locally (no PayGate); mock PayGate integration
  - **Tue 10/21**: Tier 1 critical path tests (TC-SP-001 through 007)
  - **Wed 10/22**: Analyze results; fix blockers
  - **Thu 10/23**: Tier 2 scenario tests (TC-SP-008 through 012); regression suite
  - **Fri 10/24–Mon 10/27**: Retesting + final regression on staging
  - **Tue 10/28**: Final smoke tests on sandbox; sign-off prep
  - **Wed 10/29–Thu 10/30**: Buffer for critical issues

### Resource Allocation
- **Developer 1**: Implement split payment logic; assist with unit test stubs
- **Developer 2**: PayGate integration; assist with test environment setup
- **Tester (half-time)**: Design test cases (2h), execute Tier 1 & 2 (12h), retesting & reporting (4h), sign-off (2h) = 20h

---

## Success Criteria

1. **Critical (Must-Have for Release)**
   - [ ] Both split charges post correctly to PayGate
   - [ ] Remainder cent logic is correct (verified by unit test + integration test)
   - [ ] Second charge decline triggers refund of first charge within 60 seconds (measured)
   - [ ] No refund occurs if both charges succeed
   - [ ] Existing single-card checkout passes regression suite (all Tier 1 test cases)
   - [ ] Order database records are consistent (no orphans, duplicates, or missing charges)
   - [ ] No critical bugs found in Tier 1 test execution

2. **High (Expected for Production Quality)**
   - [ ] Tier 2 tests pass or are mitigated (see Risks & Mitigations)
   - [ ] PayGate integration timeouts are handled gracefully
   - [ ] Refund logic is idempotent
   - [ ] Large order amounts (>$10K) do not cause overflow or precision loss

3. **Release Gate**
   - All Tier 1 tests must pass with zero critical or high-severity bugs
   - Tier 2 tests must have 80% pass rate or documented waivers
   - Single-card regression must be 100% pass

---

## Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| Insufficient PayGate sandbox uptime | Develop robust mock/stub PayGate service for local testing; reserve sandbox time for integration-only tests |
| Refund timing is difficult to test | Use time-mocked test harness or inject delay in PayGate response; coordinate with DevOps for time-sync |
| One tester cannot cover all test cases | Prioritize Tier 1 (critical); defer Tier 3 to post-release if needed; developers run unit tests and help with integration tests |
| Regression not caught before release | Automate single-card checkout smoke tests (3–5 core flows) and run on every build; manual regression run on staging 48h before release |
| Refund fails silently (no alerting) | Ensure error logs and monitoring are wired up; validate alerts fire in test with manual PayGate decline |
| Performance regression on 4K/day load | Run load test on Wednesday (post-Tier 1 results); if latency increases >10%, roll back or optimize before Thursday sandbox session |

---

## Test Automation Approach

**Assumed tooling** (state assumptions if not provided by project):
- Unit tests: Developers write in existing framework (e.g., Jest, pytest); cover rounding logic, amount calculations
- Integration tests: API-level tests using PayGate sandbox stub; test refund timing with mocked clock
- Regression: Automated smoke suite for single-card checkout (kept simple, <5 min runtime)
- Manual testing: Tier 1 critical flows + Tier 3 UI/mobile (tester runs via checklist)

**Automation ROI**:
- High: Rounding logic (unit tests, reusable)
- High: Refund idempotency (integration test with stub, repeatable)
- Medium: Single-card regression (smoke suite, quick turnaround for bugs)
- Low: UI/mobile tests (one-time manual checks; low value for rapid iteration)

---

## Assumptions

1. **Release includes both backend and frontend** – test assumes UI for split amount input is implemented
2. **PayGate API is RESTful with documented decline codes** – test plans assume we can trigger decline scenarios in sandbox
3. **60-second refund SLA is firm** – not a target, but a hard requirement (e.g., regulatory or user-facing guarantee)
4. **Existing single-card checkout is well-tested** – assumes existing regression suite exists; we extend it
5. **Database supports decimal precision for currency** – assumes amounts are stored as DECIMAL(10, 2) or equivalent
6. **PayGate sandbox can be reset between test runs** – assumes we can clear failed transactions to avoid state pollution
7. **Developers will complete feature by EOD Fri 10/24** – testing assumes code is ready for integration testing by Monday 10/27
8. **No external dependencies block testing** (other than PayGate sandbox availability)
9. **One working day = 8 hours; weekend work is not planned**
10. **Manual refund process exists as fallback** – if auto-refund fails after 60s, ops can manually refund (tested once, not part of daily regression)

---

## Deliverables & Sign-Off

- [ ] Test plan (this document) – approved by PM/tech lead
- [ ] Test case checklist (Tier 1 & 2, with pass/fail) – completed by 10/30
- [ ] Regression test run report (single-card checkout) – completed by 10/30
- [ ] Any critical/high bugs found – logged in tracking system with evidence (screenshots, logs, PayGate transaction IDs)
- [ ] Sign-off memo – states whether feature meets success criteria and is safe to release
- [ ] Retesting results for any bugs fixed post-Tier 1 – completed by EOD 10/29

**Planned sign-off date: Thu 10/30, 5 PM (or earlier if all tests pass)**
