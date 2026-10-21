# Security QA Rules & Guidelines

> **OWASP Top 10 Client-Side Compliance** | Penetration Auditing | Input Validation | Safe Payload Standards

This ruleset governs security-related QA processes, verification checkpoints, automated vulnerability checks, and security-focused regression test designs. AI agents and QA engineers must apply these rules to identify security vulnerabilities before code is promoted.

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

- **Token Storage**: JWTs, OAuth tokens, and session identifiers must be stored in secure, `HttpOnly`, `SameSite=Strict`, `Secure` cookies. Avoid storing them in `localStorage` or `sessionStorage` where they are vulnerable to XSS.
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

### 1. Static Security Analysis (npm audit & Semgrep)

Configure the pre-flight CI stage to catch vulnerable third-party dependencies:

```bash
# Fail build if any high or critical vulnerability is found
npm audit --audit-level=high
```

### 2. Playwright Security Payload Audits

To automate XSS detection, we write end-to-end payload tests to check if inputs are correctly sanitized:

```typescript
import { test, expect } from "@playwright/test";

test.describe("Sanitization & Security Playloads", () => {
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
      await page.goto("/profile/edit");

      // Fill input field with payload
      await page.fill("input#display-name", payload);
      await page.click("button#save-profile");

      // Navigate to viewing profile or reload to check rendering
      await page.reload();

      // Assert that alert did not fire (browser alert handler)
      page.on("dialog", (dialog) => {
        if (dialog.type() === "beforeunload" || dialog.type() === "confirm")
          return;
        throw new Error(
          `Security Violation: Alert popped up with payload: ${payload}`,
        );
      });

      // Assert that the raw script tag is NOT rendered in the DOM
      const renderedScript = page.locator("main script");
      await expect(renderedScript).toHaveCount(0);

      // Ensure it is safely rendered as escaped text or clean string
      const nameElement = page.locator("#profile-name-display");
      await expect(nameElement).not.toHaveHTML(payload);
    });
  }
});
```

---

## 🔍 Security Audit Checklist (Manual & Penetration)

AI agents drafting manual security test plans must prioritize these test cases:

1.  **Form Input Fuzzing**: Input special characters (`'`, `"`, `<>`, `\`, `--`, `OR 1=1`) in every form. Confirm the application throws clean, handled visual validation errors, and never unhandled stack traces.
2.  **Inspect Token Cookies**: Open browser dev tools -> Application -> Cookies. Confirm that session cookies have:
    - `HttpOnly` checked (prevents access via `document.cookie`).
    - `Secure` checked (prevents transmission over unencrypted HTTP).
    - `SameSite` set to `Strict` or `Lax`.
3.  **Role Escalation Verification**:
    - Log in as a standard User, capture an administrative API request (e.g. `POST /api/admin/settings`).
    - Re-send this request using the standard User's session token.
    - Assert that the server rejects the action with a `403 Forbidden` response.
4.  **HSTS & Header Audit**: Check response headers on key requests. Verify headers exist:
    - `Strict-Transport-Security`
    - `Content-Security-Policy` (CSP)
    - `X-Content-Type-Options: nosniff`
    - `X-Frame-Options: DENY` or `SAMEORIGIN`
