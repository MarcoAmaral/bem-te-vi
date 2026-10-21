---
id: ref-automation-ci
---
# Automation in CI Reference

> **Read on demand** | Moved out of `/qa-automate` | Part of the `qa-reference` skill

Read this when hunting a flaky test, adding automated tests to a pipeline, or writing console output and reporters for a test run.

---

## 🕵️ Flakiness Hunting

Flaky tests are the enemy of CI/CD. When debugging a non-deterministic test, follow these steps:

1. **Use the Trace Viewer**: `npx playwright show-trace trace.zip` is your best tool. Do not rely on screenshots alone.
2. **Remove all `waitForTimeout`**: Explicit sleeps cause flakiness. Replace them with explicit state assertions (`await expect(locator).toBeVisible()`).
3. **Wait for Network State**: If clicking a button triggers a network request, wait for the response, not just the UI change:

   <!-- ts-check: skip (fragment: page is the test's fixture) -->

   ```typescript
   const [response] = await Promise.all([
     page.waitForResponse("**/api/data"),
     page.getByRole("button", { name: "Submit" }).click(),
   ]);
   ```

4. **Stress Test the Flake**: Run the single test 100 times locally to reproduce the race condition:

   ```bash
   npx playwright test --repeat-each=100 playwright/tests/checkout/checkout.spec.ts
   ```

---

## GitLab CI/CD Pipeline

```yaml
stages:
  - test:unit
  - test:smoke
  - test:regression

test:unit:
  stage: test:unit
  script:
    - pnpm install --frozen-lockfile
    - npx vitest run --reporter=junit --outputFile=test-results/unit-junit.xml
  artifacts:
    when: always
    reports:
      junit: test-results/unit-junit.xml
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: "$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH"

test:smoke:
  stage: test:smoke
  script:
    - pnpm install --frozen-lockfile
    - npx playwright install --with-deps chromium
    - npx playwright test --grep @smoke
  artifacts:
    when: always
    reports:
      junit: test-results/e2e-junit.xml
    paths: [test-results/, playwright-report/, playwright/test-reports/artifacts/]
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'

test:regression:
  stage: test:regression
  script:
    - pnpm install --frozen-lockfile
    - npx playwright install --with-deps
    - npx playwright test --grep @regression
  artifacts:
    when: always
    paths: [test-results/, playwright-report/, playwright/test-reports/artifacts/]
  rules:
    - if: '$CI_PIPELINE_SOURCE == "schedule"'
  allow_failure: true # Regression failures don't block nightly pipeline
```

A failing `@p0`/`@p1` test must still block the release (see the release gate in the `testing-guidelines` rule); the nightly job only reports.

---

## Terminal Logging & Custom Reporters

When generating custom console logs, terminal progress output, or custom Playwright reporters, **NEVER use hardcoded ANSI escape codes** (e.g., `\x1b[31m`), as they may appear broken in different terminals or CI/CD environments.
Instead, explicitly enforce the use of specialized styling libraries such as **`picocolors`**, **`termcn`**, or **`chalk`** to handle terminal styling safely.
