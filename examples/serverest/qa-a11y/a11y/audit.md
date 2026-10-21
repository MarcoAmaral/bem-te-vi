<!-- markdownlint-disable MD060 -->
# Accessibility audit: ServeRest front end, login and sign-up pages

Produced by following the `qa-a11y` skill. Evidence files are in [`evidence/`](evidence/), raw axe-core results and measurements in [`raw/`](raw/).

## 1. Scope

| Item | Value |
| ---- | ----- |
| Target | `https://front.serverest.dev`, the public front end of ServeRest (a practice site) |
| Conformance target | WCAG 2.2 level AA (`https://www.w3.org/TR/WCAG22/`) |
| Blocking threshold | **Not given.** The skill asks the team; ServeRest has no team to ask in this example. Every finding is listed with a severity and none is marked as blocking |
| Date | 2026-10-18 |
| Build seen | Front-end bundle `main.63e8c0e3.chunk.js` (as served on 2026-10-18); API behind it at `https://serverest.dev` |
| Tools | `@axe-core/playwright` 4.14.0 with axe-core 4.14.0, `@playwright/test` 1.64.1, Chromium 156.0.8078.4, Node v24.16.0 |
| axe-core tags | `wcag2a`, `wcag2aa`, `wcag21a`, `wcag21aa`, `wcag22aa` |
| Viewports | 1440 x 900 (the evidence viewport); 390 x 844 (narrow); 720 x 450 CSS px at device scale factor 2, which is 200% zoom on a 1440 x 900 screen |
| Method | Playwright specs in [`../playwright/tests/`](../playwright/tests/); screenshots are 1440 x 900 viewports with a pointer overlay and a case label |

ServeRest's pages are in Portuguese. Glosses: `Cadastro` = sign-up; `Cadastre-se` = sign up; `Entrar` = log in or enter; `Não é cadastrado?` = not registered?; `Já é cadastrado?` = already registered?; `Cadastrar como administrador?` = register as administrator?; `Email é obrigatório` = email is required; `Digite seu email` = type your email.

### Pages and states

| Page | State | 1440 | 390 | 200% zoom | Audited |
| ---- | ----- | ---- | --- | --------- | ------- |
| Login (`/login`) | Default | yes | yes | yes | yes |
| Login | Validation error (empty submit, API answers 400) | yes | no | no | 1440 only |
| Login | Invalid credentials after a keyboard-only submit (API answers 400) | yes | no | no | 1440 only |
| Login | Success, and every page behind it | no | no | no | **not audited**: needs an account, and the run was read-only |
| Sign-up (`/cadastrarusuarios`) | Default | yes | yes | yes | yes |
| Sign-up | Validation error (empty submit, API answers 400) | yes | no | no | 1440 only |
| Sign-up | Browser's own validation of a malformed email | yes | no | no | 1440 only |
| Sign-up | Success | no | no | no | **not audited**: it creates a user on a public service, and the run was read-only |

**Read-only.** Every request was a GET except form submits: empty submits on both pages, and one login attempt with an email the API rejects. The API answered every one with 400 ([`raw/manual-checks.json`](raw/manual-checks.json) and [`raw/axe-scan-writes.json`](raw/axe-scan-writes.json), `nonGetRequestsSent`), and both specs fail if any non-GET answer is 2xx. The sign-up form with a malformed email never sent a request: the browser stopped it. No user was created, so there was nothing to delete.

## 2. Automated scan, all four result groups

Raw results per page, state and viewport: [`raw/`](raw/). `passes` and `inapplicable` are kept as rule IDs (with node counts for passes) to keep the files small; `violations` and `incomplete` are kept in full.

| Scan | Violations | Incomplete | Passes (rules) | Inapplicable (rules) |
| ---- | ---------- | ---------- | -------------- | -------------------- |
| login default, 1440 | `color-contrast` (1 node), `image-alt` (1) | none | 11 | 52 |
| login validation error, 1440 | `color-contrast` (3), `image-alt` (1) | `color-contrast` (2), `label-content-name-mismatch` (2) | 20 | 42 |
| sign-up default, 1440 | `color-contrast` (2), `image-alt` (1) | none | 12 | 51 |
| sign-up validation error, 1440 | `color-contrast` (5), `image-alt` (1) | `color-contrast` (3), `label-content-name-mismatch` (3) | 21 | 41 |
| login default, 390 | as login default, 1440 | none | 11 | 52 |
| sign-up default, 390 | as sign-up default, 1440 | none | 12 | 51 |
| login default, 200% zoom | as login default, 1440 | none | 11 | 52 |
| sign-up default, 200% zoom | as sign-up default, 1440 | none | 12 | 51 |

