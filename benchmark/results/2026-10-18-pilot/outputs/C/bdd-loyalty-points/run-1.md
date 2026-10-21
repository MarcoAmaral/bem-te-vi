Feature: Loyalty Points Program
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  # Assumptions:
  # - Points are earned immediately after order completion
  # - Tier status is determined based on cumulative points at checkout
  # - Discounts are applied to the order subtotal before tax
  # - Points page response time is measured from request to full page load

  Background:
    Given a loyalty programme member exists
    And the member has 0 points
    And the member is on the Basic tier

  Scenario: Earn 1 point per whole dollar of order subtotal
    When the member completes an order with subtotal $24.99
    Then the member earns 24 points
    And the member's total points balance is 24

  Scenario: Points earned from order with multiple dollars
    When the member completes an order with subtotal $99.99
    Then the member earns 99 points

  Scenario: Member qualifies for Silver tier at 500 points
    Given the member has 500 points
    When the member views their account
    Then the member's tier is Silver

  Scenario: Member qualifies for Gold tier at 2000 points
    Given the member has 2000 points
    When the member views their account
    Then the member's tier is Gold

  Scenario: Silver tier member receives 5% discount
    Given the member has 500 points
    When the member proceeds to checkout with order subtotal $100.00
    Then the 5% tier discount is applied
    And the subtotal after discount is $95.00

  Scenario: Gold tier member receives 10% discount
    Given the member has 2000 points
    When the member proceeds to checkout with order subtotal $100.00
    Then the 10% tier discount is applied
    And the subtotal after discount is $90.00

  Scenario: Member below 500 points remains on Basic tier
    Given the member has 499 points
    When the member views their account
    Then the member's tier is Basic
    And no tier discount is applied

  Scenario: Redeem points with insufficient balance
    Given the member has 100 points
    When the member attempts to redeem 150 points
    Then the error message "You don't have enough points." is displayed
    And the member's points balance remains 100
    And no points are deducted

  Scenario: Redeem valid point amount
    Given the member has 100 points
    When the member redeems 75 points
    Then the redemption succeeds
    And the member's points balance is 25

  Scenario: Points page loads within acceptable time
    Given the member navigates to the points page
    When the page begins loading
    Then the page fully loads within 2 seconds
