---
id: ref-playwright-patterns
---
# Playwright Patterns Reference

> **Read on demand** | Moved out of `/qa-automate` | Part of the `qa-reference` skill

Read this when scaffolding Playwright end-to-end tests: the project tree and what each folder is for, `playwright.config.ts`, the auth fixture, Page Objects, the E2E spec, the commands that run Playwright and the `data-testid` guide.

---

## Project Structure

### 2. Playwright (E2E & System Integration)

E2E testing is an independent layer and should have its own dedicated root architecture for scalability, reusability, and maintainability.

```text
my-app/
├── playwright/                 # Playwright framework root
│   ├── tests/                  # All spec files (.spec.ts)
│   │   ├── auth/               # Authentication tests
│   │   ├── regression/         # Regression tests
│   │   ├── smoke/              # Quick smoke tests
│   │   ├── sanity/             # In-depth sanity tests
│   │   └── checkout/           # Tests organized by feature
│   ├── pages/                  # Page Object Model classes
│   ├── locators/               # Centralized selectors
│   ├── fixtures/               # Injected setup and context data
│   ├── utils/                  # Helper functions (helpers, E2E formatters)
│   ├── config/                 # Environment configuration (STG, PROD)
│   ├── test-data/              # External test data (JSON, CSV)
│   └── test-reports/           # Central directory for reports and artifacts
│       └── artifacts/          # Screenshots, videos and trace files
├── playwright.config.ts
├── package.json
└── README.md
```

*(Add to `.gitignore`: `playwright-report/`, `test-results/`, `playwright/test-reports/` and `playwright/tests/auth/.auth/`, which holds the authenticated session)*

#### Purpose of the Directories (Playwright)

- **`locators/`**: Keeps selector definitions separate from page actions (Page Object).
- **`utils/`**: Common helper functions, date formatting, string generators.
- **`config/`**: Environment-specific configuration (STG, UAT, PROD).
- **`test-data/`**: Static data that feeds data-driven tests (Data-Driven Testing).
- **`test-reports/`**: Collects failure artifacts (screenshots, videos, traces) so they do not clutter the repository root.

---

## Playwright — E2E Tests

### playwright.config.ts

```typescript
import { defineConfig, devices } from "@playwright/test";
import dotenv from "dotenv";
dotenv.config();

export default defineConfig({
  testDir: "./playwright/tests",
  outputDir: "./playwright/test-reports/artifacts",
  timeout: 60_000,
  retries: process.env.CI ? 1 : 0,
  workers: process.env.CI ? 2 : 1,
  reporter: [
    ["html", { open: "on-failure", outputFolder: "playwright-report" }],
    ["junit", { outputFile: "test-results/e2e-junit.xml" }],
    ["list"],
  ],
  use: {
    baseURL: process.env.BASE_URL || "http://localhost:3000/",
    screenshot: "only-on-failure",
    video: "retain-on-failure",
    trace: "on-first-retry",
  },
  projects: [
    // Auth setup — runs before all E2E tests
    { name: "setup", testMatch: /.*\.setup\.ts/ },

    // E2E projects — depend on setup
    {
      name: "chromium",
      use: {
        ...devices["Desktop Chrome"],
        storageState: "playwright/tests/auth/.auth/user.json",
      },
      dependencies: ["setup"],
    },
    {
      name: "firefox",
      use: {
        ...devices["Desktop Firefox"],
        storageState: "playwright/tests/auth/.auth/user.json",
      },
      grep: /@smoke/, // Only smoke on Firefox
      dependencies: ["setup"],
    },
    {
      name: "webkit",
      use: {
        ...devices["Desktop Safari"],
        storageState: "playwright/tests/auth/.auth/user.json",
      },
      grep: /@smoke/,
      dependencies: ["setup"],
    },
  ],
});
```

### Auth Setup Fixture

```typescript
// playwright/tests/auth/auth.setup.ts (inside testDir, so the setup project finds it)
import { test as setup } from "@playwright/test";

const AUTH_FILE = "playwright/tests/auth/.auth/user.json";

setup("authenticate", async ({ page }) => {
  await page.goto("/login");

  await page.getByTestId("login-email").fill(process.env.TEST_USER!);
  await page.getByTestId("login-password").fill(process.env.TEST_PASS!);
  await page.getByTestId("login-submit").click();

  // Wait for app to load authenticated state
  await page.waitForSelector('[data-testid="user-profile-badge"]', {
    timeout: 30_000,
  });

  // Save auth state
  await page.context().storageState({ path: AUTH_FILE });
});
```

### Page Object Model — BasePage

