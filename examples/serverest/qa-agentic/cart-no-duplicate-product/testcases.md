---
feature: Cart - no duplicate product
feature_code: CART
tc_count: 33
ado_user_stories: []
risk_level: MEDIUM
last_updated: 2026-10-08
---

<!-- markdownlint-disable MD060 -->

<!-- Trace: TC-CART-NNN -> checklist.md "Requirement N" check -> requirements.md item N. Each case notes its requirement in the ADO Story field. -->

## TC-CART-001: Same product listed twice is rejected

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@smoke @api @p0 @candidate @cart` |
| **ADO Story**          | N/A - no tracker; Requirement 1, check 1 |
| **Automation Score**   | HIGH (not scored) |
| **ISTQB Technique**    | EP |
| **Precondition**       | Customer with a valid token and no cart; product P with stock 10 |
| **Steps**              | 1. `POST /carrinhos` with `produtos` containing P twice |
| **Expected**           | HTTP 400 |
| **data-testid needed** | N/A - API test, no UI |

## TC-CART-002: Same product listed once is accepted (control)

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@smoke @api @p0 @candidate @cart` |
| **ADO Story**          | N/A - no tracker; Requirement 1, check 2 |
| **Automation Score**   | HIGH (not scored) |
| **ISTQB Technique**    | EP |
| **Precondition**       | Customer with a valid token and no cart; product P with stock 10 |
| **Steps**              | 1. `POST /carrinhos` with `produtos` containing P once |
| **Expected**           | HTTP 201 |
| **data-testid needed** | N/A - API test, no UI |

## TC-CART-003: Repeated product as second and third item of a three-item list is rejected

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@smoke @api @p0 @candidate @cart` |
| **ADO Story**          | N/A - no tracker; Requirement 1, check 3 |
| **Automation Score**   | HIGH (not scored) |
| **ISTQB Technique**    | EP |
| **Precondition**       | Customer with a valid token and no cart; products A, B with stock 10 |
| **Steps**              | 1. `POST /carrinhos` with `produtos` = [A, B, B] |
| **Expected**           | HTTP 400 |
| **data-testid needed** | N/A - API test, no UI |

## TC-CART-004: Duplicate rejection carries the exact message

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@regression @api @p1 @candidate @cart` |
| **ADO Story**          | N/A - no tracker; Requirement 2, check 1 |
| **Automation Score**   | HIGH (not scored) |
| **ISTQB Technique**    | EP |
| **Precondition**       | Customer with a valid token and no cart; product P with stock 10 |
| **Steps**              | 1. `POST /carrinhos` with `produtos` containing P twice |
| **Expected**           | `message` equals "Não é permitido possuir produto duplicado" |
| **data-testid needed** | N/A - API test, no UI |

## TC-CART-005: Duplicate message differs from the second-cart message

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@regression @api @p1 @candidate @cart` |
| **ADO Story**          | N/A - no tracker; Requirement 2, check 2 |
| **Automation Score**   | HIGH (not scored) |
| **ISTQB Technique**    | EP |
| **Precondition**       | Customer with a valid token and no cart; product P with stock 10 |
| **Steps**              | 1. `POST /carrinhos` with P twice <br> 2. Compare its `message` with "Não é permitido ter mais de 1 carrinho" |
| **Expected**           | The `message` of the duplicate rejection is not "Não é permitido ter mais de 1 carrinho" |
| **data-testid needed** | N/A - API test, no UI |

## TC-CART-006: Duplicate rejection lists the repeated id

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@regression @api @p2 @candidate @cart` |
| **ADO Story**          | N/A - no tracker; Requirement 3, check 1. Note: `idProdutosDuplicados` is not in the written API documentation |
| **Automation Score**   | HIGH (not scored) |
| **ISTQB Technique**    | EP |
| **Precondition**       | Customer with a valid token and no cart; product P with stock 10 |
| **Steps**              | 1. `POST /carrinhos` with `produtos` containing P twice |
| **Expected**           | `idProdutosDuplicados` contains the id of P |
| **data-testid needed** | N/A - API test, no UI |

