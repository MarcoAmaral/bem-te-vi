# Test Plan: Split Payment Feature (Release 5.3)

## 1. Context of Testing

### Scope
Testing the new split-payment feature in release 5.3, which allows customers to divide a single order payment across two payment cards with automatic refund if the second card is declined.

**In Scope:**
- Two-card payment split (amount selection, distribution logic, remainder cent routing)
- Charge execution via PayGate for both cards
- Automatic refund of first charge if second charge fails (within 60-second SLA)
- Error handling and user communication for decline scenarios
- Regression testing of single-card checkout to ensure no breakage

**Out of Scope:**
- PayGate API internal behavior or stability (assumed reliable as existing integration)
- Multi-currency or multi-language payment handling
- Existing single-card checkout feature logic (except regression)
- PCI compliance or banking regulations (assumed handled by PayGate)

### Objectives
- Verify split-payment amount calculation, remainder routing, and charge execution are correct
- Confirm automatic refund completes within 60 seconds on second-charge decline
- Ensure single-card checkout (4,000 orders/day baseline) remains functional
- Identify and document risks before release

### Test Basis
- Feature specification: split payment across two cards, with automatic refund on second-card decline within 60 seconds
- Existing single-card checkout flow and API contracts
- PayGate API documentation and sandbox behavior
- Release acceptance criteria: zero critical defects, all release-gate cases pass

---

## 2. Assumptions and Constraints

### Assumptions
1. Feature development is complete by working day 5 of the 10-day window; testing occupies working days 6–10
2. PayGate integration is an existing, proven dependency; test focus is on split-payment orchestration only
3. Test environment and staging deployment are pre-production parity
4. Developers will conduct unit and integration testing; QA leads system-level testing and acceptance
5. PayGate sandbox is available without unplanned outages on all Tuesdays and Thursdays during the window
6. Single-card checkout regression suite is already written and passing on main (scope: 4 test cases per impact analysis)
7. Product Owner is available for acceptance testing and sign-off within the window
8. Amounts are always positive integers in cents (no negative or fractional-cent input)
9. "Remainder cent goes to first card" is the final, non-negotiable business rule
10. 60-second refund SLA is a hard requirement (no grace period)
11. Single currency (USD) and single language (English) for this release

### Constraints
- **PayGate sandbox availability**: Tuesdays and Thursdays only. Limits hands-on testing of PayGate integration and end-to-end decline + refund scenarios to 4 days out of the 10-day window.
- **Resource**: 1 tester (0.5 FTE = ~20 hours/week), 2 developers (unit/integration testing capacity unknown, but split among feature build and testing). Available testing window is ~40 person-hours of QA effort.
- **Timeline**: 10 working days (2 calendar weeks, ~2026-10-30 release). Development overlap with testing expected.
- **Regression scope**: Single-card checkout handles 4,000 orders/day; must not be broken.

---

## 3. Stakeholders

| Role | Responsibility | Relevance to Testing |
| :--- | :--- | :--- |
| **Product Owner** | Release decision, acceptance criteria, business rule clarification | Approves acceptance tests, signs off on exit criteria, reviews defect priority |
| **Dev Lead** | Feature implementation, code review, integration testing | Owns unit and component-integration testing; reviews test cases for technical feasibility |
| **QA Lead (this plan)** | System test planning, execution, defect reporting, release recommendation | Owns system test design, risk analysis, release-gate execution, final sign-off |
| **QA Analyst (part-time)** | Test case execution, exploratory testing, defect logging | Runs release-gate and regression cases; logs findings; supports exploratory checks |
| **PayGate SME** (external contact, if needed) | API behavior clarification | Consulted if sandbox behavior diverges from spec |

---

## 4. Communication

### Forms and Frequency
- **Daily standup** (async or 15-min): test progress, blockers, sandbox availability
- **Weekly release gate review** (Thu): pass/fail summary, critical findings, go/no-go recommendation
- **Test completion report** (end of release window): attached to release ticket, includes release-gate results, regression status, unmitigated risks

### Document Templates
- Release-gate results: one row per case (ID, what it proves, pass/fail, environment build)
- Defect log: severity, reproduction steps, affected PayGate scenario (if external), owner, status
- Test progress: cases run / not run, critical blockers (e.g., sandbox unavailability), days remaining

