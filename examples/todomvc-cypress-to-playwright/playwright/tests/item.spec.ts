import { test, expect } from '../fixtures'
import { TODO_ITEM_ONE, TODO_ITEM_TWO, TODO_ITEM_THREE } from '../data/todos'

// Migrated from cypress/e2e/app.cy.js, context 'Item'.
test.describe('Item', () => {
  test('should allow me to mark items as complete', {
    tag: ['@smoke', '@e2e', '@p0', '@automated', '@item'],
  }, async ({ todoPage }) => {
    // Arrange
    await todoPage.addTodos([TODO_ITEM_ONE, TODO_ITEM_TWO])
    const first = todoPage.itemWithText(TODO_ITEM_ONE)
    const second = todoPage.itemWithText(TODO_ITEM_TWO)

    // Act
    await todoPage.toggleOf(first).check()
    // Assert
    await expect(first).toHaveClass(/completed/)
    await expect(second).not.toHaveClass(/completed/)

    // Act
    await todoPage.toggleOf(second).check()
    // Assert
    await expect(first).toHaveClass(/completed/)
    await expect(second).toHaveClass(/completed/)
  })

  test('should allow me to un-mark items as complete', {
    tag: ['@regression', '@e2e', '@p1', '@automated', '@item'],
  }, async ({ todoPage }) => {
    // Arrange
    await todoPage.addTodos([TODO_ITEM_ONE, TODO_ITEM_TWO])
    const first = todoPage.itemWithText(TODO_ITEM_ONE)
    const second = todoPage.itemWithText(TODO_ITEM_TWO)
    await todoPage.toggleOf(first).check()
    await expect(first).toHaveClass(/completed/)
    await expect(second).not.toHaveClass(/completed/)

    // Act
    await todoPage.toggleOf(first).uncheck()

    // Assert
    await expect(first).not.toHaveClass(/completed/)
    await expect(second).not.toHaveClass(/completed/)
  })

  test('should allow me to edit an item', {
    tag: ['@regression', '@e2e', '@p1', '@automated', '@item'],
  }, async ({ todoPageWithDefaults: todoPage }) => {
    // Arrange
    const second = todoPage.items.nth(1)
    await todoPage.beginEdit(second, TODO_ITEM_TWO)

    // Act
    await todoPage.editFieldOf(second).fill('buy some sausages')
    await todoPage.editFieldOf(second).press('Enter')

    // Assert
    await expect(todoPage.items.nth(0)).toContainText(TODO_ITEM_ONE)
    await expect(second).toContainText('buy some sausages')
    await expect(todoPage.items.nth(2)).toContainText(TODO_ITEM_THREE)
  })
})
