Feature brief: Split payment (release 5.3)

Customers can pay for one order with two cards. They choose how much goes on the first card; the rest goes on the second. Amounts are handled in cents; when an amount cannot be split evenly, the remainder cent goes on the first card. Both charges go through the external payment gateway PayGate. If the second charge is declined, the first charge must be refunded automatically within 60 seconds.

Constraints:

- PayGate's sandbox is available only on Tuesdays and Thursdays.
- Release date: 10 working days from today.
- One tester, half time, plus the two developers who build the feature.
- The existing single-card checkout must keep working; it handles about 4,000 orders a day.
