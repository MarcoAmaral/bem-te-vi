import { test } from "@playwright/test";

test("non-ascii name", async ({ page }) => {
  await page.screenshot({ path: "evidence/TC-CART-004 · total.png" });
});
