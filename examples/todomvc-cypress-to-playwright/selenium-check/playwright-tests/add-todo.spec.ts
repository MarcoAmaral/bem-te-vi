import { expect, test } from "./fixtures";
import { titles } from "./data";

// Golden reference spec. Migrated from TodoTest.addsATodo (groups: smoke).
for (const title of titles) {
  test(`adds a todo "${title}" @smoke @e2e @p0 @automated @todos`, async ({ todo }) => {
    // Arrange: fixture opened the app with no todos

    // Act
    await todo.add(title);

    // Assert
    await expect(todo.items).toHaveCount(1);
    await expect(todo.item(0)).toHaveText(title.trim());
  });
}
