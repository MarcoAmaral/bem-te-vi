# Feature: Loyalty Points Program

```gherkin
Feature: Loyalty Points Program
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Scenario: Member earns 1 point per whole dollar of order subtotal
    Given a member with 0 points
    When they place an order with a subtotal of $24.99
    Then they should earn 24 points
    And their points balance should be 24

  Scenario: Member earns points on a whole dollar amount
    Given a member with 50 points
    When they place an order with a subtotal of $100.00
    Then they should earn 100 points
    And their points balance should be 150

  Scenario: Member earns points on a large order
    Given a member with 0 points
    When they place an order with a subtotal of $1500.75
    Then they should earn 1500 points
    And their points balance should be 1500

  Scenario: Member below 500 points has Basic tier
    Given a member with 0 points
    When they view their tier status
    Then their tier should be "Basic"

  Scenario: Member with 499 points remains in Basic tier
    Given a member with 499 points
    When they view their tier status
    Then their tier should be "Basic"

  Scenario: Member reaches Silver tier at 500 points
    Given a member with 500 points
    When they view their tier status
    Then their tier should be "Silver"

  Scenario: Member between 500 and 1999 points maintains Silver tier
    Given a member with 1500 points
    When they view their tier status
    Then their tier should be "Silver"

  Scenario: Member reaches Gold tier at 2000 points
    Given a member with 2000 points
    When they view their tier status
    Then their tier should be "Gold"

  Scenario: Silver member receives 5% discount on orders
    Given a member with 500 points in Silver tier
    When they place an order with a subtotal of $100.00
    Then a 5% discount should be automatically applied
    And the order total should be $95.00

  Scenario: Gold member receives 10% discount on orders
    Given a member with 2000 points in Gold tier
    When they place an order with a subtotal of $100.00
    Then a 10% discount should be automatically applied
    And the order total should be $90.00

  Scenario: Basic member receives no discount
    Given a member with 100 points in Basic tier
    When they place an order with a subtotal of $100.00
    Then no discount should be applied
    And the order total should be $100.00

  Scenario: Member attempting to redeem more points than balance
    Given a member with 100 points
    When they attempt to redeem 150 points
    Then they should see the message "You don't have enough points."
    And their points balance should remain 100
    And no points should be deducted

  Scenario: Member attempting to redeem exactly their balance
    Given a member with 100 points
    When they attempt to redeem 100 points
    Then the redemption should succeed
    And their points balance should be 0

  Scenario: Points page loads within acceptable time
    Given a member with an active loyalty account
    When they navigate to the loyalty points page
    Then the page should load within 2 seconds
    And all points and tier information should be displayed

  Scenario: Points page loads quickly for member with large points balance
    Given a member with 50000 points
    When they navigate to the loyalty points page
    Then the page should load within 2 seconds
```

**Assumptions:**
- Points are earned automatically upon order completion based on order subtotal floored to whole dollars
- Tier discounts are applied automatically at checkout for all subsequent orders (not redeemed)
- Redemption is a separate action where members can apply points as a discount to future purchases
- "Fast load" is interpreted as loading within 2 seconds
- New members start with 0 points and Basic tier
- Points balance and tier are updated immediately after purchase completion
- Fractional points are truncated (floor function applied)
