# CI Test Flakiness Analysis

## Summary
- **1 consistently failing test** (100% failure rate) → fix or remove
- **3 intermittently flaky tests** (20–40% failure rate) → fix root causes
- **1 stable test** → no action needed

---

## Tests Requiring Action

### 🔴 profile > saves a new avatar
**Status:** Consistently failing (10/10 failures)  
**Failure:** Avatar value is undefined when expected "avatar.png"

**Diagnosis:** Not flaky—persistently broken. Either the upload mechanism is non-functional, the selector is incorrect, or a dependency (e.g., file server, image processing) is down.

**Recommended action:** 
- Triage immediately; this blocks the avatar feature. Check backend upload logs and verify the test's selector matches current DOM.
- If unfixable short-term, disable the test and create a blocking bug ticket.

---

### 🟡 cart > updates the total when the quantity changes
**Status:** Intermittently failing (3/10 failures, 30% rate)  
**Failure:** Cart total doesn't update within 5000ms; test waits only 300ms after click before reading

**Diagnosis:** Race condition in test timing. The test issues a click, waits a hard-coded 300ms, then checks the DOM. The calculation sometimes takes longer than 300ms.

**Recommended action:**
- Replace the fixed `waitForTimeout(300)` with `page.waitForSelector('[data-testid="cart-total"]:has-text("€58.00")')` or Playwright's web-first assertion.
- If the backend truly needs >300ms, fix the performance issue; otherwise, eliminate the polling-style assertion.

---

### 🟡 search > filters results by tag
**Status:** Intermittently failing (4/10 failures, 40% rate)  
**Failure:** Expects 3 results; receives 5. Passes reliably in isolation (20/20 alone).

**Diagnosis:** Test isolation failure. The `tags.spec.ts` test suite renames the seeded "summer" tag during its own run. This test's results depend on test execution order.

**Recommended action:**
- Move tag seeding into a per-test fixture (e.g., beforeEach) instead of relying on a shared "summer" tag.
- Or: Run tag-related tests serially (use `.serial()` annotation if available).
- Verify CI config: with 4 workers, multiple specs run concurrently and collide on shared test data.

---

### 🟡 orders > shows the latest order first
**Status:** Intermittently failing (2/10 failures, 20% rate)  
**Failure:** New order doesn't appear in GET /orders until 2 seconds after creation.

**Diagnosis:** Backend write-read lag, likely replication delay between order write and the read replica. Rare but reproducible: 3/50 in a focused run.

**Recommended action:**
- Add polling/retry logic: after creating an order, loop `GET /orders` with exponential backoff until the new order appears (max 3–5 sec).
- If this is unacceptable, fix the backend: ensure reads query the write replica immediately, or add an explicit consistency wait.
- Assumption: The order creation returns a success response, but the order list endpoint lags. If that's backwards, the bug is in order creation, not the test.

---

## No Action Needed

### ✅ login > signs in with valid credentials
**Status:** Stable (10/10 passes)  
No action required.
