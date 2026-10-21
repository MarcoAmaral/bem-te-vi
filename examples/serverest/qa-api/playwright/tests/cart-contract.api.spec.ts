// Contract checks for the cart routes against the live OpenAPI document of https://serverest.dev
import { test, expect } from "../fixtures/serverest";

test.describe("Cart contract @cart", () => {
  // API-CART-01
  test("POST /carrinhos returns 201 and a body that conforms @smoke @api @p0 @cart", async ({
    api,
    contract,
    customer,
    newProduct,
  }) => {
    // Arrange
    const product = await newProduct(10);

    // Act
    const response = await api.createCart(customer.token, {
      produtos: [{ idProduto: product._id, quantidade: 1 }],
    });

    // Assert
    expect(response.status()).toBe(201);
    expect(contract.responseErrors("/carrinhos", "post", 201, await response.json())).toEqual([]);
  });

  // API-CART-02
  test("GET /carrinhos/{_id} returns 200 and a body that conforms @smoke @api @p0 @cart", async ({
    api,
    contract,
    customer,
    newProduct,
  }) => {
    // Arrange
    const product = await newProduct(10);
    const created = await api.createCart(customer.token, {
      produtos: [{ idProduto: product._id, quantidade: 2 }],
    });
    const { _id } = await created.json();

    // Act
    const response = await api.getCart(_id);

    // Assert
    expect(response.status()).toBe(200);
    expect(contract.responseErrors("/carrinhos/{_id}", "get", 200, await response.json())).toEqual(
      [],
    );
  });

  // API-CART-03
  test("GET /carrinhos/{_id} for an unknown id returns 400 and a body that conforms @regression @api @p1 @cart", async ({
    api,
    contract,
  }) => {
    // Act
    const response = await api.getCart("0000000000000000");

    // Assert
    expect(response.status()).toBe(400);
    expect(contract.responseErrors("/carrinhos/{_id}", "get", 400, await response.json())).toEqual(
      [],
    );
  });

  // API-CART-04
  test("GET /carrinhos for one user returns 200 and a body that conforms @regression @api @p1 @cart", async ({
    api,
    contract,
    customer,
    newProduct,
  }) => {
    // Arrange
    const product = await newProduct(10);
    await api.createCart(customer.token, { produtos: [{ idProduto: product._id, quantidade: 1 }] });

    // Act
    const response = await api.listCartsOfUser(customer.id);
    const body = await response.json();

    // Assert
    expect(response.status()).toBe(200);
    expect(body.carrinhos).toHaveLength(1);
    expect(contract.responseErrors("/carrinhos", "get", 200, body)).toEqual([]);
  });

  // API-CART-05
  test("POST /carrinhos without a token returns 401 and a body that conforms @regression @api @p1 @cart", async ({
    api,
    contract,
  }) => {
    // Act
    const response = await api.createCart(undefined, { produtos: [] });

    // Assert
    expect(response.status()).toBe(401);
    expect(contract.responseErrors("/carrinhos", "post", 401, await response.json())).toEqual([]);
  });

  // API-CART-06
  test("DELETE /carrinhos/cancelar-compra returns 200 and a body that conforms @regression @api @p1 @cart", async ({
    api,
    contract,
    customer,
    newProduct,
  }) => {
    // Arrange
    const product = await newProduct(10);
    await api.createCart(customer.token, { produtos: [{ idProduto: product._id, quantidade: 1 }] });

    // Act
    const response = await api.cancelPurchase(customer.token);

    // Assert
    expect(response.status()).toBe(200);
    expect(
      contract.responseErrors("/carrinhos/cancelar-compra", "delete", 200, await response.json()),
    ).toEqual([]);
  });

  // API-CART-07
  test("DELETE /carrinhos/cancelar-compra without a token returns 401 and a body that conforms @regression @api @p2 @cart", async ({
    api,
    contract,
  }) => {
    // Act
    const response = await api.cancelPurchase(undefined);

    // Assert
    expect(response.status()).toBe(401);
    expect(
      contract.responseErrors("/carrinhos/cancelar-compra", "delete", 401, await response.json()),
    ).toEqual([]);
  });

  // API-CART-08
  test("a duplicate product is rejected with 400 and a body that conforms @regression @api @p1 @cart", async ({
    api,
    contract,
    customer,
    newProduct,
  }) => {
    // Arrange
    const product = await newProduct(10);

    // Act
    const response = await api.createCart(customer.token, {
      produtos: [
        { idProduto: product._id, quantidade: 1 },
        { idProduto: product._id, quantidade: 1 },
      ],
    });

    // Assert
    expect(response.status()).toBe(400);
    expect(contract.responseErrors("/carrinhos", "post", 400, await response.json())).toEqual([]);
  });

  // API-CART-09 (SR-001): the request body the contract declares is accepted
  test("a request body built from the declared request schema is accepted @regression @api @p1 @cart", async ({
    api,
    contract,
    customer,
    newProduct,
  }) => {
    // Arrange: the schema declares `produtos` as one object, not an array
    const product = await newProduct(10);
    const body = { produtos: { idProduto: product._id, quantidade: 1 } };
    const declared = contract.errors(contract.requestSchema("/carrinhos", "post"), body);

    // Act
    const response = await api.createCart(customer.token, body);

    // Assert
    expect(declared, "the contract declares this body valid").toEqual([]);
    expect(response.status()).toBe(201);
  });

  // API-CART-10 (SR-005): a request the contract declares invalid is rejected
  test("a string quantidade is rejected with 400 @regression @api @p2 @cart", async ({
    api,
    contract,
    customer,
    newProduct,
  }) => {
    // Arrange
    const product = await newProduct(10);
    const body = { produtos: [{ idProduto: product._id, quantidade: "2" }] };

    // Act
    const response = await api.createCart(customer.token, body);

    // Assert: the item schema says integer, so the string is invalid by contract
    expect(response.status()).toBe(400);
  });

  // API-CART-11 (SR-005): whatever the API stored still conforms
  test("a cart created from a string quantidade still conforms to the schema @regression @api @p2 @cart", async ({
    api,
    contract,
    customer,
    newProduct,
  }) => {
    // Arrange
    const product = await newProduct(10);
    await api.createCart(customer.token, {
      produtos: [{ idProduto: product._id, quantidade: "2" }],
    });

    // Act
    const response = await api.listCartsOfUser(customer.id);

    // Assert
    expect(response.status()).toBe(200);
    expect(contract.responseErrors("/carrinhos", "get", 200, await response.json())).toEqual([]);
  });

  // API-CART-12 (SR-006): the schema is too loose to notice, so check the documented key itself
  test("a schema-validation 400 carries the documented message key @regression @api @p2 @cart", async ({
    api,
    contract,
    customer,
  }) => {
    // Act
    const response = await api.createCart(customer.token, { produtos: [] });
    const body = await response.json();

    // Assert: the 400 body conforms (nothing is required), yet `message` is documented
    expect(response.status()).toBe(400);
    expect(contract.responseErrors("/carrinhos", "post", 400, body)).toEqual([]);
    expect(body).toHaveProperty("message");
  });
});
