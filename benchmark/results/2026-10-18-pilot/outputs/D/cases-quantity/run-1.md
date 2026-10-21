---
feature: Change Cart Item Quantity
feature_code: CART
tc_count: 8
tracker_issues: [CART-12]
risk_level: HIGH
runbook: N/A — not yet created
implementation_pack: N/A — not yet created
spec: N/A — not yet automated
last_updated: 2026-10-18
---

# Test Cases — Change Cart Item Quantity

| Field                | Value                                                     |
| -------------------- | --------------------------------------------------------- |
| **Project**          | E-commerce Platform                                       |
| **Author**           | QA Analyst — Senior QA Analyst                            |
| **Date Created**      | 2026-10-18                                                |
| **Last Updated**      | 2026-10-18                                                |
| **Methodology**       | ISTQB CTFL v4.0 — EP, BVA, Decision Table, Error Guessing |

**Assumptions:**
- The cart contains at least one item before each test starts
- The quantity field is a text input that accepts numeric entry
- A confirmation dialog ("Remove this item?") appears when quantity is set to 0
- The "previous quantity" refers to the last valid quantity before an invalid input
- The feature is web-based and testable via UI automation
- No maximum cart item count exists beyond the per-item 20-unit limit

---

## TC-CART-001: Change quantity to valid value within range (happy path)

