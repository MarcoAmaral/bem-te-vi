# Test Cases for CART-12: Change the Quantity of an Item in the Cart

## AC-1: Valid Quantity Range (1–20)

| Test ID | Description | Precondition | Steps | Expected Result |
|---------|-------------|--------------|-------|-----------------|
| TC-1.1 | Accept minimum quantity of 1 | Item in cart with quantity > 1 | 1. Enter 1 in quantity field 2. Confirm change | Quantity updates to 1 |
| TC-1.2 | Accept maximum quantity of 20 | Item in cart with quantity < 20 | 1. Enter 20 in quantity field 2. Confirm change | Quantity updates to 20 |
| TC-1.3 | Accept valid quantity in middle range | Item in cart | 1. Enter 10 in quantity field 2. Confirm change | Quantity updates to 10 |
| TC-1.4 | Reject decimal numbers | Item in cart | 1. Enter 5.5 in quantity field 2. Attempt to confirm | Field rejects input or rounds to 5 or 6 (assumption: rejects) |
| TC-1.5 | Reject negative numbers | Item in cart | 1. Enter -5 in quantity field 2. Attempt to confirm | Field rejects input |
| TC-1.6 | Reject non-numeric characters | Item in cart | 1. Enter "ABC" in quantity field 2. Attempt to confirm | Field rejects input |

## AC-2: Remove Item on Quantity Zero

| Test ID | Description | Precondition | Steps | Expected Result |
|---------|-------------|--------------|-------|-----------------|
| TC-2.1 | Show confirmation dialog when entering 0 | Item in cart with quantity > 0 | 1. Enter 0 in quantity field | Dialog appears with text "Remove this item?" |
| TC-2.2 | Remove item when confirming | Confirmation dialog displayed | 1. Select **Confirm** button on dialog | Item is removed from cart |
| TC-2.3 | Keep item when canceling | Confirmation dialog displayed | 1. Select **Cancel** button on dialog | Dialog closes, item remains in cart with previous quantity |
| TC-2.4 | Restore previous quantity after cancel | Item quantity was 5, user entered 0 and canceled | 1. Enter 0 2. Select **Cancel** | Quantity field shows 5 |

## AC-3: Quantity Above Maximum (>20)

| Test ID | Description | Precondition | Steps | Expected Result |
|---------|-------------|--------------|-------|-----------------|
| TC-3.1 | Show error message for quantity 21 | Item in cart with quantity 10 | 1. Enter 21 in quantity field | Error message displays: "You can buy at most 20 of this item." |
| TC-3.2 | Show error message for quantity 100 | Item in cart with quantity 5 | 1. Enter 100 in quantity field | Error message displays: "You can buy at most 20 of this item." |
| TC-3.3 | Revert to previous quantity after exceeding max | Item in cart with quantity 15 | 1. Enter 25 in quantity field 2. (Error appears) | Quantity field reverts to 15 |
| TC-3.4 | Revert to previous quantity for boundary test | Item in cart with quantity 1 | 1. Enter 21 in quantity field | Quantity field reverts to 1 |

## Cross-Acceptance Criteria Tests

| Test ID | Description | Precondition | Steps | Expected Result |
|---------|-------------|--------------|-------|-----------------|
| TC-4.1 | Update cart total after quantity change | Item with unit price $10, quantity 5 in cart | 1. Change quantity to 8 | Cart total increases by $30 |
| TC-4.2 | Item remains in correct position after quantity change | Item at position 2 of 4 items in cart | 1. Change item quantity from 3 to 7 | Item remains at position 2 |
| TC-4.3 | Multiple items' quantities updated independently | Cart has 2 items, both quantity 5 | 1. Change first item to 10 2. Verify second item unchanged | First item is 10, second item remains 5 |

## Assumptions

- Decimal inputs are rejected (not rounded).
- The quantity field is a text input that validates on submission or on blur.
- The confirmation dialog has **Confirm** and **Cancel** buttons.
- The error message for exceeding the maximum appears inline or as a toast notification.
- "Previous quantity" refers to the quantity before the user's current input attempt.
- Cart total and item positioning update synchronously after a confirmed quantity change.
