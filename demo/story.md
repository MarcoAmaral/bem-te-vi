# Cart: no duplicate product (ServeRest API, https://serverest.dev)

As a customer, I can't add the same product to my cart twice.

- AC-1: POST /carrinhos listing the same idProduto twice returns 400.
- AC-2: POST /carrinhos with distinct products returns 201.
- AC-3: A second POST /carrinhos by a user who has a cart returns 400.
