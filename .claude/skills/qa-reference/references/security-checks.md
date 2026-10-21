---
id: ref-security-checks
---
# Security Checks Reference

> **Read on demand** | Detail behind the `security-qa` rule | Part of the `qa-reference` skill

Read this when writing a security test, an XSS payload spec, a dependency scan step or a manual security test plan. The always-on must-list is the `security-qa` rule.

---

## 🔒 OWASP Top 10 Core Client-Side Verification

All applications must be verified against these key security parameters:

### 1. Injection (SQLi, XSS, Command Injection)

- **Cross-Site Scripting (XSS)**:
  - Any data rendered in the DOM must be securely escaped or sanitized (e.g., using DOMPurify).
  - Avoid using `dangerouslySetInnerHTML` in React or `v-html` in Vue without explicit sanitization libraries.
  - Never concatenate raw user input into inline `<script>` tags, event handlers, or database queries.
- **SQL Injection (SQLi)**: Ensure all API endpoints and databases use prepared statements/parameterized queries.

### 2. Broken Authentication & Session Management

- **Token Storage**: JWTs, OAuth tokens, and session identifiers must be stored in secure, `HttpOnly`, `SameSite=Strict`, `Secure` cookies (`Lax` only with a recorded reason). Avoid storing them in `localStorage` or `sessionStorage` where they are vulnerable to XSS.
- **Logout Purge**: Ensure logging out completely invalidates the session token on the backend and deletes cookies client-side.

### 3. Sensitive Data Exposure

- **Transit Security**: All payloads must travel strictly over `HTTPS`. Ensure that `HTTP Strict-Transport-Security (HSTS)` headers are configured.
- **Console & Log Leaks**: Ensure no passwords, credit card numbers, auth tokens, or raw JSON stack traces are printed to `console.log` or client-side telemetry trackers in Production builds.

### 4. Broken Object Level Authorization (BOLA)

- **Direct Reference Scopes**: Test accessing data using modified resource IDs in API paths.
  - _Example test case_: Logged in as User A (`id=101`), send a request to `GET /api/user/102/profile`. If the system returns User B's profile without validating ownership, log a high-severity BOLA defect.

### 5. CSRF (Cross-Site Request Forgery)

- **State-Changing Requests**: Ensure all state-changing API requests (`POST`, `PUT`, `DELETE`, `PATCH`) carry an anti-CSRF token or verify `SameSite` cookie restrictions.

---

## 🛠️ Automated Security Scanning & Verification

During regression sweeps, QA pipelines must integrate basic automated scans:

### 1. Dependency Audit (npm audit)

Configure the pre-flight CI stage to catch vulnerable third-party dependencies:

```bash
# Fail build if any high or critical vulnerability is found
npm audit --audit-level=high
```

### 2. Playwright Security Payload Audits

To automate XSS detection, we write end-to-end payload tests to check if inputs are correctly sanitized:

```typescript
import { test, expect } from "@playwright/test";

test.describe("Sanitization & Security Payloads", () => {
  // Test typical XSS payloads in input fields
  const xssPayloads = [
    '<script>alert("XSS")</script>',
    '<img src=x onerror=alert("XSS")>',
    'javascript:alert("XSS")',
    '"><script>alert(1)</script>',
  ];

  for (const payload of xssPayloads) {
    test(`Should securely sanitize input for payload: ${payload}`, async ({
      page,
    }) => {
      // Collect dialogs from the start: Playwright auto-dismisses one that has no listener
      const dialogs: string[] = [];
      page.on("dialog", async (dialog) => {
        dialogs.push(`${dialog.type()}: ${dialog.message()}`);
        await dialog.dismiss();
      });

      await page.goto("/profile/edit");
      await page.getByLabel("Display name").fill(payload);
      await page.getByRole("button", { name: "Save" }).click();

      // Reload to check how the stored value renders
      await page.reload();

      // Assert that no alert, confirm or prompt fired
      expect(dialogs).toEqual([]);

      // Assert that the raw script tag is NOT rendered in the DOM
      await expect(page.locator("main script")).toHaveCount(0);

      // Assert that the payload is rendered as text, not as markup
      await expect(page.getByTestId("profile-name-display")).toHaveText(payload);
    });
  }
});
```

---

## 🔍 Security Audit Checklist (Manual & Penetration)

AI agents drafting manual security test plans must prioritize these test cases:

1. **Form Input Fuzzing**: Input special characters (`'`, `"`, `<>`, `\`, `--`, `OR 1=1`) in every form. Confirm the application throws clean, handled visual validation errors, and never unhandled stack traces.
2. **Inspect Token Cookies**: Open browser dev tools -> Application -> Cookies. Confirm that session cookies have:
    - `HttpOnly` checked (prevents access via `document.cookie`).
    - `Secure` checked (prevents transmission over unencrypted HTTP).
    - `SameSite` set to `Strict` (`Lax` only with a recorded reason).
3. **Role Escalation Verification**:
    - Log in as a standard User, capture an administrative API request (e.g. `POST /api/admin/settings`).
    - Re-send this request using the standard User's session token.
    - Assert that the server rejects the action with a `403 Forbidden` response.
4. **HSTS & Header Audit**: Check response headers on key requests. Verify headers exist:
    - `Strict-Transport-Security`
    - `Content-Security-Policy` (CSP)
    - `X-Content-Type-Options: nosniff`
    - `X-Frame-Options: DENY` or `SAMEORIGIN`
