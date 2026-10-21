import { test, expect } from '../fixtures'

// The fix for seeded-flake.spec.ts: the same Arrange and Act, with a web-first assertion that
// retries until the row is visible. BREAK_RENDER=1 makes the page never show the row again,
// which is the behaviour the test checks, broken on purpose (the red half of red-green).
test('a newly added todo is shown in the list', {
  tag: ['@regression', '@e2e', '@p2', '@candidate'],
}, async ({ todoPage, page }) => {
  // Arrange
  const neverShow = process.env.BREAK_RENDER === '1'
  await page.evaluate((never) => {
    const input = document.querySelector<HTMLInputElement>('.new-todo')!
    input.addEventListener('keydown', (event) => {
      if (event.key !== 'Enter') return
      setTimeout(() => {
        const row = document.querySelector<HTMLElement>('.todo-list li')
        if (!row) return
        row.style.visibility = 'hidden'
        if (!never) setTimeout(() => { row.style.visibility = 'visible' }, Math.random() * 10)
      }, 0)
    })
  }, neverShow)

  // Act
  await todoPage.newTodo.fill('buy milk')
  await todoPage.newTodo.press('Enter')

  // Assert
  await expect(page.locator('.todo-list li').first()).toBeVisible()
})