## TC-CART-007: Two repeated products are both listed

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@regression @api @p2 @candidate @cart` |
| **ADO Story**          | N/A - no tracker; Requirement 3, check 2 |
| **Automation Score**   | HIGH (not scored) |
| **ISTQB Technique**    | EP |
| **Precondition**       | Customer with a valid token and no cart; products A, B with stock 10 |
| **Steps**              | 1. `POST /carrinhos` with `produtos` = [A, A, B, B] |
| **Expected**           | `idProdutosDuplicados` contains the ids of both A and B |
| **data-testid needed** | N/A - API test, no UI |

## TC-CART-008: Same product and same quantity is rejected

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@regression @api @p1 @candidate @cart` |
| **ADO Story**          | N/A - no tracker; Requirement 4, check 1 |
| **Automation Score**   | HIGH (not scored) |
| **ISTQB Technique**    | Decision Table |
| **Precondition**       | Customer with a valid token and no cart; product P with stock 10 |
| **Steps**              | 1. `POST /carrinhos` with P (`quantidade` 1) and P (`quantidade` 1) |
| **Expected**           | HTTP 400 |
| **data-testid needed** | N/A - API test, no UI |

## TC-CART-009: Same product and different quantities is rejected

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@regression @api @p1 @candidate @cart` |
| **ADO Story**          | N/A - no tracker; Requirement 4, check 2 |
| **Automation Score**   | HIGH (not scored) |
| **ISTQB Technique**    | Decision Table |
| **Precondition**       | Customer with a valid token and no cart; product P with stock 10 |
| **Steps**              | 1. `POST /carrinhos` with P (`quantidade` 1) and P (`quantidade` 2) |
| **Expected**           | HTTP 400 |
| **data-testid needed** | N/A - API test, no UI |

## TC-CART-010: Same product, one quantity within stock and one over stock, returns the duplicate message

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@regression @api @p1 @candidate @cart` |
| **ADO Story**          | N/A - no tracker; Requirement 4, check 3. Note: the order of checks is undocumented, so this case records observed precedence |
| **Automation Score**   | HIGH (not scored) |
| **ISTQB Technique**    | Decision Table |
| **Precondition**       | Customer with a valid token and no cart; product P with stock 10 |
| **Steps**              | 1. `POST /carrinhos` with P (`quantidade` 1) and P (`quantidade` 11) |
| **Expected**           | HTTP 400 with the duplicate message |
| **data-testid needed** | N/A - API test, no UI |

## TC-CART-011: Rejected duplicate request leaves the user without a cart

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@regression @api @p1 @candidate @cart` |
| **ADO Story**          | N/A - no tracker; Requirement 5, check 1 |
| **Automation Score**   | HIGH (not scored) |
| **ISTQB Technique**    | State Transition |
| **Precondition**       | Customer with a valid token and no cart; product P with stock 10 |
| **Steps**              | 1. `POST /carrinhos` with P twice (rejected) <br> 2. `GET /carrinhos?idUsuario=<customer>` |
| **Expected**           | `quantidade` of the list is 0 |
| **data-testid needed** | N/A - API test, no UI |

## TC-CART-012: User can still create a valid cart after a rejected duplicate request

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@regression @api @p1 @candidate @cart` |
| **ADO Story**          | N/A - no tracker; Requirement 5, check 2 |
| **Automation Score**   | HIGH (not scored) |
| **ISTQB Technique**    | State Transition |
| **Precondition**       | Customer with a valid token and no cart; product P with stock 10 |
| **Steps**              | 1. `POST /carrinhos` with P twice (rejected) <br> 2. `POST /carrinhos` with P once |
| **Expected**           | Step 2 returns HTTP 201 |
| **data-testid needed** | N/A - API test, no UI |

