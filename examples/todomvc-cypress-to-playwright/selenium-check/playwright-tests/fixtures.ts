import { test as base } from "@playwright/test";
import { TodoPage } from "./pages/todo-page";

/** Each test gets a fresh browser context (empty localStorage) and an opened app, replacing @BeforeMethod/@AfterMethod. */
export const test = base.extend<{ todo: TodoPage }>({
  todo: async ({ page }, use) => {
    const todo = new TodoPage(page);
    await todo.goto();
    await use(todo);
  },
});

export { expect } from "@playwright/test";
