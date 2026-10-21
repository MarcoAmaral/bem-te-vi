import { test, expect } from '../fixtures'

// Migrated from cypress/e2e/app.cy.js, context 'Mark all as completed'.
test.describe('Mark all as completed', () => {
  test('should allow me to mark all items as completed', {
    tag: ['@regression', '@e2e', '@p1', '@automated', '@mark-all'],
  }, async ({ todoPageWithDefaults: todoPage }) => {
    // Arrange: three default todos (fixture)

    // Act
    await todoPage.toggleAll.check()

    // Assert
    await expect(todoPage.items).toHaveClass([/completed/, /completed/, /completed/])
  })

  test('should allow me to clear the complete state of all items', {
    tag: ['@regression', '@e2e', '@p1', '@automated', '@mark-all'],
  }, async ({ todoPageWithDefaults: todoPage }) => {
    // Arrange: all three completed. The old test skipped this check, so it also passed
    // when toggle-all did nothing.
    await todoPage.toggleAll.check()
    await expect(todoPage.items).toHaveClass([/completed/, /completed/, /completed/])

    // Act
    await todoPage.toggleAll.uncheck()

    // Assert
    await expect(todoPage.items.nth(0)).not.toHaveClass(/completed/)
    await expect(todoPage.items.nth(1)).not.toHaveClass(/completed/)
    await expect(todoPage.items.nth(2)).not.toHaveClass(/completed/)
  })

  test('complete all checkbox should update state when items are completed / cleared', {
    tag: ['@regression', '@e2e', '@p1', '@automated', '@mark-all'],
  }, async ({ todoPageWithDefaults: todoPage }) => {
    // Arrange
    await todoPage.toggleAll.check()
    await expect(todoPage.toggleAll).toBeChecked()
    const firstToggle = todoPage.toggleOf(todoPage.items.nth(0))

    // Act + Assert: clearing one item clears toggle-all
    await firstToggle.uncheck()
    await expect(todoPage.toggleAll).not.toBeChecked()

    // Act + Assert: completing it again checks toggle-all
    await firstToggle.check()
    await expect(todoPage.toggleAll).toBeChecked()
  })
})
