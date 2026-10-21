import { test, expect } from '../fixtures'
import { TODO_ITEM_ONE, TODO_ITEM_TWO, TODO_ITEM_THREE } from '../data/todos'

// Migrated from cypress/e2e/app.cy.js, context 'Editing'.
test.describe('Editing', () => {
  test('should hide other controls when editing', {
    tag: ['@regression', '@e2e', '@p1', '@automated', '@editing'],
  }, async ({ todoPageWithDefaults: todoPage }) => {
    // Arrange
    const second = todoPage.items.nth(1)

    // Act
    await todoPage.beginEdit(second, TODO_ITEM_TWO)

    // Assert: role queries skip hidden elements, so the toggle is asked for explicitly
    await expect(todoPage.editFieldOf(second)).toBeVisible()
    await expect(second.getByRole('checkbox', { includeHidden: true })).toBeHidden()
    await expect(second.getByText(TODO_ITEM_TWO)).toBeHidden()
  })

  test('should save edits on blur', {
    tag: ['@regression', '@e2e', '@p1', '@automated', '@editing'],
  }, async ({ todoPageWithDefaults: todoPage }) => {
    // Arrange
    const second = todoPage.items.nth(1)
    await todoPage.beginEdit(second, TODO_ITEM_TWO)
    await todoPage.editFieldOf(second).fill('buy some sausages')

    // Act
    await todoPage.editFieldOf(second).blur()

    // Assert
    await expect(todoPage.items.nth(0)).toContainText(TODO_ITEM_ONE)
    await expect(second).toContainText('buy some sausages')
    await expect(todoPage.items.nth(2)).toContainText(TODO_ITEM_THREE)
  })

  test('should trim entered text', {
    tag: ['@regression', '@e2e', '@p1', '@automated', '@editing'],
  }, async ({ todoPageWithDefaults: todoPage }) => {
    // Arrange
    const second = todoPage.items.nth(1)
    await todoPage.beginEdit(second, TODO_ITEM_TWO)
    await todoPage.editFieldOf(second).fill('    buy some sausages    ')

    // Act
    await todoPage.editFieldOf(second).press('Enter')

    // Assert: a regexp is matched against the raw text; the old `contain` and a string both
    // pass with the whitespace left in
    await expect(second).toHaveText(/^buy some sausages$/)
    await expect(todoPage.items.nth(0)).toContainText(TODO_ITEM_ONE)
    await expect(todoPage.items.nth(2)).toContainText(TODO_ITEM_THREE)
  })

  test('should remove the item if an empty text string was entered', {
    tag: ['@regression', '@e2e', '@p1', '@automated', '@editing'],
  }, async ({ todoPageWithDefaults: todoPage }) => {
    // Arrange
    const second = todoPage.items.nth(1)
    await todoPage.beginEdit(second, TODO_ITEM_TWO)
    await todoPage.editFieldOf(second).fill('')

    // Act
    await todoPage.editFieldOf(second).press('Enter')

    // Assert
    await expect(todoPage.items).toHaveCount(2)
  })

  test('should cancel edits on escape', {
    tag: ['@regression', '@e2e', '@p1', '@automated', '@editing'],
  }, async ({ todoPageWithDefaults: todoPage }) => {
    // Arrange
    const second = todoPage.items.nth(1)
    await todoPage.beginEdit(second, TODO_ITEM_TWO)
    await todoPage.editFieldOf(second).fill('foo')

    // Act
    await todoPage.editFieldOf(second).press('Escape')

    // Assert: the old test only read the row text, which a row still in edit mode keeps in a
    // hidden label, so it passed when Escape did nothing. Leaving edit mode is asserted too.
    await expect(second.getByText(TODO_ITEM_TWO)).toBeVisible()
    await expect(todoPage.editFieldOf(second)).toBeHidden()
    await expect(todoPage.items.nth(0)).toContainText(TODO_ITEM_ONE)
    await expect(second).toContainText(TODO_ITEM_TWO)
    await expect(todoPage.items.nth(2)).toContainText(TODO_ITEM_THREE)
  })
})
