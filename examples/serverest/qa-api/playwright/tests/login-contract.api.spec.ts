// Contract checks for POST /login against the live OpenAPI document of https://serverest.dev
import { test, expect } from "../fixtures/serverest";

test.describe("Login contract @login", () => {
  // API-LOGIN-01
  test("valid login returns 200 and a body that conforms @smoke @api @p0 @login", async ({
    api,
    contract,
    customer,
  }) => {
    // Act
    const response = await api.login(customer.email, "teste");

    // Assert
    expect(response.status()).toBe(200);
    expect(contract.responseErrors("/login", "post", 200, await response.json())).toEqual([]);
  });

  // API-LOGIN-02
  test("wrong password returns 401 and a body that conforms @regression @api @p1 @login", async ({
    api,
    contract,
    customer,
  }) => {
    // Act
    const response = await api.login(customer.email, "not-the-password");

    // Assert
    expect(response.status()).toBe(401);
    expect(contract.responseErrors("/login", "post", 401, await response.json())).toEqual([]);
  });

  // API-LOGIN-03
  test("an empty request is answered with a status the contract declares @regression @api @p2 @login", async ({
    api,
    contract,
  }) => {
    // Act
    const response = await api.login("", "");

    // Assert
    expect(contract.declaredStatuses("/login", "post")).toContain(String(response.status()));
  });
});
