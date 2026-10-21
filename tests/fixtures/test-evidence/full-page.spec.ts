import { test } from "@playwright/test";

test("full page capture", async ({ page }) => {
  await page.screenshot({ path: "evidence/TC-CART-002-cart.png", fullPage: true });
});