## TC-CART-013: Rejected duplicate request does not change stock

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@regression @api @p1 @candidate @cart` |
| **ADO Story**          | N/A - no tracker; Requirement 6, check 1 |
| **Automation Score**   | HIGH (not scored) |
| **ISTQB Technique**    | State Transition |
| **Precondition**       | Customer with a valid token and no cart; product P with stock 10 |
| **Steps**              | 1. `GET /produtos/<P>` and note `quantidade` <br> 2. `POST /carrinhos` with P twice (rejected) <br> 3. `GET /produtos/<P>` |
| **Expected**           | `quantidade` in step 3 equals the value in step 1 |
| **data-testid needed** | N/A - API test, no UI |

## TC-CART-014: Minimum quantity (1) is accepted

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@smoke @api @p0 @candidate @cart` |
| **ADO Story**          | N/A - no tracker; Requirement 7, check 1 |
| **Automation Score**   | HIGH (not scored) |
| **ISTQB Technique**    | BVA |
| **Precondition**       | Customer with a valid token and no cart; product P with stock 10 |
| **Steps**              | 1. `POST /carrinhos` with P (`quantidade` 1) |
| **Expected**           | HTTP 201 |
| **data-testid needed** | N/A - API test, no UI |

## TC-CART-015: Quantity equal to stock is accepted and empties the stock

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@regression @api @p1 @candidate @cart` |
| **ADO Story**          | N/A - no tracker; Requirement 7, check 2 |
| **Automation Score**   | HIGH (not scored) |
| **ISTQB Technique**    | BVA |
| **Precondition**       | Customer with a valid token and no cart; product P with stock 10 |
| **Steps**              | 1. `POST /carrinhos` with P (`quantidade` 10) <br> 2. `GET /produtos/<P>` |
| **Expected**           | Step 1 returns HTTP 201; step 2 shows `quantidade` 0 |
| **data-testid needed** | N/A - API test, no UI |

## TC-CART-016: Quantity of stock plus 1 is rejected

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@regression @api @p1 @candidate @cart` |
| **ADO Story**          | N/A - no tracker; Requirement 7, check 3 |
| **Automation Score**   | HIGH (not scored) |
| **ISTQB Technique**    | BVA |
| **Precondition**       | Customer with a valid token and no cart; product P with stock 10 |
| **Steps**              | 1. `POST /carrinhos` with P (`quantidade` 11) |
| **Expected**           | HTTP 400 |
| **data-testid needed** | N/A - API test, no UI |

## TC-CART-017: Quantity 0 is rejected

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@regression @api @p1 @candidate @cart` |
| **ADO Story**          | N/A - no tracker; Requirement 7, check 4 |
| **Automation Score**   | HIGH (not scored) |
| **ISTQB Technique**    | BVA |
| **Precondition**       | Customer with a valid token and no cart; product P with stock 10 |
| **Steps**              | 1. `POST /carrinhos` with P (`quantidade` 0) |
| **Expected**           | HTTP 400 |
| **data-testid needed** | N/A - API test, no UI |

## TC-CART-018: Two different products in one request are accepted

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@smoke @api @p0 @candidate @cart` |
| **ADO Story**          | N/A - no tracker; Requirement 7, check 5 |
| **Automation Score**   | HIGH (not scored) |
| **ISTQB Technique**    | BVA |
| **Precondition**       | Customer with a valid token and no cart; products A, B with stock 10 |
| **Steps**              | 1. `POST /carrinhos` with A and B, one each |
| **Expected**           | HTTP 201 |
| **data-testid needed** | N/A - API test, no UI |

## TC-CART-019: Second cart with a different product is rejected

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@smoke @api @p0 @candidate @cart` |
| **ADO Story**          | N/A - no tracker; Requirement 8, check 1 |
| **Automation Score**   | HIGH (not scored) |
| **ISTQB Technique**    | State Transition |
| **Precondition**       | Customer with a valid token and an existing cart containing product A; product B with stock 10 |
| **Steps**              | 1. `POST /carrinhos` with B |
| **Expected**           | HTTP 400 |
| **data-testid needed** | N/A - API test, no UI |

## TC-CART-020: Second cart with the same product is rejected

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@smoke @api @p0 @candidate @cart` |
| **ADO Story**          | N/A - no tracker; Requirement 8, check 2 |
| **Automation Score**   | HIGH (not scored) |
| **ISTQB Technique**    | State Transition |
| **Precondition**       | Customer with a valid token and an existing cart containing product A |
| **Steps**              | 1. `POST /carrinhos` with A |
| **Expected**           | HTTP 400 |
| **data-testid needed** | N/A - API test, no UI |

