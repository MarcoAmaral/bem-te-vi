import { test, expect, type Page } from "@playwright/test";
import { mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { click, shot, showOverlay } from "../support/evidence";

// Step 3 of the qa-a11y skill: the checks axe-core cannot decide. Each test gathers measurements
// and keeps viewport screenshots; the verdict for each check is a person's, written in
// a11y/audit.md after opening the screenshots. Read-only: GETs, form submits the API rejects with
// 400 or 401, and one signup form that the browser's own validation stops before any request.

const RAW = join(__dirname, "..", "..", "a11y", "raw");
const out: Record<string, unknown> = {};
const requests: string[] = [];

test.describe.configure({ mode: "serial" });

test.beforeEach(async ({ page }) => {
  page.on("response", (r) => {
    if (r.request().method() !== "GET")
      requests.push(`${r.request().method()} ${r.url()} -> ${r.status()}`);
  });
});

test.afterAll(() => {
  out.nonGetRequestsSent = requests;
  // read-only guarantee: every write the pages attempted was rejected
  expect(requests.filter((r) => / -> 2\d\d$/.test(r))).toEqual([]);
  mkdirSync(RAW, { recursive: true });
  writeFileSync(join(RAW, "manual-checks.json"), JSON.stringify(out, null, 2));
});

// What the focused element is, and how its focus is drawn.
async function focused(page: Page) {
  // Let a CSS transition on the focus style finish, so the style read is the settled one.
  await page.evaluate(() =>
    Promise.all(document.getAnimations().map((a) => a.finished)),
  );
  return page.evaluate(() => {
    const e = document.activeElement as HTMLElement;
    if (!e || e === document.body) return { element: "body", reachable: false };
    const s = getComputedStyle(e);
    const r = e.getBoundingClientRect();
    // Contrast of the focus box-shadow, blended over a white page, against white (1.4.11, 2.4.7).
    const m = s.boxShadow.match(/rgba?\(([^)]+)\)/);
    let ringContrast: number | null = null;
    if (m) {
      const [R, G, B, A = 1] = m[1].split(",").map(Number);
      const mix = [R, G, B].map((v) => v * A + 255 * (1 - A));
      const f = (v: number) =>
        (v /= 255) <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4;
      const L = 0.2126 * f(mix[0]) + 0.7152 * f(mix[1]) + 0.0722 * f(mix[2]);
      ringContrast = +(1.05 / (L + 0.05)).toFixed(2);
    }
    return {
      focusRingContrastAgainstWhite: ringContrast,
      element: `${e.tagName.toLowerCase()}[${e.getAttribute("data-testid") || e.getAttribute("name") || e.textContent?.trim().slice(0, 20)}]`,
      outline: `${s.outlineStyle} ${s.outlineWidth} ${s.outlineColor}`,
      boxShadow: s.boxShadow,
      borderColor: s.borderColor,
      inViewport:
        r.top >= 0 &&
        r.bottom <= innerHeight &&
        r.left >= 0 &&
        r.right <= innerWidth,
    };
  });
}

// Presses Tab `max` times and records where focus lands. After the Tab number `shotAfter` it keeps
// a screenshot: the one that follows the last control, where a skipped control shows.
async function tabThrough(
  page: Page,
  max: number,
  shotAfter: number,
  shotName: string,
) {
  const order: unknown[] = [];
  for (let i = 1; i <= max; i++) {
    await page.keyboard.press("Tab");
    order.push(await focused(page));
    if (i === shotAfter) await shot(page, shotName);
  }
  return order;
}

test("keyboard: login, tab order, focus and completing the form @a11y", async ({
  page,
}) => {
  await page.goto("/login"); // goto-ok: the page itself is the audit target
  await expect(page.getByTestId("entrar")).toBeVisible();
  await showOverlay(page, "A11Y-MAN login keyboard");
  out.loginTabOrder = await tabThrough(
    page,
    6,
    4,
    "A11Y-MAN-2.1.1-login-tab-past-last-control.png",
  );

  await page.reload();
  await showOverlay(page, "A11Y-MAN login keyboard");
  await page.keyboard.press("Tab");
  await shot(page, "A11Y-MAN-2.4.7-login-focus-email.png");
  await page.keyboard.type("qa-a11y-audit@example.invalid");
  await page.keyboard.press("Tab");
  await page.keyboard.type("not-a-real-password");
  await page.keyboard.press("Tab");
  await shot(page, "A11Y-MAN-2.4.7-login-focus-button.png");
  const reply = page.waitForResponse(
    (r) => r.url().endsWith("/login") && r.request().method() === "POST",
  );
  await page.keyboard.press("Enter");
  const res = await reply;
  await expect(page.getByRole("alert").first()).toBeVisible();
  out.loginKeyboardCompletion = {
    status: res.status(),
    alertText: await page.getByRole("alert").first().innerText(),
    focusAfterSubmit: await focused(page),
    url: page.url(),
  };
  await shot(page, "A11Y-MAN-3.3.1-login-error-after-keyboard-submit.png");
});