---

## 5. Risk Register (5×5 Matrix)

| # | ID | Risk Description | Category | L | I | Score | Level | Mitigation Strategy | Owner |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | R01 | Incorrect amount split calculation (e.g., $100 split as $60/$39 instead of $60/$40) | Product | 3 | 5 | 15 | 🔴 **CRITICAL** | Boundary-value test cases for edge splits ($0.01, $0.99 remainder); decision table for rounding rule; unit test by developer with QA code review | Dev + QA |
| 2 | R02 | Remainder cent routed to wrong card (should go to card 1) | Product | 2 | 5 | 10 | 🟠 **HIGH** | Unit test for remainder logic; acceptance test case verifying remainder receipt on card 1; exploratory testing of asymmetric splits | Dev + QA |
| 3 | R03 | Second charge declined; first charge not refunded within 60 seconds | Product | 3 | 5 | 15 | 🔴 **CRITICAL** | Automated E2E test mocking PayGate second-charge decline; timer assertion (refund initiated <60s from decline). Manual test on sandbox Tue/Thu. Rollback plan: manual refund script + customer comms template | Dev + QA |
| 4 | R04 | Refund logic fails silently or times out | Product | 3 | 5 | 15 | 🔴 **CRITICAL** | Unit test refund error handling; E2E test decline → refund → confirmation flow; monitoring of refund callback logs; escalation procedure to PayGate support | Dev + QA |
| 5 | R05 | Single-card checkout broken by split-payment code merge | Product | 2 | 5 | 10 | 🟠 **HIGH** | Regression suite (4 cases) run on every commit; code review for isolation of split logic; deployment smoke test before release | Dev + QA |
| 6 | R06 | PayGate API timeout, rate-limit, or temporary failure during charge | Product | 3 | 4 | 12 | 🟠 **HIGH** | Error-handling test (network timeout simulated); exponential backoff / retry logic validation; user-facing error message clarity; escalation to PayGate support if persistent | Dev |
| 7 | PR01 | PayGate sandbox available only Tue/Thu; limits window for decline + refund testing | Project | 4 | 4 | 16 | 🔴 **CRITICAL** | Parallelize: mock PayGate on Mon/Wed/Fri for E2E happy path; reserve Tue/Thu for real sandbox decline scenarios. Pre-stage test data by EOD Mon. Escalation: if sandbox down, conduct on staging with PayGate's help | QA |
| 8 | PR02 | Insufficient QA time (0.5 FTE, 10 days) to cover split + decline + refund + regression | Project | 3 | 4 | 12 | 🟠 **HIGH** | Prioritize by risk: R01, R03, R04, R05 first (release gate). Defer exploratory edge cases (R02, R06) if gate passes and timeline is tight. Developers own unit tests to reduce QA load. Pre-write all test cases by day 3. | QA |
| 9 | PR03 | PayGate sandbox unplanned outage on a test day | Project | 2 | 4 | 8 | 🟠 **HIGH** | Coordinate with PayGate ops; request advance notice of maintenance. Pivot to mock/staging if outage >4 hours. Document findings and re-test on next sandbox day. | QA |

---

## 6. Test Approach

### Test Levels and Independence

| Level | What We Test | Who | Independence | Why This Degree |
| :--- | :--- | :--- | :--- | :--- |
| **Unit** | Split-amount calculation, remainder logic, refund error handling, edge cases | Developers | None | Speed and efficiency; developers know intent; code-level defects caught fast |
| **Integration** | Split-payment charge calls to PayGate API; charge + refund flow; database state | Dev + QA pair | Some | Developers know API contract; QA brings fresh perspective on edge flows |
| **System** | End-to-end split payment (UI form → validation → charge → confirmation); decline + refund; single-card regression | QA | High | Independent of development; can challenge UI/UX assumptions; focused on user impact |
| **Acceptance** | Feature meets acceptance criteria; business rules validated; release approval | Product Owner | Very high | External stakeholder validates business requirement is met before release |

### Test Types

