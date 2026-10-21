import { test } from "@playwright/test";

test("direct navigation", async ({ page }) => {
  await page.goto("/orders/42");
});
