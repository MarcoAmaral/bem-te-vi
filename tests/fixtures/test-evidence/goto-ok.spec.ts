import { test } from "@playwright/test";

test("documented navigation", async ({ page }) => {
  await page.goto("/login"); // goto-ok: setup, the login page is the starting point
  // goto-ok: seeding a known starting page
  await page.goto("/orders");
});
