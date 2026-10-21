# Feature: Loyalty Points and Tier Benefits
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given the loyalty programme is active
    And I am a logged-in loyalty programme member

  # AC-1: Point earning from order subtotal
  @loyalty @points @smoke @p0
  Scenario: Member earns 1 point per whole dollar of order subtotal
    Given I have a points balance of 0
    When I complete an order with subtotal $24.99
    Then I earn 24 points
    And my total points balance is 24

  @loyalty @points @regression @p1
  Scenario: Decimal cents in order subtotal are truncated, not rounded
    Given I have a points balance of 0
    When I complete an order with subtotal $100.99
    Then I earn 100 points
    And my total points balance is 100

  @loyalty @points @regression @p1
  Scenario: Order subtotal below $1.00 earns 0 points
    Given I have a points balance of 0
    When I complete an order with subtotal $0.99
    Then I earn 0 points
    And my total points balance is 0

  # AC-2: Tier system (Basic < 500, Silver ≥ 500, Gold ≥ 2000) and automatic discounts
  @loyalty @points @smoke @p0
  Scenario Outline: Member's tier is determined by points balance
    Given I have <points> points
    Then my loyalty tier is <tier>
    And my order discount rate is <discount_percent>%

    Examples:
      | points | tier   | discount_percent |
      | 0      | Basic  | 0                |
      | 499    | Basic  | 0                |
      | 500    | Silver | 5                |
      | 1999   | Silver | 5                |
      | 2000   | Gold   | 10               |
      | 5000   | Gold   | 10               |

  @loyalty @points @smoke @p0
  Scenario: Silver member receives 5% automatic discount on order checkout
    Given I have 500 points and my tier is Silver
    When I proceed to checkout with an order subtotal of $100.00
    Then the system applies a 5% discount
    And my order total is $95.00

  @loyalty @points @smoke @p0
  Scenario: Gold member receives 10% automatic discount on order checkout
    Given I have 2000 points and my tier is Gold
    When I proceed to checkout with an order subtotal of $100.00
    Then the system applies a 10% discount
    And my order total is $90.00

  @loyalty @points @regression @p1
  Scenario: Basic member receives no automatic discount
    Given I have 100 points and my tier is Basic
    When I proceed to checkout with an order subtotal of $100.00
    Then no discount is applied
    And my order total is $100.00

  # Added by QA, AC-2 does not specify immediate tier change behavior; assumption: tier updates apply instantly
  @loyalty @points @regression @p2
  Scenario: Tier upgrade takes effect immediately after reaching threshold
    Given I have 499 points and my tier is Basic
    When I complete an order earning 1 point (subtotal $1.00)
    Then my points balance is 500
    And my tier changes to Silver immediately
    And my next order will receive the 5% Silver discount

  # AC-3: Redemption failure when balance insufficient
  @loyalty @points @smoke @p0
  Scenario: Member cannot redeem more points than available
    Given I have a points balance of 100
    When I attempt to redeem 150 points
    Then the redemption fails
    And the error message displays "You don't have enough points."
    And my points balance remains 100

  @loyalty @points @regression @p1
  Scenario: Member can redeem up to their available balance
    Given I have a points balance of 250
    When I redeem 250 points
    Then the redemption succeeds
    And my points balance is 0

  # Added by QA, AC-3 does not specify partial redemption; assumption: any amount ≤ balance can be redeemed
  @loyalty @points @regression @p1
  Scenario: Member can redeem a partial amount of their balance
    Given I have a points balance of 500
    When I redeem 200 points
    Then the redemption succeeds
    And my points balance is 300

  # AC-4: Performance requirement (metric not specified in AC; assuming web standard 2-second load time)
  @loyalty @points @performance @p2
  Scenario: Loyalty points page loads within acceptable performance threshold
    Given I navigate to my loyalty points account page
    When the page begins loading
    Then the page fully loads and is interactive within 2 seconds
    And my points balance is displayed
    And my current tier is displayed
    And any redemption options are available
