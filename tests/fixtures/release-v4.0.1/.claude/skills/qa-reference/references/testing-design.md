# Test Design Reference

> **Read on demand** | Moved from `.claude/rules/testing-guidelines.md` | Part of the `qa-reference` skill

Read this before choosing test levels, coverage targets or test design techniques, before running tests against a shared environment, and before writing CI/CD tag filters. The always-on core (principles, defect chain, tagging taxonomy, failure protocol, Definition of Done) stays in `.claude/rules/testing-guidelines.md`.

---

## The Adaptive Test Pyramid

Adapt the distribution of tests based on where the core business logic resides:

- **Backend / API / Microservices Heavy**: 70% Unit · 20% Integration · 10% E2E
- **Full-Stack Web App (React + REST API)**: 40% Unit · 40% Integration · 20% E2E
- **UI-Heavy / Interactive Canvas / Mapping**: 20% Unit · 30% Integration · 50% E2E
- **Data Pipeline / ETL Systems**: 60% Unit · 35% Integration · 5% E2E

> **Key Directive**: Push tests to the lowest level that can cover the logic cheaply, quickly, and reliably.

### Coverage Strategy Targets

Coverage is a guide, not a goal, but baseline standards must be enforced:

| Area | Target Coverage |
| ------ | ----------------- |
| **Critical Paths** (Login, Checkout) | 100% |
| **Business Logic** (Calculations, Rules) | 80%+ |
| **Utilities & Helpers** | 70%+ |
| **UI Layout / Pure Components** | As needed (Visual Regression preferred) |

### Mocking Principles Matrix

| ✅ DO Mock                     | ❌ DON'T Mock                 |
| ------------------------------ | ----------------------------- |
| External APIs (Stripe, Twilio) | The code under test           |
| Database calls (in Unit tests) | Simple, internal dependencies |
| Network latency/failures       | Pure, deterministic functions |

---

### Localhost Is a Dry Run, Never a Result

A run on a developer or tester machine answers one question per case: *is this test feasible, and what value should it produce?* That value becomes the **oracle** the shared environment is later compared against. A local pass signs nothing off: results are recorded only from the environment under test (see `.claude/rules/test-evidence.md` for evidence expectations).

---

## ISTQB Test Design Techniques

| Technique                         | Method                                                                                                                                  | Ideal Use Case                                    |
| :-------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------ |
| **Equivalence Partitioning (EP)** | Divide inputs into valid/invalid groups                                                                                                 | Input text fields, dropdown selections            |
| **Boundary Value Analysis (BVA)** | 2-value: each boundary and its neighbour in the adjacent partition (min-1, min, max, max+1); 3-value adds min+1 and max-1 (CTFL §4.2.2) | Numeric inputs, date ranges, limits               |
| **Decision Table Testing**        | Map combinations of inputs to outputs                                                                                                   | Complex business rules, logic matrices            |
| **State Transition Testing**      | Verify state changes based on triggers/events                                                                                           | Authentication, shopping carts, wizards           |
| **Error Guessing**                | Leverage experience to target common mistakes                                                                                           | Race conditions, stale closures, network dropouts |
| **Exploratory Testing**           | Session-based structured exploration                                                                                                    | High-risk areas, UX validation, rapid discovery   |

---

## Level Tags and CTFL Test Levels

The level tags in `.claude/rules/testing-guidelines.md` map onto the CTFL v4.0 test levels (§2.2.1):

| Level tag | CTFL test level |
| :-------- | :-------------- |
| `@unit` | Component testing |
| `@integration` | Component integration testing (collaborating units; external systems mocked) |
| `@api`, `@e2e` | System testing or system integration testing |
| (none) | Acceptance testing, written through `/qa-bdd` (ATDD) |

`@manual` is an execution mode, not a level: a manual case still sits at one of the levels above.

---

## Field Heuristics

Short rules for running tests against a live, shared environment:

- **Always test the positive half too.** A guard that refuses everything passes every negative test while being badly broken.
- **Capture irreversible states first.** Some evidence windows close permanently, for example a value that reads wrong only until a later operation applies.
- **Confirm what an environment runs from its deployment record, not its branch name.** A branch called `staging` may track the release line rather than the staging environment. Treat *deployed state* as a source distinct from the repository.
- **A change to shared state during testing is a write.** Announce it, record the original state and the time, and restore it afterwards.

Run-sheet and exploratory heuristics live in the `qa-explore` skill; recording pace is covered in `.claude/skills/qa-reference/references/evidence-capture.md`.

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
