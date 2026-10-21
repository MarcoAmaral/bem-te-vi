import type { Locator, Page } from '@playwright/test'

// Locators and actions only. Assertions live in the specs (.claude/rules/code-style-qa.md).
//
// The app has no test ids and no landmark for the todo list: `ul.todo-list` and `ul.filters`
// are both unnamed lists. Todo rows are therefore the list items that hold no link
// (the filter rows are the ones that do).
export class TodoPage {
  readonly newTodo: Locator
  readonly toggleAll: Locator
  readonly clearCompleted: Locator
  readonly counter: Locator
  readonly items: Locator

  constructor(readonly page: Page) {
    this.newTodo = page.getByRole('textbox', { name: 'What needs to be done?' })
    this.toggleAll = page.getByRole('checkbox', { name: 'Mark all as complete' })
    this.clearCompleted = page.getByRole('button', { name: 'Clear completed' })
    this.counter = page.getByText(/\d+ items? left/)
    this.items = page.getByRole('listitem').filter({ hasNot: page.getByRole('link') })
  }

  async goto() {
    await this.page.goto('/')
  }

  async reload() {
    await this.page.reload()
  }

  async back() {
    await this.page.goBack()
  }

  async addTodo(title: string) {
    await this.newTodo.fill(title)
    await this.newTodo.press('Enter')
  }

  async addTodos(titles: string[]) {
    for (const title of titles) {
      await this.addTodo(title)
    }
  }

  itemWithText(title: string): Locator {
    return this.items.filter({ hasText: title })
  }

  filterLink(name: 'All' | 'Active' | 'Completed'): Locator {
    return this.page.getByRole('link', { name })
  }

  // A row's own controls. `item` comes from `items`.
  toggleOf(item: Locator): Locator {
    return item.getByRole('checkbox')
  }

  // Only visible while the row is being edited.
  editFieldOf(item: Locator): Locator {
    return item.getByRole('textbox')
  }

  async beginEdit(item: Locator, currentTitle: string) {
    await item.getByText(currentTitle).dblclick()
  }
}
