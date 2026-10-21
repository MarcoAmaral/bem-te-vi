# Defect Report: Gift Card Application Fails Intermittently with Currency Service Error

**Build:** 4.12.0-rc.2 (commit 9f3c2ab)  
**Date Found:** 2026-10-14 06:12 UTC  
**Pipeline:** e2e-staging #3318  
**Test:** checkout.spec.ts > gift card > applies a gift card to an order in EUR

## Summary
Gift card application in EUR store checkout fails intermittently with a 500 error. The endpoint throws a TypeError when attempting to read the `currency` property of an undefined object. The issue manifests as a "Something went wrong" toast, leaving the order total unapplied. Flakiness is 30% failure rate (3 of 10 repeated attempts on the same commit).

## Steps to Reproduce
1. Sign in as a EUR store user (test: buyer.eur@shop.example)
2. Add an item to cart (e.g., "Desk Lamp" EUR 49.00)
3. Open checkout
4. Enter a valid gift card code (test: GC-TEST-0042, balance EUR 20.00)
5. Click "Apply"

## Expected Result
- Order summary displays the gift card deduction (e.g., "Gift card: -€20.00")
- Order total updates correctly (e.g., EUR 29.00)
- No error toast is shown

## Actual Result
- Toast notification displays: "Something went wrong. Please try again."
- Order total remains unchanged (EUR 49.00)
- API endpoint `/api/checkout/gift-card` returns HTTP 500

## Error Details
**Endpoint:** POST /api/checkout/gift-card  
**HTTP Status:** 500  
**Response Body:**
```json
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

## Frequency
- **Failure Rate:** 30% (3 failures in 10 attempts on same commit, attempts #4, #7, #9)
- **Pattern:** Non-sequential; random distribution across attempts
- **Consistency:** Same error signature across all failures

## Environment
- **Browser:** Chromium 129.0.6668.29
- **Test Framework:** Playwright 1.48.1
- **OS:** Ubuntu 22.04
- **Staging URL:** https://staging.shop.example
- **Currency:** EUR

## Assumptions
- The currency service cache is shared across concurrent test attempts
- The gift card code GC-TEST-0042 exists and has the stated balance in the staging database
- Other passing attempts (#1, 2, 3, 5, 6, 8, 10) confirm the feature is generally functional

## Root Cause (Suspected)
Currency service cache returning undefined or null for EUR currency details, causing the gift card calculation handler to fail when attempting to access the `currency` property. The intermittent nature suggests a race condition or cache invalidation timing issue.

## Recommended Next Steps
1. **Immediate:** Investigate currency service cache initialization and EUR currency fallback logic
2. **Review:** Code path that reads `currency` property in gift card POST handler
3. **Regression Check:** Verify if this issue was present in the last sprint ("flaky last sprint too")
4. **Monitoring:** Add logging around currency service resolution in staging
5. **Consider:** Cache warm-up or initialization guarantee before processing gift card requests

## Priority
High – intermittent failure blocking e2e-staging pipeline for core checkout functionality