| Field                  | Value                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate`                                                   |
| **Issue**              | [CART-12](https://linear.app/team/issue/CART-12)                                     |
| **Automation Score**   | HIGH (63.5/67.5)                                                                      |
| **ISTQB Technique**    | EP — valid partition (1–20)                                                           |
| **Manual Env**         | Local, Staging                                                                        |
| **Precondition**       | Cart contains 1 item with quantity = 5                                                |
| **Steps**              | 1. Locate the quantity field for the item <br> 2. Clear the field <br> 3. Enter `10` <br> 4. Press Tab or click away <br> 5. Observe the cart total |
| **Expected**           | Quantity field displays `10`. Cart total updates immediately. No error message shown. |
| **data-testid needed** | `cart-item-quantity-input`, `cart-total-price`                                        |
| **Source**             | AC-1                                                                                  |
| **Note**               | N/A — no caveats                                                                      |

---

## TC-CART-002: Change quantity to minimum valid boundary (1)

| Field                  | Value                                                                               |
| ---------------------- | ----------------------------------------------------------------------------------- |
| **Tags**               | `@sanity @p0 @e2e @cart @candidate`                                                 |
| **Issue**              | [CART-12](https://linear.app/team/issue/CART-12)                                   |
| **Automation Score**   | HIGH (63.5/67.5)                                                                    |
| **ISTQB Technique**    | BVA — boundary min (1)                                                              |
| **Manual Env**         | Local, Staging                                                                      |
| **Precondition**       | Cart contains 1 item with quantity = 5                                              |
| **Steps**              | 1. Locate the quantity field <br> 2. Clear and enter `1` <br> 3. Press Tab or click away |
| **Expected**           | Quantity field displays `1`. Cart total updates. No error or removal prompt appears. |
| **data-testid needed** | `cart-item-quantity-input`, `cart-total-price`                                      |
| **Source**             | AC-1                                                                                 |
| **Note**               | N/A — no caveats                                                                    |

---

## TC-CART-003: Change quantity to maximum valid boundary (20)

| Field                  | Value                                                                               |
| ---------------------- | ----------------------------------------------------------------------------------- |
| **Tags**               | `@sanity @p0 @e2e @cart @candidate`                                                 |
| **Issue**              | [CART-12](https://linear.app/team/issue/CART-12)                                   |
| **Automation Score**   | HIGH (63.5/67.5)                                                                    |
| **ISTQB Technique**    | BVA — boundary max (20)                                                             |
| **Manual Env**         | Local, Staging                                                                      |
| **Precondition**       | Cart contains 1 item with quantity = 10                                             |
| **Steps**              | 1. Locate the quantity field <br> 2. Clear and enter `20` <br> 3. Press Tab or click away |
| **Expected**           | Quantity field displays `20`. Cart total updates. No error or removal prompt appears. |
| **data-testid needed** | `cart-item-quantity-input`, `cart-total-price`                                      |
| **Source**             | AC-1                                                                                 |
| **Note**               | N/A — no caveats                                                                    |

---

## TC-CART-004: Set quantity to 0 and confirm removal

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate`                                                                      |
| **Issue**              | [CART-12](https://linear.app/team/issue/CART-12)                                                       |
| **Automation Score**   | HIGH (61/67.5)                                                                                          |
| **ISTQB Technique**    | Decision Table — quantity=0, confirm=true                                                              |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | Cart contains 1 item with quantity = 5                                                                  |
| **Steps**              | 1. Locate the quantity field <br> 2. Clear and enter `0` <br> 3. Press Tab or click away <br> 4. Dialog appears asking "Remove this item?" <br> 5. Click **Confirm** or **Yes** button |
| **Expected**           | Removal confirmation dialog appears. After confirmation, the item is removed from the cart. Cart total updates. Cart count decreases by 1. |
| **data-testid needed** | `cart-item-quantity-input`, `remove-confirmation-dialog`, `remove-confirm-button`, `cart-item-count`   |
| **Source**             | AC-2                                                                                                    |
| **Note**               | N/A — no caveats                                                                                        |

---

## TC-CART-005: Set quantity to 0 and decline removal

| Field                  | Value                                                                                                     |
| ---------------------- | --------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                  |
| **Issue**              | [CART-12](https://linear.app/team/issue/CART-12)                                                         |
| **Automation Score**   | MEDIUM (48/67.5)                                                                                         |
| **ISTQB Technique**    | Decision Table — quantity=0, confirm=false                                                              |
| **Manual Env**         | Local, Staging                                                                                           |
| **Precondition**       | Cart contains 1 item with quantity = 5                                                                   |
| **Steps**              | 1. Locate the quantity field <br> 2. Clear and enter `0` <br> 3. Press Tab or click away <br> 4. Dialog appears asking "Remove this item?" <br> 5. Click **Cancel** or **No** button |
| **Expected**           | Removal confirmation dialog appears. After cancellation, the quantity field reverts to the previous value (5). Item remains in cart. Cart total unchanged. |
| **data-testid needed** | `cart-item-quantity-input`, `remove-confirmation-dialog`, `remove-cancel-button`                         |
| **Source**             | AC-2                                                                                                     |
| **Note**               | N/A — no caveats                                                                                         |

---

## TC-CART-006: Quantity above 20 shows error and keeps previous value

| Field                  | Value                                                                                                          |
| ---------------------- | -------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate`                                                                             |
| **Issue**              | [CART-12](https://linear.app/team/issue/CART-12)                                                              |
| **Automation Score**   | HIGH (63.5/67.5)                                                                                              |
| **ISTQB Technique**    | BVA — boundary max+1 (21); EP — invalid partition (above 20)                                                   |
| **Manual Env**         | Local, Staging                                                                                                 |
| **Precondition**       | Cart contains 1 item with quantity = 10                                                                        |
| **Steps**              | 1. Locate the quantity field <br> 2. Clear and enter `21` <br> 3. Press Tab or click away <br> 4. Observe the field and any message |
| **Expected**           | Error message appears: "You can buy at most 20 of this item." Quantity field reverts to previous value (10). Cart total unchanged. No removal dialog. |
| **data-testid needed** | `cart-item-quantity-input`, `quantity-error-message`, `cart-total-price`                                       |
| **Source**             | AC-3                                                                                                           |
| **Note**               | N/A — no caveats                                                                                               |

---

## TC-CART-007: Quantity far above max (99) shows error and keeps previous value

| Field                  | Value                                                                                                          |
| ---------------------- | -------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                        |
| **Issue**              | [CART-12](https://linear.app/team/issue/CART-12)                                                              |
| **Automation Score**   | HIGH (62/67.5)                                                                                                 |
| **ISTQB Technique**    | Error Guessing — extreme out-of-bounds value                                                                   |
| **Manual Env**         | Local, Staging                                                                                                 |
| **Precondition**       | Cart contains 1 item with quantity = 7                                                                         |
| **Steps**              | 1. Locate the quantity field <br> 2. Clear and enter `99` <br> 3. Press Tab or click away                       |
| **Expected**           | Same error message as TC-CART-006: "You can buy at most 20 of this item." Quantity field reverts to 7. No removal dialog. |
| **data-testid needed** | `cart-item-quantity-input`, `quantity-error-message`                                                           |
| **Source**             | Added by QA (error guessing: verify the limit is consistently enforced beyond +1)                              |
| **Note**               | N/A — no caveats                                                                                               |

---

## TC-CART-008: Non-numeric input (text or decimal) is rejected

| Field                  | Value                                                                                                          |
| ---------------------- | -------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                                        |
| **Issue**              | [CART-12](https://linear.app/team/issue/CART-12)                                                              |
| **Automation Score**   | MEDIUM (44/67.5)                                                                                              |
| **ISTQB Technique**    | Error Guessing — invalid input type                                                                            |
| **Manual Env**         | Local, Staging                                                                                                 |
| **Precondition**       | Cart contains 1 item with quantity = 5                                                                         |
| **Steps**              | 1. Locate the quantity field <br> 2. Clear and enter `abc` or `3.5` <br> 3. Press Tab or click away           |
| **Expected**           | Input is rejected. Quantity field reverts to previous value (5). An error or validation message is shown (e.g., "Please enter a whole number"). Cart total unchanged. |
| **data-testid needed** | `cart-item-quantity-input`, `quantity-error-message`                                                           |
| **Source**             | Added by QA (error guessing: verify input validation enforces whole numbers per AC-1)                           |
| **Note**               | Assumption: the field accepts only whole numbers; decimals and text are invalid per AC-1 spec.                |