## TC-CART-021: First cart for a user without a cart is accepted (control)

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@smoke @api @p0 @candidate @cart` |
| **ADO Story**          | N/A - no tracker; Requirement 8, check 3 |
| **Automation Score**   | HIGH (not scored) |
| **ISTQB Technique**    | State Transition |
| **Precondition**       | Customer with a valid token and no cart; product P with stock 10 |
| **Steps**              | 1. `POST /carrinhos` with P |
| **Expected**           | HTTP 201 |
| **data-testid needed** | N/A - API test, no UI |

## TC-CART-022: Second-cart rejection carries the exact message

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@regression @api @p1 @candidate @cart` |
| **ADO Story**          | N/A - no tracker; Requirement 9, check 1 |
| **Automation Score**   | HIGH (not scored) |
| **ISTQB Technique**    | EP |
| **Precondition**       | Customer with a valid token and an existing cart |
| **Steps**              | 1. `POST /carrinhos` with any valid product |
| **Expected**           | `message` equals "Não é permitido ter mais de 1 carrinho" |
| **data-testid needed** | N/A - API test, no UI |

## TC-CART-023: Rejected second cart leaves the existing cart unchanged

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@regression @api @p1 @candidate @cart` |
| **ADO Story**          | N/A - no tracker; Requirement 10, check 1 |
| **Automation Score**   | HIGH (not scored) |
| **ISTQB Technique**    | State Transition |
| **Precondition**       | Customer with a valid token and an existing cart (id C) containing product A |
| **Steps**              | 1. `GET /carrinhos/<C>` and keep the body <br> 2. `POST /carrinhos` with another product (rejected) <br> 3. `GET /carrinhos/<C>` |
| **Expected**           | `produtos`, `precoTotal` and `quantidadeTotal` in step 3 equal those in step 1 |
| **data-testid needed** | N/A - API test, no UI |

## TC-CART-024: Rejected second cart does not reduce stock again

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@regression @api @p1 @candidate @cart` |
| **ADO Story**          | N/A - no tracker; Requirement 11, check 1 |
| **Automation Score**   | HIGH (not scored) |
| **ISTQB Technique**    | State Transition |
| **Precondition**       | Product P with stock 10; customer with a valid token and no cart |
| **Steps**              | 1. `POST /carrinhos` with P (`quantidade` 2) <br> 2. `GET /produtos/<P>` <br> 3. `POST /carrinhos` with P (`quantidade` 2) (rejected) <br> 4. `GET /produtos/<P>` |
| **Expected**           | Stock after step 2 is 8; stock after step 4 is still 8 |
| **data-testid needed** | N/A - API test, no UI |

## TC-CART-025: Cancelling a cart restores stock

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@regression @api @p1 @candidate @cart` |
| **ADO Story**          | N/A - no tracker; Requirement 12, check 1 |
| **Automation Score**   | HIGH (not scored) |
| **ISTQB Technique**    | State Transition |
| **Precondition**       | Customer with a valid token and a cart for product P (`quantidade` 2); P had stock 10 before the cart |
| **Steps**              | 1. `DELETE /carrinhos/cancelar-compra` <br> 2. `GET /produtos/<P>` |
| **Expected**           | The user has no cart; stock of P is back to 10 |
| **data-testid needed** | N/A - API test, no UI |

## TC-CART-026: User can create a new cart with the product from the cancelled cart

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@regression @api @p1 @candidate @cart` |
| **ADO Story**          | N/A - no tracker; Requirement 12, check 2 |
| **Automation Score**   | HIGH (not scored) |
| **ISTQB Technique**    | State Transition |
| **Precondition**       | Customer with a valid token who has just cancelled a cart that contained product P |
| **Steps**              | 1. `POST /carrinhos` with P |
| **Expected**           | HTTP 201 |
| **data-testid needed** | N/A - API test, no UI |

