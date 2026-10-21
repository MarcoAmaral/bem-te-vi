import { test, expect } from '../fixtures'
import { TODO_ITEM_ONE, TODO_ITEM_THREE } from '../data/todos'

// Migrated from cypress/e2e/app.cy.js, context 'Clear completed button'.
test.describe('Clear completed button', () => {
  test('should display the correct text', {
    tag: ['@regression', '@e2e', '@p1', '@automated', '@clear-completed'],
  }, async ({ todoPageWithDefaults: todoPage }) => {
    // Arrange: three default todos (fixture)

    // Act
    await todoPage.toggleOf(todoPage.items.nth(0)).check()

    // Assert
    await expect(todoPage.clearCompleted).toHaveText('Clear completed')
  })

  test('should remove completed items when clicked', {
    tag: ['@smoke', '@e2e', '@p0', '@automated', '@clear-completed'],
  }, async ({ todoPageWithDefaults: todoPage }) => {
    // Arrange
    await todoPage.toggleOf(todoPage.items.nth(1)).check()

    // Act
    await todoPage.clearCompleted.click()

    // Assert
    await expect(todoPage.items).toHaveCount(2)
    await expect(todoPage.items.nth(0)).toContainText(TODO_ITEM_ONE)
    await expect(todoPage.items.nth(1)).toContainText(TODO_ITEM_THREE)
  })

  test('should be hidden when there are no items that are completed', {
    tag: ['@regression', '@e2e', '@p1', '@automated', '@clear-completed'],
  }, async ({ todoPageWithDefaults: todoPage }) => {
    // Arrange
    await todoPage.toggleOf(todoPage.items.nth(1)).check()
    await expect(todoPage.clearCompleted).toBeVisible()

    // Act
    await todoPage.clearCompleted.click()

    // Assert
    await expect(todoPage.clearCompleted).toBeHidden()
  })
})
