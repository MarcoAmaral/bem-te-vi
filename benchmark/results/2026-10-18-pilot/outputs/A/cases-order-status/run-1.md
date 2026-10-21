# Test Cases for ORD-4: Order Status Changes

## Assumptions
- Orders are uniquely identified by order ID
- Status transitions are triggered by explicit actions (record payment, mark shipped, confirm delivery, cancel)
- The system enforces state transition rules and rejects invalid transitions
- Only one status can be active for an order at a time
- No time delays or async processing affect status changes

---

## Test Suite

### TC-ORD-4.1: Order Created with Placed Status
**Precondition:** No order exists  
**Action:** Create a new order  
**Expected Result:** Order status is "Placed"

---

### TC-ORD-4.2: Record Payment on Placed Order (AC-1)
**Precondition:** Order exists with status "Placed"  
**Action:** Record payment on the order  
**Expected Result:** Order status changes to "Paid"

---

### TC-ORD-4.3: Attempt Payment on Non-Placed Order (AC-1)
**Precondition:** Order exists with status "Paid"  
**Action:** Attempt to record payment  
**Expected Result:** Request is rejected; status remains "Paid"

---

### TC-ORD-4.4: Mark Paid Order as Shipped (AC-2)
**Precondition:** Order exists with status "Paid"  
**Action:** Mark order as shipped  
**Expected Result:** Order status changes to "Shipped"

---

### TC-ORD-4.5: Attempt Shipping on Non-Paid Order (AC-2)
**Precondition:** Order exists with status "Placed"  
**Action:** Attempt to mark as shipped  
**Expected Result:** Request is rejected; status remains "Placed"

---

### TC-ORD-4.6: Confirm Delivery of Shipped Order (AC-3)
**Precondition:** Order exists with status "Shipped"  
**Action:** Confirm delivery  
**Expected Result:** Order status changes to "Delivered"

---

### TC-ORD-4.7: Attempt Delivery Confirmation on Non-Shipped Order (AC-3)
**Precondition:** Order exists with status "Paid"  
**Action:** Attempt to confirm delivery  
**Expected Result:** Request is rejected; status remains "Paid"

---

### TC-ORD-4.8: Cancel Placed Order (AC-4)
**Precondition:** Order exists with status "Placed"  
**Action:** Cancel the order  
**Expected Result:** Order status changes to "Cancelled"

---

### TC-ORD-4.9: Cancel Paid Order (AC-4)
**Precondition:** Order exists with status "Paid"  
**Action:** Cancel the order  
**Expected Result:** Order status changes to "Cancelled"

---

### TC-ORD-4.10: Attempt to Cancel Shipped Order (AC-5)
**Precondition:** Order exists with status "Shipped"  
**Action:** Attempt to cancel the order  
**Expected Result:** Request is rejected with error message "Shipped orders cannot be cancelled."; status remains "Shipped"

---

### TC-ORD-4.11: Attempt to Cancel Delivered Order (AC-5)
**Precondition:** Order exists with status "Delivered"  
**Action:** Attempt to cancel the order  
**Expected Result:** Request is rejected; status remains "Delivered"

---

### TC-ORD-4.12: Attempt to Cancel Cancelled Order
**Precondition:** Order exists with status "Cancelled"  
**Action:** Attempt to cancel the order again  
**Expected Result:** Request is rejected or idempotent; status remains "Cancelled"

---

### TC-ORD-4.13: Verify State Transition Sequence (Happy Path)
**Precondition:** New order created  
**Action:** Execute sequence: Record payment → Mark shipped → Confirm delivery  
**Expected Result:** Status transitions: Placed → Paid → Shipped → Delivered

---

### TC-ORD-4.14: Verify Cancellation Blocks Subsequent Transitions
**Precondition:** Order exists with status "Cancelled"  
**Action:** Attempt to record payment, mark as shipped, or confirm delivery  
**Expected Result:** All requests are rejected; status remains "Cancelled"
