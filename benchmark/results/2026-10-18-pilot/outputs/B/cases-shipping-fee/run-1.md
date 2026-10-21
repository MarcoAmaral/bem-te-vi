# Test Cases for SHIP-9: Shipping Fee at Checkout

## Assumptions
- Membership status is determined and verified before checkout
- Subtotal excludes taxes, shipping, and discounts
- Currency is USD
- Standard shipping is the default option
- Both standard and express shipping options are available
- Shipping fees apply to all eligible orders
- Order subtotals can contain two decimal places

---

## Test Suite

| Test ID | Title | Precondition | Test Steps | Expected Result |
|---------|-------|--------------|-----------|-----------------|
| TC-001 | Standard shipping - non-member with subtotal under $50 | Non-member customer, no items in cart | 1. Add item totaling $49.99 to cart<br>2. Proceed to checkout<br>3. Select standard shipping | Standard shipping fee displays as $5.99 |
| TC-002 | Standard shipping - non-member with subtotal exactly $50 | Non-member customer, no items in cart | 1. Add items totaling exactly $50.00 to cart<br>2. Proceed to checkout<br>3. Select standard shipping | Standard shipping fee displays as free ($0.00) |
| TC-003 | Standard shipping - non-member with subtotal over $50 | Non-member customer, no items in cart | 1. Add items totaling $75.50 to cart<br>2. Proceed to checkout<br>3. Select standard shipping | Standard shipping fee displays as free ($0.00) |
| TC-004 | Standard shipping - member with low subtotal | Member customer, no items in cart | 1. Add item totaling $25.00 to cart<br>2. Proceed to checkout<br>3. Select standard shipping | Standard shipping fee displays as free ($0.00) |
| TC-005 | Standard shipping - member with high subtotal | Member customer, no items in cart | 1. Add items totaling $150.00 to cart<br>2. Proceed to checkout<br>3. Select standard shipping | Standard shipping fee displays as free ($0.00) |
| TC-006 | Express shipping - non-member with low subtotal | Non-member customer, no items in cart | 1. Add item totaling $20.00 to cart<br>2. Proceed to checkout<br>3. Select express shipping | Express shipping fee displays as $12.99 |
| TC-007 | Express shipping - non-member with high subtotal | Non-member customer, no items in cart | 1. Add items totaling $200.00 to cart<br>2. Proceed to checkout<br>3. Select express shipping | Express shipping fee displays as $12.99 |
| TC-008 | Express shipping - member with low subtotal | Member customer, no items in cart | 1. Add item totaling $20.00 to cart<br>2. Proceed to checkout<br>3. Select express shipping | Express shipping fee displays as $7.99 |
| TC-009 | Express shipping - member with high subtotal | Member customer, no items in cart | 1. Add items totaling $200.00 to cart<br>2. Proceed to checkout<br>3. Select express shipping | Express shipping fee displays as $7.99 |
| TC-010 | Boundary condition - non-member at $49.99 | Non-member customer, no items in cart | 1. Add items totaling exactly $49.99 to cart<br>2. Proceed to checkout<br>3. Select standard shipping | Standard shipping fee displays as $5.99 |
| TC-011 | Boundary condition - non-member at $50.01 | Non-member customer, no items in cart | 1. Add items totaling exactly $50.01 to cart<br>2. Proceed to checkout<br>3. Select standard shipping | Standard shipping fee displays as free ($0.00) |
| TC-012 | Shipping fee changes when items added to cart | Non-member customer with item totaling $30.00 in cart at checkout | 1. Add second item worth $25.00 during checkout<br>2. Subtotal updates to $55.00<br>3. Verify standard shipping fee | Standard shipping fee updates and displays as free ($0.00) |
| TC-013 | Membership status affects shipping fee | Non-member customer with $40.00 subtotal in cart | 1. Proceed to checkout with standard shipping selected<br>2. Apply membership upgrade mid-checkout<br>3. Verify standard shipping fee updates | Standard shipping fee updates from $5.99 to free ($0.00) |
| TC-014 | Multiple orders - non-member standard shipping consistency | Non-member customer placing first order | 1. Complete order 1 with $45.00 subtotal and standard shipping ($5.99)<br>2. Create new order with same subtotal and shipping method | Second order also displays $5.99 for standard shipping |
| TC-015 | Tax excluded from subtotal calculation | Non-member customer with items | 1. Add items with subtotal of $49.99 (before tax)<br>2. Tax calculated on subtotal<br>3. Proceed to checkout with standard shipping | Shipping fee is $5.99 (based on pre-tax subtotal, not post-tax total) |
| TC-016 | Zero subtotal order | Any customer type, no items | 1. Proceed to checkout with $0.00 subtotal<br>2. Select standard shipping | Shipping fee displays as $5.99 for non-members; free for members |
| TC-017 | Very large order subtotal - non-member | Non-member customer with $9,999.99 subtotal | 1. Proceed to checkout<br>2. Select standard shipping | Standard shipping fee displays as free ($0.00) |
| TC-018 | Very large order subtotal - member express | Member customer with $9,999.99 subtotal | 1. Proceed to checkout<br>2. Select express shipping | Express shipping fee displays as $7.99 |
