<!-- markdownlint-disable MD022 MD032 -->

# Test Design Checklist

Source: requirements.md

## Requirement 1: A `POST /carrinhos` request whose `produtos` list contains the same `idProduto` in two items is rejected with HTTP status 400
- Technique: EP
- Checks:
  - [ ] Invalid partition: one product listed twice in `produtos` returns 400
  - [ ] Valid partition (control): the same product listed once returns 201
  - [ ] Invalid partition: the repeated product is the second and the third item of a three-item list returns 400
- Priority: P0
- Suite: @smoke
- Level: @api

## Requirement 2: The 400 response for a repeated `idProduto` has the `message` "Não é permitido possuir produto duplicado"
- Technique: EP
- Checks:
  - [ ] The `message` equals "Não é permitido possuir produto duplicado" exactly
  - [ ] The `message` differs from the message for a second cart ("Não é permitido ter mais de 1 carrinho")
- Priority: P1
- Suite: @regression
- Level: @api

## Requirement 3: The 400 response for a repeated `idProduto` lists the repeated id in `idProdutosDuplicados`
- Technique: EP
- Checks:
  - [ ] `idProdutosDuplicados` contains the repeated `idProduto`
  - [ ] When two different products are each repeated, `idProdutosDuplicados` contains both ids
  - [ ] Note: this field is not in the written API documentation; the check is taken from the context notes of the requirement source
- Priority: P2
- Suite: @regression
- Level: @api

## Requirement 4: A `POST /carrinhos` request with a repeated `idProduto` is rejected even when the two items have different `quantidade` values
- Technique: Decision Table
- Checks:
  - [ ] Same `idProduto`, same `quantidade` → 400
  - [ ] Same `idProduto`, different `quantidade` → 400
  - [ ] Same `idProduto`, one `quantidade` within stock and the other over stock → 400 with the duplicate message (rule precedence; the order of checks is undocumented)
- Priority: P1
- Suite: @regression
- Level: @api

## Requirement 5: A rejected duplicate request does not create a cart for the user
- Technique: State Transition
- Checks:
  - [ ] Precondition: user has no cart. After the rejected request, `GET /carrinhos?idUsuario=<user>` returns `quantidade` 0
  - [ ] After the rejected request the same user can still create a valid cart with 201
- Priority: P1
- Suite: @regression
- Level: @api

## Requirement 6: A rejected duplicate request does not reduce the stock of the product
- Technique: State Transition
- Checks:
  - [ ] `GET /produtos/<id>` before and after the rejected request returns the same `quantidade`
- Priority: P1
- Suite: @regression
- Level: @api

## Requirement 7: A `POST /carrinhos` request is accepted with HTTP status 201 when every `idProduto` in `produtos` is different
- Technique: BVA
- Checks:
  - [ ] One item with `quantidade` 1 (minimum) returns 201
  - [ ] One item with `quantidade` equal to the stock returns 201 and leaves the stock at 0
  - [ ] One item with `quantidade` equal to the stock plus 1 returns 400
  - [ ] One item with `quantidade` 0 returns 400
  - [ ] Two different products in one request return 201
- Priority: P0
- Suite: @smoke
- Level: @api

## Requirement 8: A user who already has a cart is rejected with HTTP status 400 on a second `POST /carrinhos`
- Technique: State Transition
- Checks:
  - [ ] State "has a cart" + event "POST /carrinhos" with a different product → 400
  - [ ] State "has a cart" + event "POST /carrinhos" with the same product → 400
  - [ ] State "no cart" + event "POST /carrinhos" → 201 (control)
- Priority: P0
- Suite: @smoke
- Level: @api

## Requirement 9: The 400 response for a second cart has the `message` "Não é permitido ter mais de 1 carrinho"
- Technique: EP
- Checks:
  - [ ] The `message` equals "Não é permitido ter mais de 1 carrinho" exactly
- Priority: P1
- Suite: @regression
- Level: @api

## Requirement 10: A rejected second cart request leaves the existing cart unchanged
- Technique: State Transition
- Checks:
  - [ ] `GET /carrinhos/<id>` before and after the rejected request returns the same `produtos`, `precoTotal` and `quantidadeTotal`
- Priority: P1
- Suite: @regression
- Level: @api

## Requirement 11: A rejected second cart request does not reduce the stock of the product again
- Technique: State Transition
- Checks:
  - [ ] Stock after the first cart equals stock before minus `quantidade`; stock after the rejected second request is unchanged
- Priority: P1
- Suite: @regression
- Level: @api

## Requirement 12: After `DELETE /carrinhos/cancelar-compra`, the same user can create a new cart that contains the product from the cancelled cart
- Technique: State Transition
- Checks:
  - [ ] State "has a cart" + event "cancelar-compra" → state "no cart", stock restored to its original value
  - [ ] State "no cart" after cancel + event "POST /carrinhos" with the same product → 201
  - [ ] Event "cancelar-compra" in state "no cart" → 200 with "Não foi encontrado carrinho para esse usuário" (no state change)
- Priority: P1
- Suite: @regression
- Level: @api

## Requirement 13: A `POST /carrinhos` request without an `Authorization` token is rejected with HTTP status 401
- Technique: EP
- Checks:
  - [ ] No `Authorization` header → 401
  - [ ] Malformed token value → 401
  - [ ] Note: the requirement does not say whether an expired token is covered; expired-token is left as a manual check
- Priority: P1
- Suite: @regression
- Level: @api

## Requirement 14: A `POST /carrinhos` request whose `quantidade` is a JSON string instead of an integer is rejected with HTTP status 400
- Technique: Error Guessing
- Checks:
  - [ ] `quantidade` as the string `"2"` → 400 (the requirement notes this is expected to fail today)
  - [ ] `quantidade` as `1.5` → 400
  - [ ] `quantidade` as `null` → 400
  - [ ] Exploratory: a charter on type confusion in other numeric cart fields
- Priority: P2
- Suite: @regression
- Level: @api
