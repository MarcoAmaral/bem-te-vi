# Requirements: A customer cannot add the same product to the cart twice

Source: user-provided story "As a customer, I can't add the same product to my cart twice", read against the ServeRest API documentation (`https://serverest.dev/swagger.json`, version 3.2.2) and the live API at `https://serverest.dev` on 2026-10-08

Context notes: No local repository or knowledge base was found, so the OpenAPI document is the only written source and the live API was called to check it (Tier 1 wins for current behaviour). (a) The API has no operation to add a product to an existing cart: a user may own one cart and there is no PUT/PATCH, so "twice" can only happen inside one `POST /carrinhos` request, and a second `POST /carrinhos` is rejected for a different reason (one cart per user); requirements 1-6 cover the first case and 7-9 the second, an assumption about the story's intent. (b) Docs and behaviour disagree in places: the request schema declares `produtos` as an object but the API requires an array; the documented 400 body is only `{message}` but the duplicate rejection also returns `idProdutosDuplicados` (requirement 3 is taken from the live API, not the docs). (c) Live API accepts the string `"2"` as `quantidade` and returns `quantidadeTotal: "02"`; requirement 14 states what the schema declares and is expected to fail today. (d) "Customer" is taken as a non-administrator user (`administrador: "false"`); the cart route is not documented as restricted by role. (e) Not found in any source: the order of validation when a request breaks several rules at once, and the retention of data on the public instance.

1. A `POST /carrinhos` request whose `produtos` list contains the same `idProduto` in two items is rejected with HTTP status 400.
2. The 400 response for a repeated `idProduto` has the `message` "Não é permitido possuir produto duplicado".
3. The 400 response for a repeated `idProduto` lists the repeated id in `idProdutosDuplicados`.
4. A `POST /carrinhos` request with a repeated `idProduto` is rejected even when the two items have different `quantidade` values.
5. A rejected duplicate request does not create a cart for the user.
6. A rejected duplicate request does not reduce the stock of the product.
7. A `POST /carrinhos` request is accepted with HTTP status 201 when every `idProduto` in `produtos` is different.
8. A user who already has a cart is rejected with HTTP status 400 on a second `POST /carrinhos`.
9. The 400 response for a second cart has the `message` "Não é permitido ter mais de 1 carrinho".
10. A rejected second cart request leaves the existing cart unchanged.
11. A rejected second cart request does not reduce the stock of the product again.
12. After `DELETE /carrinhos/cancelar-compra`, the same user can create a new cart that contains the product from the cancelled cart.
13. A `POST /carrinhos` request without an `Authorization` token is rejected with HTTP status 401.
14. A `POST /carrinhos` request whose `quantidade` is a JSON string instead of an integer is rejected with HTTP status 400.
