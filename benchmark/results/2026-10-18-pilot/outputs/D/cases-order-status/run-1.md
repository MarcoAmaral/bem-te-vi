---
feature: Order Status Changes
feature_code: ORD
tc_count: 8
tracker_issues: [ORD-4]
risk_level: HIGH
runbook: N/A — no runbook created yet
implementation_pack: N/A — no implementation pack
spec: N/A — not yet automated
last_updated: 2026-10-18
---

# Test Cases — Order Status Changes

| Field                | Value                                      |
| -------------------- | ------------------------------------------ |
| **Project**          | E-commerce Order Management                |
| **Author**           | Senior QA Analyst                          |
| **Date Created**     | 2026-10-18                                 |
| **Last Updated**     | 2026-10-18                                 |
| **Methodology**      | ISTQB CTFL v4.0 — State Transition, EP     |

**Assumptions:**
- Orders are created with status "Placed" via order creation API/UI
- Status changes are performed via dedicated endpoints or UI actions
- Order operations are performed by store operators in an admin panel or API
- All status operations return the updated order with its new status
- Error messages match the exact text provided in AC-5
- Environments include Local (with test data) and Staging

---

## TC-ORD-001: Order created with Placed status

| Field                  | Value                                                         |
| ---------------------- | ------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate`                             |
| **Issue**              | ORD-4                                                         |
| **Automation Score**   | HIGH (58/67.5)                                                |
| **ISTQB Technique**    | State Transition — Initial state                              |
| **Manual Env**         | Local, Staging                                                |
| **Precondition**       | Order management system is operational; no prior orders exist |
| **Steps**              | 1. Create a new order                                         |
| **Expected**           | Order is created with status = "Placed"                       |
| **data-testid needed** | `order-status-display`, `order-id`                            |
| **Source**             | Story requirement (initial state)                             |
| **Note**               | N/A — foundational state for all transitions                  |

---

## TC-ORD-002: Record payment on Placed order changes status to Paid

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate`                                                       |
| **Issue**              | ORD-4                                                                                   |
| **Automation Score**   | HIGH (60/67.5)                                                                          |
| **ISTQB Technique**    | State Transition — Placed → Paid (AC-1)                                                |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | Order exists with status = "Placed"                                                     |
| **Steps**              | 1. Open order details <br> 2. Click or select "Record Payment" action <br> 3. Confirm  |
| **Expected**           | Order status changes to "Paid". Status is persisted and visible on reload.              |
| **data-testid needed** | `order-status-display`, `record-payment-btn`, `order-actions-menu`                      |
| **Source**             | AC-1                                                                                    |
| **Note**               | N/A — no caveats                                                                        |

---

## TC-ORD-003: Mark Paid order as shipped changes status to Shipped

| Field                  | Value                                                                               |
| ---------------------- | ----------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate`                                                   |
| **Issue**              | ORD-4                                                                               |
| **Automation Score**   | HIGH (60/67.5)                                                                      |
| **ISTQB Technique**    | State Transition — Paid → Shipped (AC-2)                                            |
| **Manual Env**         | Local, Staging                                                                      |
| **Precondition**       | Order exists with status = "Paid"                                                   |
| **Steps**              | 1. Open order details <br> 2. Click or select "Mark as Shipped" action <br> 3. Confirm |
| **Expected**           | Order status changes to "Shipped". Status is persisted and visible on reload.        |
| **data-testid needed** | `order-status-display`, `mark-shipped-btn`, `order-actions-menu`                    |
| **Source**             | AC-2                                                                                |
| **Note**               | N/A — no caveats                                                                    |

---

## TC-ORD-004: Confirm delivery of Shipped order changes status to Delivered

| Field                  | Value                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate`                                                     |
| **Issue**              | ORD-4                                                                                 |
| **Automation Score**   | HIGH (58/67.5)                                                                        |
| **ISTQB Technique**    | State Transition — Shipped → Delivered (AC-3)                                        |
| **Manual Env**         | Local, Staging                                                                        |
| **Precondition**       | Order exists with status = "Shipped"                                                 |
| **Steps**              | 1. Open order details <br> 2. Click or select "Confirm Delivery" action <br> 3. Confirm |
| **Expected**           | Order status changes to "Delivered". Status is persisted and visible on reload.       |
| **data-testid needed** | `order-status-display`, `confirm-delivery-btn`, `order-actions-menu`                 |
| **Source**             | AC-3                                                                                 |
| **Note**               | N/A — no caveats                                                                     |

---

