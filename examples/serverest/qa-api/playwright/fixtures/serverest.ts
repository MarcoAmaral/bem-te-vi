// playwright/fixtures/serverest.ts
// Every test gets its own administrator, customer and products and removes them afterwards, so no
// test depends on another test or on data left on the shared public instance. The contract is
// loaded once per worker, from the live OpenAPI document.
import { test as base, expect } from "@playwright/test";
import { randomUUID } from "node:crypto";
import { ServeRestApi } from "../api/ServeRestApi";
import { Contract } from "../contract/contract";

const PASSWORD = "teste";
const CONTRACT_URL = process.env.CONTRACT_URL || "https://serverest.dev/swagger.json";

export interface Account {
  id: string;
  email: string;
  token: string;
}

type Fixtures = {
  api: ServeRestApi;
  admin: Account;
  customer: Account;
  newProduct: (stock: number) => Promise<{ _id: string }>;
};

type WorkerFixtures = { contract: Contract };

async function createAccount(api: ServeRestApi, administrador: "true" | "false"): Promise<Account> {
  const email = `contract-${randomUUID()}@example.com`;
  const created = await api.createUser({
    nome: `Contract test ${administrador === "true" ? "admin" : "customer"}`,
    email,
    password: PASSWORD,
    administrador,
  });
  expect(created.status(), "user setup").toBe(201);
  const { _id } = await created.json();
  const login = await api.login(email, PASSWORD);
  expect(login.status(), "login setup").toBe(200);
  const { authorization } = await login.json();
  return { id: _id, email, token: authorization };
}

export const test = base.extend<Fixtures, WorkerFixtures>({
  contract: [
    async ({}, use) => {
      await use(await Contract.load(CONTRACT_URL));
    },
    { scope: "worker" },
  ],

  api: async ({ request }, use) => {
    await use(new ServeRestApi(request));
  },

  admin: async ({ api }, use) => {
    const admin = await createAccount(api, "true");
    await use(admin);
    await api.deleteUser(admin.id);
  },

  customer: async ({ api }, use) => {
    const customer = await createAccount(api, "false");
    await use(customer);
    // A user with a cart cannot be deleted, so cancel first (200 even when there is none).
    await api.cancelPurchase(customer.token);
    await api.deleteUser(customer.id);
  },

  newProduct: async ({ api, admin, customer }, use) => {
    const created: { _id: string }[] = [];
    await use(async (stock: number) => {
      const response = await api.createProduct(admin.token, {
        nome: `Contract test product ${randomUUID()}`,
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
    for (const product of created) await api.deleteProduct(admin.token, product._id);
  },
});

export { expect };
