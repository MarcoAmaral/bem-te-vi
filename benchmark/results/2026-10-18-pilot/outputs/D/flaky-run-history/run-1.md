## Flaky tests detected

**1. cart > updates the total when the quantity changes**
- **Evidence:** 3 failures in 10 runs (R2, R5, R9); 70% pass rate on c0ffee1
- **Cause class:** Test timing — the test has a hard sleep of 300ms then reads the DOM, but the app needs more time to update the cart total. Missing web-first wait for the expected text.
- **Action:** Fix the test. Replace `page.waitForTimeout(300)` with `await page.getByTestId('cart-total').toHaveText('€58.00')`.

**2. search > filters results by tag**
- **Evidence:** 4 failures in 10 runs (R2, R4, R7, R10); 60% pass rate on c0ffee1. Repeat test alone: `npx playwright test search.spec.ts --workers=1 --repeat-each=20` passed 20/20.
- **Cause class:** Order or shared state — the test passes in isolation, fails in the suite. The shared tag "summer" is renamed during tags.spec.ts execution, polluting the data for subsequent tests.
- **Action:** Fix test isolation. Add test setup to create a unique, scoped tag or reset tags.spec.ts to clean up after itself.

**3. orders > shows the latest order first**
- **Evidence:** 2 failures in 10 runs (R3, R8); 80% pass rate on c0ffee1. Repeat test alone with `--repeat-each=50`, new user per run, web-first assertions: failed 3/50 (6% failure rate). In those runs, GET /orders returned the list without the new order for up to 2 seconds post-creation.
- **Cause class:** Product intermittent defect — the backend has eventual consistency delay. The order is not visible in the list endpoint for 1–2 seconds after POST /orders returns. This is not a test issue.
- **Action:** File `/qa-defect` report against the backend: order list API does not reflect newly created orders for up to 2 seconds post-creation; observed 3/50 failures with real users and proper waits. Recommend the product team add a write-through cache or client-side optimistic update. Quarantine the test to avoid false CI failures while the backend is fixed.

---

## Deterministic failure

**profile > saves a new avatar**
- **Evidence:** 10 failures in 10 runs; 0% pass rate on c0ffee1
- **Failure:** `expect(received).toBe(expected). Expected: "avatar.png". Received: undefined.`
- **Status:** Not flaky; consistent defect. The avatar file path or upload endpoint is broken.
- **Action:** File `/qa-defect` report against the feature. This test should not be quarantined; it should remain in the suite to catch the regression.

---

## Passing

**login > signs in with valid credentials**
- **Evidence:** 10/10 passes; no flakiness detected.
- **Action:** No action needed.

---

## Proposed ledger entries

| Test ID | Cause class | Defect report | Owner | Quarantined on | Deadline | Status |
| --- | --- | --- | --- | --- | --- | --- |
| cart > updates the total when the quantity changes | Test timing | — | <team> | 2026-10-18 | 2026-11-01 | @flaky → fix test |
| search > filters results by tag | Order or shared state | — | <team> | 2026-10-18 | 2026-11-01 | @flaky → fix isolation |
| orders > shows the latest order first | Product intermittent defect | <defect-id> | <backend-team> | 2026-10-18 | 2026-11-01 | @quarantine pending defect fix |

**Assumptions:** Quarantine deadline is 14 days (two-week sprint); team is undeclared. Share: 3/120 tests = 2.5% quarantined. Escalation threshold not stated in the rule provided; cannot flag escalation.

**Not in the history:** Prior runs of these tests, Playwright trace files, or environment state (cache, database resets). A repeat run of `cart > updates the total` under the same CI conditions would confirm whether the issue is a consistent race or variance in test execution order.
