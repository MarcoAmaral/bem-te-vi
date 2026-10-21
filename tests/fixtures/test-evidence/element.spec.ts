import { test } from "@playwright/test";

test("element capture", async ({ page }) => {
  await page.getByTestId("order-total").screenshot({ path: "evidence/TC-CART-003-total.png" });
});