### Violations

Every violation is a finding in section 4: `image-alt` is A11Y-LOGIN-001 and A11Y-SIGNUP-001; `color-contrast` is A11Y-LOGIN-002, A11Y-LOGIN-003, A11Y-SIGNUP-002, A11Y-SIGNUP-003 and A11Y-SIGNUP-009.

### Incomplete: each item has a verdict

| axe rule | Element | Why axe could not decide | Verdict |
| -------- | ------- | ------------------------ | ------- |
| `color-contrast` | The `×` glyph in each error alert (`span[aria-hidden]` inside the close button) | "Element content is too short to determine if it is actual text content" | **Fail, measured by hand.** White (`rgb(255, 255, 255)`) on the alert's `rgb(243, 150, 154)` is 2.17:1; as a control glyph the bar is 3:1 (1.4.11). Finding A11Y-LOGIN-008 and A11Y-SIGNUP-008 |
| `label-content-name-mismatch` | The close button, visible text `×`, `aria-label="Close"` | "Unable to determine if the visible text is part of the accessible name" | **Pass.** The visible label is a multiplication sign used as an icon, not words, so there is no text for the name to mismatch. Observation, not a finding: the name is English on a Portuguese page |

### Passes

Recorded as **automated pass** for the rule, on the nodes it tested, and nowhere as conformant. Rules that passed on at least one scan: `aria-allowed-attr`, `aria-conditional-attr`, `aria-deprecated-role`, `aria-hidden-body`, `aria-hidden-focus`, `aria-prohibited-attr`, `aria-required-attr`, `aria-roles`, `aria-valid-attr`, `aria-valid-attr-value`, `button-name`, `color-contrast` (on the nodes that passed), `document-title`, `duplicate-id-aria`, `form-field-multiple-labels`, `html-has-lang`, `html-lang-valid`, `label`, `meta-viewport`, `nested-interactive`, `target-size`.

`html-has-lang` and `html-lang-valid` passed on a page whose declared language is wrong (A11Y-LOGIN-005): they check that a valid code exists, not that it is the right one.

### Inapplicable: what the pages never exercised

The pages have no frames, video, audio, lists, tables, SVG, image buttons, marquee, or `autocomplete` attributes, so those rules found nothing to test. Two matter here. `link-name` is inapplicable because **the pages contain no link with an `href`**, which is the root of A11Y-LOGIN-004. `bypass` is inapplicable because there is nothing repeated to skip. `autocomplete-valid` is inapplicable because no field declares `autocomplete`. Full lists: `inapplicable` in each file in [`raw/`](raw/).

## 3. Manual checks

Each verdict is mine, after opening the screenshot and reading the measurements in [`raw/manual-checks.json`](raw/manual-checks.json). Only Chromium was used.

