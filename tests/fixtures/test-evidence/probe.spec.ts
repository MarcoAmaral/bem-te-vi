// evidence-check: probe
import { test } from "@playwright/test";

test("reconnaissance", async ({ page }) => {
  await page.goto("/orders");
  await page.getByRole("button", { name: "Save" }).click();
});
