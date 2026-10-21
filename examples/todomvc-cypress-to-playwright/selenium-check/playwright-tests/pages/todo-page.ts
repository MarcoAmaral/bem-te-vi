import type { Locator, Page } from "@playwright/test";

/** Replaces the Java `TodoPage`. Actions and locators only; assertions live in the specs. */
export class TodoPage {
  readonly newTodo: Locator;
  readonly items: Locator;
  readonly count: Locator;
  readonly clearCompleted: Locator;

  constructor(private readonly page: Page) {
    this.newTodo = page.getByPlaceholder("What needs to be done?");
    // A todo row is any list item without a link (the three footer filters are list items that hold links).
    // Not "has a checkbox": a row being edited hides its checkbox and would stop matching.
    this.items = page.getByRole("listitem").filter({ hasNot: page.getByRole("link") });
    this.count = page.getByText(/items? left/);
    this.clearCompleted = page.getByRole("button", { name: "Clear completed" });
  }

  async goto() {
    await this.page.goto("/");
  }

  async add(title: string) {
    await this.newTodo.fill(title);
    await this.newTodo.press("Enter");
  }

  item(index: number): Locator {
    return this.items.nth(index);
  }

  async toggle(index: number) {
    await this.item(index).getByRole("checkbox").check();
  }

  async edit(index: number, text: string) {
    const item = this.item(index);
    await item.getByText(/./).dblclick();
    const box = item.getByRole("textbox");
    await box.fill(text);
    await box.press("Enter");
  }

  async filter(name: "All" | "Active" | "Completed") {
    await this.page.getByRole("link", { name }).click();
  }
}
