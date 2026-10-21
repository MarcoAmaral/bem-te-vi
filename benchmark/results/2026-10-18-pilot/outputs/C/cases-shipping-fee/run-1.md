# Test Cases: SHIP-9 Shipping Fee at Checkout

## Assumptions

- Two user types exist: Members and non-Members.
- Two shipping methods are available at checkout: Standard and Express.
- Membership status is determined before the user reaches checkout.
- All fees are displayed to the user before they confirm the order.
- Subtotal is calculated before tax and does not include shipping.
- Fees are in USD.

---

## Test Case 1: Standard Shipping – Non-Member, Subtotal Below $50

**Precondition:** User is not a member; order subtotal is $25.00.

**Steps:**
1. Add items to cart totaling $25.00.
2. Proceed to checkout.
3. Select **Standard Shipping**.

**Expected Result:** Shipping fee displays as $5.99.

---

## Test Case 2: Standard Shipping – Non-Member, Subtotal at $50.00

**Precondition:** User is not a member; order subtotal is exactly $50.00.

**Steps:**
1. Add items to cart totaling $50.00.
2. Proceed to checkout.
3. Select **Standard Shipping**.

**Expected Result:** Shipping fee displays as $0.00 (free).

---

## Test Case 3: Standard Shipping – Non-Member, Subtotal Above $50

**Precondition:** User is not a member; order subtotal is $75.00.

**Steps:**
1. Add items to cart totaling $75.00.
2. Proceed to checkout.
3. Select **Standard Shipping**.

**Expected Result:** Shipping fee displays as $0.00 (free).

---

## Test Case 4: Standard Shipping – Member, Low Subtotal

**Precondition:** User is a member; order subtotal is $10.00.

**Steps:**
1. Add items to cart totaling $10.00.
2. Proceed to checkout.
3. Select **Standard Shipping**.

**Expected Result:** Shipping fee displays as $0.00 (free).

---

## Test Case 5: Standard Shipping – Member, High Subtotal

**Precondition:** User is a member; order subtotal is $100.00.

**Steps:**
1. Add items to cart totaling $100.00.
2. Proceed to checkout.
3. Select **Standard Shipping**.

**Expected Result:** Shipping fee displays as $0.00 (free).

---

## Test Case 6: Express Shipping – Non-Member

**Precondition:** User is not a member; order subtotal is any amount.

**Steps:**
1. Add items to cart.
2. Proceed to checkout.
3. Select **Express Shipping**.

**Expected Result:** Shipping fee displays as $12.99.

---

## Test Case 7: Express Shipping – Member

**Precondition:** User is a member; order subtotal is any amount.

**Steps:**
1. Add items to cart.
2. Proceed to checkout.
3. Select **Express Shipping**.

**Expected Result:** Shipping fee displays as $7.99.

---

## Test Case 8: Shipping Method Switch – Non-Member

**Precondition:** User is not a member; order subtotal is $30.00; Standard Shipping is selected showing $5.99.

**Steps:**
1. At checkout, select **Express Shipping**.

**Expected Result:** Shipping fee updates to $12.99.

---

## Test Case 9: Shipping Method Switch – Member

**Precondition:** User is a member; order subtotal is $30.00; Express Shipping is selected showing $7.99.

**Steps:**
1. At checkout, select **Standard Shipping**.

**Expected Result:** Shipping fee updates to $0.00.

---

## Test Case 10: Subtotal Boundary – Just Below $50

**Precondition:** User is not a member; order subtotal is $49.99.

**Steps:**
1. Add items to cart totaling $49.99.
2. Proceed to checkout.
3. Select **Standard Shipping**.

**Expected Result:** Shipping fee displays as $5.99.

---

## Test Case 11: Order Total Display Includes Shipping Fee

**Precondition:** User is not a member; order subtotal is $40.00; Standard Shipping is selected.

**Steps:**
1. View the order summary at checkout.

**Expected Result:** Order total is $45.99 (subtotal $40.00 + shipping $5.99).

---

## Test Case 12: Order Total Display – Member with Express

**Precondition:** User is a member; order subtotal is $40.00; Express Shipping is selected.

**Steps:**
1. View the order summary at checkout.

**Expected Result:** Order total is $47.99 (subtotal $40.00 + shipping $7.99).
