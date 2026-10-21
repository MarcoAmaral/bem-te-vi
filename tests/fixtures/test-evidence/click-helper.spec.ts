import { test } from "@playwright/test";
import { click } from "../helpers";

test("click through the helper", async ({ page }) => {
  await click(page, page.getByRole("button", { name: "Save" }));
});
