Historical: written for v1.x; not maintained.

# `/qa` Skill — Self-Test Acceptance Checklist

Use this document to verify the `/qa` skill behaves correctly after any changes to the skill definition or compiled adapters. Run all tests after each version bump before committing.

**How to run:** Open a session in your preferred AI assistant (Claude Code, Antigravity, Gemini, OpenAI, etc.) or IDE (Trae, Cursor, Windsurf, Copilot, Cline, etc.), apply the prompt prefix or slash command, type each prompt below, and check the response against the expected output criteria.

---

## Test Execution Log

| Date       | Version | Tester  | Result | Notes                                 |
| ---------- | ------- | ------- | ------ | ------------------------------------- |
| 2026-03-24 | v1.1.0  | Initial | —      | Baseline — run after all improvements |

---

## Module 1: ISTQB Knowledge Base

### ST-01: Seven Testing Principles

**Prompt:**

```text
/qa list the 7 ISTQB testing principles
```

**Pass criteria:**

- [ ] Lists exactly 7 principles
- [ ] Principle 1: testing shows presence, not absence
- [ ] Principle 3: early testing (shift-left)
- [ ] Principle 4: defects cluster (Pareto)
- [ ] Each principle includes a practical implication

---

### ST-02: Test Levels

**Prompt:**

```text
/qa explain the 5 test levels and when each is used
```

**Pass criteria:**

- [ ] Covers: Component, Component Integration, System, System Integration, Acceptance
- [ ] Includes UAT, Alpha, Beta under Acceptance Testing
- [ ] Distinguishes black-box vs white-box approach per level

---

### ST-03: Chapter 4 Techniques

**Prompt:**

```text
/qa apply equivalence partitioning and BVA to: discount field accepts 0-100 integer
```

**Pass criteria:**

- [ ] Identifies valid partition: 0–100
- [ ] Identifies invalid partitions: <0, >100, non-integer
- [ ] Lists boundary values: -1, 0, 1, 99, 100, 101
- [ ] Produces test cases for each boundary

---

## Module 2: Templates

### ST-04: Defect Report Template

**Prompt:**

```text
/qa write a defect report for: login button is disabled and cannot be clicked after entering valid credentials on Chrome 122 / Windows 11
```

**Pass criteria:**

- [ ] Uses structured Defect Report Template (ID, Title, Environment, Steps, Expected, Actual)
- [ ] Title follows format: `[Component] – [failure] when [condition]`
- [ ] Severity and Priority are set with justification
- [ ] Steps to reproduce are numbered
- [ ] Expected vs Actual are clearly separated
- [ ] Environment includes OS and browser version

---

### ST-05: Test Plan Template

**Prompt:**

```text
/qa create a test plan for: Sprint 5 — User Profile feature (view, edit, avatar upload)
```

**Pass criteria:**

- [ ] Uses Test Plan Template structure (Objectives, Scope, Entry/Exit Criteria, Resources, Schedule)
- [ ] Scope explicitly lists IN SCOPE and OUT OF SCOPE
- [ ] Entry criteria include working test environment and completed unit tests
- [ ] Exit criteria include zero open P0 defects and regression passing
- [ ] Risk section references the Risk Scoring Matrix

---

### ST-06: Risk Scoring Matrix

**Prompt:**

```text
/qa perform risk analysis for: Payment processing module going live next sprint
```

**Pass criteria:**

- [ ] Uses 5×5 Likelihood × Impact matrix
- [ ] Produces a Risk Register table with columns: Risk, Category, Likelihood, Impact, Score, Level, Mitigation
- [ ] At least one CRITICAL risk (score 15–25) identified
- [ ] Mitigation strategies are specific (not vague)
- [ ] Advises reviewing CRITICAL risks with PO

---

## Module 3: Test Generation

### ST-07: BDD / Gherkin Scenarios

**Prompt:**

```text
/qa write BDD scenarios for: user password reset flow
```

**Pass criteria:**

- [ ] Uses valid Gherkin syntax (Feature, Scenario, Given/When/Then/And)
- [ ] Includes happy path scenario
- [ ] Includes at least 2 error scenarios (invalid email, expired token)
- [ ] Uses `Scenario Outline` + `Examples` for data-driven cases
- [ ] Tags scenarios with `@smoke`, `@regression`, etc.
- [ ] Does NOT mix implementation details into Gherkin steps

---

### ST-08: JUnit Test Generation

**Prompt:**

```text
/qa write JUnit 5 tests for a UserService.deactivateUser(Long userId) method that: throws UserNotFoundException if user doesn't exist, sets user.active=false and saves if user exists
```

**Pass criteria:**

- [ ] Produces a complete test class with `@ExtendWith(MockitoExtension.class)`
- [ ] Uses `@BeforeEach` for setup, `@Mock` for repository
- [ ] Test for happy path: user found, active set to false, save called
- [ ] Test for error path: user not found, `UserNotFoundException` thrown
- [ ] Uses `assertThrows` for exception testing
- [ ] Test names follow `methodName_condition_expectedResult` convention
- [ ] Includes `@Tag` annotations for categorization

