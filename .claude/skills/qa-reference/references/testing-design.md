---
id: ref-testing-design
---
# Test Design Reference

> **Read on demand** | Detail behind the `testing-guidelines` rule | Part of the `qa-reference` skill

Read this before choosing test levels, coverage targets or test design techniques, before running tests against a shared environment, and before writing CI/CD tag filters. The always-on core (principles, defect chain, tagging taxonomy, failure protocol, Definition of Done) is the `testing-guidelines` rule.

---

## The Adaptive Test Pyramid

The test pyramid is a CTFL v4.0 model (§5.1.6); the distributions below are this package's presets, not syllabus figures. Adapt the distribution of tests based on where the core business logic resides:

- **Backend / API / Microservices Heavy**: 70% Unit · 20% Integration · 10% E2E
- **Full-Stack Web App (React + REST API)**: 40% Unit · 40% Integration · 20% E2E
- **UI-Heavy / Interactive Canvas / Mapping**: 20% Unit · 30% Integration · 50% E2E
  - The E2E share is a cost accepted because the logic lives in the UI, not a goal. End-to-end tests are the slowest layer (CTFL v4.0 §5.1.6) and the most expensive to write and the most brittle (Valente, *Engenharia de Software Moderna*, sections 8.1 and 8.9). Before accepting it, move logic out of the canvas or UI into units that can be tested alone (the `qa-engineer` agent's Testability gate), cover rendering with component tests and visual regression, and check that the E2E suite still fits the suite duration targets in the `testing-guidelines` rule.
- **Data Pipeline / ETL Systems**: 60% Unit · 35% Integration · 5% E2E

> **Key Directive**: Push tests to the lowest level that can cover the logic cheaply, quickly, and reliably.

### Coverage Strategy Targets

A coverage figure means nothing until it says what is counted, so each row names its measure:

| Area | Measure | Floor |
| ------ | --------- | ------- |
| **Critical Paths** (Login, Checkout) | Requirements coverage, not code: the journey's acceptance criteria and its risk items in the register, each exercised by at least one case | 100% |
| **Business Logic** (Calculations, Rules) | Branch coverage of the code (CTFL v4.0 §4.3.2) | 80%+ |
| **Utilities & Helpers** | Statement coverage of the code (CTFL v4.0 §4.3.1) | 70%+ |
| **UI Layout / Pure Components** | Visual regression of the agreed screens; no code figure | As needed |

Each figure is a floor that triggers a look, not a target to reach. Below it, read the uncovered lines or criteria and decide whether they matter; a test written only to lift the number adds cost and no confidence. Follow the figure from build to build: a falling trend shows tests no longer keeping up with the code. No single figure is right for every project (Valente, *Engenharia de Software Moderna*, section 8.4).

### Mocking Principles Matrix

| ✅ DO Mock                     | ❌ DON'T Mock                 |
| ------------------------------ | ----------------------------- |
| External APIs (Stripe, Twilio) | The code under test           |
| Database calls (in Unit tests) | Simple, internal dependencies |
| Network latency/failures       | Pure, deterministic functions |

### Kinds of Test Double, and What Mocking Costs

A test double stands in for a real dependency during a test. The five kinds below are Gerard
Meszaros' vocabulary (*xUnit Test Patterns*, 2007), which Valente cites (*Engenharia de Software
Moderna*, section 8.6); the book itself uses "mock" for stubs too. Name the kind you mean, because it says
what the test checks:

| Kind | What it does | What the test checks | In Vitest |
| :--- | :----------- | :------------------- | :-------- |
| **Dummy** | Fills a parameter the code path never uses | Nothing about the dummy | Any placeholder, e.g. `{} as AuditLog` |
| **Stub** | Returns canned answers | The result or state the code produces from them | `vi.fn().mockReturnValue(...)`, `mockResolvedValue(...)` |
| **Fake** | A working, lightweight implementation | The result, as with a stub | A class with the same interface, e.g. a repository backed by a `Map` |
| **Mock** | Records the calls made to it, and the test verifies them | The interaction: which calls, with which arguments (interaction testing) | `expect(fn).toHaveBeenCalledWith(...)` on a `vi.fn()` |
| **Spy** | Records calls on a real or stubbed object | The interaction, while the real behaviour still runs unless stubbed | `vi.spyOn(object, "method")` |

What mocking costs:

- **It couples the test to how the code works.** A test that asserts on calls to a dependency
  breaks when the code is refactored to call it differently, even if the behaviour is unchanged
  (Valente, section 8.6). When the call itself is not the behaviour, use a stub or a fake and assert on
  the result; verify calls when the call is the point, such as a payment requested or a message
  sent.
