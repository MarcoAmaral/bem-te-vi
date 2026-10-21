# Test Cases for SHIP-9: Shipping Fee at Checkout

## Test Case 1: Standard Shipping - Non-Member Below Minimum Threshold
**Scenario:** Non-member shopper with subtotal below $50 selects standard shipping
- **Given:** User is not a member
- **When:** Order subtotal is $49.99 and standard shipping is selected
- **Then:** Shipping fee displays as $5.99

## Test Case 2: Standard Shipping - Non-Member At Minimum Threshold
**Scenario:** Non-member shopper with subtotal exactly at threshold selects standard shipping
- **Given:** User is not a member
- **When:** Order subtotal is $50.00 and standard shipping is selected
- **Then:** Shipping fee displays as $0.00

## Test Case 3: Standard Shipping - Non-Member Above Minimum Threshold
**Scenario:** Non-member shopper with subtotal above threshold selects standard shipping
- **Given:** User is not a member
- **When:** Order subtotal is $150.00 and standard shipping is selected
- **Then:** Shipping fee displays as $0.00

## Test Case 4: Standard Shipping - Member At Low Subtotal
**Scenario:** Member shopper with subtotal below $50 selects standard shipping
- **Given:** User is a member
- **When:** Order subtotal is $20.00 and standard shipping is selected
- **Then:** Shipping fee displays as $0.00

## Test Case 5: Standard Shipping - Member At High Subtotal
**Scenario:** Member shopper with subtotal above $50 selects standard shipping
- **Given:** User is a member
- **When:** Order subtotal is $100.00 and standard shipping is selected
- **Then:** Shipping fee displays as $0.00

## Test Case 6: Express Shipping - Non-Member
**Scenario:** Non-member shopper selects express shipping
- **Given:** User is not a member
- **When:** Express shipping is selected at any subtotal
- **Then:** Shipping fee displays as $12.99

## Test Case 7: Express Shipping - Non-Member with Multiple Subtotals
**Scenario:** Non-member shopper with express shipping at various subtotals
- **Given:** User is not a member
- **When:** Express shipping is selected with subtotal $30.00
- **Then:** Shipping fee displays as $12.99
- **When:** Express shipping is selected with subtotal $75.00
- **Then:** Shipping fee displays as $12.99

## Test Case 8: Express Shipping - Member At Low Subtotal
**Scenario:** Member shopper selects express shipping below standard threshold
- **Given:** User is a member
- **When:** Order subtotal is $25.00 and express shipping is selected
- **Then:** Shipping fee displays as $7.99

## Test Case 9: Express Shipping - Member At High Subtotal
**Scenario:** Member shopper selects express shipping above standard threshold
- **Given:** User is a member
- **When:** Order subtotal is $100.00 and express shipping is selected
- **Then:** Shipping fee displays as $7.99

## Test Case 10: Shipping Option Toggle - Non-Member
**Scenario:** Non-member shopper switches between standard and express
- **Given:** User is not a member with subtotal $30.00
- **When:** Standard shipping is initially selected
- **Then:** Shipping fee displays as $5.99
- **When:** Shipping method is changed to express
- **Then:** Shipping fee updates to $12.99

## Test Case 11: Shipping Option Toggle - Member
**Scenario:** Member shopper switches between standard and express
- **Given:** User is a member with subtotal $30.00
- **When:** Standard shipping is initially selected
- **Then:** Shipping fee displays as $0.00
- **When:** Shipping method is changed to express
- **Then:** Shipping fee updates to $7.99

## Test Case 12: Total Price Calculation - Non-Member Standard
**Scenario:** Order total reflects correct shipping fee for non-member standard
- **Given:** User is not a member with subtotal $40.00
- **When:** Standard shipping is selected and checkout is reviewed
- **Then:** Subtotal $40.00 + Shipping $5.99 = Total $45.99

## Test Case 13: Total Price Calculation - Member Express
**Scenario:** Order total reflects correct shipping fee for member express
- **Given:** User is a member with subtotal $60.00
- **When:** Express shipping is selected and checkout is reviewed
- **Then:** Subtotal $60.00 + Shipping $7.99 = Total $67.99

## Test Case 14: Edge Case - Subtotal $50.01
**Scenario:** Non-member just above free shipping threshold
- **Given:** User is not a member
- **When:** Order subtotal is $50.01 and standard shipping is selected
- **Then:** Shipping fee displays as $0.00

## Test Case 15: Membership Status Change
**Scenario:** Shopper updates membership status during checkout
- **Given:** User completes items with subtotal $45.00 as non-member with standard shipping showing $5.99
- **When:** User opts into membership
- **Then:** Shipping fee updates to $0.00 without requiring reshipping method selection
