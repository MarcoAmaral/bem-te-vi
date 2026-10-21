---
feature: Shipping Fee Calculation at Checkout
feature_code: SHIP
tc_count: 7
tracker_issues: [SHIP-9]
risk_level: HIGH
runbook: N/A — shipping calculation is integrated into checkout flow
implementation_pack: N/A — not a separate implementation
spec: N/A — web checkout module
last_updated: 2026-10-18
---

# Test Cases — Shipping Fee Calculation at Checkout

| Field                | Value                                      |
| -------------------- | ------------------------------------------ |
| **Project**          | E-Commerce Platform                        |
| **Author**           | QA Analyst — Senior QA Analyst             |
| **Date Created**     | 2026-10-18                                 |
| **Last Updated**     | 2026-10-18                                 |
| **Methodology**      | ISTQB CTFL v4.0 — EP, BVA, Decision Table  |

---

## TC-SHIP-001: Standard shipping — non-member, subtotal below $50

| Field                  | Value                                                                                      |
| ---------------------- | ------------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @e2e @shipping @candidate`                                                     |
| **Issue**              | [SHIP-9](https://example.com/issues/SHIP-9)                                               |
| **Automation Score**   | HIGH (64/67.5)                                                                             |
| **ISTQB Technique**    | EP — valid partition (non-member, subtotal < $50); BVA — $49.99 (just below threshold)    |
| **Manual Env**         | Staging                                                                                    |
| **Precondition**       | Non-member user is logged in; cart contains items totaling $49.99 subtotal; checkout page loads |
| **Steps**              | 1. Navigate to checkout review page <br> 2. Locate shipping method selector <br> 3. Select or verify "Standard Shipping" is shown                                                  |
| **Expected**           | Standard shipping fee displays as "$5.99" next to "Standard Shipping" label; checkout total reflects this amount; no discount is applied                                                                                                    |
| **data-testid needed** | `shipping-method-standard`, `shipping-fee-amount`, `checkout-total`                        |
| **Source**             | AC-1                                                                                       |
| **Note**               | Assumption: subtotal shown does not include tax, shipping, or other fees; currency is USD; prices display with exactly 2 decimal places |

---

## TC-SHIP-002: Standard shipping — non-member, subtotal at $50.00 boundary

| Field                  | Value                                                                                  |
| ---------------------- | -------------------------------------------------------------------------------------- |
| **Tags**               | `@sanity @p0 @e2e @shipping @candidate`                                                |
| **Issue**              | [SHIP-9](https://example.com/issues/SHIP-9)                                            |
| **Automation Score**   | HIGH (65/67.5)                                                                         |
| **ISTQB Technique**    | BVA — boundary value ($50.00 exactly); three-value BVA (min value for free shipping)   |
| **Manual Env**         | Staging                                                                                |
| **Precondition**       | Non-member user is logged in; cart contains items totaling exactly $50.00 subtotal    |
| **Steps**              | 1. Navigate to checkout review page <br> 2. Verify subtotal displays as "$50.00" <br> 3. Observe standard shipping fee |
| **Expected**           | Standard shipping displays as "Free" or "$0.00"; checkout total equals subtotal with no shipping charge added                                           |
| **data-testid needed** | `shipping-fee-amount`, `checkout-subtotal`, `checkout-total`                           |
| **Source**             | AC-1                                                                                   |
| **Note**               | This is the boundary condition; off-by-one errors are common (e.g., showing $5.99 when subtotal is exactly $50) |

---

## TC-SHIP-003: Standard shipping — non-member, subtotal above $50

| Field                  | Value                                                                                       |
| ---------------------- | ------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @shipping @candidate`                                                      |
| **Issue**              | [SHIP-9](https://example.com/issues/SHIP-9)                                                |
| **Automation Score**   | HIGH (64/67.5)                                                                              |
| **ISTQB Technique**    | EP — valid partition (non-member, subtotal ≥ $50); BVA — $50.01 (just above threshold)     |
| **Manual Env**         | Staging                                                                                     |
| **Precondition**       | Non-member user is logged in; cart contains items totaling $75.00 subtotal; checkout page loads |
| **Steps**              | 1. Navigate to checkout review page <br> 2. Locate shipping method selector <br> 3. Verify "Standard Shipping" is displayed             |
| **Expected**           | Standard shipping displays as "Free" or "$0.00"; checkout total equals subtotal with no shipping fee; "Free standard shipping" message may be shown |
| **data-testid needed** | `shipping-method-standard`, `shipping-fee-amount`, `checkout-total`                         |
| **Source**             | AC-1                                                                                        |
| **Note**               | Assumption: the $50 threshold applies to subtotal before tax and shipping; any promotional discounts are applied first |

---

## TC-SHIP-004: Standard shipping — member, any subtotal

| Field                  | Value                                                                                  |
| ---------------------- | -------------------------------------------------------------------------------------- |
| **Tags**               | `@sanity @p0 @e2e @shipping @candidate`                                                |
| **Issue**              | [SHIP-9](https://example.com/issues/SHIP-9)                                            |
| **Automation Score**   | HIGH (63/67.5)                                                                         |
| **ISTQB Technique**    | EP — valid partition (member status overrides subtotal rule); Decision Table — member flag = T |
| **Manual Env**         | Staging                                                                                |
| **Precondition**       | Member user is logged in and membership status is active; cart contains items totaling $25.00 subtotal (below threshold) |
| **Steps**              | 1. Navigate to checkout review page <br> 2. Verify user's membership badge or status indicator <br> 3. Locate standard shipping fee      |
| **Expected**           | Standard shipping displays as "Free" or "$0.00" regardless of subtotal amount; total reflects free shipping; membership benefit messaging may appear |
| **data-testid needed** | `user-membership-status`, `shipping-fee-amount`, `checkout-total`                      |
| **Source**             | AC-2                                                                                   |
| **Note**               | Assumption: membership status is tied to the logged-in user account and is verified server-side; member benefit overrides all subtotal thresholds |

---

## TC-SHIP-005: Express shipping — non-member

| Field                  | Value                                                                                  |
| ---------------------- | -------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @shipping @candidate`                                            |
| **Issue**              | [SHIP-9](https://example.com/issues/SHIP-9)                                            |
| **Automation Score**   | HIGH (62/67.5)                                                                         |
| **ISTQB Technique**    | EP — valid partition (express shipping, non-member); Decision Table — shipping_type = express, is_member = F |
| **Manual Env**         | Staging                                                                                |
| **Precondition**       | Non-member user is logged in; cart contains items with any subtotal; checkout page displays shipping methods |
| **Steps**              | 1. Navigate to checkout review page <br> 2. Locate shipping method selector <br> 3. Select "Express Shipping" option |
| **Expected**           | Express shipping fee displays as "$12.99" next to "Express Shipping" label; checkout total is updated to include this fee; no member discount is applied |
| **data-testid needed** | `shipping-method-express`, `shipping-fee-amount-express`, `checkout-total`             |
| **Source**             | AC-3                                                                                   |
| **Note**               | Assumption: express shipping is always available as an option; the $12.99 fee is fixed and does not vary by subtotal or region |

---

## TC-SHIP-006: Express shipping — member

| Field                  | Value                                                                                  |
| ---------------------- | -------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @shipping @candidate`                                            |
| **Issue**              | [SHIP-9](https://example.com/issues/SHIP-9)                                            |
| **Automation Score**   | HIGH (62/67.5)                                                                         |
| **ISTQB Technique**    | EP — valid partition (express shipping, member); Decision Table — shipping_type = express, is_member = T |
| **Manual Env**         | Staging                                                                                |
| **Precondition**       | Member user is logged in and membership status is active; cart contains items with any subtotal; checkout page displays shipping methods |
| **Steps**              | 1. Navigate to checkout review page <br> 2. Locate shipping method selector <br> 3. Select "Express Shipping" option       |
| **Expected**           | Express shipping fee displays as "$7.99" (member discount applied); checkout total is updated with this reduced fee; membership benefit messaging may appear |
| **data-testid needed** | `shipping-method-express`, `shipping-fee-amount-express`, `checkout-total`, `member-discount-badge` |
| **Source**             | AC-3                                                                                   |
| **Note**               | Assumption: member express discount ($7.99 vs $12.99) applies server-side and cannot be bypassed by client-side manipulation |

---

## TC-SHIP-007: Shipping fee updates when cart subtotal crosses threshold

| Field                  | Value                                                                                  |
| ---------------------- | -------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @shipping @candidate`                                            |
| **Issue**              | [SHIP-9](https://example.com/issues/SHIP-9)                                            |
| **Automation Score**   | MEDIUM (48/67.5)                                                                       |
| **ISTQB Technique**    | Added by QA — state change validation (cart update during checkout); error guessing (dynamic cart updates) |
| **Manual Env**         | Staging                                                                                |
| **Precondition**       | Non-member user is logged in; checkout page displays cart with $45.00 subtotal; standard shipping shows "$5.99" |
| **Steps**              | 1. Keep checkout page open <br> 2. Add item to cart from another browser tab or concurrent session (e.g., value $6.00) <br> 3. Refresh checkout or wait for cart to auto-sync <br> 4. Observe shipping fee |
| **Expected**           | Subtotal updates to "$51.00"; standard shipping fee recalculates and displays as "Free" or "$0.00"; checkout total reflects the new amount |
| **data-testid needed** | `checkout-subtotal`, `shipping-fee-amount`, `checkout-total`, `cart-sync-status`      |
| **Source**             | Added by QA (the ticket is silent on cart updates during checkout; this validates the system recalculates correctly) |
| **Note**               | Assumption: cart can be updated concurrently; system correctly syncs cart state before final payment; this is an integration test, not pure calculation |
