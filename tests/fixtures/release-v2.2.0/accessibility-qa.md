# Accessibility (a11y) QA Rules & Guidelines

> **WCAG 2.2 AA Standard** | Semantic HTML | Screen Reader Testing | Automated & Manual Audits

This ruleset governs all Accessibility (a11y) testing processes, test criteria, and automated verification rules. AI agents and QA engineers must apply these rules to ensure the user interface is accessible to all users, including those relying on assistive technologies.

---

## ♿ WCAG 2.2 AA Key Success Criteria

Every frontend feature must be verified against these core pillars:

### 1. Perceivable (Can users see/hear it?)

- **Non-Text Content (1.1.1)**: All images and icons must have appropriate `alt` descriptions or `aria-label` tags. Decorative elements must carry `alt=""` or `role="presentation"`.
- **Contrast (Minimum) (1.4.3)**:
  - Normal text (<18pt or <14pt bold): At least **4.5:1** contrast ratio.
  - Large text (>=18pt or >=14pt bold): At least **3.0:1** contrast ratio.
  - UI components and graphical objects: At least **3.0:1** contrast ratio.
- **Resize Text (1.4.4)**: Text must be resizable up to 200% without loss of content or functionality (no hardcoded container heights that clip text).

### 2. Operable (Can users navigate it?)

- **Keyboard Accessible (2.1.1)**: All interactive elements (buttons, links, inputs, dropdowns) must be navigable and operable using only the `Tab` and `Enter` / `Space` keys.
- **No Keyboard Trap (2.1.2)**: Focus must never be trapped in visual modals, overlays, or calendar pickers. Modals must close on `Escape`.
- **Focus Visible (2.4.7)**: Highly visible focus indicators (outlines) must be styled and must never be suppressed (`outline: none` is forbidden unless custom, highly visible `:focus-visible` styles are provided).
- **Focus Order (2.4.3)**: Keyboard navigation must follow a logical reading order (top-to-bottom, left-to-right). Use native HTML tab order; avoid `tabindex` values > `0`.

### 3. Understandable (Is the content clear?)

- **Language of Page (3.1.1)**: The `<html>` element must carry a valid `lang` attribute (e.g., `<html lang="en">`).
- **On Focus / On Input (3.2.1 / 3.2.2)**: Focusing or changing the state of any input must never trigger a sudden change of context (e.g., auto-submitting a form or opening a new window without warning).
- **Error Identification & Suggestions (3.3.1 / 3.3.3)**: Validation errors must be described in text and point out the specific error. Assistive technologies must be notified using `aria-describedby` or `role="alert"`.

### 4. Robust (Does it work with assistive tech?)

- **Name, Role, Value (4.1.2)**: Assistive technologies must be able to resolve the name, role, and current state of every interactive component. Custom components (e.g., custom checkboxes, toggle switch divs) must use correct ARIA attributes (`role="checkbox"`, `aria-checked="true"`, etc.).

---

## 🛠️ Automated a11y Integration (Playwright)

For automated end-to-end regressions, we integrate **@axe-core/playwright**. All main page flows must be audited using the following test template:

```typescript
import { test, expect } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";

test.describe("Accessibility Audits", () => {
  test("Should pass WCAG 2.2 AA audits on the home page", async ({ page }) => {
    await page.goto("/");

    // Wait for dynamic content to render
    await page.waitForSelector("main");

    // Run Axe audit
    const results = await new AxeBuilder({ page })
      .withTags(["wcag2a", "wcag2aa", "wcag22aa"])
      .analyze();

    // Assert zero violations
    expect(results.violations).toEqual([]);
  });

  test("Should pass audits on active modal dialog", async ({ page }) => {
    await page.goto("/dashboard");
    await page.click("button#open-settings");
    await page.waitForSelector("role=dialog");

    const results = await new AxeBuilder({ page })
      .include("role=dialog")
      .withTags(["wcag2a", "wcag2aa"])
      .analyze();

    expect(results.violations).toEqual([]);
  });
});
```

---

## 🔍 Visual & Interactive Manual Checklist

AI agents drafting manual test plans must include this quick a11y testing guide:

1.  **Tab Test**: Tab through the entire page. Does the focus indicator land on every button, link, and form input? Does it skip non-interactive text?
2.  **Modal Trap Test**: Open a modal. Can you Tab out of the modal back to the main page? (If yes, bug!). Does pressing `Escape` close the modal? Does focus return to the button that opened it?
3.  **Color Blindness Simulation**: Run tests in grayscale or using browser emulation tools (e.g., Chrome DevTools -> Rendering -> Emulate visual deficiencies). Are errors, alerts, or links still distinguishable without relying on color?
4.  **Screen Reader Emulation (VoiceOver/NVDA/TalkBack)**:
    - Navigate by headings (`H1` to `H6`). Are they nested logically?
    - Do custom dropdowns declare their expanded state (`aria-expanded="true/false"`)?
    - Are status updates or success messages announced using `aria-live="polite"`?
