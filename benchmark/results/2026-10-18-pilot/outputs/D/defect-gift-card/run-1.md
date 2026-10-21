─────────────────────────────────────────────────────────
DEFECT REPORT
─────────────────────────────────────────────────────────
Defect ID      : DR-SHOP-0318
Title          : Checkout – Gift card fails to apply with 500 error when applying gift card in EUR store
Reported By    : CI e2e-staging pipeline #3318
Reporter Role  : Automated E2E test execution, staging validation
Date Reported  : 2026-10-14
Assigned To    : Backend / Checkout team

─── Classification ──────────────────────────────────────
Severity       : ☒ High  □ Critical  □ Medium  □ Low
Priority       : ☒ P2 (High)  □ P1 (Immediate)  □ P3 (Medium)  □ P4 (Low)
Status         : ☒ New  □ Assigned  □ Open  □ Deferred  □ Duplicate  □ Fixed  □ Retest  □ Closed  □ Rejected  □ Reopened
Type           : ☒ Functional  ☒ Integration  □ UI  □ Performance  □ Security  □ Data

─── Environment ─────────────────────────────────────────
Application    : Shop v4.12.0-rc.2 (Release candidate)
Environment    : ☒ Staging  □ Local  □ Dev  □ Production
OS / Browser   : Ubuntu 22.04 LTS / Chromium 129.0.6668.29 (Playwright 1.48.1)
Build / Commit : 4.12.0-rc.2 (commit 9f3c2ab)
Issue          : N/A — issue not yet created

─── Context ─────────────────────────────────────────────
Test Case      : checkout.spec.ts > gift card > applies a gift card to an order in EUR
Test Activity  : E2E regression test execution (--repeat-each=10)
SDLC Phase     : Release candidate testing, pre-production validation
Technique      : Functional test, happy-path scenario with gift card
Test Data Used : Test user: buyer.eur@shop.example (EUR store); Gift card: GC-TEST-0042 (balance €20.00); Product: Desk Lamp (€49.00)

─── Reproduction ────────────────────────────────────────
Pre-conditions :
  1. User is signed in as buyer.eur@shop.example in a EUR currency store context
  2. Shopping cart contains "Desk Lamp" item priced at €49.00
  3. Checkout page is open and ready for payment configuration
  4. Gift card GC-TEST-0042 (balance €20.00) exists in test data

Steps to Reproduce :
  1. Navigate to checkout with items in cart
  2. Locate the gift card input field on the order summary
  3. Enter gift card code "GC-TEST-0042" 
  4. Click "Apply" button

Expected Result :
  Order summary is updated to show "Gift card: -€20.00" as a line item. Order total recalculates to €29.00 (€49.00 − €20.00).

Actual Result :
  A toast notification displays: "Something went wrong. Please try again."
  Order total remains at €49.00 (discount not applied).
  Network error logged: POST /api/checkout/gift-card returns HTTP 500
  Response body: `{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}`

Reproducibility : ☒ Intermittent (3/10 attempts)

─── Evidence ────────────────────────────────────────────
Attachments    : ☒ Network log (HTTP 500 response with error trace)
Link/Path      : CI log artifact: e2e-staging #3318, test output (attempts 4, 7, 9 failures); 7 passing attempts confirm intermittency

─── Analysis ────────────────────────────────────────────
Defect Location : Backend API endpoint POST /api/checkout/gift-card; null-check missing on currency object before property access
Root Cause     : Suspected currency service cache stale state or race condition; developer note indicates previous sprint flakiness in same component

─── Resolution ──────────────────────────────────────────
Fix Applied    : N/A — not yet fixed
Fixed In Build : N/A — pending
Verified By    : N/A — pending
Verified On    : N/A — pending

─── Linked Items ────────────────────────────────────────
Issue / Bug    : N/A — create issue in tracker
Related Defects: Suspected related to sprint prior flakiness in currency service caching (developer note)
Test Case      : checkout.spec.ts::gift card::applies a gift card to an order in EUR
─────────────────────────────────────────────────────────

**Retest Criteria (once fix applied):**
1. Run gift card application flow 15 times with --repeat-each in EUR store; confirm all attempts pass
2. Verify order summary displays correct discount and total
3. Regression: test gift card application in additional currency stores (GBP, USD) to confirm fix is currency-agnostic
4. Monitor POST /api/checkout/gift-card response time; confirm no increased latency from cache invalidation strategy
