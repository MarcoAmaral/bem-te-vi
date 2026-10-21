# Test Cases for CART-12: Change the Quantity of an Item in the Cart

## Assumptions
- A quantity field exists for each item in the cart (numeric input or increment/decrement controls)
- Changes are persisted immediately upon valid submission
- Error messages appear inline or as toast notifications
- The cart contains at least one item for all test scenarios
- Quantity changes are limited to whole positive integers only
- The previous quantity is retained in the input field until a valid change is confirmed

---

## Test Case 1: Set Valid Quantity - Boundary Value (Minimum)
**ID:** CART-12-TC-001  
**Summary:** Verify that quantity can be set to 1 (minimum valid value)  
**Preconditions:** Cart contains an item with quantity > 1

**Steps:**
1. Navigate to the cart
2. Locate the quantity field for the item
3. Clear the current value
4. Enter "1"
5. Submit/confirm the change

**Expected Result:**
- Quantity updates to 1
- Item remains in cart
- Cart total updates accordingly
- No error message appears

---

## Test Case 2: Set Valid Quantity - Boundary Value (Maximum)
**ID:** CART-12-TC-002  
**Summary:** Verify that quantity can be set to 20 (maximum valid value)  
**Preconditions:** Cart contains an item with quantity < 20

**Steps:**
1. Navigate to the cart
2. Locate the quantity field for the item
3. Clear the current value
4. Enter "20"
5. Submit/confirm the change

**Expected Result:**
- Quantity updates to 20
- Item remains in cart
- Cart total updates accordingly
- No error message appears

---

## Test Case 3: Set Valid Quantity - Mid-Range Value
**ID:** CART-12-TC-003  
**Summary:** Verify that any quantity between 1 and 20 can be set successfully  
**Preconditions:** Cart contains an item

**Steps:**
1. Navigate to the cart
2. Locate the quantity field for the item
3. Clear the current value
4. Enter "10"
5. Submit/confirm the change

**Expected Result:**
- Quantity updates to 10
- Item remains in cart
- Cart total updates accordingly
- No error message appears

---

## Test Case 4: Increase Quantity from Current Value
**ID:** CART-12-TC-004  
**Summary:** Verify that quantity can be increased to a valid value  
**Preconditions:** Cart contains an item with quantity 5

**Steps:**
1. Navigate to the cart
2. Locate the quantity field showing "5"
3. Clear the field
4. Enter "12"
5. Submit/confirm the change

**Expected Result:**
- Quantity updates to 12
- Item remains in cart
- Cart total increases accordingly

---

## Test Case 5: Decrease Quantity to Valid Value
**ID:** CART-12-TC-005  
**Summary:** Verify that quantity can be decreased to a valid value  
**Preconditions:** Cart contains an item with quantity 15

**Steps:**
1. Navigate to the cart
2. Locate the quantity field showing "15"
3. Clear the field
4. Enter "3"
5. Submit/confirm the change

**Expected Result:**
- Quantity updates to 3
- Item remains in cart
- Cart total decreases accordingly

---

## Test Case 6: Set Quantity to Zero - User Confirms Removal
**ID:** CART-12-TC-006  
**Summary:** Verify that setting quantity to 0 prompts for confirmation and removes item when confirmed  
**Preconditions:** Cart contains an item with quantity > 0

**Steps:**
1. Navigate to the cart
2. Locate the quantity field for the item
3. Clear the current value
4. Enter "0"
5. Observe the confirmation dialog
6. Click "Yes" or "Confirm" button

**Expected Result:**
- A confirmation dialog appears with message "Remove this item?"
- Item is removed from cart after confirmation
- Cart updates and no longer displays the removed item
- Cart total updates accordingly

---

## Test Case 7: Set Quantity to Zero - User Cancels Removal
**ID:** CART-12-TC-007  
**Summary:** Verify that canceling the removal confirmation keeps the item in the cart  
**Preconditions:** Cart contains an item with quantity > 0

**Steps:**
1. Navigate to the cart
2. Locate the quantity field for the item
3. Clear the current value
4. Enter "0"
5. Observe the confirmation dialog
6. Click "No", "Cancel", or close the dialog

**Expected Result:**
- A confirmation dialog appears with message "Remove this item?"
- Item remains in cart
- Quantity field reverts to the previous quantity value
- Cart total remains unchanged

---

## Test Case 8: Set Quantity Above Maximum - Single Digit Overage
**ID:** CART-12-TC-008  
**Summary:** Verify that quantity above 20 shows error message and retains previous quantity  
**Preconditions:** Cart contains an item with quantity 15

**Steps:**
1. Navigate to the cart
2. Locate the quantity field showing "15"
3. Clear the field
4. Enter "21"
5. Attempt to submit/confirm the change

**Expected Result:**
- Error message appears: "You can buy at most 20 of this item."
- Quantity field retains the previous value "15"
- Item is not updated in cart
- Cart total remains unchanged

---

## Test Case 9: Set Quantity Above Maximum - Significant Overage
**ID:** CART-12-TC-009  
**Summary:** Verify that significantly high quantities are rejected  
**Preconditions:** Cart contains an item

**Steps:**
1. Navigate to the cart
2. Locate the quantity field
3. Clear the field
4. Enter "100"
5. Attempt to submit/confirm the change

**Expected Result:**
- Error message appears: "You can buy at most 20 of this item."
- Quantity field retains the previous value
- Item is not updated in cart

---

## Test Case 10: Enter Invalid Input - Negative Number
**ID:** CART-12-TC-010  
**Summary:** Verify that negative numbers are rejected  
**Preconditions:** Cart contains an item with quantity 5

