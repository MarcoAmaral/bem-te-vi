# Loyalty Points - Gherkin Scenarios

```gherkin
Feature: Loyalty Points Programme
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Scenario: Member earns one point per whole dollar of order subtotal
    Given a member has 0 points
    When the member completes an order with a subtotal of $24.99
    Then the member's balance increases by 24 points
    And the final balance is 24 points

  Scenario: Member earns points only for whole dollars
    Given a member has 100 points
    When the member completes an order with a subtotal of $49.99
    Then the member earns 49 points
    And the final balance is 149 points

  Scenario: Member in Basic tier receives no discount
    Given a member has 300 points
    And is classified as Basic tier
    When the member checks their tier status
    Then the member should not receive any discount

  Scenario: Member in Silver tier receives 5% discount
    Given a member has 500 points
    And is classified as Silver tier
    When the member completes an order with a subtotal of $100
    Then the member receives a 5% discount
    And the discounted subtotal is $95

  Scenario: Member in Gold tier receives 10% discount
    Given a member has 2000 points
    And is classified as Gold tier
    When the member completes an order with a subtotal of $100
    Then the member receives a 10% discount
    And the discounted subtotal is $90

  Scenario: Tier classification updates when crossing threshold
    Given a member has 499 points in Basic tier
    When the member completes an order with a subtotal of $1.50 and earns 1 point
    Then the member is promoted to Silver tier
    And the member now qualifies for 5% discount

  Scenario: Member attempting to redeem insufficient points receives error
    Given a member has 100 points
    When the member attempts to redeem 150 points
    Then the redemption fails
    And the message "You don't have enough points." is displayed
    And the member's balance remains 100 points

  Scenario: Member successfully redeems points within balance
    Given a member has 300 points
    When the member redeems 150 points
    Then the redemption succeeds
    And the member's balance becomes 150 points

  Scenario: Loyalty points page loads with acceptable performance
    When a member navigates to their loyalty points page
    Then the page loads within 2 seconds
    And all account balance, tier level, and redemption options are visible
```
