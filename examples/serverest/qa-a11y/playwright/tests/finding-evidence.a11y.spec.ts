import { test, expect } from "@playwright/test";
import { mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { click, shot, showOverlay } from "../support/evidence";

// Step 4 of the qa-a11y skill: one viewport screenshot per finding, with the pointer on the
// element, named after the finding ID. Read-only: GETs and empty form submits that the API
// rejects with 400.

const RAW = join(__dirname, "..", "..", "a11y", "raw");
const details: Record<string, unknown> = {};

test.afterAll(() => {
  mkdirSync(RAW, { recursive: true });
  writeFileSync(
    join(RAW, "finding-details.json"),
    JSON.stringify(details, null, 2),
  );
});

const PAGES = [
  { key: "LOGIN", path: "/login", submit: "entrar", switchLink: "cadastrar" },
  {
    key: "SIGNUP",
    path: "/cadastrarusuarios",
    submit: "cadastrar",
    switchLink: "entrar",
  },
];

for (const p of PAGES) {
  test(`findings evidence on the ${p.key} page @a11y`, async ({ page }) => {
    await page.goto(p.path); // goto-ok: the page itself is the audit target
    await expect(page.getByTestId(p.submit)).toBeVisible();
    await showOverlay(page, `A11Y-${p.key}-001 logo has no alt`);

    // 1.1.1 logo without alt
    await page.locator("img").first().hover();
    details[`${p.key}Logo`] = await page
      .locator("img")
      .first()
      .evaluate((i) => ({
        alt: i.getAttribute("alt"),
        src: i.getAttribute("src"),
      }));
    await shot(page, `A11Y-${p.key}-001-logo-no-alt.png`);

    // 1.4.3 contrast of the switch-page text and, on signup, the administrator label
    await showOverlay(page, `A11Y-${p.key}-002 switch text contrast 3.54`);
    await page.locator("small.message").hover();
    await shot(page, `A11Y-${p.key}-002-switch-text-contrast.png`);
    if (p.key === "SIGNUP") {
      await showOverlay(page, "A11Y-SIGNUP-009 admin label contrast 3.54");
      await page.locator("label.form-check-label").hover();
      await shot(page, "A11Y-SIGNUP-009-admin-label-contrast.png");
    }

    // 2.1.1 and 4.1.2: the switch-page control is an anchor with no href
    details[`${p.key}SwitchControl`] = await page
      .getByTestId(p.switchLink)
      .evaluate((a) => ({
        tag: a.tagName.toLowerCase(),
        href: a.getAttribute("href"),
        tabindex: a.getAttribute("tabindex"),
        role: a.getAttribute("role"),
        type: a.getAttribute("type"),
      }));

    // 3.1.1 declared language against the content
    await showOverlay(page, `A11Y-${p.key}-005 lang en, text Portuguese`);
    details[`${p.key}Lang`] = await page.evaluate(
      () => document.documentElement.lang,
    );
    await shot(page, `A11Y-${p.key}-005-lang-en-portuguese-text.png`);

    // 1.4.3 contrast of the error text, and the incomplete close glyph
    await showOverlay(page, `A11Y-${p.key}-003 error text contrast 2.17`);
    await click(page, page.getByTestId(p.submit));
    await expect(page.getByRole("alert").first()).toBeVisible();
    await page.getByRole("alert").first().locator("span").last().hover();
    details[`${p.key}ErrorColours`] = await page
      .getByRole("alert")
      .first()
      .evaluate((a) => {
        const text = a.querySelector("span:not([aria-hidden])")!;
        const glyph = a.querySelector("button span")!;
        const btn = a.querySelector("button")!;
        return {
          alertBackground: getComputedStyle(a).backgroundColor,
          textColor: getComputedStyle(text).color,
          glyphColor: getComputedStyle(glyph).color,
          closeButtonOpacity: getComputedStyle(btn).opacity,
          closeButtonColor: getComputedStyle(btn).color,
          closeButtonAriaLabel: btn.getAttribute("aria-label"),
          closeButtonWidth: btn.getBoundingClientRect().width,
          closeButtonHeight: btn.getBoundingClientRect().height,
        };
      });
    await shot(page, `A11Y-${p.key}-003-error-text-contrast.png`);
  });
}