1. **Functional Testing** (majority): split calculation, charge execution, refund flow, error messages
2. **Boundary Value Analysis**: amounts at edges ($0.01, amounts with remainder cents, maximum order value)
3. **Decision Table Testing**: split rules (e.g., $100 = $60/$40, $100 = $33.33 → $33.34/$66.66 remainder)
4. **State Transition Testing**: order states (pending charge → charged → refunded on decline)
5. **Error Guessing / Exploratory Testing**: edge cases (network timeouts, duplicate charges, race conditions)

### Test Pyramid (Payment System, Backend-Heavy)
- **60% Unit**: split logic, remainder, refund error paths, PayGate mock scenarios (developers + QA review)
- **30% Integration**: real PayGate API calls (sandbox Tue/Thu), charge + refund workflows, transaction consistency
- **10% System E2E**: happy path and decline-refund flow through UI to confirmation

### Test Techniques per Requirement

| Requirement | Technique | Coverage |
| :--- | :--- | :--- |
| Split amount correctly | Decision table + boundary value | $1–$9,999 with even and remainder cents |
| Remainder cent to first card | Equivalence partition + decision table | All splits with $0.01–$0.99 remainder |
| Charge both cards via PayGate | State transition + error guessing | Successful charge, second-charge decline, timeout, duplicate-prevention |
| Refund within 60 seconds | Timer assertion + exploratory | Refund initiated <60s from decline notification |
| Single-card checkout still works | Regression + smoke | 4 existing test cases + 1 new smoke case |

### Deliverables

1. **Test Cases** (system and acceptance level)
   - Release-gate cases (ID, what it proves, expected result)
   - Analysis cases (edge splits, error flows, exploratory scenarios)
2. **Release-Gate Results** (pass/fail, environment build, owner)
3. **Regression Suite Results** (single-card checkout cases)
4. **Defect Log** (ID, severity, reproducibility, PayGate involvement, owner)
5. **Test Completion Report** (summary, exit criteria met, unmitigated risks, lessons learned)

### Entry Criteria (System-Level Testing)

- [ ] Feature code merged to main, builds without errors
- [ ] PayGate API mock / sandbox confirmed accessible
- [ ] Test data (customer accounts, test card tokens) seeded in test environment
- [ ] Checkout UI has `data-testid` for amount-input, card-select, split-review fields
- [ ] Developers have completed unit and integration testing with >80% code coverage
- [ ] Single-card checkout regression suite passes on main

### Exit Criteria (Release Gate & Regression)

- [ ] **Release gate**: all 6 gate cases pass (see table below)
- [ ] **Regression**: single-card checkout 4 cases all pass
- [ ] **Critical defects**: zero open; all P0 findings resolved or accepted by Product Owner
- [ ] **High defects**: zero open, or each has a documented Product Owner exception
- [ ] **Refund timer**: refund confirmed <60s in sandbox E2E test (at least once on Tue/Thu)
- [ ] **Test completion report** signed off by QA and Product Owner

### Release Gate (6 Cases — Minimum Proof)

The gate answers: "Does split payment work? Is single-card checkout broken?"

| # | Gate Case ID | What It Proves | Pass/Fail | Environment Build | Owner |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | GC-001 | $100.00 split as $60.00 / $40.00, both charges succeed | TBD | TBD | QA |
| 2 | GC-002 | $100.01 split as $60.01 / $40.00 (remainder to card 1) | TBD | TBD | QA |
| 3 | GC-003 | Second card declined; first refunded within 60 seconds | TBD | TBD | QA |
| 4 | GC-004 | Decline + refund error handling (e.g., refund API fails) shows user message, escalates | TBD | TBD | QA |
| 5 | GC-005 | Single-card checkout (existing flow) succeeds (regression) | TBD | TBD | QA |
| 6 | GC-006 | Smoke: split payment visible in order history and billing | TBD | TBD | QA |

---

## 7. Estimate

### Technique: Three-Point Estimation

**Task breakdown:**
- Test case design (6 gate cases + 12 analysis cases): 5 hours
- Automation of gate + regression (mocking PayGate): 6 hours
- Sandbox E2E testing (Tue/Thu only): 4 hours
- Manual exploratory testing (remainder logic, error flows): 5 hours
- Defect retesting and sign-off: 3 hours
- **Total**: optimistic = 15 hrs, most likely = 23 hrs, pessimistic = 36 hrs