test("keyboard: signup, every control reachable and operable @a11y", async ({
  page,
}) => {
  await page.goto("/cadastrarusuarios"); // goto-ok: the page itself is the audit target
  await expect(page.getByTestId("cadastrar")).toBeVisible();
  await showOverlay(page, "A11Y-MAN signup keyboard");
  out.signupTabOrder = await tabThrough(
    page,
    7,
    6,
    "A11Y-MAN-2.1.1-signup-tab-past-last-control.png",
  );

  await page.reload();
  await showOverlay(page, "A11Y-MAN signup keyboard");
  await page.keyboard.press("Tab");
  await shot(page, "A11Y-MAN-2.4.7-signup-focus-name.png");
  await page.keyboard.type("QA Audit");
  await page.keyboard.press("Tab");
  await page.keyboard.type("not-an-email"); // the browser's own validation stops the submit
  await page.keyboard.press("Tab");
  await page.keyboard.type("not-a-real-password");
  await page.keyboard.press("Tab");
  await page.keyboard.press("Space");
  const checked = await page.getByTestId("checkbox").isChecked();
  await shot(page, "A11Y-MAN-2.4.7-signup-focus-checkbox.png");
  await page.keyboard.press("Tab");
  const before = requests.length;
  await page.keyboard.press("Enter");
  await expect(page.getByTestId("email")).toBeFocused();
  out.signupKeyboardCompletion = {
    checkboxToggledBySpace: checked,
    newRequestsAfterSubmit: requests.length - before,
    validationMessage: await page
      .getByTestId("email")
      .evaluate((e: HTMLInputElement) => e.validationMessage),
    focusAfterSubmit: await focused(page),
  };
  await shot(page, "A11Y-MAN-3.3.1-signup-native-validation-focus.png");
});

test("errors, authentication, language, context changes @a11y", async ({
  page,
}) => {
  await page.goto("/login"); // goto-ok: the page itself is the audit target
  await showOverlay(page, "A11Y-MAN login errors");
  const urlBefore = page.url();
  await click(page, page.getByTestId("entrar"));
  await expect(page.getByRole("alert").first()).toBeVisible();
  out.loginEmptySubmit = await page.evaluate(() => ({
    alerts: [...document.querySelectorAll("[role=alert]")].map((a) =>
      a.textContent?.trim(),
    ),
    inputs: [...document.querySelectorAll("input")].map((i) => ({
      name: i.name,
      ariaInvalid: i.getAttribute("aria-invalid"),
      ariaDescribedby: i.getAttribute("aria-describedby"),
      autocomplete: i.getAttribute("autocomplete"),
    })),
    focus: (document.activeElement as HTMLElement)?.tagName,
  }));
  await shot(page, "A11Y-MAN-3.3.1-login-empty-submit-errors.png");

  // 3.3.8: is paste blocked in the password field?
  out.pasteIntoPasswordPrevented = await page
    .getByTestId("senha")
    .evaluate((el) => {
      const ev = new ClipboardEvent("paste", {
        bubbles: true,
        cancelable: true,
        clipboardData: new DataTransfer(),
      });
      el.dispatchEvent(ev);
      return ev.defaultPrevented;
    });

  // 3.2.1 and 3.2.2: focusing and typing do not change the page
  await page.getByTestId("email").focus();
  await page.getByTestId("email").fill("a@b.c");
  await page.getByTestId("senha").focus();
  out.contextChangedByFocusOrInput = page.url() !== urlBefore;

  // 3.1.1: declared language against the language of the content
  out.language = await page.evaluate(() => ({
    htmlLang: document.documentElement.lang,
    visibleText: document.body.innerText.replace(/\s+/g, " ").slice(0, 120),
  }));

  // 2.4.11, 2.5.7: anything fixed or sticky, anything draggable
  out.fixedOrSticky = await page.evaluate(
    () =>
      [...document.querySelectorAll("body *")]
        .filter(
          (e) =>
            ["fixed", "sticky"].includes(getComputedStyle(e).position) &&
            !e.id.startsWith("qa-evidence"),
        )
        .map((e) => e.tagName).length,
  );
  out.draggable = await page.evaluate(
    () => document.querySelectorAll("[draggable=true]").length,
  );
});

