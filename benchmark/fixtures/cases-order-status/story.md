Story ORD-4: Order status changes

As a store operator, I want every order to move through a fixed set of statuses, so that customers and staff always see where an order is.

An order is created with the status Placed.

- AC-1: Recording a payment on a Placed order changes its status to Paid.
- AC-2: Marking a Paid order as shipped changes its status to Shipped.
- AC-3: Confirming delivery of a Shipped order changes its status to Delivered.
- AC-4: A Placed or Paid order can be cancelled; its status becomes Cancelled.
- AC-5: Cancelling a Shipped order is refused with "Shipped orders cannot be cancelled."