```typescript
// playwright/pages/BasePage.ts
import { Page, Locator } from "@playwright/test";

export abstract class BasePage {
  constructor(protected readonly page: Page) {}

  protected getByTestId(testId: string): Locator {
    return this.page.getByTestId(testId);
  }

  async waitForVisible(locator: Locator, timeout = 10_000): Promise<void> {
    await locator.waitFor({ state: "visible", timeout });
  }

  async isVisible(locator: Locator): Promise<boolean> {
    return locator.isVisible();
  }
}
```

### Page Object — Feature Page

```typescript
// playwright/pages/CheckoutPage.ts
import { Page, Locator } from "@playwright/test";
import { BasePage } from "./BasePage";

export class CheckoutPage extends BasePage {
  readonly shippingAddress: Locator;
  readonly cardNumber: Locator;
  readonly placeOrderBtn: Locator;
  readonly orderSuccessMsg: Locator;

  constructor(page: Page) {
    super(page);
    this.shippingAddress = this.getByTestId("checkout-address-input");
    this.cardNumber = this.getByTestId("checkout-card-input");
    this.placeOrderBtn = this.getByTestId("checkout-place-order-btn");
    this.orderSuccessMsg = this.getByTestId("checkout-success-msg");
  }

  async fillShipping(address: string): Promise<void> {
    await this.shippingAddress.fill(address);
  }

  async submitOrder(): Promise<void> {
    await this.placeOrderBtn.click();
  }
}
```

### E2E Test Spec

```typescript
// playwright/tests/checkout/checkout.spec.ts
import { test, expect } from "@playwright/test";
import { CheckoutPage } from "../../pages/CheckoutPage";

test.describe("Checkout Flow @checkout", () => {
  test.beforeEach(async ({ page }) => {
    // Assuming auth setup already ran, user has items in cart
    await page.goto("/checkout");
  });

  // TC-CHK-001
  test("prevents order submission with empty shipping address @smoke @p0 @e2e", async ({
    page,
  }) => {
    const checkout = new CheckoutPage(page);
    await checkout.submitOrder();

    await expect(page.getByTestId("address-error")).toBeVisible();
    await expect(page.getByTestId("address-error")).toContainText(
      /Address is required/i,
    );
  });

  // TC-CHK-002
  test("successful order routes to confirmation page @smoke @p0 @e2e", async ({
    page,
  }) => {
    const checkout = new CheckoutPage(page);
    await checkout.fillShipping("123 Main St, NY");

    // Payment mocking/filling would happen here
    await checkout.submitOrder();

    await expect(checkout.orderSuccessMsg).toBeVisible({ timeout: 15_000 });
    await expect(page).toHaveURL(/\/order-confirmation/);
  });

  // TC-CHK-010: Chaos Testing (Unhappy Path)
  test("handles 500 payment gateway error gracefully @regression @p1 @e2e", async ({
    page,
  }) => {
    const checkout = new CheckoutPage(page);
    await checkout.fillShipping("123 Main St, NY");

    // Mock a 500 error on the payment processing endpoint
    await page.route("**/api/payments/process", (route) => {
      route.fulfill({ status: 500, body: "Gateway Timeout" });
    });

    await checkout.submitOrder();

    // Assert that the app handles the crash without a white screen
    await expect(page.getByTestId("global-error-toast")).toBeVisible();
    await expect(page.getByTestId("global-error-toast")).toContainText(
      /Payment failed/i,
    );
  });
});
```

---

## Running Playwright

```bash
# Install
npx playwright install --with-deps

# Run all tests
npx playwright test

# Run by tag
npx playwright test --grep @smoke
npx playwright test --grep @p0
npx playwright test --grep "(?=.*@smoke)(?=.*@p0)"   # AND (intersection)
npx playwright test --grep "@smoke|@sanity"           # OR (union)
npx playwright test --grep @regression --grep-invert @slow

# Run specific file
npx playwright test playwright/tests/checkout/checkout.spec.ts

# UI mode (interactive)
npx playwright test --ui

# Debug mode
npx playwright test --debug

# View last report
npx playwright show-report
```

---

## data-testid Guide

Every UI element being asserted in automation needs a `data-testid`.

<!-- ts-check: skip (a JSX attribute beside two Playwright expressions, not one file) -->

```typescript
// React — add to JSX elements:
<div data-testid="sign-in-overlay" className="overlay">

// Playwright — access with:
page.getByTestId('sign-in-overlay')
// Equivalent to:
page.locator('[data-testid="sign-in-overlay"]')
```

**Naming convention:** `[component]-[element]-[modifier]`

- `sign-in-overlay`
- `sign-in-email-input`
- `sign-in-submit`
- `topbar-user-profile-btn`
- `validation-error-panel`

Locator choice follows the `code-style-qa` rule: roles first, then test IDs, then labels and text; never structural CSS or XPath.