## TC-CART-027: Cancelling when there is no cart changes nothing

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@regression @api @p2 @candidate @cart` |
| **ADO Story**          | N/A - no tracker; Requirement 12, check 3 |
| **Automation Score**   | HIGH (not scored) |
| **ISTQB Technique**    | State Transition |
| **Precondition**       | Customer with a valid token and no cart |
| **Steps**              | 1. `DELETE /carrinhos/cancelar-compra` |
| **Expected**           | HTTP 200 with `message` "Não foi encontrado carrinho para esse usuário" |
| **data-testid needed** | N/A - API test, no UI |

## TC-CART-028: Request without an Authorization header is rejected

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@regression @api @p1 @candidate @cart` |
| **ADO Story**          | N/A - no tracker; Requirement 13, check 1 |
| **Automation Score**   | HIGH (not scored) |
| **ISTQB Technique**    | EP |
| **Precondition**       | Product P with stock 10 |
| **Steps**              | 1. `POST /carrinhos` with P and no `Authorization` header |
| **Expected**           | HTTP 401 |
| **data-testid needed** | N/A - API test, no UI |

## TC-CART-029: Request with a malformed token is rejected

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@regression @api @p1 @candidate @cart` |
| **ADO Story**          | N/A - no tracker; Requirement 13, check 2. Note: expired-token behaviour is left as a manual check |
| **Automation Score**   | HIGH (not scored) |
| **ISTQB Technique**    | EP |
| **Precondition**       | Product P with stock 10 |
| **Steps**              | 1. `POST /carrinhos` with P and `Authorization: Bearer not-a-token` |
| **Expected**           | HTTP 401 |
| **data-testid needed** | N/A - API test, no UI |

## TC-CART-030: `quantidade` as the string "2" is rejected

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@regression @api @p2 @candidate @cart` |
| **ADO Story**          | N/A - no tracker; Requirement 14, check 1. Note: the requirement states this is expected to fail today |
| **Automation Score**   | HIGH (not scored) |
| **ISTQB Technique**    | Error Guessing |
| **Precondition**       | Customer with a valid token and no cart; product P with stock 10 |
| **Steps**              | 1. `POST /carrinhos` with P and `quantidade` as the JSON string `"2"` |
| **Expected**           | HTTP 400 |
| **data-testid needed** | N/A - API test, no UI |

## TC-CART-031: `quantidade` 1.5 is rejected

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@regression @api @p2 @candidate @cart` |
| **ADO Story**          | N/A - no tracker; Requirement 14, check 2 |
| **Automation Score**   | HIGH (not scored) |
| **ISTQB Technique**    | Error Guessing |
| **Precondition**       | Customer with a valid token and no cart; product P with stock 10 |
| **Steps**              | 1. `POST /carrinhos` with P and `quantidade` 1.5 |
| **Expected**           | HTTP 400 |
| **data-testid needed** | N/A - API test, no UI |

## TC-CART-032: `quantidade` null is rejected

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@regression @api @p2 @candidate @cart` |
| **ADO Story**          | N/A - no tracker; Requirement 14, check 3 |
| **Automation Score**   | HIGH (not scored) |
| **ISTQB Technique**    | Error Guessing |
| **Precondition**       | Customer with a valid token and no cart; product P with stock 10 |
| **Steps**              | 1. `POST /carrinhos` with P and `quantidade` null |
| **Expected**           | HTTP 400 |
| **data-testid needed** | N/A - API test, no UI |

## TC-CART-033: Exploratory charter on type confusion in cart numeric fields

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@regression @manual @p2 @manual-only @cart` |
| **ADO Story**          | N/A - no tracker; Requirement 14, check 4 |
| **Automation Score**   | LOW (not scored) |
| **ISTQB Technique**    | Exploratory |
| **Precondition**       | Customer with a valid token and no cart; product P with stock 10 |
| **Steps**              | 1. Time-box 30 minutes <br> 2. Send numeric cart fields (`quantidade`) as other JSON types and encodings <br> 3. Read the stored cart (`precoTotal`, `quantidadeTotal`) after every accepted request |
| **Expected**           | Notes on every accepted request and every stored value whose type differs from the declared one |
| **data-testid needed** | N/A - API test, no UI |
