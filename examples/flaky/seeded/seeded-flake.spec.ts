import { test, expect } from '../fixtures'

// SEEDED FLAKE. Written on purpose for the qa-flaky example; it is not a flake found in TodoMVC.
// The race is simulated: after a todo is added, the page hides the new row and shows it again
// after a random 0 to 10 ms, standing in for a slow render. This version reads the row at once,
// with a non-retrying check, so whether it passes depends on which side of the delay it lands.
test('a newly added todo is shown in the list', {
  tag: ['@regression', '@e2e', '@p2', '@candidate', '@flaky'],
}, async ({ todoPage, page }) => {
  // Arrange
  await page.evaluate(() => {
    const input = document.querySelector<HTMLInputElement>('.new-todo')!
    input.addEventListener('keydown', (event) => {
      if (event.key !== 'Enter') return
      setTimeout(() => {
        const row = document.querySelector<HTMLElement>('.todo-list li')
        if (!row) return
        row.style.visibility = 'hidden'
        setTimeout(() => { row.style.visibility = 'visible' }, Math.random() * 10)
      }, 0)
    })
  })

  // Act
  await todoPage.newTodo.fill('buy milk')
  await todoPage.newTodo.press('Enter')

  // Assert: non-retrying, so it races the delay above
  const shown = await page.locator('.todo-list li').first().isVisible()
  expect(shown).toBe(true)
})
