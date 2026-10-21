Historical: written for v1.x; not maintained.

# QA Skill - Usage Examples

Comprehensive examples of how to use the `/qa` command or prompt prefix across different AI assistants (Claude Code, Antigravity, Gemini, OpenAI) and IDEs (Trae, Cursor, Windsurf, Copilot, Cline, etc.).

---

## Table of Contents

- [Requirements Analysis](#requirements-analysis)
- [Test Design](#test-design)
- [API Testing (Postman)](#api-testing-postman)
- [Unit Testing (JUnit)](#unit-testing-junit)
- [E2E Testing (Playwright)](#e2e-testing-playwright)
- [Risk Analysis](#risk-analysis)
- [Defect Reporting](#defect-reporting)
- [Test Planning](#test-planning)
- [CI/CD Integration](#cicd-integration)
- [Agile Work Items](#agile-work-items)
- [Advanced Examples](#advanced-examples)
- [Tips for Effective Use](#tips-for-effective-use)
- [Example Workflow](#example-workflow)
- [Test Tagging & Organization](#test-tagging--organization)
- [Automation Candidate Evaluation](#automation-candidate-evaluation)
- [Manual Test Case with Tags](#manual-test-case-with-tags)
- [CI/CD Pipeline Integration](#cicd-pipeline-integration)
- [Failure Cases & Ambiguous Inputs](#failure-cases--ambiguous-inputs)
- [Jest + Testing Library (React Component)](#jest--testing-library-react-component)
- [Cypress E2E (Login with Intercept)](#cypress-e2e-login-with-intercept)
- [Spring Boot Integration Test (@WebMvcTest)](#spring-boot-integration-test-webmvctest)
- [Exploratory Testing Charter](#exploratory-testing-charter)
- [Three Amigos Session](#three-amigos-session)
- [Framework Scaffolding (Playwright from Zero)](#framework-scaffolding-playwright-from-zero)

---

## Requirements Analysis

### Example 1: Review User Story for Testability

> **ISTQB Reference:** Ch.2 — SDLC & Test Levels; Ch.5 — Test Planning; BDD (Ch.2 Test-Driven Approaches); INVEST from Agile Testing practices

**Your Input:**

```text
/qa review this user story for testability:

Title: User Login
As a registered user
I want to login to the system
So that I can access my account
```

**Expected Output:**

- INVEST criteria analysis
- Testability assessment
- Missing acceptance criteria
- Suggested Given/When/Then scenarios
- Edge cases and boundary conditions
- Test levels needed (unit, integration, E2E)

---

### Example 2: Write Acceptance Criteria

> **ISTQB Reference:** Ch.5 — Test Planning (test objectives); SMART AC guide (see Agile Refinement section); BDD Given/When/Then (Ch.2)

**Your Input:**

```text
/qa write acceptance criteria for this feature:

Feature: Password Reset
Users should be able to reset their password if they forget it.
```

**Expected Output:**

- Multiple scenarios in Given/When/Then format
- Happy path scenario
- Error scenarios (invalid email, expired token)
- Edge cases (multiple reset requests, already logged in)
- Non-functional criteria (email delivery time, token expiration)

---

### Example 3: Identify Test Scenarios

> **ISTQB Reference:** Ch.4 — Equivalence Partitioning (EP), Boundary Value Analysis (BVA), Decision Table Testing

**Your Input:**

```text
/qa identify test scenarios for user registration with the following fields:
- Email (required, valid email format)
- Password (required, min 8 chars, must contain uppercase, lowercase, number, special char)
- Confirm Password (must match password)
- Age (required, 18-120)
```

**Expected Output:**

- Equivalence partitions for each field
- Boundary value test cases
- Combination testing scenarios
- Decision table for complex validation rules
- Positive and negative test cases

---

## Test Design

> **ISTQB Reference:** Ch.4 — Test Analysis and Design; Black-box techniques (EP, BVA, Decision Table, State Transition); White-box techniques (Statement/Branch Coverage)

### Example 1: Equivalence Partitioning

**Your Input:**

```text
/qa apply equivalence partitioning to this input:

Discount percentage based on order amount:
- $0-$49: No discount
- $50-$99: 5% discount
- $100-$199: 10% discount
- $200+: 15% discount
```

**Expected Output:**

- Valid partitions identified
- Invalid partitions identified
- Representative values from each partition
- Test case table with expected results

---

### Example 2: Boundary Value Analysis

**Your Input:**

```text
/qa apply boundary value analysis to:

Age field: minimum 18, maximum 65
```

**Expected Output:**

- Boundary values: 17, 18, 19, 64, 65, 66
- Test cases for each boundary
- Invalid boundary test cases
- Expected results for each

---

### Example 3: Decision Table

**Your Input:**

```text
/qa create a decision table for loan approval:

Rules:
- Age >= 18
- Income >= $30,000
- Credit score >= 650
- No bankruptcy in last 7 years

Decision: Approve or Reject
```

**Expected Output:**

- Complete decision table with all condition combinations
- Reduced decision table (removing redundant rules)
- Test cases based on decision table
- Expected outcomes

---

### Example 4: State Transition Testing

**Your Input:**

```text
/qa design state transition tests for order workflow:

States: Draft → Submitted → Approved → Shipped → Delivered → Completed
Also: Cancelled (from any state except Completed)
```

**Expected Output:**

- State transition diagram description
- Valid transitions list
- Invalid transitions list
- Test cases for state coverage
- Test cases for transition coverage

---

## API Testing (Postman)

> **ISTQB Reference:** Ch.2 — Component Integration Testing, System Integration Testing; Ch.6 — Test Execution Tools; Ch.5 — Test Monitoring metrics (response time, status codes)

### Example 1: Login API Tests

**Your Input:**

```text
/qa write Postman tests for login API:

Endpoint: POST /api/auth/login
Request Body: {
  "email": "user@example.com",
  "password": "SecurePass123"
}
Success Response (200): {
  "token": "jwt-token-here",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "user@example.com"
  }
}
Error Response (401): {
  "error": "Invalid credentials"
}
```

**Expected Output:**

- Complete Postman test script
- Status code assertions
- Response time checks
- JSON schema validation
- Response body assertions
- Environment variable setup (save token)
- Pre-request script (if needed)
- Test cases for success and error scenarios

---

### Example 2: CRUD Operations

**Your Input:**

```text
/qa create Postman collection for User CRUD API:

- POST /api/users (Create)
- GET /api/users/:id (Read)
- PUT /api/users/:id (Update)
- DELETE /api/users/:id (Delete)
- GET /api/users (List all)

Authentication: Bearer token required
```

**Expected Output:**

- Collection structure
- Test scripts for each endpoint
- Request chaining (use created user ID in subsequent requests)
- Environment variables setup
- Test data management
- Newman CLI command for CI/CD

---

### Example 3: Error Handling Tests

**Your Input:**

```text
/qa write Postman tests for error scenarios:

POST /api/orders
Test these error cases:
- 400: Missing required fields
- 401: Unauthorized (no token)
- 403: Forbidden (insufficient permissions)
- 404: Product not found
- 422: Invalid quantity (negative or zero)
```

**Expected Output:**

- Test scripts for each error scenario
- Assertions for status codes
- Error message validation
- Response structure checks

---

## Unit Testing (JUnit)

> **ISTQB Reference:** Ch.2 — Component Testing (Unit Testing); Ch.4 — White-box techniques (C0 Statement, C1 Branch Coverage); Modern Practices — FIRST Principles, AAA Pattern, Mocks and Stubs

### Example 1: Calculator Class

**Your Input:**

```text
/qa create JUnit tests for this Calculator class:

public class Calculator {
    public int add(int a, int b) {
        return a + b;
    }

    public int divide(int a, int b) {
        if (b == 0) {
            throw new ArithmeticException("Division by zero");
        }
        return a / b;
    }

    public boolean isPrime(int n) {
        if (n <= 1) return false;
        for (int i = 2; i <= Math.sqrt(n); i++) {
            if (n % i == 0) return false;
        }
        return true;
    }
}
```

**Expected Output:**

- Complete JUnit test class
- Test methods for each public method
- Assertions for normal cases
- Exception testing
- Parameterized tests
- Edge cases and boundary values
- FIRST principles applied

---

### Example 2: UserService with Mock Dependencies

**Your Input:**

```text
/qa write JUnit tests with Mockito for:

public class UserService {
    private UserRepository repository;
    private EmailService emailService;

    public User createUser(User user) {
        if (!isValidEmail(user.getEmail())) {
            throw new ValidationException("Invalid email");
        }
        User saved = repository.save(user);
        emailService.sendWelcomeEmail(saved.getEmail());
        return saved;
    }
}
```

**Expected Output:**

- Test class with @Mock annotations
- Mockito setup
- Test for successful user creation
- Test for validation failure
- Verification of mock interactions
- Test for email service failure

---

### Example 3: Parameterized Tests

**Your Input:**

```text
/qa write parameterized JUnit tests for password validation:

Requirements:
- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one digit
- At least one special character (!@#$%^&*)

Test both valid and invalid passwords.
```

**Expected Output:**

- @ParameterizedTest with @MethodSource
- Test data provider with valid passwords
- Test data provider with invalid passwords
- Clear test descriptions
- Assertions for each test case

---

## E2E Testing (Playwright)

> **ISTQB Reference:** Ch.2 — System Testing, Acceptance Testing; Ch.4 — Black-box techniques; Ch.5 — Test Execution; Modern Practices — Test Pyramid (E2E = top 10%), Page Object Model pattern

### Example 1: Login Flow

**Your Input:**

```text
/qa write Playwright tests for login flow:

URL: https://app.example.com/login
Fields: Email, Password
Button: "Sign In"
Success: Redirects to /dashboard, shows "Welcome, [Name]"
Error: Shows "Invalid credentials" message
```

**Expected Output:**

- Complete test spec
- Test for successful login
- Test for failed login
- Proper locators (getByLabel, getByRole)
- Assertions for redirect and welcome message
- Page Object Model structure (if requested)

---

### Example 2: Form Validation

**Your Input:**

```text
/qa create Playwright tests for registration form with Page Object Model:

Form fields:
- First Name (required, 2-50 chars)
- Last Name (required, 2-50 chars)
- Email (required, valid email)
- Password (required, 8+ chars)
- Confirm Password (must match)
- Terms checkbox (required)

Submit button should be disabled until form is valid.
```

**Expected Output:**

- RegistrationPage class (POM)
- Test spec with multiple scenarios
- Validation tests for each field
- Submit button state tests
- Successful registration test
- Locators using getByLabel, getByRole
- Assertions for validation messages

---

### Example 3: E-commerce Checkout

**Your Input:**

```text
/qa write Playwright E2E test for checkout flow:

1. Add product to cart
2. View cart
3. Proceed to checkout
4. Fill shipping info
5. Select payment method
6. Review order
7. Confirm order
8. See confirmation page

Use Page Object Model pattern.
```

**Expected Output:**

- Multiple Page Object classes (ProductPage, CartPage, CheckoutPage, ConfirmationPage)
- Complete E2E test spec
- Step-by-step navigation
- Form filling
- Assertions at each step
- Screenshot on failure configuration

---

## Risk Analysis

> **ISTQB Reference:** Ch.5 — Risk-Based Testing, Risk Analysis (product vs project risks); Risk Scoring Matrix (Likelihood × Impact 5×5); Ch.1 — Testing Principle #2 (Exhaustive testing impossible — prioritize by risk)

### Example 1: Epic Risk Analysis

**Your Input:**

```text
/qa perform risk analysis on this epic:

Epic: Payment Gateway Integration
Description: Integrate Stripe payment gateway for credit card and ACH payments.
Includes: PCI compliance, fraud detection, refund processing, webhook handling.
Timeline: 3 sprints
Team: 2 backend devs, 1 frontend dev, 1 QA
```

**Expected Output:**

- Product risks identified (payment failures, security vulnerabilities, data breaches)
- Project risks identified (timeline, resource constraints, third-party dependency)
- Risk matrix (Likelihood × Impact)
- Risk levels assigned (Critical, High, Medium, Low)
- Testing recommendations based on risk levels
- Mitigation strategies

---

### Example 2: Feature Risk Assessment

**Your Input:**

```text
/qa assess risks for this feature:

Feature: Multi-factor Authentication (MFA)
Users can enable MFA using SMS or authenticator app.
Backup codes provided for account recovery.
```

**Expected Output:**

- Security risks (SMS interception, backup code leakage)
- Usability risks (users locked out, lost devices)
- Functional risks (SMS delivery failures, time sync issues)
- Risk prioritization
- Test focus areas
- Risk mitigation through testing

---

## Defect Reporting

> **ISTQB Reference:** Ch.5 — Defect Management (Defect Report Contents, Severity vs Priority, Defect Lifecycle); Ch.1 — Error → Defect → Failure distinction; Defect Report Template (see qa.md)

### Example 1: Write Defect Report

**Your Input:**

```text
/qa write a defect report:

Bug: Login button doesn't work on Chrome when password field is empty
Steps: Go to login page, enter email, leave password empty, click Login
Expected: Validation message "Password is required"
Actual: Button is unresponsive, no message shown
Environment: Chrome 120, Windows 11
```

**Expected Output:**

- Complete defect report with all required fields
- Defect ID format
- Title (clear, concise)
- Severity and Priority assessment
- Detailed steps to reproduce
- Expected vs Actual results
- Environment details
- Suggestions for root cause
- Regression testing recommendations

---

### Example 2: Root Cause Analysis

**Your Input:**

```text
/qa analyze root cause for this defect:

Defect: Order total calculation incorrect when discount code applied
Issue: 10% discount code applies to shipping cost as well as product cost
Expected: Discount should only apply to product cost
Code:
totalDiscount = (productCost + shippingCost) * discountPercentage
finalTotal = (productCost + shippingCost) - totalDiscount
```

**Expected Output:**

- Root cause identification
- Explanation of the logic error
- Suggested fix
- Test cases to prevent regression
- Similar bugs to check for
- Code review recommendations

---

## Test Planning

> **ISTQB Reference:** Ch.5 — Test Planning (objectives, scope, approach, entry/exit criteria, resources, schedule, deliverables); Ch.5 — Risk-Based Testing; Test Plan Template (see qa.md)

### Example 1: Sprint Test Plan

**Your Input:**

```text
/qa create a test plan for this sprint:

Sprint 12: User Profile Management
User Stories:
1. Edit profile information
2. Upload profile picture
3. Change password
4. Delete account

Team: 3 devs, 1 QA
Duration: 2 weeks
```

**Expected Output:**

- Test plan outline
- Scope (in-scope, out-of-scope)
- Test approach (levels, types, techniques)
- Test deliverables
- Entry/exit criteria
- Test environment requirements
- Resource allocation
- Schedule and milestones
- Risks and mitigation

---

### Example 2: Automation Strategy

**Your Input:**

```text
/qa suggest automation strategy for our regression suite:

Current state:
- 500 manual test cases
- Regression takes 3 days per release
- Release every 2 weeks
- Tools available: JUnit, Postman, Playwright

Application:
- REST API backend
- React frontend
- 20 critical user journeys
```

**Expected Output:**

- Test pyramid distribution (70% unit, 20% API, 10% E2E)
- Automation candidates identification
- Priority for automation (high-value, frequently executed)
- Tool mapping (JUnit for unit, Postman for API, Playwright for E2E)
- Implementation roadmap (sprints 1-6)
- ROI estimation
- Maintenance strategy

---

## CI/CD Integration

> **ISTQB Reference:** Ch.2 — DevOps and Shift-Left testing; Ch.6 — Test Tools (CI/CD integration, Newman CLI, Maven/Gradle, Playwright config); Modern Practices — Test Categorization by tag for pipeline execution

### Example 1: Newman Command for Pipeline

**Your Input:**

```text
/qa provide Newman CLI command for running Postman collection in Azure Pipeline
```

**Expected Output:**

- Newman installation command
- Newman run command with options
- Report generation (HTML, JSON, JUnit)
- Exit code handling for pipeline
- Environment variable passing
- Azure Pipeline YAML example

---

### Example 2: JUnit in Maven Pipeline

**Your Input:**

```text
/qa provide Maven commands to run JUnit tests in CI/CD with code coverage
```

**Expected Output:**

- Maven test command
- JaCoCo plugin configuration
- Coverage threshold settings
- Report generation
- Failure handling
- Azure Pipeline YAML example

---

### Example 3: Playwright in CI/CD

**Your Input:**

```text
/qa configure Playwright for Azure Pipeline with parallel execution
```

**Expected Output:**

- Playwright installation in pipeline
- Browser installation
- Parallel worker configuration
- Test execution command
- Report publishing
- Artifact storage for failures (screenshots, videos, traces)
- Complete Azure Pipeline YAML

---

## Agile Work Items

> **ISTQB Reference:** Ch.3 — Static Testing (reviews, work product examination); Ch.5 — Test Planning (requirements traceability); SMART AC guide; INVEST criteria; Agile Work Item Review Checklists (Epic, Feature, User Story, Task — see qa.md)

### Example 1: Review Epic

**Your Input:**

```text
/qa review this epic:

Epic ID: 12345
Title: Customer Support Chat Integration
Description: Integrate live chat functionality so customers can get real-time support.
Acceptance Criteria:
- Chat widget on all pages
- Support agents can handle multiple chats
```

**Expected Output:**

- Completeness check (missing details?)
- Testability analysis
- Suggested improvements for description
- Enhanced acceptance criteria with specifics
- Non-functional requirements needed (performance, security)
- Risk identification
- Test strategy recommendation

---

### Example 2: Improve User Story

**Your Input:**

```text
/qa improve this user story:

Title: Search Products
Description: Users can search for products
```

**Expected Output:**

- Rewritten user story in proper format (As a... I want... So that...)
- INVEST criteria assessment
- Detailed acceptance criteria (Given/When/Then)
- Edge cases and error scenarios
- Test scenarios list
- Dependencies identified
- Suggestions for testability improvements

---

### Example 3: Review Task List

**Your Input:**

```text
/qa review tasks for this user story and suggest missing test tasks:

Story: User Login
Tasks:
1. Create login API endpoint
2. Design login UI
3. Connect frontend to API
4. Deploy to staging
```

**Expected Output:**

- Missing test tasks identified:
  - Write unit tests for login API
  - Create Postman tests for login endpoint
  - Develop Playwright E2E tests for login flow
  - Prepare test data
  - Execute manual exploratory testing
  - Perform security testing (SQL injection, XSS)
  - Run regression tests
  - Document test results
- Task descriptions with clear DoD

---

## Advanced Examples

### Example 1: Performance Testing Guidance

**Your Input:**

```text
/qa suggest performance test scenarios for our API:

Endpoint: GET /api/products
Expected: 100 concurrent users, response time < 500ms
```

**Expected Output:**

- Performance test scenarios (load, stress, spike, endurance)
- Tool recommendations (JMeter, k6, Gatling)
- Test configuration details
- Metrics to collect
- Success criteria
- Bottleneck identification approach

---

### Example 2: Security Testing

**Your Input:**

```text
/qa what security tests should we run on our login feature?
```

**Expected Output:**

- Security test scenarios:
  - SQL injection attempts
  - XSS (Cross-Site Scripting)
  - CSRF (Cross-Site Request Forgery)
  - Brute force protection
  - Password storage (hashing)
  - Session management
  - HTTPS enforcement
- OWASP Top 10 relevance
- Tool recommendations
- Test data examples

---

### Example 3: Accessibility Testing

**Your Input:**

```text
/qa how should we test accessibility for our registration form?
```

**Expected Output:**

- WCAG 2.1 guidelines relevant to forms
- Keyboard navigation testing
- Screen reader compatibility
- Color contrast checks
- Form label associations
- Error message accessibility
- Tool recommendations (axe, Lighthouse, NVDA)
- Playwright accessibility testing integration

---

## Tips for Effective Use

1. **Be Specific**: Provide context, requirements, and constraints
2. **Include Code**: When asking about unit tests, share the code to test
3. **Share URLs**: For work item reviews, paste the work item URL or content
4. **Ask Follow-ups**: Request clarification or expansion on responses
5. **Combine Techniques**: Ask for multiple test techniques in one request
6. **Request Examples**: Ask for code examples, not just theory
7. **Specify Tools**: Mention which tool (Postman/JUnit/Playwright) you want to use

---

## Example Workflow

Here's a typical workflow using `/qa` for a new feature:

```text
1. /qa review this user story for testability: [paste story]
   → Get feedback, improved acceptance criteria

2. /qa apply boundary value analysis to the age field (18-65)
   → Get boundary test cases

3. /qa write Postman tests for the API endpoint: [paste API details]
   → Get Postman collection with test scripts

4. /qa create JUnit tests for UserService: [paste code]
   → Get unit test class

5. /qa write Playwright tests for the registration flow with POM
   → Get E2E tests with Page Objects

6. /qa perform risk analysis on this feature
   → Get risk assessment and testing priorities

7. /qa suggest automation strategy for these 20 test cases
   → Get automation recommendations

8. /qa write defect report for: [describe bug]
   → Get properly formatted defect report
```

---

## Test Tagging & Organization

### Example 1: Organize Test Suite with Tags

**Your Input:**

```text
/qa help me organize my test suite with tags for CI/CD:

Current tests:
- 50 unit tests (JUnit)
- 30 API tests (Postman)
- 20 E2E tests (Playwright)

I want to run:
- Quick smoke tests on every commit
- Full regression suite nightly
- Critical tests before release
```

**Expected Output:**

- Tag categorization strategy
- JUnit @Tag examples for unit tests
- Playwright tag examples for E2E tests
- Postman collection organization
- Maven/Gradle/npx commands for each scenario
- Complete CI/CD pipeline configuration with tag filters

---

### Example 2: Write Tagged JUnit Tests

**Your Input:**

```text
/qa write tagged JUnit tests for UserService:
- createUser() - critical, smoke test
- updateUser() - regression, medium priority
- deleteUser() - regression, low priority
```

**Expected Output:**

- JUnit test class with @Tag annotations
- @Tag("smoke"), @Tag("critical"), @Tag("regression")
- Maven commands to run: `mvn test -Dgroups="smoke"`

---

### Example 3: Write Tagged Playwright Tests

**Your Input:**

```text
/qa write Playwright tests for checkout flow with tags:
- Add to cart - smoke, critical
- Complete checkout - smoke, critical, slow
```

**Expected Output:**

- Playwright tests with tags in test names: `test('add to cart @smoke @critical @e2e', ...)`
- npx commands: `npx playwright test --grep @smoke`

---

## Automation Candidate Evaluation

### Example 1: Evaluate Single Test

**Your Input:**

```text
/qa should I automate this test case?

Test: Password Reset Flow
- Executed: Weekly in regression
- Priority: High (P1)
- Feature: Stable (2 years old)
- Steps: 8 steps including email verification
- Current execution: 5 minutes manual
```

**Expected Output:**

- Automation Candidate Decision Matrix with scores
- Total score: 48.5/57.5
- Decision: ✅ HIGH Priority - Automate
- Tool recommendation: Playwright with email mocking
- Implementation priority: Next sprint

---

### Example 2: Evaluate Multiple Tests

**Your Input:**

```text
/qa which of these tests should I automate?

1. User Login - daily, critical, simple, stable
2. Complex Report - monthly, low priority, unstable
3. Product Search - daily, high priority, simple API
```

**Expected Output:**

- Decision Matrix scores for each
- Prioritized list:
  1. ✅ User Login (Score: 55) - AUTOMATE NOW
  2. ✅ Product Search (Score: 52) - AUTOMATE NOW
  3. ❌ Complex Report (Score: 22) - KEEP MANUAL
- Implementation roadmap

---

## Manual Test Case with Tags

### Example: Write Complete Test Case

**Your Input:**

```text
/qa write manual test case for user registration with tags and automation assessment
```

**Expected Output:**

- Complete test case template with all fields
- Tags: @smoke, @critical, @e2e, @candidate
- Automation Status: Candidate (High Priority)
- Automation Candidate Score: 52/57.5
- Decision Matrix breakdown
- Recommendation: Automate with Playwright

---

## CI/CD Pipeline Integration

### Example: Azure Pipeline with Tags

**Your Input:**

```text
/qa create Azure Pipeline YAML for running tagged tests at different stages
```

**Expected Output:**

```yaml
stages:
  - stage: CommitTests
    steps:
      - script: mvn test -Dgroups="unit & smoke"
        displayName: "Fast Tests (< 2 min)"

  - stage: NightlyTests
    condition: eq(variables['Build.Reason'], 'Schedule')
    steps:
      - script: mvn test -Dgroups="regression"
        displayName: "Full Regression"
```

---

## Failure Cases & Ambiguous Inputs

> **Why this matters:** QA value is highest when requirements are unclear, incomplete, or contradictory. These examples show how `/qa` handles the hard cases — not just the happy path.
>
> **ISTQB Reference:** Ch.1 — Testing Principle #7 (Absence-of-defects fallacy); Ch.3 — Static Testing (review of work products); Ch.5 — Test Planning (risk identification)

---

### Example 1: Untestable Acceptance Criteria

**Your Input:**

```text
/qa review these acceptance criteria:

AC1: The system should be user-friendly
AC2: Login should be fast
AC3: The app must be secure
AC4: Error handling should be good
```

**What `/qa` should do:**

- Flag ALL four ACs as untestable (vague, immeasurable)
- Explain WHY each is untestable (no threshold, no observable behaviour)
- Rewrite each with SMART alternatives:
  - AC1 → "Users can complete registration in ≤3 steps with no external help"
  - AC2 → "Login API must respond in <500ms for 95% of requests under 100 concurrent users"
  - AC3 → "Passwords are hashed with bcrypt (cost factor ≥10); session tokens expire in 30 min"
  - AC4 → "All validation errors display specific field-level messages within 200ms of submission"
- Ask: "Should I rewrite all four in Given/When/Then format for the PO to review?"

---

### Example 2: Contradictory Requirements

**Your Input:**

```text
/qa review this user story:

US-5012: Password Policy
AC1: Passwords must be at least 12 characters
AC2: Passwords must be exactly 10 characters
AC3: Users must be able to use their previous password
AC4: Users cannot reuse their last 5 passwords
```

**What `/qa` should do:**

- Identify the contradictions:
  - AC1 vs AC2: 12 chars vs exactly 10 chars — mutually exclusive
  - AC3 vs AC4: allow reuse vs prohibit reuse — mutually exclusive
- Refuse to write tests until contradictions are resolved (testing contradictions produces meaningless results)
- Raise a clarification request for the PO with specific questions:
  - "What is the intended minimum length — 10 or 12 characters?"
  - "Should users be able to reuse passwords at all? If not, how many previous passwords are blocked?"
- Suggest interim: test what is unambiguous (e.g., password field exists, error messages display)

---

### Example 3: Incomplete User Story — Missing Personas

**Your Input:**

```text
/qa identify test scenarios for:

Feature: Export Report
Users can export reports to PDF.
```

**What `/qa` should do:**

- Identify missing information before writing tests:
  - Who are the "users"? All roles? Only admins? Premium tier only?
  - Which reports? All reports? Specific report types?
  - PDF only, or also CSV/Excel?
  - What happens to large reports? (timeout, pagination, async?)
  - What about empty reports?
  - What permissions are required?
- Ask clarifying questions as a numbered list
- Offer to write tests based on reasonable assumptions with explicit caveats:
  - "Assuming: any logged-in user, any report type, synchronous export, max 1000 rows..."
- Tag all test cases generated from assumptions as `@assumption-<topic>` for easy review

---

### Example 4: Flaky / Unreliable Test Diagnosis

**Your Input:**

```text
/qa this Playwright test fails intermittently (~30% of runs). Help me fix it:

test('user can add item to cart', async ({ page }) => {
  await page.goto('/products');
  await page.click('.add-to-cart');
  expect(await page.textContent('.cart-count')).toBe('1');
});
```

**What `/qa` should do:**

- Diagnose the root causes of flakiness:
  1. No wait strategy — `.click()` fires before element is interactive
  2. Selector `.add-to-cart` and `.cart-count` are fragile CSS classes (may change)
  3. No assertion on `.add-to-cart` being visible before clicking
  4. `textContent` compared directly — no tolerance for whitespace
- Provide a corrected, stable version:

```typescript
test("user can add item to cart @smoke @cart", async ({ page }) => {
  await page.goto("/products");
  const addToCartButton = page
    .getByRole("button", { name: "Add to Cart" })
    .first();
  await expect(addToCartButton).toBeVisible();
  await addToCartButton.click();
  const cartCount = page.getByTestId("cart-count");
  await expect(cartCount).toHaveText("1");
});
```

- Explain each fix: `getByRole` over CSS class, explicit visibility assertion, `toHaveText` auto-waits
- Tag the original as `@flaky` until replaced, then remove it

---

### Example 5: Out-of-Scope Request

**Your Input:**

```text
/qa write tests for the entire e-commerce platform before our go-live in 2 days.
```

**What `/qa` should do:**

- Acknowledge the constraint (2 days = insufficient time for full coverage)
- Pivot to risk-based testing:
  1. Ask: "What are the most critical user journeys and business functions?"
  2. Apply the Risk Matrix — prioritize CRITICAL and HIGH risks
  3. Propose a Smoke + Sanity test plan executable in the available time
  4. Identify what is explicitly OUT OF SCOPE and document it with rationale
  5. Recommend a minimum viable test execution plan:
     - P0 tests only: checkout, payment, login, order confirmation
     - Skip: admin panel, reports, email templates, edge cases
  6. Produce a written risk acceptance statement for the PO to sign off

---

### Example 6: No Acceptance Criteria at All

**Your Input:**

```text
/qa write test cases for US-3301: User Profile Page
(No acceptance criteria provided)
```

**What `/qa` should do:**

- Flag: "This story has no acceptance criteria — I'll generate tests based on industry standards for a User Profile feature, but these must be validated by the PO before execution."
- Generate assumption-based test cases covering:
  - View profile (own profile displayed correctly)
  - Edit profile fields (name, email, avatar)
  - Save changes (persistence, success message)
  - Validation (email format, required fields)
  - Access control (can't view/edit other users' profiles)
  - Non-functional (profile page loads in <1s)
- Mark all as `@assumption-no-ac @manual` pending PO review
- Produce a draft of missing acceptance criteria for PO to review and approve before test execution

---

## Jest + Testing Library (React Component)

**Prompt**: `/qa write a Jest test with Testing Library for a SearchBar component that filters users`

**Expected Output**:

```tsx
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { SearchBar } from "./SearchBar";

describe("SearchBar", () => {
  const mockOnSearch = vi.fn();

  beforeEach(() => {
    mockOnSearch.mockClear();
  });

  it("should call onSearch when user types and submits", async () => {
    render(<SearchBar onSearch={mockOnSearch} />);

    await userEvent.type(screen.getByRole("searchbox"), "Alice");
    await userEvent.click(screen.getByRole("button", { name: /search/i }));

    expect(mockOnSearch).toHaveBeenCalledWith("Alice");
  });

  it('should show "No results" when search returns empty', async () => {
    mockOnSearch.mockResolvedValue([]);
    render(<SearchBar onSearch={mockOnSearch} />);

    await userEvent.type(screen.getByRole("searchbox"), "zzz");
    await userEvent.click(screen.getByRole("button", { name: /search/i }));

    await waitFor(() => {
      expect(screen.getByText(/no results found/i)).toBeInTheDocument();
    });
  });
});
```

---

## Cypress E2E (Login with Intercept)

**Prompt**: `/qa write a Cypress test for a login flow that intercepts the API and tests both success and error paths`

**Expected Output**:

```typescript
describe("Login Flow", () => {
  it("should login successfully and redirect to dashboard", () => {
    cy.intercept("POST", "/api/auth/login", {
      statusCode: 200,
      body: { token: "fake-jwt", user: { name: "Alice" } },
    }).as("loginRequest");

    cy.visit("/login");
    cy.get('[data-cy="email"]').type("alice@example.com");
    cy.get('[data-cy="password"]').type("password123");
    cy.get('[data-cy="submit"]').click();

    cy.wait("@loginRequest");
    cy.url().should("include", "/dashboard");
    cy.contains("Welcome, Alice").should("be.visible");
  });

  it("should show error message on invalid credentials", () => {
    cy.intercept("POST", "/api/auth/login", {
      statusCode: 401,
      body: { error: "Invalid credentials" },
    }).as("loginFail");

    cy.visit("/login");
    cy.get('[data-cy="email"]').type("wrong@example.com");
    cy.get('[data-cy="password"]').type("bad");
    cy.get('[data-cy="submit"]').click();

    cy.wait("@loginFail");
    cy.get('[data-cy="error-message"]').should(
      "contain",
      "Invalid credentials",
    );
  });
});
```

---

## Spring Boot Integration Test (@WebMvcTest)

**Prompt**: `/qa write a Spring Boot @WebMvcTest for a ProductController with GET and POST endpoints`

**Expected Output**:

```java
@WebMvcTest(ProductController.class)
class ProductControllerTest {
    @Autowired private MockMvc mockMvc;
    @MockBean private ProductService productService;

    @Test
    @DisplayName("GET /api/products returns list of products")
    void shouldReturnProducts() throws Exception {
        when(productService.findAll()).thenReturn(List.of(
            new Product(1L, "Widget", 9.99),
            new Product(2L, "Gadget", 19.99)
        ));

        mockMvc.perform(get("/api/products"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.length()").value(2))
            .andExpect(jsonPath("$[0].name").value("Widget"));
    }

    @Test
    @DisplayName("POST /api/products creates product and returns 201")
    void shouldCreateProduct() throws Exception {
        when(productService.create(any())).thenReturn(new Product(3L, "Gizmo", 29.99));

        mockMvc.perform(post("/api/products")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\": \"Gizmo\", \"price\": 29.99}"))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.id").value(3));
    }
}
```

---

## Exploratory Testing Charter

**Prompt**: `/qa create an exploratory testing charter for a new payment checkout feature`

**Expected Output**:

| Field           | Value                                                                                                               |
| --------------- | ------------------------------------------------------------------------------------------------------------------- |
| **Charter ID**  | ET-042                                                                                                              |
| **Mission**     | Explore the payment checkout flow to discover edge cases in payment processing, error handling, and user experience |
| **Target Area** | Cart → Shipping → Payment → Confirmation (end-to-end)                                                               |
| **Time-Box**    | 90 minutes                                                                                                          |
| **Heuristics**  | SFDPOT (focus on Data + Platform) + FEW HICCUPS (Error Handling + Interruption)                                     |
| **Test Data**   | Visa/MC/Amex test cards, expired card, insufficient funds, $0 order, $99,999 order, international address           |
| **Environment** | Chrome + Safari mobile, staging environment, test payment gateway                                                   |
| **Notes**       | Pay special attention to: concurrent cart modifications, back button during payment, session timeout mid-checkout   |

**Key scenarios to explore**:

- Apply + remove discount code during checkout
- Change shipping address after payment method selected
- Browser back button at each step
- Network timeout during payment submission
- Multiple tabs with same cart
- Accessibility: complete checkout via keyboard only

---

## Three Amigos Session

**Prompt**: `/qa facilitate a Three Amigos session for this user story: "As a user, I want to reset my password so I can regain access to my account"`

**Expected Output**:

**PO perspective**: User clicks "Forgot Password", enters email, receives reset link, creates new password. Must work for active accounts only.

**Dev questions**:

- How long should the reset token be valid? → PO: 24 hours
- Do we invalidate previous tokens? → PO: Yes, only latest is valid
- Rate limiting on reset requests? → Team: Max 3 per hour per email

**QA questions**:

- What if the email doesn't exist in our system? → PO: Show same "email sent" message (security)
- Password requirements? → PO: Same as registration (8+ chars, 1 uppercase, 1 number)
- What happens if token is expired? → PO: "Link expired, request a new one"
- Can user reuse their current password? → PO: No, must be different

**Refined Acceptance Criteria**:

```gherkin
Given a registered user
When they request a password reset with their email
Then they receive a reset link valid for 24 hours

Given an unregistered email
When they request a password reset
Then they see the same "email sent" message (no information leak)

Given a valid reset token
When the user submits a new valid password (different from current)
Then their password is updated and all previous tokens are invalidated

Given an expired or used reset token
When the user clicks the link
Then they see "Link expired" with option to request a new one

Given a user has requested 3 resets in the last hour
When they request another reset
Then the request is rate-limited with a clear message
```

---

## Framework Scaffolding (Playwright from Zero)

**Prompt**: `/qa help me set up a Playwright E2E test framework for a React app from scratch`

**Expected Output**:

```bash
# 1. Initialize project
mkdir e2e-tests && cd e2e-tests
npm init -y
npm install -D @playwright/test
npx playwright install

# 2. Project structure
mkdir -p tests/pages tests/fixtures tests/test-data
```

```typescript
// playwright.config.ts
import { defineConfig } from "@playwright/test";
export default defineConfig({
  testDir: "./tests",
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [["html"], ["junit", { outputFile: "results.xml" }]],
  use: {
    baseURL: "http://localhost:3000",
    trace: "on-first-retry",
    screenshot: "only-on-failure",
  },
  projects: [
    { name: "chromium", use: { browserName: "chromium" } },
    { name: "firefox", use: { browserName: "firefox" } },
  ],
});

// tests/pages/BasePage.ts
export abstract class BasePage {
  constructor(protected page: Page) {}
  async navigate(path: string) {
    await this.page.goto(path);
  }
  async getTitle() {
    return this.page.title();
  }
}

// tests/pages/LoginPage.ts
export class LoginPage extends BasePage {
  async login(email: string, password: string) {
    await this.navigate("/login");
    await this.page.getByLabel("Email").fill(email);
    await this.page.getByLabel("Password").fill(password);
    await this.page.getByRole("button", { name: "Sign In" }).click();
  }
}

// tests/login.spec.ts
import { test, expect } from "@playwright/test";
import { LoginPage } from "./pages/LoginPage";

test("@smoke login with valid credentials", async ({ page }) => {
  const loginPage = new LoginPage(page);
  await loginPage.login("alice@test.com", "password123");
  await expect(page).toHaveURL(/dashboard/);
});
```

```bash
# 3. Run tests
npx playwright test
npx playwright test --grep @smoke
npx playwright show-report
```

---

**For more examples, experiment with `/qa` in your daily testing work!**
