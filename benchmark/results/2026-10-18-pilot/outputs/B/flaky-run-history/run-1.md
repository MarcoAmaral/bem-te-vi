# Flaky Test Analysis Report

## Summary
Of the 5 tests analyzed, 3 are flaky, 1 is consistently broken, and 1 is stable.

---

## Flaky Tests

### 1. cart > updates the total when the quantity changes
**Failure Rate:** 30% (3/10 runs)

**Root Cause:** Race condition. The test waits 300ms after clicking "+", but the DOM update and price calculation can take longer. This is amplified under load (4 workers) and on slower CI machines.

**Recommendation:** Use Playwright's web-first assertion `waitForSelector` or `toHaveText` with the default timeout (30s), or query the element and call `waitFor()` on the assertion. Remove the hardcoded 300ms wait.

```typescript
// Instead of page.waitForTimeout(300)
await expect(page.locator('[data-testid="cart-total"]')).toHaveText("€58.00");
```

---

### 2. search > filters results by tag
**Failure Rate:** 40% (4/10 runs)

**Root Cause:** Test isolation failure under parallel execution. The test depends on a seeded tag "summer" that `tags.spec.ts` deletes or renames during its concurrent run in a different worker. This manifests as 5 results instead of 3 (likely the full unfiltered set).

**Recommendation:** Replace global seed data with per-test isolation:
- Use API fixtures or factories to create isolated test data for each run, or
- Move the tag seed into a setup hook that runs per worker (not globally), or  
- Add a test.describe.configure() with serial execution for tests that share seed data, or
- Namespace seed data per worker (append worker ID to tag name).

Do not rely on `--workers=1` for a permanent fix; the real issue is shared state.

---

### 3. orders > shows the latest order first
**Failure Rate:** 20% (2/10 runs)

**Root Cause:** Backend eventual consistency issue. After the test creates a new order via API, `GET /orders` returns the stale list for up to 2 seconds. This is not a test bug; it's a real system behavior.

**Recommendation:**
- Use web-first assertions with polling: `await expect(ordersList).toContainText("Order #1043", { timeout: 10000 });` to wait for the order to appear.
- Alternatively, add explicit polling in the test: retry the API call until the new order appears, or wait for an event/webhook confirmation that the order is visible.
- Address the backend: investigate why the orders endpoint has a 2-second lag. Consider adding read-your-writes consistency or using a transaction log.

---

## Consistently Broken Test (Not Flaky)

### profile > saves a new avatar
**Failure Rate:** 100% (10/10 runs)

**Root Cause:** The avatar file is not being saved or retrieved. The API/feature returns `undefined` instead of the filename.

**Recommendation:** This is not a flaky test—it's a broken feature or test. Treat as a blocking bug:
1. Check if the avatar upload endpoint returns the filename correctly.
2. Verify the form actually sends the file (network tab inspection).
3. Check backend file storage (permissions, disk space, persistence layer).
4. If the feature is incomplete, unblock the test by mocking the response until the feature is ready, or skip it with a `test.skip()` and link to the tracking issue.

---

## Stable Test

### login > signs in with valid credentials
**Status:** Reliable (10/10 passes)  
**No action needed.**

---

## Recommendations by Priority

1. **Critical:** Fix the `profile > saves a new avatar` feature—it's completely broken.
2. **High:** Fix the `search > filters results by tag` test isolation issue—40% failure rate blocks confidence in the suite.
3. **Medium:** Replace the hardcoded wait in `cart > updates the total` with web-first assertions.
4. **Medium:** Add polling to `orders > shows the latest order first` and investigate backend consistency lag.
