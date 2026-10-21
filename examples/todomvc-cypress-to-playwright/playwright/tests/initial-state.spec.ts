import { test, expect } from '../fixtures'

// Migrated from cypress/e2e/app.cy.js, contexts 'When page is initially opened' and 'No Todos'.
test.describe('Initial state', () => {
  test('should focus on the todo input field', {
    tag: ['@regression', '@e2e', '@p2', '@automated', '@focus'],
  }, async ({ todoPage }) => {
    // Arrange: page just opened (fixture)

    // Act: nothing

    // Assert
    await expect(todoPage.newTodo).toBeFocused()
  })

  test('should hide #main and #footer', {
    tag: ['@regression', '@e2e', '@p2', '@automated', '@initial-state'],
  }, async ({ todoPage }) => {
    // Arrange: empty list (fixture)

    // Act: nothing

    // Assert: #main holds the toggle-all and the list, #footer the counter and the filters
    await expect(todoPage.items).toHaveCount(0)
    await expect(todoPage.toggleAll).toBeHidden()
    await expect(todoPage.counter).toBeHidden()
    await expect(todoPage.filterLink('All')).toBeHidden()
  })
})
