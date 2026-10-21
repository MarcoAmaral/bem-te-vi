---
title: E2e tests are failing intermittently in CI
slug: e2e-tests-failing-intermittently-ci
article_type: troubleshooting
product_area: Testing
audience: Test Engineer, Development Team
plan_availability: All teams
reading_time: 5 min
related_articles: [test-isolation-in-parallel-execution, playwright-wait-for-element, database-consistency-in-tests]
last_updated: 2026-10-18
---

# E2e tests are failing intermittently in CI

Out of 5 test cases in your e2e suite, 3 are flaky (passing and failing randomly on the same commit) and 1 is consistently broken. The stable test suite passes reliably. Fix the flaky tests in order of failure rate.

## Test isolation: "search > filters results by tag" (40% failure rate)

This test fails 4 out of 10 runs in parallel mode but passes every time when run alone.

**Cause:** The test uses the seeded tag "summer" to filter results. The `tags.spec.ts` suite renames "summer" during its own run. In parallel mode, `tags.spec.ts` sometimes completes its rename before this test reads the tag, so the search returns 5 results instead of the expected 3.

**Fix:**

1. Give this test its own unique tag name (for example, a UUID or a timestamp) instead of using a seeded tag.
2. Alternatively, create the tag inside this test's setup so no other test can modify it.

Verify the fix by running `npx playwright test search.spec.ts --workers=1 --repeat-each=20`. It should pass all 20 times.

## Race condition on frontend: "cart > updates the total when the quantity changes" (30% failure rate)

This test clicks the "+" button, waits 300ms, and reads the cart total. The timeout fires before the total updates.

**Cause:** 300ms is not long enough. The cart-total DOM update takes longer in some runs due to browser rendering delays, CI resource contention, or network lag. A fixed wait is unreliable.

**Fix:**

Replace `page.waitForTimeout(300)` with Playwright's web-first assertion:

```javascript
await expect(page.getByTestId('cart-total')).toContainText('€58.00');
```

Playwright waits for the element to match the assertion (up to the default 5-second timeout) before moving forward.

## Race condition on backend: "orders > shows the latest order first" (20% failure rate)

This test creates an order and immediately checks for it in the order list. It fails when the new order is not returned for up to 2 seconds after creation.

**Cause:** The order-creation endpoint returns before the database write fully commits or replicates. The test queries the list before the database is consistent.

**Fix:**

After creating the order, poll the order list until the new order appears:

```javascript
await page.waitForFunction(
  async () => {
    const response = await page.request.get('/api/orders');
    const orders = await response.json();
    return orders.some(o => o.id === newOrderId);
  },
  {timeout: 5000}
);
```

## Broken test (not flaky): "profile > saves a new avatar" (100% failure rate)

This test fails the same way every time: the avatar filename is undefined instead of "avatar.png". This is not a flaky test; the feature or the test setup is broken.

**Recommendation:**

Check that the avatar file is properly seeded in the test setup, or file a bug for the avatar-upload feature. This is not a test-suite parallelization issue. Fix the bug, then re-run the test.

## Stable test: "login > signs in with valid credentials" (0% failure rate)

This test always passes. No changes needed.

---

**Assumption:** "plan_availability" applies to internal test infrastructure; shown as "All teams".
