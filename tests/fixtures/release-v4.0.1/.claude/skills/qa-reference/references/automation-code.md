# Automation Code Reference

> **Read on demand** | Moved from `.claude/rules/code-style-qa.md` | Part of the `qa-reference` skill

Read this when writing or reviewing test automation code, and before committing, pushing or claiming that a spec passes or a bug is fixed. The always-on core (locator order and anti-patterns) stays in `.claude/rules/code-style-qa.md`.

---

## 🏗️ Architectural Patterns

### 1. The Arrange-Act-Assert (AAA) Pattern

Every single test must be divided into three clear, logical sections:

- **Arrange**: Set up the environment, database, mocks, preconditions, and page states.
- **Act**: Execute the core action under test (clicking buttons, filling forms, calling APIs).
- **Assert**: Verify the expected outcome using explicit, robust assertions.

### 2. Page Object Model (POM) Structure

For all browser-based End-to-End (`@e2e`) tests, keep locators and page actions out of the test file.

- **Encapsulation**: Encapsulate selectors and interactive page actions (fill, click, submit) in class methods inside page objects.
- **Fluent API**: Methods that transition the user to a new page should return an instance of that new Page Object.
- **No Assertions in Page Objects**: Page objects should expose selectors and actions, never assertions (assertions belong exclusively in the test files).

---

## 🧪 Assertion Standards & Examples

### Playwright E2E Assertions

Always use web-first, auto-retrying assertions:

```typescript
// Good: Playwright will retry until the element satisfies the condition (up to timeout)
await expect(page.getByTestId("success-alert")).toBeVisible();
await expect(page.getByRole("button", { name: "Save" })).toBeDisabled();

// Bad: Non-retrying assertions (prone to race conditions and flakiness)
const isVisible = await page.getByTestId("success-alert").isVisible();
expect(isVisible).toBe(true);
```

### Vitest Unit & Integration Assertions

```typescript
// AAA Structure
it("should calculate order total with tax @smoke @unit", () => {
  // Arrange
  const cart = [{ id: 1, price: 100, qty: 2 }];
  const taxRate = 0.05;

  // Act
  const total = calculateTotal(cart, taxRate);

  // Assert
  expect(total).toBe(210);
});
```

---

## 🌿 Git & Version Control Standards

### Atomic Commits

AI Assistants and Developers must adhere to the **Atomic Commit** philosophy when generating Git commits. An atomic commit represents a single, indivisible logical change.

1. **One Concept Per Commit**: Never mix a feature addition with a bug fix, or a test refactor with a new locator addition.
2. **No "Loads of Diffs"**: Massive, multi-concern commits are strictly forbidden. Split changes into multiple smaller, focused commits.
3. **Commit Message Format**: Follow **Conventional Commits** (`feat:`, `fix:`, `test:`, `refactor:`).
4. **The "AND" Rule**: If you have to use the word "and" in the commit message (e.g., `test: added e2e auth AND fixed linting`), the commit is too large and must be split.
5. **Always Pass Tests**: Every atomic commit must leave the system in a working state.

### Pre-Push Verification (Evidence Before Claims)

Before pushing to the automation repo — or to a product repo, for a `data-testid` change — and
before saying a spec "passes" or a bug "is fixed", run the actual command and read its output. A
claim made without fresh command output is a guess, not a result.

| Claim | Requires | Not Sufficient |
| ------- | ---------- | ---------------- |
| Spec passes | This run's test output, 0 failures | "Should pass now," a previous run |
| Bug fixed | The regression spec fails on unfixed code, then passes after the fix | Spec passes once, fix "looks right" |
| Linter/format clean | This run's linter output, 0 errors | Assuming it's fine because the diff is small |

### Red-Green Proof for Regression Specs

Every regression spec written for a specific defect must be proven to catch the bug it is named
for: run it against the pre-fix behavior and confirm it fails for the expected reason, then confirm
it passes once the fix is present. If the fix is already deployed and the pre-fix state cannot be
reproduced, say so explicitly in the PR or commit description instead of skipping the step
silently.

### Isolate Parallel Ticket Work

When more than one ticket's automation is in flight at once, keep each on its own branch (or git
worktree) so unrelated defect specs never land in the same diff — this is what makes the Atomic
Commit and "AND" rules above actually enforceable.