**Steps:**
1. Navigate to the cart
2. Locate the quantity field
3. Clear the field
4. Enter "-5"
5. Attempt to submit/confirm the change

**Expected Result:**
- Change is rejected (input prevented or error shown)
- Quantity field retains the previous value "5"
- No negative quantity appears in the cart

---

## Test Case 11: Enter Invalid Input - Decimal Number
**ID:** CART-12-TC-011  
**Summary:** Verify that decimal numbers are rejected (only whole numbers accepted)  
**Preconditions:** Cart contains an item with quantity 8

**Steps:**
1. Navigate to the cart
2. Locate the quantity field
3. Clear the field
4. Enter "5.5"
5. Attempt to submit/confirm the change

**Expected Result:**
- Change is rejected (input prevented, rounded, or error shown)
- Quantity field retains the previous value "8"
- Item quantity remains whole number in cart

---

## Test Case 12: Enter Invalid Input - Non-Numeric Characters
**ID:** CART-12-TC-012  
**Summary:** Verify that non-numeric input is rejected  
**Preconditions:** Cart contains an item with quantity 10

**Steps:**
1. Navigate to the cart
2. Locate the quantity field
3. Clear the field
4. Enter "abc"
5. Attempt to submit/confirm the change

**Expected Result:**
- Change is rejected (input prevented or error shown)
- Quantity field retains the previous value "10"
- Item is not updated in cart

---

## Test Case 13: Empty Quantity Field
**ID:** CART-12-TC-013  
**Summary:** Verify behavior when quantity field is left empty  
**Preconditions:** Cart contains an item with quantity 7

**Steps:**
1. Navigate to the cart
2. Locate the quantity field
3. Clear the field completely
4. Leave it empty
5. Attempt to submit/confirm the change (or move focus away)

**Expected Result:**
- Either an error appears or field auto-reverts to previous value "7"
- Item quantity remains unchanged
- Cart is not affected

---

## Test Case 14: Rapid Successive Quantity Changes
**ID:** CART-12-TC-014  
**Summary:** Verify cart handles multiple rapid quantity changes correctly  
**Preconditions:** Cart contains an item with quantity 5

**Steps:**
1. Navigate to the cart
2. Change quantity to 8 and confirm
3. Immediately change quantity to 12 and confirm
4. Immediately change quantity to 3 and confirm
5. Verify cart state

**Expected Result:**
- All changes are processed in order
- Final quantity is 3
- Cart total reflects the final quantity accurately
- No duplicate or lost updates occur

---

## Test Case 15: Quantity Change Persists After Page Refresh
**ID:** CART-12-TC-015  
**Summary:** Verify that quantity changes are saved and persist after page reload  
**Preconditions:** Cart contains an item with quantity 5

**Steps:**
1. Navigate to the cart
2. Change quantity to 14 and confirm
3. Refresh/reload the page
4. Navigate back to the cart
5. Observe the item's quantity

**Expected Result:**
- Item quantity remains 14 after page refresh
- Change was persisted to backend/storage
- Cart total reflects the persisted quantity

---

## Test Case 16: Quantity Change for Multiple Items in Cart
**ID:** CART-12-TC-016  
**Summary:** Verify that changing one item's quantity does not affect other items  
**Preconditions:** Cart contains at least two different items (Item A with qty 5, Item B with qty 8)

**Steps:**
1. Navigate to the cart
2. Change quantity of Item A to 12
3. Confirm the change
4. Verify Item B's quantity

**Expected Result:**
- Item A quantity updates to 12
- Item B quantity remains unchanged at 8
- Cart total updates correctly for both items

---

## Test Case 17: Set Quantity to 0 on Last Item (Confirmation)
**ID:** CART-12-TC-017  
**Summary:** Verify removal confirmation workflow when item is the last item in cart  
**Preconditions:** Cart contains only one item

**Steps:**
1. Navigate to the cart
2. Locate the quantity field
3. Enter "0"
4. Confirm removal in the dialog

**Expected Result:**
- Confirmation dialog appears: "Remove this item?"
- Item is removed after confirmation
- Cart becomes empty
- Empty cart state/message is displayed

---

## Test Case 18: Boundary Test - Quantity Change from 20 to 19
**ID:** CART-12-TC-018  
**Summary:** Verify that decreasing quantity from maximum valid value works  
**Preconditions:** Cart contains an item with quantity 20

**Steps:**
1. Navigate to the cart
2. Locate the quantity field showing "20"
3. Clear the field
4. Enter "19"
5. Submit/confirm the change

**Expected Result:**
- Quantity updates to 19
- No error message appears
- Cart total updates accordingly

---

## Test Case 19: Boundary Test - Quantity Change from 1 to 2
**ID:** CART-12-TC-019  
**Summary:** Verify that increasing quantity from minimum valid value works  
**Preconditions:** Cart contains an item with quantity 1

**Steps:**
1. Navigate to the cart
2. Locate the quantity field showing "1"
3. Clear the field
4. Enter "2"
5. Submit/confirm the change

**Expected Result:**
- Quantity updates to 2
- No error message appears
- Cart total updates accordingly

---

## Test Case 20: Accessibility - Tab Navigation Through Quantity Field
**ID:** CART-12-TC-020  
**Summary:** Verify that quantity field is accessible via keyboard navigation  
**Preconditions:** Cart contains an item

**Steps:**
1. Navigate to the cart
2. Use Tab key to navigate through page elements
3. Focus on the quantity field
4. Enter a valid quantity (e.g., "7")
5. Press Tab or Enter to move away/submit

**Expected Result:**
- Quantity field is keyboard accessible
- Focus indicator is visible
- Quantity change is processed when focus leaves the field or Enter is pressed
- No keyboard navigation issues occur
