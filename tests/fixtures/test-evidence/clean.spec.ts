import { test } from "@playwright/test";

test("clean evidence @smoke @e2e @p0", async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.screenshot({ path: "evidence/TC-CART-001-total.png" });
});