**Calculation:**
- E = (15 + 4×23 + 36) / 6 = 157 / 6 = **26 hours**
- SD = (36 − 15) / 6 = 3.5 hours
- **Estimate: 26 ± 3.5 hours (range: 22.5–29.5 hours)**

### Confidence Level
**Medium** — new feature with external API dependency, tight timeline, limited sandbox window, but small scope (one feature, clear spec).

### Available Capacity
- QA: 0.5 FTE × 20 hrs/week × 2 weeks = **40 person-hours**
- Headroom: 40 − 26 = 14 hours (buffer for retesting, blockers)
- **Timeline fit: feasible**

### Effort Allocation
- Risk R01, R03, R04 (split logic, refund, errors): 18 hours (highest priority)
- Risk R05, R02 (regression, remainder): 8 hours
- Buffer and exploratory: 14 hours

---

## 8. Budget and Schedule

### Timeline (10 Working Days, ~2026-10-18 to ~2026-10-30)

| Phase | Dates | Deliverables | Notes |
| :--- | :--- | :--- | :--- |
| **Design & Prep** | Days 1–3 (Tue–Thu) | Test cases, mock PayGate setup, test data | Parallel with dev; use Tue/Thu for sandbox smoke-test access |
| **Early Testing** | Days 4–5 (Fri–Mon) | Unit/integration test results (dev-led); mock-based E2E of split + decline | Developers run unit tests; QA reviews and designs system cases |
| **Sandbox Testing** | Days 6–7 (Tue–Wed) | Real PayGate sandbox: decline + refund flow, timer validation, edge splits | Reserve Tue/Thu for PayGate availability; Mon/Wed use mocks |
| **Regression & Gate** | Days 8–9 (Thu–Fri) | Single-card regression 4 cases pass; gate 6 cases all pass or defects logged | QA executes gate; Product Owner spot-checks |
| **Completion & Sign-Off** | Day 10 (Mon) | Defect retesting, test completion report, release recommendation | Release gate all pass, no open Critical, PO approval |

### Sandbox Availability Fit
- **Tue/Thu only**: Days 1 (Tue), 3 (Thu), 6 (Tue), 7 (Wed—defer if no Tue access), 8 (Thu). **4 sandbox test days available.**
- Workaround: Days 2, 4, 5, 9 use mocked PayGate for split + decline logic; Tue/Thu confirm with real sandbox.

### Resource Allocation
- **QA (0.5 FTE, ~20 hrs/week)**:
  - Week 1: 5 hrs test case design, 15 hrs execution (early tests + sandbox Day 1)
  - Week 2: 8 hrs sandbox + regression (Days 6–8), 12 hrs completion + retesting (Days 9–10)
- **Developers**: unit/integration testing; QA reviews findings.
- **Product Owner**: 2 hrs acceptance sign-off (days 9–10).

### Budget
Assuming fully-loaded rates ($150/hr for QA):
- QA effort: 26 hours × $150 = **$3,900** (estimate + retesting)
- Developers unit/integration: estimated 15 hrs × $200 = **$3,000** (outside this plan, included for awareness)
- **Total QA-led testing cost: ~$4,000**

---

## 9. Test Data and Environment

### Environment
- **Test system**: pre-production parity, checkout flow mirrors production
- **PayGate sandbox**: available Tue/Thu; test cards provided by PayGate (e.g., decline card: 4000000000000002)
- **Database**: test database with rollback capability between test runs

### Test Data Fixture Set

| Fixture | Records | State | Scope | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Customer account** | `test-cust-001` | Active, verified | Read + write balance | Used for all split-payment tests |
| **Test cards** | `Card-A (Visa)`, `Card-B (Mastercard)` | Valid tokens on file | Read tokens only | Provided by PayGate sandbox docs |
| **Decline card** | `Card-Decline (test 4000000000000002)` | Will fail charge | Write (test second-card decline) | PayGate sandbox standard |
| **Orders** | `ORD-split-001` through `ORD-split-006` | Draft (pending charge) | Write and rollback | One per gate case; recreate between runs |

### Preconditions
- Customer logged in and both cards on file
- Order total known and stable ($100, $100.01, etc.)
- PayGate sandbox accessible (confirm with curl before each session)

