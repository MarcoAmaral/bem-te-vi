# Accessibility Audit: Sign-Up Page

## Critical Issues

### 1. Duplicate Element IDs
**Severity: Critical**
- Both the email and password inputs have `id="email"`
- IDs must be unique in HTML
- This breaks form association, label targeting, and JavaScript functionality
- **Fix**: Change password field to `id="password"`

### 2. Missing Button Semantics
**Severity: Critical**
- "Create account" is a `<div>` with `onclick` handler, not a `<button>` element
- Screen readers will not announce this as a button
- Keyboard users cannot activate it with Enter or Space keys
- No keyboard accessibility for non-mouse users
- **Fix**: Replace with `<button type="submit">Create account</button>`

### 3. Removed Focus Indicators
**Severity: Critical**
- CSS rule `:focus { outline: none; }` removes all focus indicators
- Keyboard users cannot see which element is focused
- Violates WCAG 2.1 Success Criterion 2.4.7 (Focus Visible)
- **Fix**: Remove this CSS rule or replace with visible focus styling

### 4. Missing Image Alt Text
**Severity: Critical**
- Logo image has no `alt` attribute
- Screen reader users cannot understand what the image depicts
- **Fix**: Add `alt="Company logo"` or appropriate descriptive text

## Major Issues

### 5. Unlabeled Form Inputs
**Severity: Major**
- Email input has no associated `<label>` element
- Password input has no associated `<label>` element
- Relying only on placeholders is insufficient; placeholders disappear when users start typing
- Screen reader users won't know what each field is for
- **Fix**: Add explicit labels: `<label for="email">Email</label>` above each input

### 6. Hint Text Not Associated with Field
**Severity: Major**
- Password hint "At least 8 characters" is not programmatically linked to the password field
- Screen reader users won't know this requirement applies to the password field
- **Fix**: Add `aria-describedby="password-hint"` to password input and `id="password-hint"` to the hint element

### 7. Form Lacks Required Attributes
**Severity: Major**
- Email and password inputs have no `required` attribute
- No validation indicators
- No `type="password"` attribute on the password field (this must be corrected due to duplicate ID issue)
- **Fix**: Add `required` attributes and correct input types

### 8. Missing Form Action/Method
**Severity: Major**
- Form element has no `action` or `method` attributes
- Backend submission path is unclear
- Accessibility tools cannot determine form destination
- **Fix**: Add `action="/signup"` and `method="post"` attributes

## Moderate Issues

### 9. Poor Positive Tabindex Usage
**Severity: Moderate**
- "Read the terms" link has `tabindex="3"`
- Positive tabindex values should be avoided; they override natural document order
- Suggests tab order management issues
- **Fix**: Remove positive tabindex values and rely on natural DOM order

### 10. Checkbox Label Accessibility
**Severity: Moderate**
- Checkbox label is acceptable but could be clearer
- Label text "I accept the terms" should link to or reference the terms
- Currently, "Read the terms" link is separate, creating cognitive load
- **Fix**: Link the checkbox label text to the terms, or restructure layout

### 11. Questionable Color Contrast
**Severity: Moderate**
- Hint text (#595959 on #fff) has contrast ratio ~4.5:1
- Meets WCAG AA for normal text (4.5:1 minimum) but at the threshold
- May be difficult for users with color vision deficiency
- **Fix**: Use darker gray (#404040 or darker) for better contrast

## Summary

**Total Issues: 11**
- Critical: 4
- Major: 5  
- Moderate: 3

**WCAG Compliance: Fails Level A**

The page requires significant remediation before it can be considered accessible. Critical issues with button semantics, keyboard navigation, focus indicators, and form labeling make this unusable for keyboard and screen reader users. Recommend addressing all critical and major issues before launch.
