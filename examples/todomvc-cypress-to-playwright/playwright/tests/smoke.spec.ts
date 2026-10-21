import { test, expect } from '../fixtures'

// Phase 3 environment check: baseURL, the web server and the built bundle work.
// New test: it has no Cypress counterpart and is not part of the parity count.
test('app is served and the new-todo field is ready', {
  tag: ['@smoke', '@e2e', '@p0', '@automated', '@environment'],
}, async ({ todoPage, page }) => {
  // Arrange: the fixture opened baseURL
  // Act: nothing
  // Assert
  await expect(page.getByRole('heading', { name: 'todos' })).toBeVisible()
  await expect(todoPage.newTodo).toBeVisible()
})
