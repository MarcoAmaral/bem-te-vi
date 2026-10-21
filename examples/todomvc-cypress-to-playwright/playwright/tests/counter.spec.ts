import { test, expect } from '../fixtures'
import { TODO_ITEM_ONE, TODO_ITEM_TWO } from '../data/todos'

// Migrated from cypress/e2e/app.cy.js, context 'Counter'.
test.describe('Counter', () => {
  test('should display the current number of todo items', {
    tag: ['@regression', '@e2e', '@p1', '@automated', '@counter'],
  }, async ({ todoPage }) => {
    // Arrange: empty list (fixture)

    // Act
    await todoPage.addTodo(TODO_ITEM_ONE)
    // Assert
    await expect(todoPage.counter).toHaveText('1 item left')

    // Act
    await todoPage.addTodo(TODO_ITEM_TWO)
    // Assert
    await expect(todoPage.counter).toHaveText('2 items left')
  })
})
