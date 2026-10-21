import { test, expect } from '../fixtures'
import { TODO_ITEM_ONE, TODO_ITEM_TWO } from '../data/todos'

// Migrated from cypress/e2e/app.cy.js, context 'Persistence'.
test.describe('Persistence', () => {
  test('should persist its data', {
    tag: ['@smoke', '@e2e', '@p0', '@automated', '@persistence'],
  }, async ({ todoPage }) => {
    // Arrange
    await todoPage.addTodos([TODO_ITEM_ONE, TODO_ITEM_TWO])
    const first = todoPage.itemWithText(TODO_ITEM_ONE)
    const second = todoPage.itemWithText(TODO_ITEM_TWO)
    await todoPage.toggleOf(first).check()
    await expect(first).toHaveClass(/completed/)
    await expect(second).not.toHaveClass(/completed/)

    // Act
    await todoPage.reload()

    // Assert
    await expect(first).toContainText(TODO_ITEM_ONE)
    await expect(first).toHaveClass(/completed/)
    await expect(second).toContainText(TODO_ITEM_TWO)
    await expect(second).not.toHaveClass(/completed/)
  })
})
