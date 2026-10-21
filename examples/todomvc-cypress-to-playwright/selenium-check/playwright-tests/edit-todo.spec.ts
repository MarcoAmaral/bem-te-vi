import { expect, test } from "./fixtures";

// Migrated from TodoTest.editsATodoOnDoubleClick (groups: regression).
test("edits a todo on double click @regression @e2e @p2 @automated @todos", async ({ todo }) => {
  // Arrange
  await todo.add("book a doctors appointment");

  // Act
  await todo.edit(0, "book a dentist appointment");

  // Assert
  await expect(todo.item(0)).toHaveText("book a dentist appointment");
});
