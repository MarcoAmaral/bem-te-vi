---
title: Sign-up page accessibility audit
slug: sign-up-page-accessibility-audit
article_type: reference
product_area: Accessibility
audience: Developers
plan_availability: All plans
reading_time: 4 min
related_articles: None: this is an audit report for a specific page
last_updated: 2026-10-18
---

# Sign-up page accessibility audit

This page has 11 accessibility issues that block keyboard users and screen reader users.

## Critical issues (blocks use entirely)

| Issue | Location | Impact | Fix |
| --- | --- | --- | --- |
| Submit button is a `<div>`, not a `<button>` | Line 19: `<div class="btn" onclick="submitForm()">` | Keyboard users cannot submit the form with Enter. Screen readers do not announce it as a button. | Replace with `<button type="submit">Create account</button>` and remove the `onclick` handler and JavaScript function. |
| Focus outline removed with no replacement | Line 8: `:focus { outline: none; }` | Keyboard users cannot see which element has focus. | Remove the `:focus { outline: none; }` rule or replace it with a visible focus style, e.g., `outline: 2px solid #0a58ca;` |
| Email and password inputs lack associated `<label>` elements | Lines 14–15: inputs have only `placeholder` attributes | Screen readers do not announce what each field is for. Placeholders disappear when typing. | Add `<label for="email">Email</label>` above the email input and `<label for="password">Password</label>` above the password input. |
| Password input has wrong `id` | Line 15: `id="email"` on the password field | Cannot associate a label to the password field; it has the same `id` as the email field. | Change to `id="password"`. |

## Major issues (missing context or feedback)

| Issue | Location | Impact | Fix |
| --- | --- | --- | --- |
| Logo image has no alt text | Line 13: `<img src="/img/logo-2024-final.png">` | Screen reader users do not know what the image is. Assume: the image is the company logo. | Add `alt="Company logo"` (or the actual company name if known). |
| Password constraint not associated with field | Line 16: `<p class="hint">At least 8 characters.</p>` | Screen readers do not link the hint to the password field. Users may miss the requirement. | Add `id="password-hint"` to the `<p>` and `aria-describedby="password-hint"` to the password input. |
| Manual tab order with `tabindex="3"` | Line 17: `tabindex="3"` on the link | Tab order is unclear and fragile. Elements without explicit tab indices will be skipped. | Remove `tabindex="3"`. Use natural DOM order (move the link after the checkbox if it should come after). |

## Minor issues (usability and compatibility)

| Issue | Location | Impact | Fix |
| --- | --- | --- | --- |
| Missing `lang` attribute | Line 2: `<html>` | Screen readers may not apply the correct language pronunciation rules. | Add `lang="en"` (or the appropriate language code) to the `<html>` tag. |
| Insufficient color contrast on hint text | Line 8: `.hint { color: #595959; }` on white background | Hint text is hard to read for users with low vision. Contrast ratio is approximately 4.6:1; WCAG AA requires 4.5:1 (just meets AA) but not AAA (7:1). Assume: intended for general readability. | For WCAG AAA compliance, change hint color to `#404040` or darker. For AA, current color is acceptable but borderline. |

## Assumptions

- The logo image is decorative or company branding; alt text should name the company or brand.
- The page is in English; `lang="en"` is appropriate.
- The form submits to a server (the `<form>` element has no `action` attribute, so it will post to the current URL by default).
- The "At least 8 characters" hint applies only to the password field.
- Screen reader users and keyboard-only users are the primary audiences for this audit.

## Impact summary

**Keyboard navigation:** The submit button is not reachable or usable via keyboard. The form cannot be completed without a mouse.

**Screen readers:** Inputs lack labels, the button is not announced as a button, the password constraint is not associated with its field, and the logo is not described.

**Visual:** Focus indicators are invisible; users cannot see which field or button is active during keyboard navigation.
