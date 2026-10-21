# Sign-Up Page Accessibility Audit

## Critical Issues

### 1. Missing Form Labels
The email and password inputs lack associated `<label>` elements. Placeholders alone are insufficient—they disappear on focus and aren't read reliably by screen readers.

**Fix:** Add labels above or adjacent to each input:
```html
<label for="email">Email</label>
<input type="email" placeholder="Email" id="email">
```

### 2. Duplicate ID Attribute
Both email and password inputs have `id="email"`. IDs must be unique. The password field needs `id="password"`.

### 3. Non-Semantic Button Element
The "Create account" action uses a `<div>` with `onclick` instead of a `<button>`. This breaks:
- Keyboard accessibility (cannot tab to it or activate with Enter/Space)
- Screen reader announcement (not identified as a button)
- Fallback without JavaScript

**Fix:** Use a semantic `<button>` element:
```html
<button type="submit" class="btn">Create account</button>
```

### 4. Focus Outline Removed Without Replacement
The CSS rule `:focus { outline: none; }` removes the default focus indicator without providing an alternative. This makes keyboard navigation invisible to sighted users and violates WCAG 2.4.7 (Focus Visible).

**Fix:** Add a visible focus style:
```css
:focus { outline: 2px solid #0a58ca; outline-offset: 2px; }
```

## Major Issues

### 5. Missing Image Alt Text
The logo image lacks an `alt` attribute. Screen readers cannot describe it. Assuming it's decorative or serves as a branding element:
```html
<img src="/img/logo-2024-final.png" alt="Company logo">
```

### 6. Disconnected Hint Text
The "At least 8 characters" hint is a standalone paragraph, not associated with the password field. Use `aria-describedby`:
```html
<input type="password" placeholder="Password" id="password" aria-describedby="pwd-hint">
<p class="hint" id="pwd-hint">At least 8 characters.</p>
```

### 7. Problematic Tab Index
The link has `tabindex="3"`, creating a hard-coded tab order that breaks natural sequencing. Either remove it or restructure the form's tabindex coherently.

### 8. Insufficient Color Contrast (Minor)
The hint text (#595959 on white) has ~4.5:1 contrast. While this meets WCAG AA for normal text, it's at the threshold. Consider #454545 or darker for improved readability.

## Summary Table

| Issue | Level | WCAG Criterion |
|-------|-------|---|
| Missing labels | Critical | 1.3.1 Info and Relationships |
| Duplicate ID | Critical | N/A (HTML spec violation) |
| Non-button button | Critical | 4.1.2 Name, Role, Value |
| No focus indicator | Critical | 2.4.7 Focus Visible |
| Missing alt text | Major | 1.1.1 Non-text Content |
| Disconnected hint | Major | 1.3.1 Info and Relationships |
| Hard-coded tabindex | Major | 2.4.3 Focus Order |

**Assumption:** The password field's placeholder "Password" is a labeling error (not copy-paste of "Email"), and the actual intended placeholder is "Password".
