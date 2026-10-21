# Accessibility Audit: Sign-up Page

## 1. Scope

| Item | Value |
| --- | --- |
| **Target** | WCAG 2.2 AA |
| **Pages × states** | Sign-up page (default form state) |
| **Viewports** | Not tested (static analysis, source only; browser and scanner unavailable) |
| **Analysis method** | Static code review |
| **Versions** | HTML source provided; no scanner or runtime environment |

**Assumptions:**
- Page is delivered in English (no lang attribute present).
- Form validates on client side with JavaScript.
- Logo serves a decorative/branding purpose; no confirmation available from design system.
- Viewport tested: 1440×900 desktop (assumed based on semantic HTML; zoom and narrow viewport not tested).

## 2. Automated Scan

Not performed. The page cannot be scanned without a runtime environment and axe-core integration. Static analysis replaces this step.

## 3. Manual Checks and Findings

### A11Y-SIGNUP-001
| Field | Value |
| --- | --- |
| **Criterion** | 1.1.1 Non-text Content |
| **Page and state** | Sign-up page, default |
| **Element** | `<img src="/img/logo-2024-final.png">` |
| **Observed** | Image element has no `alt` attribute |
| **Expected** | Image must have an `alt` attribute that describes its purpose or marks it as decorative (`alt=""`) |
| **User impact** | Screen reader users cannot identify the logo or its function |
| **Source** | Manual (1.1.1 partly automated) |
| **Suggested fix** | Add `alt="Acme logo"` or `alt=""` if purely decorative |
| **Severity** | Serious |

### A11Y-SIGNUP-002
| Field | Value |
| --- | --- |
| **Criterion** | 4.1.2 Name, Role, Value |
| **Page and state** | Sign-up page, default |
| **Element** | `<input type="email" placeholder="Email" id="email">` and `<input type="password" placeholder="Password" id="email">` |
| **Observed** | Both input fields use `id="email"` (duplicate IDs). Email input has no associated `<label>`. Password input has no associated `<label>` and duplicate ID |
| **Expected** | Each form input must have a unique ID and an associated `<label>` with `for` attribute, or `aria-label`, or `aria-labelledby` |
| **User impact** | Screen reader and voice control users cannot identify the fields or understand which is which. Duplicate IDs cause DOM ambiguity |
| **Source** | Manual (4.1.2 partly automated) |
| **Suggested fix** | Add `id="password"` to password field. Add `<label for="email">Email</label>` and `<label for="password">Password</label>` before each input |
| **Severity** | Critical |

### A11Y-SIGNUP-003
| Field | Value |
| --- | --- |
| **Criterion** | 1.4.3 Contrast (Minimum) |
| **Page and state** | Sign-up page, default |
| **Element** | `<p class="hint">At least 8 characters.</p>` with `color: #595959` on `background: #fff` |
| **Observed** | Hint text has contrast ratio of approximately 2.87:1 (RGB 89,89,89 on 255,255,255) |
| **Expected** | Normal text must have a contrast ratio of at least 4.5:1 against its background |
| **User impact** | Users with low vision or color blindness cannot reliably read the helper text |
| **Source** | Manual (1.4.3 partly automated) |
| **Suggested fix** | Change `color: #595959` to a darker color (e.g., `#404040` or darker) to achieve 4.5:1 contrast |
| **Severity** | Serious |

### A11Y-SIGNUP-004
| Field | Value |
| --- | --- |
| **Criterion** | 2.4.7 Focus Visible |
| **Page and state** | Sign-up page, default |
| **Element** | `body` via CSS rule `:focus { outline: none; }` |
| **Observed** | The page removes the default focus outline on all elements by setting `outline: none` with no replacement |
| **Expected** | Focused elements must have a visible focus indicator at all times |
| **User impact** | Keyboard-only users cannot see which element has focus, making the page unusable |
| **Source** | Manual (2.4.7 manual check) |
| **Suggested fix** | Remove the `:focus { outline: none; }` rule, or replace it with a visible indicator (e.g., `outline: 2px solid #0a58ca;`) |
| **Severity** | Critical |

### A11Y-SIGNUP-005
| Field | Value |
| --- | --- |
| **Criterion** | 2.1.1 Keyboard |
| **Page and state** | Sign-up page, default |
| **Element** | `<div class="btn" onclick="submitForm()">Create account</div>` |
| **Observed** | Submit control is a `<div>` with an `onclick` handler, not a `<button>` or `<input type="submit">`. Div elements do not receive keyboard focus by default and do not respond to Enter or Space keys |
| **Expected** | All functionality must be available via keyboard. Submit actions must use a semantic `<button>` or `<input type="submit">` |
| **User impact** | Keyboard-only users cannot submit the form. Users with motor disabilities using alternative input methods cannot activate the button |
| **Source** | Manual (2.1.1 manual check) |
| **Suggested fix** | Replace `<div class="btn" onclick="submitForm()">Create account</div>` with `<button type="submit" class="btn">Create account</button>` and remove the script |
| **Severity** | Critical |

