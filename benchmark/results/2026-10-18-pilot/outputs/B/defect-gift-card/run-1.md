# Defect Report: Gift Card Application Fails with Currency Service Error (EUR Store)

## Summary
Gift card application in EUR store checkout fails intermittently with a 500 API error and currency service exception, preventing users from applying valid gift cards to their orders.

## Environment
- **Build Version:** 4.12.0-rc.2 (commit 9f3c2ab)
- **Test Environment:** staging.shop.example
- **Browser:** Chromium 129.0.6668.29
- **Test Framework:** Playwright 1.48.1
- **OS:** Ubuntu 22.04
- **Test Suite:** checkout.spec.ts

## Severity
**High** – Payment/checkout functionality affected; users unable to apply promotional/stored value during order completion.

## Reproducibility
**Flaky** – Non-deterministic; 3 of 10 repeated attempts failed (30% failure rate) on the same build and commit.

## Steps to Reproduce
1. Sign in to EUR store account (buyer.eur@shop.example)
2. Add "Desk Lamp" (EUR 49.00) to cart
3. Proceed to checkout
4. Enter gift card code GC-TEST-0042 (balance: EUR 20.00)
5. Click "Apply"

## Expected Result
- Order summary displays: "Gift card: -€20.00"
- Order total updates to: €29.00
- Toast notification confirms successful application

## Actual Result
- Toast message displays: "Something went wrong. Please try again."
- Order total remains: €49.00
- Gift card is not applied
- API returns HTTP 500 error

## Technical Details
**Failing Endpoint:** `POST /api/checkout/gift-card`  
**HTTP Status:** 500  
**Error Response:**
```json
{
  "error": "TypeError: Cannot read properties of undefined (reading 'currency')"
}
```

**Root Cause (Suspected):** Null/undefined reference in currency service when reading the `currency` property. The exception occurs server-side during gift card validation, likely when attempting to validate the gift card against the store's currency configuration.

## Affected Attempts
- Failed: Attempts 4, 7, 9
- Passed: Attempts 1, 2, 3, 5, 6, 8, 10

## Additional Notes
- **Cache-related issue suspected:** Developer indicated this mirrors a previously reported flaky issue with the currency service cache from the prior sprint
- **Intermittent nature suggests:** Race condition, cache inconsistency, or timing-dependent initialization of currency configuration service
- **Scope:** Issue observed specifically in EUR store; other currency stores should be tested to determine if limited to EUR or broader currency handling

## Recommendations for Investigation
1. Review currency service cache initialization logic and TTL settings
2. Check for race conditions in gift card validation when currency service is being populated/refreshed
3. Verify that currency configuration is always initialized before gift card endpoint is accessible
4. Consider adding defensive null-checking or optional chaining in currency property access
5. Increase cache reliability or implement fallback mechanisms

## Test Data References
- **Test User:** buyer.eur@shop.example
- **Test Gift Card:** GC-TEST-0042 (EUR 20.00)
- **Test Product:** Desk Lamp (EUR 49.00)
- **CI Run ID:** e2e-staging #3318
- **Run Timestamp:** 2026-10-14 06:12 UTC
