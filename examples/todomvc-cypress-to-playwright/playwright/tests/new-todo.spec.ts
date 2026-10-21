import { test, expect } from '../fixtures'
import { TODO_ITEM_ONE, TODO_ITEM_TWO, TODO_ITEM_THREE, DEFAULT_TODOS } from '../data/todos'

// Migrated from cypress/e2e/app.cy.js, context 'New Todo'.
test.describe('New Todo', () => {
  // golden reference spec: later specs follow its structure (AAA, page object, tag details)
  test('should allow me to add todo items', {
    tag: ['@smoke', '@e2e', '@p0', '@automated', '@todo-create'],
  }, async ({ todoPage }) => {
    // Arrange: empty list (fixture)

    // Act
    await todoPage.addTodo(TODO_ITEM_ONE)
    // Assert
    await expect(todoPage.items.nth(0)).toHaveText(TODO_ITEM_ONE)

    // Act
    await todoPage.addTodo(TODO_ITEM_TWO)
    // Assert
    await expect(todoPage.items.nth(1)).toHaveText(TODO_ITEM_TWO)
  })

  test('adds items', {
    tag: ['@regression', '@e2e', '@p1', '@automated', '@todo-create'],
  }, async ({ todoPage }) => {
    // Arrange: empty list (fixture)

    // Act
    await todoPage.addTodos(['todo A', 'todo B', 'todo C', 'todo D'])

    // Assert
    await expect(todoPage.items).toHaveCount(4)
  })

  test('should clear text input field when an item is added', {
    tag: ['@regression', '@e2e', '@p1', '@automated', '@todo-create'],
  }, async ({ todoPage }) => {
    // Arrange: empty list (fixture)

    // Act
    await todoPage.addTodo(TODO_ITEM_ONE)

    // Assert: the old `have.text ''` read the text of an <input>, which is always empty
    await expect(todoPage.newTodo).toHaveValue('')
  })

  test('should append new items to the bottom of the list', {
    tag: ['@smoke', '@e2e', '@p0', '@automated', '@todo-create'],
  }, async ({ todoPage }) => {
    // Arrange: empty list (fixture)

    // Act
    await todoPage.addTodos(DEFAULT_TODOS)

    // Assert
    await expect(todoPage.counter).toHaveText('3 items left')
    await expect(todoPage.items).toHaveText([TODO_ITEM_ONE, TODO_ITEM_TWO, TODO_ITEM_THREE])
  })

  test('should trim text input', {
    tag: ['@regression', '@e2e', '@p1', '@automated', '@todo-create'],
  }, async ({ todoPage }) => {
    // Arrange: empty list (fixture)

    // Act
    await todoPage.addTodo(`    ${TODO_ITEM_ONE}    `)

    // Assert: a regexp is matched against the raw text; a string would ignore the whitespace
    await expect(todoPage.items.nth(0)).toHaveText(new RegExp(`^${TODO_ITEM_ONE}$`))
  })

  test('should show #main and #footer when items added', {
    tag: ['@regression', '@e2e', '@p2', '@automated', '@todo-create'],
  }, async ({ todoPage }) => {
    // Arrange: empty list (fixture)

    // Act
    await todoPage.addTodo(TODO_ITEM_ONE)

    // Assert: #main holds the toggle-all and the list, #footer the counter and the filters
    await expect(todoPage.toggleAll).toBeVisible()
    await expect(todoPage.items).toBeVisible()
    await expect(todoPage.counter).toBeVisible()
    await expect(todoPage.filterLink('All')).toBeVisible()
  })
})
