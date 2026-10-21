---
id: ref-automation-code
---
# Automation Code Reference

> **Read on demand** | Detail behind the `code-style-qa` rule | Part of the `qa-reference` skill

Read this when writing or reviewing test automation code, and before committing, pushing or claiming that a spec passes or a bug is fixed. The always-on core (locator order and anti-patterns) is the `code-style-qa` rule.

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

## FIRST: What Each Letter Requires

FIRST names five properties a good unit test has (Valente, *Engenharia de Software Moderna*,
section 8.3). Treat each as a check on every test you write or review: a test that fails one is a
finding, not a matter of taste. The same checks apply, with longer time limits, to integration
and end-to-end tests.

| Property | What it requires | Check |
| :------- | :--------------- | :---- |
| **Fast** | The test is quick enough to run on every change | A unit test finishes in milliseconds (the `@unit` target in the `testing-guidelines` rule is under 100 ms). A test that cannot be made fast goes into a separately scheduled group (`@slow`, run with `@regression` rather than `@smoke`), so the suite people run all day stays fast. |
| **Independent** | The result does not depend on which tests ran before it or beside it | It passes alone, first, last and in parallel with the rest. It shares no state with other tests through module-level variables, `localStorage`, files or database rows. This is the rule's "Independent Test Isolation". |
| **Repeatable** | The same code gives the same result on every run | Nothing in it depends on the real clock, timers, random values, a live network or thread timing unless the test controls that input (fake timers, a fixed seed, a stubbed response). A fixed sleep is one of these causes, and the `code-style-qa` rule bans it. A test that passes and fails on the same code is flaky: tag it and follow the rule's quarantine protocol, and find the cause with the `qa-reference` skill's `references/automation-ci.md` ("Flakiness Hunting"). |
| **Self-checking** | The test decides pass or fail by itself | The verdict comes from its assertions, never from a person reading console output, a log or a screenshot. A test with no assertion, or with an assertion that cannot fail, checks nothing. |
| **Timely** | The test is written with the code, not long after it | Write it before the code (`/qa-tdd`) or in the same change. Code written without its tests is often hard to test afterwards; the `qa-engineer` agent's Testability gate lists the fixes. |

## Test Smells

A test smell is a sign that a test may be hard to read, to trust or to keep up to date: the idea
of a code smell applied to test code (Valente, *Engenharia de Software Moderna*, section 8.3; code smells
in general, section 9.5). A smell is a prompt to look again and ask whether a shorter, straight-line test
would do, not a ban. Two smells are already rules in `code-style-qa`, and there the rule decides:
"No Conditional Assertions" and "No Hardcoded Sleeps".

- **A long test that is hard to follow.** A reader cannot tell in a few seconds which behaviour
  it checks, usually because it checks several, or because its setup hides the one input that
  matters. Split it by behaviour, and move incidental setup into a named builder or fixture.
- **Logic in the test body.** An `if`, `switch` or loop means some lines run on some paths and not
  others, so the reader has to work out which path ran. Write one test per path, and replace a
  loop over inputs with `it.each`, which reports each input as its own case.
- **Duplicated test code.** The same arrange block copied into many tests drifts apart as copies
  are fixed one at a time. Extract it into a helper, a fixture or `beforeEach`, and keep the values
  that matter to each test visible in that test.

**How many assertions per test.** One test checks one behaviour. Several assertions are fine when
they examine one result, such as the fields of one returned object. A test that can fail for two
unrelated reasons should be two tests, so the failing test's name says what broke.

**Test code is refactored like production code.** When a smell is worth fixing, fix it in its own
commit, with the suite green before and after.

<!-- ts-check: skip (shows test structure: applyDiscount is the code under test, not shown) -->

```typescript
// Before: two behaviours, a loop and a branch in one test
it("applies discount codes", () => {
  for (const code of ["SAVE10", "EXPIRED5"]) {
    const result = applyDiscount(200, code);
    if (code === "EXPIRED5") {
      expect(result.error).toBe("code expired");
    } else {
      expect(result.total).toBe(180);
    }
  }
});

// After: one behaviour per test, no logic in the body
it("takes 10% off with SAVE10 @regression @unit @p2 @automated", () => {
  expect(applyDiscount(200, "SAVE10")).toEqual({ total: 180 });
});

it("refuses an expired code and keeps the price @regression @unit @p2 @automated", () => {
  // Two assertions, one result: the price and the reason belong to the same behaviour
  const result = applyDiscount(200, "EXPIRED5");
  expect(result.total).toBe(200);
  expect(result.error).toBe("code expired");
});
```

---

## 🧪 Assertion Standards & Examples

### Playwright E2E Assertions

Always use web-first, auto-retrying assertions:

<!-- ts-check: skip (fragment: page and expect come from the surrounding test) -->

```typescript
// Good: Playwright will retry until the element satisfies the condition (up to timeout)
await expect(page.getByTestId("success-alert")).toBeVisible();
await expect(page.getByRole("button", { name: "Save" })).toBeDisabled();

// Bad: Non-retrying assertions (prone to race conditions and flakiness)
const isVisible = await page.getByTestId("success-alert").isVisible();
expect(isVisible).toBe(true);
```

### Vitest Unit & Integration Assertions

<!-- ts-check: skip (shows Arrange-Act-Assert: calculateTotal is the code under test, not shown) -->

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