- **A double can disagree with the real dependency.** A stub returns what its author believed the
  dependency returns. If that belief is wrong, the unit test passes and the defect appears only
  when the real parts meet. Give every mocked boundary at least one test against the real thing: a
  component integration test, or a contract test.
- **Some code cannot take a double without a design change.** A dependency created inside the
  function, a module-level singleton, or a direct call to `Date.now()` or `Math.random()` can be
  replaced only by mocking the whole module (`vi.mock`, which is hoisted; see "Mocking an External
  SDK" in the `qa-reference` skill's `references/vitest-patterns.md`), or not at all. The book notes the same limit for the
  Java constructs its mocking framework cannot replace (section 8.6). Report it as a testability finding
  under the `qa-engineer` agent's Testability gate: inject the dependency instead.

```typescript
import { expect, it, vi } from "vitest";

interface RateSource { rateFor(currency: string): Promise<number> }
interface Mailer { send(to: string, subject: string): Promise<void> }

const convert = async (amount: number, currency: string, rates: RateSource) =>
  amount * (await rates.rateFor(currency));

const remindOverdue = async (email: string, mailer: Mailer) =>
  mailer.send(email, "Your invoice is overdue");

// Stub: the rate is an input; the test checks the result, not how it was fetched
it("converts with the current rate @regression @unit @p2 @automated", async () => {
  const rates: RateSource = { rateFor: vi.fn().mockResolvedValue(5) };
  await expect(convert(10, "BRL", rates)).resolves.toBe(50);
});

// Mock: sending the reminder is the behaviour, so the test verifies the call
it("sends the overdue reminder @regression @unit @p1 @automated", async () => {
  const mailer: Mailer = { send: vi.fn().mockResolvedValue(undefined) };
  await remindOverdue("client@example.com", mailer);
  expect(mailer.send).toHaveBeenCalledWith("client@example.com", "Your invoice is overdue");
});
```

---

### Localhost Is a Dry Run, Never a Result

A run on a developer or tester machine answers one question per case: *is this test feasible, and what value should it produce?* That value becomes the **oracle** the shared environment is later compared against. A local pass signs nothing off: results are recorded only from the environment under test (see the `test-evidence` rule for evidence expectations).

---

## ISTQB Test Design Techniques

CTFL v4.0 sorts techniques into three families (§4.1):

- **Black-box** (specification-based): cases come from the specified behavior, not from the code, so they stay valid when the implementation changes and the behavior does not.
- **White-box** (structure-based): cases come from the internal structure, so they can be written only once the design or the code exists.
- **Experience-based**: cases come from the tester's knowledge and experience, and are only as good as that skill. They find defects the other two families miss, and complement them rather than replace them.

| Technique                         | Method                                                                                                                                  | Ideal Use Case                                    |
| :-------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------ |
| **Equivalence Partitioning (EP)** | Divide inputs into valid/invalid groups (CTFL §4.2.1)                                                                                   | Input text fields, dropdown selections            |
| **Boundary Value Analysis (BVA)** | 2-value: each boundary and its neighbour in the adjacent partition (min-1, min, max, max+1); 3-value adds min+1 and max-1 (CTFL §4.2.2) | Numeric inputs, date ranges, limits               |
| **Decision Table Testing**        | Map combinations of inputs to outputs (CTFL §4.2.3)                                                                                     | Complex business rules, logic matrices            |
| **State Transition Testing**      | Verify state changes based on triggers/events (CTFL §4.2.4)                                                                             | Authentication, shopping carts, wizards           |
| **Error Guessing**                | Leverage experience to target common mistakes (CTFL §4.4.1)                                                                             | Race conditions, stale closures, network dropouts |
| **Exploratory Testing**           | Session-based structured exploration (CTFL §4.4.2)                                                                                      | High-risk areas, UX validation, rapid discovery   |
| **Checklist-Based Testing**       | Design and run tests that cover the conditions on a checklist (CTFL §4.4.3); see "Checklist-Based Testing" below                        | Known weak spots, usability heuristics, NFRs      |

### Coverage Items: What 100% Means for Each Black-box Technique

A technique becomes measurable once its coverage items are named. For every row, coverage = items exercised / items identified, as a percentage.

| Technique | Coverage items | 100% coverage |
| :-------- | :------------- | :------------ |
| **EP** (§4.2.1) | The equivalence partitions, valid and invalid | Every partition exercised by at least one case. With several inputs, the simplest criterion is **Each Choice**: every partition of every input exercised at least once; it ignores combinations |
| **BVA** (§4.2.2) | 2-value: each boundary value and its closest neighbour in the adjacent partition. 3-value: each boundary value and both neighbours | Every identified item exercised |
| **Decision table** (§4.2.3) | The columns (rules) whose combination of conditions is feasible | Every feasible column exercised |
| **State transition** (§4.2.4) | Depends on the criterion: the states (all states), the single valid transitions (valid transitions, also called 0-switch), or every transition in the state table, valid and invalid (all transitions) | Every item of the chosen criterion exercised; invalid transitions are attempted |

**Decision tables** (§4.2.3). Conditions are marked `T` (true), `F` (false), `–` (irrelevant to the outcome) or `N/A` (infeasible for that rule); actions are marked `X` (occurs) or left blank (does not occur). A full table has a column for every combination of conditions. Delete the columns with infeasible combinations, and merge columns where a condition does not change the outcome. With many conditions the rules grow exponentially; use a minimized table or pick rules by risk.

**State transition** (§4.2.4). A test case is a sequence of events and usually covers several transitions. Choose the criterion by risk:

- **All states** is the weakest: it can be met without exercising every transition.
- **Valid transitions** is the most widely used and the usual minimum; full valid transitions coverage guarantees full all states coverage.
- **All transitions** exercises every valid transition and attempts every invalid one, and guarantees the other two. The syllabus names it the minimum for mission-critical and safety-critical software.
- **One invalid transition per test case**, so that one defect cannot hide another (defect masking).

### Checklist-Based Testing (CTFL v4.0 §4.4.3)

An experience-based technique: the tester designs, implements and runs tests that cover the test conditions on a checklist. The checklist comes from experience, from what matters to the user, or from knowing why and how software fails. It is dynamic testing of the running system; checklist-based reviewing in `/qa-static` is static testing of a work product.

- **One question per item**, checkable on its own and directly ("Does the error message name the field that failed?"). Items can refer to requirements, interface properties, quality characteristics or other test conditions, so a checklist serves functional and non-functional testing alike (usability heuristics are a common example).
- **Leave out** what a tool can check automatically, what belongs in entry or exit criteria, and anything too general to check.
- **Keep it short**, and keep it current through defect analysis: add an item when a new high-severity defect shows a gap, and retire items that stop finding anything once developers learn to avoid that error.
- **Detail sets repeatability.** Where no detailed test cases exist, a checklist gives guidance and some consistency. A high-level checklist lets each run vary: more coverage, less repeatability. Write items as specific as the repeatability you need.

---

## White-box Techniques and Code Coverage

CTFL v4.0 teaches two code-based white-box techniques (§4.3). Each counts its own coverage items, and coverage is the share of them that the tests exercise.

- **Statement testing** (§4.3.1): the coverage items are executable statements; coverage = statements exercised / executable statements. At 100%, every statement ran at least once, so a defective statement had its chance to fail. It still misses defects that depend on data (a division that fails only when the divisor is zero) and does not show that every decision outcome was taken.
- **Branch testing** (§4.3.2): a branch is a transfer of control between two nodes of the control-flow graph, either unconditional (straight-line code) or conditional (each outcome of an `if`, each outcome of a `switch`, the exit or continue decision of a loop). Coverage = branches exercised / all branches. 100% branch coverage implies 100% statement coverage, not the other way round. It can still miss a defect that shows only on one particular path through the code.
- **What white-box testing adds** (§4.3.3): it considers the whole implementation, so it finds defects even when the specification is vague, outdated or incomplete. It cannot find what was never built: a requirement nobody implemented leaves no code to cover. Black-box testing alone gives no measure of code coverage; white-box measures give an objective figure and show where more tests are needed.
- **Reading a coverage report**: Vitest (`npx vitest run --coverage`, with a coverage provider such as `@vitest/coverage-v8` installed) reports statements, branches, functions and lines in separate columns. For business logic, read the branch column: a file at 100% statements and 60% branches has decisions whose other outcome no test has taken.

---

## Level Tags and CTFL Test Levels

The level tags in the `testing-guidelines` rule map onto the CTFL v4.0 test levels (§2.2.1):

| Level tag | CTFL test level |
| :-------- | :-------------- |
| `@unit` | Component testing |
| `@integration` | Component integration testing (collaborating units; external systems mocked) |
| `@api`, `@e2e` | System testing or system integration testing |
| (none) | Acceptance testing, written through `/qa-bdd` (ATDD) |

`@manual` is an execution mode, not a level: a manual case still sits at one of the levels above.

### What Each Level Is For (CTFL v4.0 §2.2.1)

| CTFL test level | Focus | Usually done by (§1.5.3) |
| :-------------- | :---- | :----------------------- |
| Component (unit) | One component in isolation, with a test harness or unit test framework | Developers, in their own environment |
| Component integration | The interfaces and interactions between components; shaped by the integration strategy (bottom-up, top-down, big-bang) | Developers |
| System | The behavior and capabilities of the whole system: end-to-end functional tasks and non-functional characteristics, some of which (usability) are best tested on the complete system in a representative environment | A test team, often independent, against the system specification |
| System integration | The interfaces between the system and other systems or external services, in an environment close to the operational one | A test team |
| Acceptance | Validation: the system meets the users' business needs and is ready to deploy | Business representatives; ideally the intended users |

Five attributes tell one level from another, and defining each level by them keeps two levels from repeating the same testing: the **test object**, the **test objectives**, the **test basis**, the **defects and failures** it is expected to find, and the **approach and responsibilities**.

Acceptance testing takes several forms: user acceptance testing (UAT), operational, contractual and regulatory acceptance testing, and alpha and beta testing.

Levels organize test activities; they are not a sequence. They can overlap in time, and one development activity can span several levels (CTFL v4.0 §2.2).

### Test Types (CTFL v4.0 §2.2.2)

A test type groups test activities by what they evaluate. CTFL names four:

- **Functional testing**: what the system does. It checks functional completeness, correctness and appropriateness.
- **Non-functional testing**: how well the system behaves, against the quality characteristics below. Many non-functional tests reuse a functional test and add a constraint (the same search, finished within a time limit). Starting early, in reviews or component tests, is cheaper than finding a non-functional defect late; some characteristics need a dedicated environment, such as a usability lab.
- **Black-box testing**: tests derived from the specification, without reference to the internal structure; it checks behavior against the specification (the techniques under "ISTQB Test Design Techniques" above).
- **White-box testing**: tests derived from the implementation or internal structure (code, architecture, workflows, data flows); it aims to cover that structure to an acceptable level (see "White-box Techniques and Code Coverage" above).

The non-functional quality characteristics, as the syllabus lists them from ISO/IEC 25010, and where this package covers each:

| Characteristic | Covered in this package by |
| :------------- | :------------------------- |
| Performance efficiency | Not covered yet |
| Compatibility | Not covered yet |
| Usability (also called interaction capability) | Accessibility: the `accessibility-qa` rule and the `qa-reference` skill's `references/accessibility-checks.md`; exploratory usability checks: the `qa-explore` skill |
| Reliability | Not covered yet |
| Security | The `security-qa` rule and the `qa-reference` skill's `references/security-checks.md` |
| Maintainability | The testability review of the `qa-engineer` agent |
| Portability (also called flexibility) | Not covered yet |
| Safety | Not covered yet |

Every type applies at every level, with a different focus at each: a security test of one component and a security test of the deployed system are both security testing.

A type is neither a technique nor a level. "Functional" says what is evaluated; the technique (EP, decision table, ...) says how the cases were derived; the level says which test object is tested. A test case's **ISTQB Technique** field takes a technique; record the type, when it matters, in its **Note**.

---

## Field Heuristics

Short rules for running tests against a live, shared environment:

- **Always test the positive half too.** A guard that refuses everything passes every negative test while being badly broken.
- **Capture irreversible states first.** Some evidence windows close permanently, for example a value that reads wrong only until a later operation applies.
- **Confirm what an environment runs from its deployment record, not its branch name.** A branch called `staging` may track the release line rather than the staging environment. Treat *deployed state* as a source distinct from the repository.
- **A change to shared state during testing is a write.** Announce it, record the original state and the time, and restore it afterwards.

Runbook and exploratory heuristics live in the `qa-explore` skill; recording pace is covered in the `qa-reference` skill's `references/evidence-capture.md`.

---

## CI/CD Pipeline & Filtering Reference

### Playwright `--grep` Command Syntax

```bash
# Execute Smoke Suite
npx playwright test --grep @smoke

# Intersection (AND): Run Smoke tests that are P0
npx playwright test --grep "(?=.*@smoke)(?=.*@p0)"

# Union (OR): Run Smoke or Sanity tests
npx playwright test --grep "@smoke|@sanity"

# Exclude Tag: Run Regression but exclude slow tests
npx playwright test --grep @regression --grep-invert @slow
```

### Vitest `testNamePattern` Syntax

```bash
# Filter by tag in Vitest
npx vitest run --testNamePattern="@smoke"
```
