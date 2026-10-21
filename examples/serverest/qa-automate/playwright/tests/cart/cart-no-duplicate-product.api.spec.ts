// Automates a subset of ../../../../qa-agentic/cart-no-duplicate-product/testcases.md
// Target: https://serverest.dev (API only, no browser)
import { test, expect } from "../../fixtures/serverest";

test.describe("Cart: no duplicate product @cart", () => {
  // TC-CART-001
  test("rejects the same product listed twice @smoke @api @p0 @cart", async ({
    api,
    customer,
    newProduct,
  }) => {
    // Arrange
    const product = await newProduct(10);

    // Act
    const response = await api.createCart(customer.token, [
      { idProduto: product._id, quantidade: 1 },
      { idProduto: product._id, quantidade: 1 },
    ]);

    // Assert
    expect(response.status()).toBe(400);
  });

  // TC-CART-002
  test("accepts the same product listed once @smoke @api @p0 @cart", async ({
    api,
    customer,
    newProduct,
  }) => {
    // Arrange
    const product = await newProduct(10);

    // Act
    const response = await api.createCart(customer.token, [
      { idProduto: product._id, quantidade: 1 },
    ]);

    // Assert
    expect(response.status()).toBe(201);
  });

  // TC-CART-004
  test("duplicate rejection carries the exact message @regression @api @p1 @cart", async ({
    api,
    customer,
    newProduct,
  }) => {
    // Arrange
    const product = await newProduct(10);

    // Act
    const response = await api.createCart(customer.token, [
      { idProduto: product._id, quantidade: 1 },
      { idProduto: product._id, quantidade: 1 },
    ]);

    // Assert
    expect((await response.json()).message).toBe(
      "Não é permitido possuir produto duplicado",
    );
  });

  // TC-CART-006
  test("duplicate rejection lists the repeated id @regression @api @p2 @cart", async ({
    api,
    customer,
    newProduct,
  }) => {
    // Arrange
    const product = await newProduct(10);

    // Act
    const response = await api.createCart(customer.token, [
      { idProduto: product._id, quantidade: 1 },
      { idProduto: product._id, quantidade: 1 },
    ]);

    // Assert
    expect((await response.json()).idProdutosDuplicados).toContain(product._id);
  });

  // TC-CART-009
  test("rejects the same product with different quantities @regression @api @p1 @cart", async ({
    api,
    customer,
    newProduct,
  }) => {
    // Arrange
    const product = await newProduct(10);

    // Act
    const response = await api.createCart(customer.token, [
      { idProduto: product._id, quantidade: 1 },
      { idProduto: product._id, quantidade: 2 },
    ]);

    // Assert
    expect(response.status()).toBe(400);
  });

  // TC-CART-011
  test("rejected duplicate request leaves the user without a cart @regression @api @p1 @cart", async ({
    api,
    customer,
    newProduct,
  }) => {
    // Arrange
    const product = await newProduct(10);

    // Act
    await api.createCart(customer.token, [
      { idProduto: product._id, quantidade: 1 },
      { idProduto: product._id, quantidade: 1 },
    ]);
    const carts = await api.listCartsOfUser(customer.id);

    // Assert
    expect((await carts.json()).quantidade).toBe(0);
  });

  // TC-CART-013
  test("rejected duplicate request does not change stock @regression @api @p1 @cart", async ({
    api,
    customer,
    newProduct,
  }) => {
    // Arrange
    const product = await newProduct(10);

    // Act
    await api.createCart(customer.token, [
      { idProduto: product._id, quantidade: 1 },
      { idProduto: product._id, quantidade: 1 },
    ]);
    const after = await api.getProduct(product._id);

    // Assert
    expect((await after.json()).quantidade).toBe(10);
  });

  // TC-CART-015
  test("quantity equal to stock is accepted and empties the stock @regression @api @p1 @cart", async ({
    api,
    customer,
    newProduct,
  }) => {
    // Arrange
    const product = await newProduct(10);

    // Act
    const response = await api.createCart(customer.token, [
      { idProduto: product._id, quantidade: 10 },
    ]);
    const after = await api.getProduct(product._id);

    // Assert
    expect(response.status()).toBe(201);
    expect((await after.json()).quantidade).toBe(0);
  });

  // TC-CART-016
  test("quantity of stock plus 1 is rejected @regression @api @p1 @cart", async ({
    api,
    customer,
    newProduct,
  }) => {
    // Arrange
    const product = await newProduct(10);

    // Act
    const response = await api.createCart(customer.token, [
      { idProduto: product._id, quantidade: 11 },
    ]);

    // Assert
    expect(response.status()).toBe(400);
  });

  // TC-CART-019
  test("second cart with a different product is rejected @smoke @api @p0 @cart", async ({
    api,
    customer,
    newProduct,
  }) => {
    // Arrange
    const first = await newProduct(10);
    const second = await newProduct(10);
    const created = await api.createCart(customer.token, [
      { idProduto: first._id, quantidade: 1 },
    ]);
    expect(created.status(), "first cart setup").toBe(201);

    // Act
    const response = await api.createCart(customer.token, [
      { idProduto: second._id, quantidade: 1 },
    ]);

    // Assert
    expect(response.status()).toBe(400);
  });

  // TC-CART-022
  test("second-cart rejection carries the exact message @regression @api @p1 @cart", async ({
    api,
    customer,
    newProduct,
  }) => {
    // Arrange
    const product = await newProduct(10);
    const created = await api.createCart(customer.token, [
      { idProduto: product._id, quantidade: 1 },
    ]);
    expect(created.status(), "first cart setup").toBe(201);

    // Act
    const response = await api.createCart(customer.token, [
      { idProduto: product._id, quantidade: 1 },
    ]);

    // Assert
    expect((await response.json()).message).toBe(
      "Não é permitido ter mais de 1 carrinho",
    );
  });

  // TC-CART-024
  test("rejected second cart does not reduce stock again @regression @api @p1 @cart", async ({
    api,
    customer,
    newProduct,
  }) => {
    // Arrange
    const product = await newProduct(10);
    const created = await api.createCart(customer.token, [
      { idProduto: product._id, quantidade: 2 },
    ]);
    expect(created.status(), "first cart setup").toBe(201);
    const stockAfterFirst = (await (await api.getProduct(product._id)).json())
      .quantidade;

    // Act
    await api.createCart(customer.token, [
      { idProduto: product._id, quantidade: 2 },
    ]);
    const stockAfterSecond = (await (await api.getProduct(product._id)).json())
      .quantidade;

    // Assert
    expect(stockAfterFirst).toBe(8);
    expect(stockAfterSecond).toBe(8);
  });

  // TC-CART-025
  test("cancelling a cart restores stock @regression @api @p1 @cart", async ({
    api,
    customer,
    newProduct,
  }) => {
    // Arrange
    const product = await newProduct(10);
    const created = await api.createCart(customer.token, [
      { idProduto: product._id, quantidade: 2 },
    ]);
    expect(created.status(), "cart setup").toBe(201);

    // Act
    const cancelled = await api.cancelPurchase(customer.token);
    const after = await api.getProduct(product._id);
    const carts = await api.listCartsOfUser(customer.id);

    // Assert
    expect(cancelled.status()).toBe(200);
    expect((await after.json()).quantidade).toBe(10);
    expect((await carts.json()).quantidade).toBe(0);
  });

  // TC-CART-026
  test("new cart with the product of a cancelled cart is accepted @regression @api @p1 @cart", async ({
    api,
    customer,
    newProduct,
  }) => {
    // Arrange
    const product = await newProduct(10);
    const created = await api.createCart(customer.token, [
      { idProduto: product._id, quantidade: 1 },
    ]);
    expect(created.status(), "first cart setup").toBe(201);
    await api.cancelPurchase(customer.token);

    // Act
    const response = await api.createCart(customer.token, [
      { idProduto: product._id, quantidade: 1 },
    ]);

    // Assert
    expect(response.status()).toBe(201);
  });

  // TC-CART-028
  test("request without an Authorization header is rejected @regression @api @p1 @cart", async ({
    api,
    newProduct,
  }) => {
    // Arrange
    const product = await newProduct(10);

    // Act
    const response = await api.createCart(undefined, [
      { idProduto: product._id, quantidade: 1 },
    ]);

    // Assert
    expect(response.status()).toBe(401);
  });

  // TC-CART-030: expected to FAIL against the live API today (see SR-005 in the qa-static review)
  test("quantidade as the string '2' is rejected @regression @api @p2 @cart", async ({
    api,
    customer,
    newProduct,
  }) => {
    // Arrange
    const product = await newProduct(10);

    // Act
    const response = await api.createCart(customer.token, [
      { idProduto: product._id, quantidade: "2" },
    ]);

    // Assert
    expect(response.status()).toBe(400);
  });
});
