# Order Status Changes (ORD-4) - Test Cases

## Assumptions
- Test environment has a way to create orders and perform status change actions
- Store operators can access an order management interface
- Status transitions are atomic (no partial updates)
- System logs status change attempts

---

## TC-ORD-4-01: Order created with Placed status

**Pre-condition:** Fresh order creation

**Steps:**
1. Create a new order

**Expected Result:** Order status is "Placed"

---

## TC-ORD-4-02: Record payment on Placed order (AC-1)

**Pre-condition:** Order exists with status "Placed"

**Steps:**
1. Open the order
2. Record a payment

**Expected Result:** Order status changes to "Paid"

---

## TC-ORD-4-03: Record payment on non-Placed order (AC-1 negative case)

**Pre-condition:** Order exists with status "Paid"

**Steps:**
1. Open the order
2. Attempt to record a payment

**Expected Result:** Action is refused or system prevents duplicate payment recording

---

## TC-ORD-4-04: Mark Paid order as shipped (AC-2)

**Pre-condition:** Order exists with status "Paid"

**Steps:**
1. Open the order
2. Mark as shipped

**Expected Result:** Order status changes to "Shipped"

---

## TC-ORD-4-05: Mark order as shipped without Paid status (AC-2 negative case)

**Pre-condition:** Order exists with status "Placed"

**Steps:**
1. Open the order
2. Attempt to mark as shipped

**Expected Result:** Action is refused or system prevents shipping unpaid orders

---

## TC-ORD-4-06: Confirm delivery of Shipped order (AC-3)

**Pre-condition:** Order exists with status "Shipped"

**Steps:**
1. Open the order
2. Confirm delivery

**Expected Result:** Order status changes to "Delivered"

---

## TC-ORD-4-07: Confirm delivery on non-Shipped order (AC-3 negative case)

**Pre-condition:** Order exists with status "Paid"

**Steps:**
1. Open the order
2. Attempt to confirm delivery

**Expected Result:** Action is refused or system prevents confirming delivery for non-shipped orders

---

## TC-ORD-4-08: Cancel Placed order (AC-4)

**Pre-condition:** Order exists with status "Placed"

**Steps:**
1. Open the order
2. Cancel the order

**Expected Result:** Order status changes to "Cancelled"

---

## TC-ORD-4-09: Cancel Paid order (AC-4)

**Pre-condition:** Order exists with status "Paid"

**Steps:**
1. Open the order
2. Cancel the order

**Expected Result:** Order status changes to "Cancelled"

---

## TC-ORD-4-10: Attempt to cancel Shipped order (AC-5)

**Pre-condition:** Order exists with status "Shipped"

**Steps:**
1. Open the order
2. Attempt to cancel the order

**Expected Result:** Cancellation is refused; error message displays "Shipped orders cannot be cancelled."

---

## TC-ORD-4-11: Attempt to cancel Delivered order (AC-5 variant)

**Pre-condition:** Order exists with status "Delivered"

**Steps:**
1. Open the order
2. Attempt to cancel the order

**Expected Result:** Cancellation is refused; appropriate error message displays

---

## TC-ORD-4-12: Verify no status transitions bypass the defined flow

**Pre-condition:** Order exists with status "Placed"

**Steps:**
1. Attempt to move order directly from "Placed" to "Shipped" (skipping "Paid")
2. Attempt to move order directly from "Placed" to "Delivered"

**Expected Result:** Both attempts are refused; system enforces sequential status transitions only
