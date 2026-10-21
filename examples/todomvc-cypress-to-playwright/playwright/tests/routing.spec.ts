import { test, expect } from '../fixtures'
import { TODO_ITEM_ONE, TODO_ITEM_THREE } from '../data/todos'

// Migrated from cypress/e2e/app.cy.js, context 'Routing'.
test.describe('Routing', () => {
  test('should allow me to display active items', {
    tag: ['@regression', '@e2e', '@p1', '@automated', '@routing'],
  }, async ({ todoPageWithDefaults: todoPage }) => {
    // Arrange
    await todoPage.toggleOf(todoPage.items.nth(1)).check()

    // Act
    await todoPage.filterLink('Active').click()

    // Assert
    await expect(todoPage.items).toHaveCount(2)
    await expect(todoPage.items.nth(0)).toContainText(TODO_ITEM_ONE)
    await expect(todoPage.items.nth(1)).toContainText(TODO_ITEM_THREE)
  })

  test('should respect the back button', {
    tag: ['@regression', '@e2e', '@p1', '@automated', '@routing'],
  }, async ({ todoPageWithDefaults: todoPage }) => {
    // Arrange
    await todoPage.toggleOf(todoPage.items.nth(1)).check()
    await todoPage.filterLink('Active').click()
    await todoPage.filterLink('Completed').click()
    await expect(todoPage.items).toHaveCount(1)

    // Act + Assert: Completed -> Active
    await todoPage.back()
    await expect(todoPage.items).toHaveCount(2)

    // Act + Assert: Active -> All
    await todoPage.back()
    await expect(todoPage.items).toHaveCount(3)
  })

  test('should allow me to display completed items', {
    tag: ['@regression', '@e2e', '@p1', '@automated', '@routing'],
  }, async ({ todoPageWithDefaults: todoPage }) => {
    // Arrange
    await todoPage.toggleOf(todoPage.items.nth(1)).check()

    // Act
    await todoPage.filterLink('Completed').click()

    // Assert
    await expect(todoPage.items).toHaveCount(1)
  })

  test('should allow me to display all items', {
    tag: ['@regression', '@e2e', '@p1', '@automated', '@routing'],
  }, async ({ todoPageWithDefaults: todoPage }) => {
    // Arrange
    await todoPage.toggleOf(todoPage.items.nth(1)).check()
    await todoPage.filterLink('Active').click()
    await todoPage.filterLink('Completed').click()

    // Act
    await todoPage.filterLink('All').click()

    // Assert
    await expect(todoPage.items).toHaveCount(3)
  })

  test('should highlight the currently applied filter', {
    tag: ['@regression', '@e2e', '@p2', '@automated', '@routing'],
  }, async ({ todoPageWithDefaults: todoPage }) => {
    // Arrange: three default todos (fixture)

    // Assert: All is selected on load
    await expect(todoPage.filterLink('All')).toHaveClass(/selected/)

    // Act + Assert
    await todoPage.filterLink('Active').click()
    await expect(todoPage.filterLink('Active')).toHaveClass(/selected/)

    // Act + Assert
    await todoPage.filterLink('Completed').click()
    await expect(todoPage.filterLink('Completed')).toHaveClass(/selected/)
  })
})
