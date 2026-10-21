import { test } from "@playwright/test";
import * as ui from "../helpers";

test("click through a namespaced helper", async ({ page }) => {
  await ui.click(page, page.getByRole("button", { name: "Save" }));
});
