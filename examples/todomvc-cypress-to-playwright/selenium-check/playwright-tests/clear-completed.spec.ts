import { expect, test } from "./fixtures";

// Migrated from TodoTest.clearsCompletedTodos (groups: regression).
// The old test asserted only the remaining count, not which todo remains; this one does the same.
test("clears completed todos @regression @e2e @p2 @automated @todos", async ({ todo }) => {
  // Arrange
  await todo.add("one");
  await todo.add("two");
  await todo.toggle(1);

  // Act
  await todo.clearCompleted.click();

  // Assert
  await expect(todo.items).toHaveCount(1);
});