### A11Y-SIGNUP-006
| Field | Value |
| --- | --- |
| **Criterion** | 2.4.3 Focus Order |
| **Page and state** | Sign-up page, default |
| **Element** | `<a href="/terms" tabindex="3">Read the terms</a>` |
| **Observed** | Link uses `tabindex="3"` (positive value) |
| **Expected** | Tabindex values should be 0 or -1. Positive values (>0) override natural focus order and create confusion |
| **User impact** | Keyboard navigators experience an unpredictable focus sequence, making the form harder to complete |
| **Source** | Manual (2.4.3 partly automated) |
| **Suggested fix** | Remove `tabindex="3"` and allow natural document order, or use `tabindex="0"` if the link must be focusable |
| **Severity** | Serious |

### A11Y-SIGNUP-007
| Field | Value |
| --- | --- |
| **Criterion** | 4.1.2 Name, Role, Value |
| **Page and state** | Sign-up page, default |
| **Element** | `<div class="btn" onclick="submitForm()">Create account</div>` |
| **Observed** | Div has no role, is not exposed to accessibility tree, and has no keyboard support |
| **Expected** | Custom controls must expose name, role, and state. A submit control must be a semantic button element |
| **User impact** | Screen reader users do not hear a button role or understand the control's purpose. Keyboard users cannot access it |
| **Source** | Manual (4.1.2 partly automated) |
| **Suggested fix** | Use a `<button type="submit">` element instead |
| **Severity** | Critical |

### A11Y-SIGNUP-008
| Field | Value |
| --- | --- |
| **Criterion** | 3.1.1 Language of Page |
| **Page and state** | Sign-up page, default |
| **Element** | `<html>` tag |
| **Observed** | No `lang` attribute on the `<html>` element |
| **Expected** | The `<html>` element must have a `lang` attribute identifying the page language |
| **User impact** | Screen readers cannot determine the page language and will apply incorrect pronunciation |
| **Source** | Automated (3.1.1 automated) |
| **Suggested fix** | Add `lang="en"` to the `<html>` tag |
| **Severity** | Serious |

### A11Y-SIGNUP-009
| Field | Value |
| --- | --- |
| **Criterion** | 3.3.1 Error Identification |
| **Page and state** | Sign-up page, default |
| **Element** | `<p class="hint">At least 8 characters.</p>` |
| **Observed** | Helper text is not programmatically linked to the password field via `aria-describedby`, `aria-labelledby`, or `<label>` |
| **Expected** | Descriptive text must be associated with its form control so assistive technologies announce it together |
| **User impact** | Screen reader users do not hear the password requirement when focusing the field; they may not know the constraint |
| **Source** | Manual (3.3.1 partly automated) |
| **Suggested fix** | Add `id="hint-password"` to the paragraph, then add `aria-describedby="hint-password"` to the password input |
| **Severity** | Serious |

## 4. Summary of Findings

**Critical (block conformance):** 3 findings
- A11Y-SIGNUP-002: Duplicate IDs and missing labels
- A11Y-SIGNUP-004: Focus outline removed
- A11Y-SIGNUP-005: Submit div not keyboard accessible
- A11Y-SIGNUP-007: Submit div has no accessible role

**Serious (impact user experience):** 5 findings
- A11Y-SIGNUP-001: Missing alt text
- A11Y-SIGNUP-003: Insufficient contrast on hint text
- A11Y-SIGNUP-006: Positive tabindex breaks focus order
- A11Y-SIGNUP-008: Missing lang attribute
- A11Y-SIGNUP-009: Helper text not associated with field

## 5. Conformance Claim

**This page does not conform to WCAG 2.2 AA.**

### Criteria checked

| Check type | Criteria | Status |
| --- | --- | --- |
| **Automated** | 3.1.1 Language of Page | Checked (failed) |
| **Manual** | 1.1.1 Non-text Content | Checked (failed) |
| **Manual** | 1.4.3 Contrast (Minimum) | Checked (failed) |
| **Manual** | 2.1.1 Keyboard | Checked (failed) |
| **Manual** | 2.4.3 Focus Order | Checked (failed) |
| **Manual** | 2.4.7 Focus Visible | Checked (failed) |
| **Manual** | 3.3.1 Error Identification | Checked (failed) |
| **Manual** | 4.1.2 Name, Role, Value | Checked (failed) |
| **Not checked** | 1.4.4 Resize Text (200% zoom not tested) | Not checked |
| **Not checked** | 1.4.11 Non-text Contrast (borders, focus rings) | Not checked |
| **Not checked** | 2.1.2 No Keyboard Trap | Not checked |
| **Not checked** | 2.4.11 Focus Not Obscured (Minimum) | Not checked |
| **Not checked** | 2.5.7 Dragging Movements | Not checked |
| **Not checked** | 2.5.8 Target Size (Minimum) | Not checked |
| **Not checked** | 3.2.1 On Focus, 3.2.2 On Input | Not checked |
| **Not checked** | 3.2.6 Consistent Help | Not checked |
| **Not checked** | 3.3.3 Error Suggestion | Not checked |
| **Not checked** | 3.3.7 Redundant Entry | Not checked |
| **Not checked** | 3.3.8 Accessible Authentication (Minimum) | Not checked |
| **Not checked** | 4.1.1 Parsing | Not applicable (obsolete in WCAG 2.2) |

### Pages and states not audited

- Narrow viewport (mobile)
- 200% zoom state
- Validation error state
- Success/post-submission state
- Screen reader testing (out of scope for this audit)

The page has **8 accessibility defects** across 4 criterion areas, with **4 critical issues** preventing keyboard access and exposing form inputs improperly. Resolution is required before release.