---

### ST-09: Playwright Test Generation

**Prompt:**

```text
/qa write Playwright test for: adding an item to the shopping cart and verifying the cart count updates
```

**Pass criteria:**

- [ ] Uses TypeScript with `@playwright/test`
- [ ] Uses `getByRole` or `getByTestId` locators (not CSS classes)
- [ ] Uses `await expect().toBeVisible()` before interacting
- [ ] Uses `await expect().toHaveText()` for assertions (not raw `.textContent()`)
- [ ] Follows Page Object Model pattern (separate page class)
- [ ] Includes tags in test name (`@smoke`, `@cart`)

---

### ST-10: pytest Generation

**Prompt:**

```text
/qa write pytest tests for a Python function: calculate_discount(amount: float) that returns 0% for <50, 5% for 50-99, 10% for 100-199, 15% for 200+
```

**Pass criteria:**

- [ ] Uses `@pytest.mark.parametrize` for boundary values
- [ ] Tests cover all 4 discount tiers
- [ ] Tests cover boundary values (49.99, 50, 99.99, 100, 199.99, 200)
- [ ] Uses descriptive test IDs in parametrize
- [ ] Includes negative test (negative amount)
- [ ] Follows FIRST principles

---

### ST-11: Automation Decision Matrix

**Prompt:**

```text
/qa evaluate this test case for automation: "Verify that clicking 'Forgot Password' sends a reset email to the registered address" — runs weekly in regression, critical feature, email stub required, tests pass reliably with mock
```

**Pass criteria:**

- [ ] Uses the 8-criterion weighted Decision Matrix
- [ ] Shows individual criterion scores with justification
- [ ] Calculates weighted total
- [ ] Maps total to HIGH/MEDIUM/LOW priority level
- [ ] Recommends specific tool (Playwright, Postman, JUnit) with reason
- [ ] Assigns CI/CD trigger tag (@regression, @nightly, etc.)

---

### ST-18: Jest + Testing Library Test Generation

**Prompt:**

```text
/qa write Jest tests with Testing Library for a SearchBar React component
```

**Pass criteria:**

- [ ] Uses `@testing-library/react` imports (`render`, `screen`, `userEvent`)
- [ ] Describes behavior in test names
- [ ] Uses `expect` matchers for assertions
- [ ] Follows Testing Library best practices (queries by role/label, not implementation details)

---

### ST-19: Cypress E2E Test Generation

**Prompt:**

```text
/qa write a Cypress test for login flow with API mocking
```

**Pass criteria:**

- [ ] Uses `cy.visit` and `cy.get` for navigation and element selection
- [ ] Uses `cy.intercept` for API mocking
- [ ] Uses `cy.wait('@alias')` to wait for intercepted requests
- [ ] Uses `data-cy` attributes for selectors

---

### ST-20: Spring Boot Integration Test

**Prompt:**

```text
/qa write a @WebMvcTest for a ProductController GET endpoint
```

**Pass criteria:**

- [ ] Uses `@WebMvcTest` annotation
- [ ] Uses `MockMvc` for HTTP request simulation
- [ ] Uses `@MockBean` for service layer mocking
- [ ] Uses `mockMvc.perform` with `status()` and `jsonPath()` assertions

---

### ST-21: Contract Test Generation

**Prompt:**

```text
/qa write a Pact consumer test for a user API
```

**Pass criteria:**

- [ ] Uses `PactV3` for contract definition
- [ ] Defines provider interaction (request/response pair)
- [ ] Uses `executeTest` to run the contract test
- [ ] Uses matchers for flexible contract matching

---

## Module 4: Static Testing & Review

### ST-12: User Story Review

**Prompt:**

```text
/qa review this user story:
Title: User Login
As a user I want to login so I can access my account
AC1: The system should be user-friendly
AC2: Login should be fast
```

**Pass criteria:**

- [ ] Checks INVEST criteria
- [ ] Flags AC1 "user-friendly" as untestable — proposes SMART alternative
- [ ] Flags AC2 "fast" as untestable — proposes measurable threshold (e.g., <500ms)
- [ ] Identifies missing error scenarios (wrong password, locked account)
- [ ] Suggests Given/When/Then scenarios
- [ ] Does NOT write test cases based on the bad ACs without first flagging the issues

---

### ST-13: Code Review Focus

**Prompt:**

```text
/qa review this code from a QA perspective:

def login(email, password):
    query = "SELECT * FROM users WHERE email='" + email + "' AND password='" + password + "'"
    result = db.execute(query)
    return result[0] if result else None
```

**Pass criteria:**

- [ ] Identifies SQL injection vulnerability (string concatenation in query)
- [ ] Identifies untestable design (no dependency injection, direct db call)
- [ ] Recommends parameterized query
- [ ] Suggests how to make the function testable (inject db session)
- [ ] Does NOT improve/fix the code — only raises findings with clear rationale

---

## Module 5: Failure Cases

### ST-14: Contradictory Requirements

**Prompt:**

