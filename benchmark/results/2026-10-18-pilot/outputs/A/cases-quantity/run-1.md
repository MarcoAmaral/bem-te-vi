# Test Cases for CART-12: Change the Quantity of an Item in the Cart

## Acceptance Criteria Tests

### TC-CART-12-001: Valid quantity within range (AC-1)
**Description:** Verify quantity field accepts whole numbers 1-20
**Precondition:** Item exists in cart with quantity 1
**Steps:**
1. Click quantity field for item
2. Clear current value
3. Enter "5"
4. Press Enter or click away from field
**Expected Result:** Quantity updates to 5, cart total recalculates

### TC-CART-12-002: Minimum valid quantity (AC-1)
**Description:** Verify quantity 1 is accepted
**Precondition:** Item in cart with quantity > 1
**Steps:**
1. Change quantity to "1"
2. Confirm change
**Expected Result:** Quantity updates to 1

### TC-CART-12-003: Maximum valid quantity (AC-1)
**Description:** Verify quantity 20 is accepted
**Precondition:** Item in cart with quantity < 20
**Steps:**
1. Change quantity to "20"
2. Confirm change
**Expected Result:** Quantity updates to 20

### TC-CART-12-004: Zero quantity triggers confirmation dialog (AC-2)
**Description:** Verify setting quantity to 0 shows removal confirmation
**Precondition:** Item in cart with quantity 1
**Steps:**
1. Change quantity to "0"
2. Observe dialog
**Expected Result:** Dialog appears with text "Remove this item?"

### TC-CART-12-005: Confirm item removal (AC-2)
**Description:** Verify item is removed when user confirms
**Precondition:** Item in cart, confirmation dialog open
**Steps:**
1. Click "Confirm" or "Yes" button on removal dialog
2. Observe cart
**Expected Result:** Item is removed from cart, cart total updates

### TC-CART-12-006: Cancel item removal (AC-2)
**Description:** Verify item is not removed when user cancels
**Precondition:** Item in cart, confirmation dialog open
**Steps:**
1. Click "Cancel" or "No" button on removal dialog
2. Observe item
**Expected Result:** Item remains in cart with original quantity unchanged

### TC-CART-12-007: Quantity above 20 shows error message (AC-3)
**Description:** Verify entering quantity above 20 displays error
**Precondition:** Item in cart with quantity 5
**Steps:**
1. Change quantity to "25"
2. Attempt to confirm
**Expected Result:** Error message "You can buy at most 20 of this item." displays, quantity reverts to 5

### TC-CART-12-008: Quantity 21 triggers error (AC-3)
**Description:** Verify boundary condition at 21
**Precondition:** Item in cart with quantity 10
**Steps:**
1. Change quantity to "21"
2. Confirm change
**Expected Result:** Error message displays, quantity remains 10

## Edge Case Tests

### TC-CART-12-009: Non-whole number input
**Description:** Verify decimal numbers are rejected or rounded
**Precondition:** Item in cart
**Steps:**
1. Enter "5.5" in quantity field
**Expected Result:** Either field rejects input or value is rounded to 5

### TC-CART-12-010: Negative number input
**Description:** Verify negative numbers are rejected
**Precondition:** Item in cart
**Steps:**
1. Enter "-5" in quantity field
**Expected Result:** Field rejects input or treats as invalid

### TC-CART-12-011: Non-numeric input
**Description:** Verify letters and special characters are rejected
**Precondition:** Item in cart
**Steps:**
1. Enter "abc" or "!@#" in quantity field
**Expected Result:** Field rejects input or displays validation error

### TC-CART-12-012: Empty field submission
**Description:** Verify empty quantity field is handled
**Precondition:** Item in cart with quantity 3
**Steps:**
1. Clear quantity field completely
2. Press Enter or click away
**Expected Result:** Either field shows error, or quantity reverts to previous value (3)

### TC-CART-12-013: Leading zeros
**Description:** Verify leading zeros are handled correctly
**Precondition:** Item in cart
**Steps:**
1. Enter "05" in quantity field
**Expected Result:** Quantity updates to 5 (leading zero stripped)

### TC-CART-12-014: Rapid quantity changes
**Description:** Verify system handles quick successive changes
**Precondition:** Item in cart
**Steps:**
1. Change quantity to 2
2. Immediately change to 5
3. Immediately change to 15
4. Wait for processing
**Expected Result:** Final quantity is 15, cart updates once without errors

### TC-CART-12-015: Multiple items with different quantities
**Description:** Verify changing one item doesn't affect others
**Precondition:** Cart contains 3 different items with quantities 2, 5, 8
**Steps:**
1. Change first item quantity to 10
2. Verify other items
**Expected Result:** First item is 10, other items remain 5 and 8

### TC-CART-12-016: Quantity change persists across page refresh
**Description:** Verify quantity changes are saved
**Precondition:** Item in cart with quantity updated to 15
**Steps:**
1. Refresh page
2. Navigate back to cart
**Expected Result:** Item quantity remains 15

### TC-CART-12-017: Cart total updates correctly
**Description:** Verify price calculations reflect quantity changes
**Precondition:** Item in cart with unit price $10, quantity 2 ($20 total)
**Steps:**
1. Change quantity to 5
**Expected Result:** Item subtotal updates to $50, cart total updates accordingly
