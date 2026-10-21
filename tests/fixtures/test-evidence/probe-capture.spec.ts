// evidence-check: probe
import { test } from "@playwright/test";

test("probe that captures evidence", async ({ page }) => {
  await page.screenshot({ path: "evidence/TC-PROBE-001.png" });
});
