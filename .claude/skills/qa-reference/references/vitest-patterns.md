---
id: ref-vitest-patterns
---
# Vitest Patterns Reference

> **Read on demand** | Moved out of `/qa-automate` | Part of the `qa-reference` skill

Read this when scaffolding Vitest unit or integration tests: the project tree, `vitest.config.ts`, the setup file, the unit test pattern, mocking an external SDK, `localStorage` testing and the commands that run them.

---

## Project Structure

### 1. Vitest (Unit & Component Integration)

Unit tests should live as close to the source code as possible.

```text
my-app/
├── src/                        # Application source code
│   ├── components/
│   │   ├── Button.tsx
│   │   └── Button.test.tsx     # Vitest unit test
│   └── utils/
│       ├── format.ts
│       └── format.test.ts      # Vitest unit test
├── tests/setup.ts              # Global test setup (JSDOM/Happy-DOM)
└── vitest.config.ts
```

---

## Vitest — Unit Tests

Vitest is the tool for fast unit and integration tests on `src/**/*.test.ts` files. Combined with **React Testing Library (RTL)** and its **mocking** system, it checks business logic and component rendering at high execution speed.

### Setup

```bash
pnpm add -D vitest @vitest/coverage-v8 @testing-library/react @testing-library/jest-dom jsdom
```

### vitest.config.ts

```typescript
import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";
import path from "path";

export default defineConfig({
  plugins: [react()],
  resolve: { alias: { "@": path.resolve(__dirname, "src") } },
  test: {
    globals: true,
    environment: "jsdom",
    setupFiles: ["./tests/setup.ts"],
    include: ["src/**/*.test.ts", "src/**/*.test.tsx"],
    coverage: {
      provider: "v8",
      reporter: ["text", "html", "lcov"],
      include: ["src/**"],
      thresholds: { lines: 70, branches: 60, functions: 70 },
    },
  },
});
```

### tests/setup.ts

```typescript
import "@testing-library/jest-dom";
```

### Unit Test Pattern

<!-- ts-check: skip (template: ./fileName stands for the module under test) -->

```typescript
/**
 * Unit tests — [FileName].ts
 * Tags: @unit @p1 @[feature]
 * ISTQB: [Techniques used]
 */
import { describe, it, expect, beforeEach, vi } from "vitest";
import { functionUnderTest } from "./fileName";

describe("functionName @unit @[feature]", () => {
  beforeEach(() => {
    localStorage.clear(); // isolation
    vi.clearAllMocks();
  });

  it("TEST-001: [what it does] @p1", () => {
    // Arrange
    const input = "test-value";
    // Act
    const result = functionUnderTest(input);
    // Assert
    expect(result).toBe("expected-value");
  });

  it("TEST-002: returns default when input is empty @p2", () => {
    expect(functionUnderTest("")).toBe("");
  });
});
```

### Mocking an External SDK (MUST be before imports)

<!-- ts-check: skip (fragment: the top of a test file, with vi as a Vitest global and the module under test not shown) -->

```typescript
// vi.mock() is hoisted above every other statement, so a value its factory uses must come
// from vi.hoisted() — a plain const would still be in its temporal dead zone. Do not move
// vi.mock() inside describe/it.
const { mockPaymentClient } = vi.hoisted(() => ({ mockPaymentClient: vi.fn() }));
vi.mock("@my-company/payment-sdk/client", () => ({ default: mockPaymentClient }));

vi.mock("@my-company/payment-sdk/types", () => ({
  default: { Currency: { isFiat: true, toJSON: () => ({ code: "USD" }) } },
}));

// Then import:
import { evaluateValidation } from "./validationUtils";
```

### localStorage Testing Pattern

<!-- ts-check: skip (fragment: Vitest globals, and saveCartTotal and loadCartTotal are the code under test, not shown) -->

```typescript
describe("cartStorage @unit @cart", () => {
  beforeEach(() => localStorage.clear());

  it("saves and loads cart total", () => {
    saveCartTotal("guest_user", 300);
    expect(loadCartTotal("guest_user", 0)).toBe(300);
  });

  it("returns default when nothing stored", () => {
    expect(loadCartTotal("guest_user", 0)).toBe(0);
  });

  it("returns default when value is corrupted", () => {
    localStorage.setItem("cart-total-guest_user", "not-a-number");
    expect(loadCartTotal("guest_user", 0)).toBe(0);
  });
});
```

### Running Vitest

```bash
pnpm test                   # Run all tests once
pnpm test:watch             # Watch mode
pnpm test:unit              # Unit tests only (verbose)
pnpm test:coverage          # With coverage report

# Filter by tag or name:
npx vitest run --testNamePattern="@smoke"
npx vitest run --testNamePattern="@validation"
npx vitest run src/utils/cartUtils.test.ts
```