```text
/qa write tests for:
AC1: Password must be exactly 10 characters
AC2: Password must be at least 12 characters
```

**Pass criteria:**

- [ ] Refuses to write tests until contradiction is resolved
- [ ] Explicitly identifies which ACs conflict and why
- [ ] Raises a clarification question for the PO
- [ ] Does NOT pick one AC and silently ignore the other

---

### ST-15: Untestable Story (No ACs)

**Prompt:**

```text
/qa write tests for US-9999: Improve checkout experience
(no acceptance criteria)
```

**Pass criteria:**

- [ ] Flags that no acceptance criteria exist
- [ ] Does not refuse — generates assumption-based test cases with explicit caveats
- [ ] Tags all generated tests as `@assumption-no-ac`
- [ ] Produces draft acceptance criteria for PO review
- [ ] Recommends not executing tests until ACs are approved

---

## Module 6: Non-Functional Testing

### ST-16: Performance Test Design

**Prompt:**

```text
/qa design a k6 load test for: checkout API must handle 200 concurrent users with p95 response time <800ms
```

**Pass criteria:**

- [ ] Produces valid k6 script with `options.stages` (ramp up, sustain, ramp down)
- [ ] Sets `thresholds` matching the requirement (p95 < 800ms)
- [ ] Uses `check()` with status code and response time assertions
- [ ] Calculates expected RPS for 200 concurrent users
- [ ] Recommends when to run (pre-release, after major changes)

---

### ST-17: Accessibility Test Design

**Prompt:**

```text
/qa create an accessibility test plan for the login page
```

**Pass criteria:**

- [ ] References WCAG 2.1 AA standard
- [ ] Includes axe-core/Playwright automated check
- [ ] Includes keyboard navigation test
- [ ] Includes color contrast check
- [ ] Includes screen reader test (NVDA/VoiceOver)
- [ ] Covers form labels and error message association

---

## Module 7: QA Process & Collaboration

### ST-22: Three Amigos Facilitation

**Prompt:**

```text
/qa facilitate a Three Amigos session for "As a user, I want to export reports to PDF so I can share them offline"
```

**Pass criteria:**

- [ ] Identifies PO, Dev, and QA perspectives separately
- [ ] QA surfaces edge cases (large reports, special characters, concurrent exports)
- [ ] Produces refined ACs in Given/When/Then format
- [ ] Lists open questions and risks identified during session
- [ ] Output is actionable — team can start implementation after reading it

---

### ST-23: Exploratory Testing Charter

**Prompt:**

```text
/qa create an SBTM charter for testing a new search feature with autocomplete
```

**Pass criteria:**

- [ ] Uses charter template format (Mission, Target Area, Time-Box, Heuristics)
- [ ] References SFDPOT or FEW HICCUPS heuristics
- [ ] Specifies concrete test data and environments
- [ ] Includes debrief/notes section
- [ ] Time-box is realistic (60-90 min)

---

### ST-24: Test Process Assessment

**Prompt:**

```text
/qa assess our test process maturity — we have manual regression taking 3 days, no CI tests, and defects found mostly in production
```

**Pass criteria:**

- [ ] References TMMi maturity levels
- [ ] Correctly identifies current level (likely Level 1 — Initial)
- [ ] Suggests specific metrics to track (defect escape rate, automation %)
- [ ] Provides actionable improvement steps with priorities
- [ ] Recommends a realistic timeline for improvement

---

### ST-25: Framework Scaffolding Guidance

**Prompt:**

```text
/qa help me set up a Playwright test framework from scratch for a React web app
```

**Pass criteria:**

- [ ] Provides project structure with folders (tests/, pages/, fixtures/)
- [ ] Shows playwright.config.ts with sensible defaults
- [ ] Includes a BasePage or Page Object example
- [ ] Shows a working first test
- [ ] Includes CI/CD integration step

---

## Summary Scorecard

After running all tests, tally results:

| Module                         | Tests               | Passed | Failed |
| ------------------------------ | ------------------- | ------ | ------ |
| 1. ISTQB Knowledge             | ST-01, ST-02, ST-03 |        |        |
| 2. Templates                   | ST-04, ST-05, ST-06 |        |        |
| 3. Test Generation (Core)      | ST-07 to ST-11      |        |        |
| 4. Static Testing              | ST-12, ST-13        |        |        |
| 5. Failure Cases               | ST-14, ST-15        |        |        |
| 6. NFT                         | ST-16, ST-17        |        |        |
| 3b. Test Generation (Extended) | ST-18 to ST-21      |        |        |
| 7. QA Process & Collaboration  | ST-22 to ST-25      |        |        |
| **Total**                      | **25**              |        |        |

**Release Gate:**

- All ST-01 through ST-03: MUST PASS (core ISTQB knowledge)
- All ST-04 through ST-06: MUST PASS (templates)
- ST-14, ST-15: MUST PASS (failure case handling is critical)
- ST-22: MUST PASS (Three Amigos is fundamental QA process)
- All others: SHOULD PASS (>80% to ship a new version)
