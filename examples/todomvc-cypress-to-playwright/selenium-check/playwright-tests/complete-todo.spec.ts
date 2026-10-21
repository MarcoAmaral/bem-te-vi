import { expect, test } from "./fixtures";

// Migrated from TodoTest.completesATodo (groups: regression). The 500 ms Thread.sleep is not carried over:
// the web-first assertions retry until the state is reached.
test("completes a todo @regression @e2e @p1 @automated @todos", async ({ todo }) => {
  // Arrange
  await todo.add("feed the cat");

  // Act
  await todo.toggle(0);

  // Assert
  await expect(todo.item(0)).toHaveClass(/completed/);
  await expect(todo.count).toHaveText("0 items left");
});