| Criterion | Means in the skill | Verdict | Pages and states | Evidence and measurement |
| --------- | ------------------ | ------- | ---------------- | ------------------------ |
| 1.1.1 Non-text Content | Partly | **Fail** (A11Y-LOGIN-001, A11Y-SIGNUP-001) | Both pages, every state | The logo `<img>` has no `alt` attribute (`finding-details.json`). It is the only image |
| 1.4.3 Contrast (Minimum) | Partly | **Fail** (002, 003, 009) | Both pages | Switch text 3.54:1 and administrator label 3.54:1 (`#888888` on white); error text 2.17:1 (white on `rgb(243, 150, 154)`) |
| 1.4.4 Resize Text | Partly | **Pass**, default states only | Login and sign-up default at 200% | No horizontal scroll (`scrollWidth` 720 = `clientWidth` 720 on both); nothing clipped in [login](evidence/A11Y-MAN-1.4.4-login-zoom200.png) and [sign-up](evidence/A11Y-MAN-1.4.4-signup-zoom200.png). Error states at 200% and text-only resize: **not checked** |
| 1.4.11 Non-text Contrast | Manual | **Fail** (006, 007, 008) | Both pages | Field border `rgb(206, 212, 218)` on white is 1.49:1; focus ring on a field 1.19:1, on a button 1.34:1; close glyph 2.17:1 |
| 2.1.1 Keyboard | Manual | **Fail** (004) | Both pages | Tab order on login is email, password, Entrar, then out of the page; on sign-up it is name, email, password, checkbox, Cadastrar, then out. The `Cadastre-se` and `Entrar` switch controls are never reached ([login](evidence/A11Y-MAN-2.1.1-login-tab-past-last-control.png), [sign-up](evidence/A11Y-MAN-2.1.1-signup-tab-past-last-control.png)). Every field and button works from the keyboard: login was filled and submitted with keys only and the API answered; on sign-up the checkbox toggled with `Space` and `Enter` on `Cadastrar` was stopped by the browser's email validation (0 requests). A real sign-up was not completed (read-only) |
| 2.1.2 No Keyboard Trap | Manual | **Pass** | Both pages | Focus leaves the last control on both pages (on login the fourth `Tab` lands on the page body and the fifth on the first field; on sign-up the sixth and seventh). No modal exists, so `Escape` handling was not applicable. Browser chrome was not exercised |
| 2.4.3 Focus Order | Partly | **Pass** for the controls that take focus | Both pages | Order matches the visual order top to bottom. The skipped switch controls are A11Y-LOGIN-004 |
| 2.4.7 Focus Visible | Manual | **Pass**, faint (see 007) | Both pages | [Field](evidence/A11Y-MAN-2.4.7-login-focus-email.png), [button](evidence/A11Y-MAN-2.4.7-login-focus-button.png) and [sign-up field](evidence/A11Y-MAN-2.4.7-signup-focus-name.png) show a ring; the [checkbox](evidence/A11Y-MAN-2.4.7-signup-focus-checkbox.png) shows the browser's default ring. I judged the field ring visible but pale |
| 2.4.11 Focus Not Obscured (Minimum) | Manual | **Not applicable** | Both pages | 0 fixed or sticky elements (the audit overlay is excluded) |
| 2.5.7 Dragging Movements | Manual | **Not applicable** | Both pages | 0 draggable elements |
| 2.5.8 Target Size (Minimum) | Partly | **Pass** | Both pages | Fields 320 x 38, buttons 75 x 38 and 101 x 38, switch controls 121 x 38 and 75 x 38, close buttons 54 x 48. The checkbox is 13 x 13, but its label (224 x 24, the minimum) toggles it, so the function has a control of 24 px. `target-size` passed on 3, 5 and 8 nodes with nothing incomplete |
| 3.1.1 Language of Page | Automated | **Fail** (005) | Both pages | `lang="en"` on content that is Portuguese ([login](evidence/A11Y-LOGIN-005-lang-en-portuguese-text.png), [sign-up](evidence/A11Y-SIGNUP-005-lang-en-portuguese-text.png)). axe passes it |
| 3.2.1 On Focus, 3.2.2 On Input | Manual | **Pass** | Login | Focusing and typing left the URL unchanged. Only the URL was watched; focus and input on sign-up were not checked for other context changes |
| 3.2.6 Consistent Help | Manual | **Not applicable** | Both pages | Neither page offers a help mechanism (read from the page text) |
| 3.3.1 Error Identification, 3.3.3 Error Suggestion | Partly | **Pass** for the text; announcement **not checked** | Both pages, error states | Each error is text naming its field (`Email é obrigatório`), in an element with `role="alert"` ([login](evidence/A11Y-MAN-3.3.1-login-empty-submit-errors.png), [after a keyboard submit](evidence/A11Y-MAN-3.3.1-login-error-after-keyboard-submit.png), [native validation](evidence/A11Y-MAN-3.3.1-signup-native-validation-focus.png)). No field carries `aria-invalid` or `aria-describedby`, and focus stays on the submit button. A screen reader was not used, so whether the alert is announced is not checked. Required-field messages do not say how to fix the field beyond naming it; the email message does (`Email deve ser um email válido`, email must be a valid email) |
| 3.3.7 Redundant Entry | Manual | **Not applicable** | Both pages | Each form is one step and asks nothing twice |
| 3.3.8 Accessible Authentication (Minimum) | Manual | **Pass**, partly checked | Login | Password field is `type="password"`, a synthetic paste event was not prevented, no puzzle or code. A real password manager was not tried |
| 4.1.2 Name, Role, Value | Partly | **Fail** for the switch controls (004); fields and buttons pass | Both pages | `label`, `button-name` and `nested-interactive` passed. The switch controls are `<a type="button">` with no `href`, no `role` and no `tabindex` ([`finding-details.json`](raw/finding-details.json)) |

