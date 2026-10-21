// playwright/fixtures/serverest.ts
// Every test gets its own administrator, customer and products, and removes them afterwards,
// so no test depends on another test or on data left on the shared public instance.
import { test as base, expect } from "@playwright/test";
import { randomUUID } from "node:crypto";
import { ServeRestApi } from "../api/ServeRestApi";

export interface Customer {
  id: string;
  token: string;
}

export interface Product {
  _id: string;
}

type Fixtures = {
  api: ServeRestApi;
  admin: { id: string; token: string };
  customer: Customer;
  newProduct: (stock: number) => Promise<Product>;
};

const PASSWORD = "teste";

async function createUserWithToken(
  api: ServeRestApi,
  administrador: "true" | "false",
): Promise<{ id: string; token: string; email: string }> {
  const email = `cart-${randomUUID()}@example.com`;
  const created = await api.createUser({
    nome: `Cart test ${administrador === "true" ? "admin" : "customer"}`,
    email,
    password: PASSWORD,
    administrador,
  });
  expect(created.status(), "user setup").toBe(201);
  const { _id } = await created.json();
  const login = await api.login(email, PASSWORD);
  expect(login.status(), "login setup").toBe(200);
  const { authorization } = await login.json();
  return { id: _id, token: authorization, email };
}

export const test = base.extend<Fixtures>({
  api: async ({ request }, use) => {
    await use(new ServeRestApi(request));
  },

  admin: async ({ api }, use) => {
    const admin = await createUserWithToken(api, "true");
    await use({ id: admin.id, token: admin.token });
    await api.deleteUser(admin.id);
  },

  customer: async ({ api }, use) => {
    const customer = await createUserWithToken(api, "false");
    await use({ id: customer.id, token: customer.token });
    // A user with a cart cannot be deleted, so cancel first (200 even when there is none).
    await api.cancelPurchase(customer.token);
    await api.deleteUser(customer.id);
  },

  newProduct: async ({ api, admin, customer }, use) => {
    const created: Product[] = [];
    await use(async (stock: number) => {
      const response = await api.createProduct(admin.token, {
        nome: `Cart test product ${randomUUID()}`,
        preco: 100,
        descricao: "Created by an automated test",
        quantidade: stock,
      });
      expect(response.status(), "product setup").toBe(201);
      const product = await response.json();
      created.push(product);
      return product;
    });
    // A product that is in a cart cannot be deleted, so cancel the customer's cart first.
    await api.cancelPurchase(customer.token);
    for (const product of created) {
      await api.deleteProduct(admin.token, product._id);
    }
  },
});

export { expect };
