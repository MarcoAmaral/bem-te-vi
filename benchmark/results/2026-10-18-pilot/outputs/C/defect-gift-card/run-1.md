---
title: Gift card application fails intermittently in EUR checkout
slug: gift-card-application-fails-intermittently-eur-checkout
article_type: troubleshooting
product_area: Checkout
audience: Developer, QA
plan_availability: None: this is an internal defect report
reading_time: 2 min
related_articles: None: internal only
last_updated: 2026-10-18
---

# Gift card application fails intermittently in EUR checkout

Gift card application on the EUR store returns a 500 error and fails to deduct the gift card balance from the order total, though the same test run shows 7 of 10 passes on the same build.

## Environment and reproduction

**Build:** 4.12.0-rc.2 (commit 9f3c2ab)  
**Browser:** Chromium 129.0.6668.29, Playwright 1.48.1, Ubuntu 22.04 runner  
**Test:** `checkout.spec.ts > gift card > applies a gift card to an order in EUR`  
**Frequency:** 3 of 10 attempts failed on 2026-10-14 06:12 UTC (pipeline e2e-staging #3318)

**Steps:**
1. Sign in as `buyer.eur@shop.example` (EUR store)
2. Add "Desk Lamp" (€49.00) to cart and open checkout
3. Enter gift card `GC-TEST-0042` (balance €20.00) and select **Apply**

**Expected:** Order summary displays "Gift card: −€20.00" and total updates to €29.00

**Actual:** Toast shows "Something went wrong. Please try again." and total remains €49.00

## Root cause

POST `/api/checkout/gift-card` returns HTTP 500 with error: `TypeError: Cannot read properties of undefined (reading 'currency')`

The same test commit passes 70% of the time on identical runner configurations, suggesting a race condition or cache state issue rather than a code logic error.

## Flakiness pattern

Failures occurred on attempts 4, 7, and 9 of 10; all returned the same error. The passing attempts showed the correct order summary with gift card applied. This intermittent pattern and the developer note suggest the currency service cache is not thread-safe or expires during the test run, leaving currency lookups without a value.

## Next steps for diagnosis

Collect:
- Currency service logs for 2026-10-14 06:12–06:20 UTC
- Any cache invalidation or expiry events during that window
- Thread/request IDs from the 3 failed POST calls
- Recent changes to the currency service cache layer (last sprint referenced as problematic)
