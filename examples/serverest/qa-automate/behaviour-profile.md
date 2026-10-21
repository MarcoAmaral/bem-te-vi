# Behaviour profile: ServeRest cart API

Observed on `https://serverest.dev` (API version 3.2.2 per its OpenAPI document) on 2026-10-08, by calling the API directly. The browser front end (`https://front.serverest.dev`) was not explored, so navigation, toast and focus observations do not apply to these API tests.

- A duplicated `idProduto` in one `POST /carrinhos` returns 400 with `message` "Não é permitido possuir produto duplicado" and `idProdutosDuplicados` (an array of ids). The duplicate check ran before the stock check.
- A second `POST /carrinhos` for a user who has a cart returns 400 "Não é permitido ter mais de 1 carrinho".
- A successful `POST /carrinhos` returns 201 and reduces product stock by `quantidade` at once. A quantity equal to the stock is accepted (stock becomes 0).
- `DELETE /carrinhos/cancelar-compra` returns 200 and restores stock. With no cart it also returns 200, with the message "Não foi encontrado carrinho para esse usuário".
- `DELETE /carrinhos/concluir-compra` returns 200 and does not restore stock.
- `DELETE /produtos/{_id}` for a product in a cart, and `DELETE /usuarios/{_id}` for a user with a cart, return 400. Test teardown therefore cancels the cart first.
- Reads (`GET /carrinhos`, `GET /carrinhos/{_id}`, `GET /produtos/{_id}`) need no token.
- State is visible immediately after a write: no eventual consistency was seen, so the specs wait on the response of each call and never on a timer.
- The string `"2"` as `quantidade` is accepted (201) and stored as a string, with `quantidadeTotal` returned as `"02"`. TC-CART-030 asserts the declared behaviour (400) and therefore fails.