### The manual checklist in the reference

| Check | Verdict |
| ----- | ------- |
| Tab test | Done, see 2.1.1 and 2.4.7 |
| Modal trap test | **Not applicable**: no modal on either page |
| Colour-blindness simulation | **Not checked** |
| Screen reader (headings, expanded state, live regions) | **Not checked**: no screen reader was run |

### Seen, not in the criteria list, not reported

The fields have placeholders (`Digite seu email`) and no visible `label`. Whether that fails 3.3.2 (Labels or Instructions) is outside the criteria the reference lists, so it is raised as a question for the audit's owner, not counted as a finding.

## 4. Findings

Severity follows the `/qa-defect` scale. With no blocking threshold given, none is marked as blocking. axe's own impact label is quoted where it differs.

| ID | Criterion | Page and state | Element | Observed / expected | User impact | Source | Evidence | Suggested fix | Severity |
| -- | --------- | -------------- | ------- | ------------------- | ----------- | ------ | -------- | ------------- | -------- |
| A11Y-LOGIN-001, A11Y-SIGNUP-001 | 1.1.1 Non-text Content | Both pages, all states | `img.imagem` (the ServeRest logo) | No `alt` attribute; expected a name (`ServeRest`) or `alt=""` if decorative | A screen reader may read the file name or skip the logo; the product name is lost | axe `image-alt` (impact: critical) | [login](evidence/A11Y-LOGIN-001-logo-no-alt.png), [sign-up](evidence/A11Y-SIGNUP-001-logo-no-alt.png) | Add `alt="ServeRest"` | Medium |
| A11Y-LOGIN-002, A11Y-SIGNUP-002 | 1.4.3 Contrast (Minimum) | Both pages, default and error | `small.message` ("Não é cadastrado?" / "Já é cadastrado?") | `#888888` on white, 3.54:1 at 12.8 px; expected 4.5:1 | Low-vision users cannot read the prompt that points to the other page | axe `color-contrast` (impact: serious) | [login](evidence/A11Y-LOGIN-002-switch-text-contrast.png), [sign-up](evidence/A11Y-SIGNUP-002-switch-text-contrast.png) | Use a colour of at least 4.5:1, for example `#767676` | Medium |
| A11Y-SIGNUP-009 | 1.4.3 Contrast (Minimum) | Sign-up, default and error | `label.form-check-label` ("Cadastrar como administrador?") | `#888888` on white, 3.54:1 at 16 px; expected 4.5:1 | The only visible label on the form is hard to read | axe `color-contrast` (impact: serious) | [sign-up](evidence/A11Y-SIGNUP-009-admin-label-contrast.png) | Use a colour of at least 4.5:1 | Medium |
| A11Y-LOGIN-003, A11Y-SIGNUP-003 | 1.4.3 Contrast (Minimum) | Both pages, validation error | `.alert > span` (error text) | White on `rgb(243, 150, 154)`, 2.17:1 at 16 px; expected 4.5:1 | The messages that say what to fix are the hardest text on the page to read | axe `color-contrast` (impact: serious) | [login](evidence/A11Y-LOGIN-003-error-text-contrast.png), [sign-up](evidence/A11Y-SIGNUP-003-error-text-contrast.png) | Darker alert background or dark text, at least 4.5:1 | High |
| A11Y-LOGIN-004, A11Y-SIGNUP-004 | 2.1.1 Keyboard; 4.1.2 Name, Role, Value | Both pages, all states | `a[data-testid="cadastrar"]` on login, `a[data-testid="entrar"]` on sign-up | `<a type="button">` with no `href`: never takes focus, exposes no link or button role; expected to be reachable and operable by keyboard with a role | A keyboard or screen-reader user cannot move between login and sign-up without typing the address | Manual (axe reports nothing: `link-name` is inapplicable) | [login](evidence/A11Y-MAN-2.1.1-login-tab-past-last-control.png), [sign-up](evidence/A11Y-MAN-2.1.1-signup-tab-past-last-control.png) | Use `<a href="/cadastrarusuarios">` and `<a href="/login">`, or a real `<button>` | High |
| A11Y-LOGIN-005, A11Y-SIGNUP-005 | 3.1.1 Language of Page | Both pages, all states | `<html lang="en">` | Content is Portuguese; expected `lang="pt-BR"` | A screen reader reads Portuguese with an English voice | Manual (axe passes `html-has-lang`, `html-lang-valid`) | [login](evidence/A11Y-LOGIN-005-lang-en-portuguese-text.png), [sign-up](evidence/A11Y-SIGNUP-005-lang-en-portuguese-text.png) | Set `lang="pt-BR"` | Medium |
| A11Y-LOGIN-006, A11Y-SIGNUP-006 | 1.4.11 Non-text Contrast | Both pages, all states | `input.form-control` (all fields) | Border `rgb(206, 212, 218)` against white, 1.49:1, and the fill is white too; expected 3:1 for the field boundary | Low-vision users cannot see where a field starts and ends | Manual (measured) | [login](evidence/A11Y-MAN-1.4.11-login-field-border.png), [sign-up](evidence/A11Y-MAN-2.4.7-signup-focus-name.png) | Darker border, at least 3:1 | Medium |
| A11Y-LOGIN-007, A11Y-SIGNUP-007 | 1.4.11 Non-text Contrast | Both pages, focus | Focus ring on fields and buttons | Box-shadow ring is 1.19:1 on a field and 1.34:1 on a button against white; expected 3:1 | Keyboard users have trouble finding the focused control, in bright light or on a poor screen | Manual (measured) | [field](evidence/A11Y-MAN-2.4.7-login-focus-email.png), [button](evidence/A11Y-MAN-2.4.7-login-focus-button.png), [sign-up field](evidence/A11Y-MAN-2.4.7-signup-focus-name.png) | A 2 px outline of at least 3:1 | Medium |
| A11Y-LOGIN-008, A11Y-SIGNUP-008 | 1.4.11 Non-text Contrast | Both pages, validation error | The `×` close glyph in each alert | White on `rgb(243, 150, 154)`, 2.17:1; expected 3:1 | The control that dismisses an error is hard to see | axe `color-contrast` (incomplete, resolved by hand) | [login](evidence/A11Y-LOGIN-003-error-text-contrast.png), [sign-up](evidence/A11Y-SIGNUP-003-error-text-contrast.png) | Same fix as A11Y-LOGIN-003 | Low |

