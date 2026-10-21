# Test Cases for ORD-4: Order Status Changes

## Assumptions
- Orders are created via API or system function that automatically sets initial status to "Placed"
- Payment recording, shipment marking, and delivery confirmation are distinct operations
- Status changes are persisted immediately
- Order IDs uniquely identify orders
- System validates status transitions and returns appropriate error messages

---

## AC-1: Recording a Payment on a Placed Order

**TC-1.1: Record payment on Placed order**
- Precondition: Order exists with status "Placed"
- Steps: Record a payment against the order
- Expected: Order status changes to "Paid"

**TC-1.2: Verify only Placed orders transition to Paid**
- Precondition: Order exists with status "Paid"
- Steps: Attempt to record another payment
- Expected: Status remains "Paid" or operation fails (system behavior to be clarified)

**TC-1.3: Payment recording with valid payment details**
- Precondition: Order exists with status "Placed" and valid payment amount
- Steps: Record payment matching order amount
- Expected: Order status changes to "Paid" and payment is recorded

---

## AC-2: Marking a Paid Order as Shipped

**TC-2.1: Mark Paid order as shipped**
- Precondition: Order exists with status "Paid"
- Steps: Mark order as shipped
- Expected: Order status changes to "Shipped"

**TC-2.2: Cannot ship Placed order**
- Precondition: Order exists with status "Placed"
- Steps: Attempt to mark order as shipped
- Expected: Operation fails or status remains "Placed"

**TC-2.3: Cannot re-ship Shipped order**
- Precondition: Order exists with status "Shipped"
- Steps: Attempt to mark order as shipped again
- Expected: Operation fails or status remains "Shipped"

---

## AC-3: Confirming Delivery of a Shipped Order

**TC-3.1: Confirm delivery of Shipped order**
- Precondition: Order exists with status "Shipped"
- Steps: Confirm delivery
- Expected: Order status changes to "Delivered"

**TC-3.2: Cannot confirm delivery of Paid order**
- Precondition: Order exists with status "Paid"
- Steps: Attempt to confirm delivery
- Expected: Operation fails or status remains "Paid"

**TC-3.3: Cannot confirm delivery of already Delivered order**
- Precondition: Order exists with status "Delivered"
- Steps: Attempt to confirm delivery again
- Expected: Operation fails or status remains "Delivered"

---

## AC-4: Cancelling Placed or Paid Orders

**TC-4.1: Cancel Placed order**
- Precondition: Order exists with status "Placed"
- Steps: Request order cancellation
- Expected: Order status changes to "Cancelled"

**TC-4.2: Cancel Paid order**
- Precondition: Order exists with status "Paid"
- Steps: Request order cancellation
- Expected: Order status changes to "Cancelled"

**TC-4.3: Cannot cancel Delivered order**
- Precondition: Order exists with status "Delivered"
- Steps: Attempt to cancel order
- Expected: Operation fails or status remains "Delivered"

**TC-4.4: Verify Cancelled order is final**
- Precondition: Order exists with status "Cancelled"
- Steps: Attempt to transition to any other status
- Expected: Operation fails or status remains "Cancelled"

---

## AC-5: Refusing to Cancel Shipped Orders

**TC-5.1: Attempt to cancel Shipped order**
- Precondition: Order exists with status "Shipped"
- Steps: Request order cancellation
- Expected: Operation fails with error message "Shipped orders cannot be cancelled."

**TC-5.2: Verify exact error message for Shipped cancellation**
- Precondition: Order exists with status "Shipped"
- Steps: Request order cancellation and capture response message
- Expected: Error message exactly matches "Shipped orders cannot be cancelled."

**TC-5.3: Shipped order remains unchanged after cancellation attempt**
- Precondition: Order exists with status "Shipped"
- Steps: Attempt to cancel order
- Expected: Order status remains "Shipped" and no side effects occur

---

## Status Transition Matrix Tests

**TC-6.1: Validate all valid state transitions**
- Precondition: Various orders in different states
- Steps: Execute each valid transition (Placed→Paid, Paid→Shipped, Shipped→Delivered, Placed→Cancelled, Paid→Cancelled)
- Expected: All valid transitions succeed

**TC-6.2: Validate all invalid state transitions**
- Precondition: Various orders in different states
- Steps: Attempt invalid transitions (e.g., Placed→Shipped, Delivered→any, Cancelled→any)
- Expected: All invalid transitions fail appropriately

---

## Concurrent Operations Tests

**TC-7.1: Handle concurrent payment recording**
- Precondition: Order exists with status "Placed"
- Steps: Simultaneously record payment twice
- Expected: Only one succeeds; second request either fails or idempotently returns Paid status

**TC-7.2: Handle race between shipment and cancellation**
- Precondition: Order exists with status "Paid"
- Steps: Simultaneously request shipment and cancellation
- Expected: One operation succeeds; other fails or is rejected gracefully