---

## 10. Configuration Management of Testware

### Versioning and Tracking
- **Test cases**: version-controlled in repo under `/tests/split-payment/`, tagged by release (e.g., `v5.3-gate`, `v5.3-analysis`)
- **Test results**: logged in release ticket with build SHA, test-environment version, timestamp
- **Defects**: tracked in issue tracker (ADO/JIRA), linked to test case ID and gate status
- **Testware baseline**: snapshot of test cases + known-good mock PayGate responses at release start; used to restore if defect is reopened

### Traceability
- Each test case links to one risk (R01–R09) and one feature requirement (split, refund, regression)
- Defect log links defects back to test case and risk
- Release-gate results form the configuration item "approved for release"

---

## 11. Roles and Independence

| Activity | Role | Independence | Rationale |
| :--- | :--- | :--- | :--- |
| **Test design (system level)** | QA Lead | High | Independent of development; challenges spec feasibility |
| **Unit + integration test** | Developers | None | Authors know intent; efficient catch of code-level bugs |
| **Code review (unit tests)** | QA (spot-check) | Some | QA ensures test coverage of risky paths |
| **System E2E testing** | QA Analyst | High | Independent execution; fresh perspective on user flows |
| **Acceptance testing** | Product Owner | Very high | External validation that business rules are met |
| **Release decision** | QA + PO | N/A | Joint sign-off; neither unilateral |

---

## 12. Metrics to Collect and Monitor

### Test Progress
- Cases designed / cases executed / cases passed / cases failed / cases blocked
- Daily count; plot against 10-day timeline to spot gaps

### Defect Metrics
- Defects found by severity (Critical, High, Medium, Low)
- Defects found by risk (which risks surfaced defects?)
- Defects fixed vs. deferred to next release
- Defect density: total defects ÷ risk cases executed

### Coverage
- Risk register coverage: how many risks have at least one passing test case?
- Requirement coverage: all feature requirements tested?
- Code coverage: >80% target for split + refund logic (developers report)

### Risk Status
- Residual risk: re-score register weekly as mitigations progress
- Unmitigated risks: any R03 or R04 without a passing test case blocks release

### Resource & Timeline
- Estimated hours remaining vs. actual hours spent
- Days until release vs. gate completeness
- Sandbox availability: days used / days available (target ≥3 of 4)

---

## 13. Deviations from Standard Test Policy

- **Limited sandbox window (Tue/Thu only)**: Use PayGate mocks Mon/Wed/Fri for non-sandbox tests; accept that some decline scenarios are tested only once on sandbox before release.
- **Part-time QA (0.5 FTE)**: Prioritize release-gate cases (R01, R03, R04) over exploratory edge cases (R02, R06) if timeline slips.
- **No separate UAT phase**: Product Owner acceptance is concurrent with QA system testing (days 8–10).
- **Short timeline**: Design and early testing overlap (parallel dev + QA); accept higher retesting cost if defects surface late.

---

## 14. Communication Plan (Reporting)

### Daily (Async)
- Slack standup: sandbox availability, blockers, cases run today

### Weekly (Thu, 10:00 AM)
- Release-gate status: how many cases pass, any new blockers
- Defect summary: count by severity, any Critical findings
- Risk re-score: has any risk level changed?

### End of Release (Day 10)
- **Test Completion Report** (Markdown, in release ticket):
  - Release-gate: all 6 cases pass ✓ or list failures
  - Regression: single-card 4 cases pass ✓
  - Defects: critical = 0, high = 0 (or exceptions documented)
  - Residual risks: any unmitigated (R03, R04 must pass before release)
  - Lessons learned: sandbox window, part-time capacity, scope creep observations
  - Sign-off: "QA approved for release" + date, "PO approved" + date

---

## 15. Not Run — Resume Point

If testing is interrupted (e.g., sandbox outage, blocker found late), resume from:
1. **Release-gate completion**: finish gate cases before analysis cases
2. **Sandbox test day**: if Tue/Thu is skipped, resume on next available sandbox day
3. **Blocker**: document blocker, attempt workaround (e.g., manual PayGate test if API mock fails), escalate to dev lead if unresolved by EOD

---

**End of Test Plan**