test("size and contrast of controls, both pages @a11y", async ({ page }) => {
  const measure = () =>
    page.evaluate(() => {
      const lum = (c: string) => {
        const m = c.match(/[\d.]+/g)!.map(Number);
        const f = (v: number) =>
          (v /= 255) <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4;
        return 0.2126 * f(m[0]) + 0.7152 * f(m[1]) + 0.0722 * f(m[2]);
      };
      const ratio = (a: string, b: string) => {
        const [x, y] = [lum(a), lum(b)].sort((p, q) => q - p);
        return +((x + 0.05) / (y + 0.05)).toFixed(2);
      };
      // The page paints no background of its own, so it is white.
      const raw = getComputedStyle(document.body).backgroundColor;
      const bg = raw === "rgba(0, 0, 0, 0)" ? "rgb(255, 255, 255)" : raw;
      return [...document.querySelectorAll("input,button,a,label")].map((e) => {
        const r = e.getBoundingClientRect();
        const s = getComputedStyle(e);
        return {
          element: `${e.tagName.toLowerCase()}[${e.getAttribute("data-testid") || e.getAttribute("name") || e.textContent?.trim().slice(0, 12)}]`,
          width: +r.width.toFixed(1),
          height: +r.height.toFixed(1),
          borderColor: s.borderColor,
          borderWidth: s.borderTopWidth,
          pageBackground: bg,
          borderToPageContrast: s.borderTopColor.startsWith("rgba(0, 0, 0, 0")
            ? null
            : ratio(s.borderTopColor, bg),
        };
      });
    });
  for (const [key, path] of [
    ["login", "/login"],
    ["signup", "/cadastrarusuarios"],
  ]) {
    await page.goto(path); // goto-ok: the page itself is the audit target
    await expect(page.getByRole("heading").first()).toBeVisible();
    out[`${key}Targets`] = await measure();
    // the error state adds the alert close buttons
    await click(
      page,
      page.getByTestId(key === "login" ? "entrar" : "cadastrar"),
    );
    await expect(page.getByRole("alert").first()).toBeVisible();
    out[`${key}TargetsAfterError`] = (await measure()).filter(
      (t) =>
        t.element.startsWith("button[×") ||
        t.element.startsWith("button[Close") ||
        t.element.startsWith("button[\u00d7"),
    );
  }
  await page.goto("/login"); // goto-ok: the page itself is the audit target
  await showOverlay(page, "A11Y-MAN login field border");
  await click(page, page.getByTestId("email"));
  await shot(page, "A11Y-MAN-1.4.11-login-field-border.png");

  await page.close();
});

test("200% zoom, both pages @a11y", async ({ browser }) => {
  // 200% zoom on a 1440 x 900 screen is a 720 x 450 CSS viewport at device scale factor 2: the
  // page reflows as it does under browser zoom, and the screenshot is still 1440 x 900 pixels.
  const context = await browser.newContext({
    viewport: { width: 720, height: 450 },
    deviceScaleFactor: 2,
  });
  const page = await context.newPage();
  for (const [key, path] of [
    ["login", "/login"],
    ["signup", "/cadastrarusuarios"],
  ]) {
    await page.goto(path); // goto-ok: the page itself is the audit target
    await expect(page.getByRole("heading").first()).toBeVisible();
    await showOverlay(page, `A11Y-MAN ${key} zoom 200`);
    out[`${key}Zoom200`] = await page.evaluate(() => ({
      scrollWidth: document.documentElement.scrollWidth,
      clientWidth: document.documentElement.clientWidth,
    }));
    // the subject is the whole form: scroll its last control into view before the capture
    await page
      .getByTestId(key === "login" ? "cadastrar" : "entrar")
      .scrollIntoViewIfNeeded();
    await shot(page, `A11Y-MAN-1.4.4-${key}-zoom200.png`);
  }
  await context.close();
});
