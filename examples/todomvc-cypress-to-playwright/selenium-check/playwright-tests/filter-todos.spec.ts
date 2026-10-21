import { expect, test } from "./fixtures";

// Migrated from TodoTest.filtersActiveTodos (groups: regression).
test("shows only active todos under the Active filter @regression @e2e @p1 @automated @todos", async ({ todo }) => {
  // Arrange
  await todo.add("one");
  await todo.add("two");
  await todo.toggle(0);

  // Act
  await todo.filter("Active");

  // Assert
  await expect(todo.items).toHaveCount(1);
  await expect(todo.item(0)).toHaveText("two");
});