A11Y-LOGIN-006 and A11Y-LOGIN-007 are the same CSS on every field and button, so one screenshot per page stands for all of them.

## 5. What this audit does and does not claim

**Claimed.** On the audited pages and states, listed in section 1, the page does **not** meet WCAG 2.2 AA: nine distinct failures are evidenced above (eight on both pages, plus the administrator label on sign-up). A failure is something one check can show; this is not a score.

**Not claimed.** Nothing here says a page or a criterion is conformant. "axe reported no violations" is a statement only about rules axe ran on the nodes it tested, and axe passed `html-lang-valid` on a page with the wrong language.

| By means | Criteria |
| -------- | -------- |
| Checked by the scanner and by hand | 1.1.1, 1.4.3, 1.4.4, 1.4.11, 2.5.8, 3.1.1, 3.3.1, 4.1.2 |
| Checked by hand only | 2.1.1, 2.1.2, 2.4.3, 2.4.7, 3.2.1, 3.2.2, 3.3.3, 3.3.8 |
| Not applicable (nothing on the pages to test) | 2.4.11, 2.5.7, 3.2.6, 3.3.7 |
| **Not checked at all** | Screen-reader behaviour (including whether the `role="alert"` messages are read), colour-blindness simulation, 200% zoom of the error states, text-only resize, other browsers (only Chromium), a real password manager, the success state of both forms, every page behind login, Tab order inside the browser's own chrome, any criterion outside the reference's list (3.3.2 raised above) |

Dates and values were seen once, on 2026-10-18, against a public service that can change.
