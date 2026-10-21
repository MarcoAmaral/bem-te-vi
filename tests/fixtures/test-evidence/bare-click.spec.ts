import { test } from "@playwright/test";

test("bare click", async ({ page }) => {
  await page.getByRole("button", { name: "Save" }).click();
});
