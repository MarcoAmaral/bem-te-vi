import { test as base } from '@playwright/test'
import { DEFAULT_TODOS } from './data/todos'
import { TodoPage } from './pages/todo-page'

type Fixtures = {
  // The app opened on an empty list. Replaces the Cypress `beforeEach(cy.visit('/'))`.
  todoPage: TodoPage
  // The same, with the three default todos added. Replaces `cy.createDefaultTodos()` in a hook.
  todoPageWithDefaults: TodoPage
}

// No authentication: the app has no login, so there is no storageState setup project.
// Every test gets a fresh browser context, so localStorage never leaks between tests;
// the Cypress `afterEach` blur (a Firefox workaround) is not ported.
export const test = base.extend<Fixtures>({
  todoPage: async ({ page }, use) => {
    const todoPage = new TodoPage(page)
    await todoPage.goto()
    await use(todoPage)
  },
  todoPageWithDefaults: async ({ page }, use) => {
    const todoPage = new TodoPage(page)
    await todoPage.goto()
    await todoPage.addTodos(DEFAULT_TODOS)
    await use(todoPage)
  },
})

export { expect } from '@playwright/test'