## TC-ORD-005: Cancel Placed order changes status to Cancelled

| Field                  | Value                                                                        |
| ---------------------- | ---------------------------------------------------------------------------- |
| **Tags**               | `@sanity @p1 @e2e @ord @candidate`                                           |
| **Issue**              | ORD-4                                                                        |
| **Automation Score**   | HIGH (56/67.5)                                                               |
| **ISTQB Technique**    | State Transition — Placed → Cancelled (AC-4)                                |
| **Manual Env**         | Local, Staging                                                               |
| **Precondition**       | Order exists with status = "Placed"                                         |
| **Steps**              | 1. Open order details <br> 2. Click or select "Cancel Order" action <br> 3. Confirm |
| **Expected**           | Order status changes to "Cancelled". Status is persisted and visible on reload. |
| **data-testid needed** | `order-status-display`, `cancel-order-btn`, `order-actions-menu`            |
| **Source**             | AC-4                                                                        |
| **Note**               | N/A — no caveats                                                             |

---

## TC-ORD-006: Cancel Paid order changes status to Cancelled

| Field                  | Value                                                                        |
| ---------------------- | ---------------------------------------------------------------------------- |
| **Tags**               | `@sanity @p1 @e2e @ord @candidate`                                           |
| **Issue**              | ORD-4                                                                        |
| **Automation Score**   | HIGH (56/67.5)                                                               |
| **ISTQB Technique**    | State Transition — Paid → Cancelled (AC-4)                                  |
| **Manual Env**         | Local, Staging                                                               |
| **Precondition**       | Order exists with status = "Paid"                                           |
| **Steps**              | 1. Open order details <br> 2. Click or select "Cancel Order" action <br> 3. Confirm |
| **Expected**           | Order status changes to "Cancelled". Status is persisted and visible on reload. |
| **data-testid needed** | `order-status-display`, `cancel-order-btn`, `order-actions-menu`            |
| **Source**             | AC-4                                                                        |
| **Note**               | N/A — no caveats                                                             |

---

## TC-ORD-007: Attempt to cancel Shipped order is refused with error message

| Field                  | Value                                                                                                                      |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@sanity @p1 @e2e @ord @candidate`                                                                                         |
| **Issue**              | ORD-4                                                                                                                      |
| **Automation Score**   | HIGH (58/67.5)                                                                                                             |
| **ISTQB Technique**    | State Transition — Invalid transition (Shipped → Cancelled rejected)                                                      |
| **Manual Env**         | Local, Staging                                                                                                             |
| **Precondition**       | Order exists with status = "Shipped"                                                                                      |
| **Steps**              | 1. Open order details <br> 2. Attempt to click or select "Cancel Order" action (button disabled or dialog shown) <br> 3. If dialog appears, attempt to confirm cancellation |
| **Expected**           | Cancellation is refused. Error message displays: "Shipped orders cannot be cancelled." Order status remains "Shipped".      |
| **data-testid needed** | `order-status-display`, `cancel-order-btn`, `error-message`, `error-toast`                                                 |
| **Source**             | AC-5                                                                                                                       |
| **Note**               | Assumption: Cancel button is either disabled or shows a confirmation dialog that returns this error. Test both if applicable. |

---

## TC-ORD-008: Full order lifecycle — Placed to Paid to Shipped to Delivered

| Field                  | Value                                                                                                                                                            |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate`                                                                                                                              |
| **Issue**              | ORD-4                                                                                                                                                          |
| **Automation Score**   | HIGH (62/67.5)                                                                                                                                                 |
| **ISTQB Technique**    | State Transition — Valid path coverage (Placed → Paid → Shipped → Delivered)                                                                                  |
| **Manual Env**         | Local, Staging                                                                                                                                                 |
| **Precondition**       | Order management system is operational                                                                                                                         |
| **Steps**              | 1. Create a new order (verify status = "Placed") <br> 2. Record payment (verify status = "Paid") <br> 3. Mark as shipped (verify status = "Shipped") <br> 4. Confirm delivery (verify status = "Delivered") <br> 5. Reload order details to confirm persistence |
| **Expected**           | Each transition succeeds in sequence. Final status is "Delivered". Order is persisted at each step with no status regress.                                     |
| **data-testid needed** | `order-status-display`, `record-payment-btn`, `mark-shipped-btn`, `confirm-delivery-btn`, `order-id`                                                         |
| **Source**             | AC-1, AC-2, AC-3 (integrated path coverage)                                                                                                                   |
| **Note**               | N/A — comprehensive happy-path coverage of the primary business flow                                                                                           |
