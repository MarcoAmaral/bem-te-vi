import AxeBuilder from '@axe-core/playwright'
import { test, expect } from '../fixtures'
import { TODO_ITEM_ONE, TODO_ITEM_TWO } from '../data/todos'

// Migrated from cypress/e2e/app.cy.js, context 'Contrast'.
// Cypress: cy.checkA11y(null, { runOnly: ['cat.color'] }); here the same axe tag.
// cypress-axe ran axe-core 4.10.3; @axe-core/playwright bundles its own axe-core (see migration/parity.md).
test.describe('Contrast', () => {
  test('has good contrast when empty', {
    tag: ['@regression', '@e2e', '@p2', '@automated', '@a11y'],
  }, async ({ todoPage, page }) => {
    // Arrange: empty list (fixture)
    await expect(todoPage.newTodo).toBeVisible()

    // Act
    const results = await new AxeBuilder({ page }).withTags(['cat.color']).analyze()

    // Assert
    expect(results.violations).toEqual([])
  })

  test('has good contrast with several todos', {
    tag: ['@regression', '@e2e', '@p2', '@automated', '@a11y'],
  }, async ({ todoPage, page }) => {
    // Arrange
    await todoPage.addTodos([TODO_ITEM_ONE, TODO_ITEM_TWO])
    await expect(todoPage.items).toHaveCount(2)

    // Act + Assert: with two todos
    const withTodos = await new AxeBuilder({ page }).withTags(['cat.color']).analyze()
    expect(withTodos.violations).toEqual([])

    // Act + Assert: after completing one
    await todoPage.toggleOf(todoPage.items.first()).check()
    await expect(todoPage.items.first()).toHaveClass(/completed/)
    const withCompleted = await new AxeBuilder({ page }).withTags(['cat.color']).analyze()
    expect(withCompleted.violations).toEqual([])
  })
})
