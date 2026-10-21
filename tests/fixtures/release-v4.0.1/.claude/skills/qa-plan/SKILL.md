---
name: qa-plan
description: "Builds test strategies, test plans and risk registers (5x5 likelihood x impact) with estimation, entry and exit criteria, a release gate, and monitoring, per ISTQB CTFL v4.0 chapter 5. Use when asked for a test plan, QA strategy, risk assessment, test estimate or release criteria."
---
# Skill: Test Strategy, Planning & Risk Assessment

> **Senior QA Analyst** | ISTQB CTFL v4.0 (Chapter 5) | Test Planning & Risk Register Workflow

This skill is automatically activated when tasks involve creating test plans, designing test strategies, performing risk assessments, or setting up quality gates.

---

## 🎯 Task Activation Patterns

This skill matches tasks containing:

- `test plan`, `test strategy`, `risk register`, `entry criteria`, `exit criteria`
- `test pyramid design`, `traceability matrix`, `quality gates`
- `risk-based testing`, `test estimation`, `test effort`

---

## 📖 Test Strategy & Planning Workflow

### Step 1: Establish Project Parameters

Obtain or define the baseline project metadata:

- Project Name, Version, Owner, board URL (GitHub/ADO/JIRA).
- Tech stack and hosting environments (Local, Dev, Staging, Production).

### Step 2: Scope Delineation

Clearly divide the application into:

- **In Scope**: Feature areas, user story IDs, test levels, and business priority.
- **Out of Scope**: Specifically state what is excluded (and why) to manage expectations and timeline limits.

### Step 3: Core Strategy (The Adaptive Test Pyramid)

Define the test distribution using the "One Diagnostic Question":

> **"Where does the business logic live?"**

Select the matching architectural preset:

1. **Backend / API / Microservices**: 70% Unit · 20% Integration · 10% E2E
2. **Full-stack web app (React + API)**: 40% Unit · 40% Integration · 20% E2E
3. **UI-heavy / Canvas / GIS / Mapping**: 20% Unit · 30% Integration · 50% E2E
4. **Data pipeline / ETL**: 60% Unit · 35% Integration · 5% E2E

### Step 4: Estimate the Test Effort

An estimate is a prediction built on assumptions and is always subject to error (CTFL v4.0 §5.1.4). State the assumptions next to the number, and say which technique produced it. Estimating a small task is usually more accurate than estimating a large one, so decompose large work into smaller tasks and estimate those (CTFL v4.0 §5.1.4).

- **Estimation by ratios** (metrics-based): apply a ratio taken from earlier projects of the same organization, e.g. a development-to-test effort ratio of 3:2 (CTFL v4.0 §5.1.4). Fits when historical data exists for a similar project.
- **Extrapolation** (metrics-based): measure early in the current project, then extend the data, e.g. the average effort of the last three iterations (CTFL v4.0 §5.1.4). Fits iterative delivery with several finished iterations.
- **Wideband Delphi** (expert-based): experts estimate in isolation, discuss estimates that deviate beyond agreed bounds, then re-estimate until they converge; Planning Poker is a variant (CTFL v4.0 §5.1.4). Fits new work with no history, when a group can discuss.
- **Three-point estimation** (expert-based): optimistic (a), most likely (m) and pessimistic (b) estimates give E = (a + 4m + b) / 6 and SD = (b − a) / 6 (CTFL v4.0 §5.1.4). Fits when one estimator is available and the margin of error must be shown.

Worked example (CTFL v4.0 §5.1.4): a = 6, m = 9, b = 18 person-hours gives E = 10 and SD = 2, reported as "10 ± 2 person-hours (between 8 and 12)".

Report the estimate as a range with its assumptions, not as a single figure. When the plan carries a risk register, the risk level of each item also feeds the effort assigned to it (see Risk-Based Testing below).

---

## 📊 Risk-Based Testing: The Risk Register Blueprint (5×5 Matrix)

This register is the package's **risk-based testing** mechanism: the test approach in which test activities are selected, prioritized and managed on the basis of risk analysis and risk control (CTFL v4.0 §5.2). A risk is characterized by its likelihood and its impact, and the two together give the risk level (CTFL v4.0 §5.2.1). The higher the level, the more important its treatment.

The risk level drives the plan (CTFL v4.0 §5.2.3):

- **Depth and scope**: which items are tested and how deeply, and which test levels and types apply.
- **Technique and coverage**: stronger techniques and higher coverage for higher levels (e.g. decision tables and state transition for a CRITICAL rule; happy path plus exploratory for a LOW one).
- **Effort**: more effort goes to tasks with a higher risk level (estimate it in Step 4).
- **Order**: test the highest levels first, so critical defects surface as early as possible.
- **Non-test measures**: where testing alone does not reduce a risk, say what else would (a review, a feature flag, a rollback plan).

Distinguish the two kinds of risk (CTFL v4.0 §5.2.2). **Product risks** concern the quality of the product (wrong calculation, security hole, poor response time). **Project risks** concern managing the project (late delivery, missing skills, tool problems, inaccurate estimates). Mark each register row with its Category.

Classify risks based on **Likelihood (1–5)** and **Impact (1–5)**:

- **Score = Likelihood × Impact**

| Score     | Severity Level | Action Required                                                  |
| :-------- | :------------- | :--------------------------------------------------------------- |
| **15–25** | 🔴 CRITICAL    | Test first, absolute automated coverage, regular reviews         |
| **8–14**  | 🟠 HIGH        | Prioritize in test cycles, automate in Regression, track metrics |
| **4–7**   | 🟡 MEDIUM      | Standard functional coverage, run on Sprint deployments          |
| **1–3**   | 🟢 LOW         | Basic happy-path coverage, exploratory checks only               |

### Risk Register Schema

```markdown
| #   | ID  | Risk Description                            | Category | L   | I   | Score | Level       | Mitigation Strategy                       | Owner  |
| --- | --- | ------------------------------------------- | -------- | --- | --- | ----- | ----------- | ----------------------------------------- | ------ |
| 1   | R01 | Authentication session drops during editing | Product  | 3   | 5   | 15    | 🔴 CRITICAL | LocalStorage state persistence + E2E test | Dev/QA |
```

Risk control follows the analysis (CTFL v4.0 §5.2.4): **mitigation** carries out the actions that reduce the level, and **monitoring** checks that those actions work, gathers information to improve the assessment, and spots emerging risks. Responses are not only more testing: a risk can also be accepted, transferred, or covered by a contingency plan. Review the register at every progress report (see Test Monitoring and Control below) and re-score a row when its facts change.

---

## 🚪 Quality Gates (Entry & Exit Criteria)

Entry criteria are the preconditions for starting an activity; exit criteria define what must be achieved to declare it complete. Define both for each test level, as they differ with the test objectives (CTFL v4.0 §5.1.3). Running out of time or budget can also end testing, but only when stakeholders have reviewed and accepted the risk of going live without further testing (CTFL v4.0 §5.1.3).

### The Release Gate: Separate from the Analysis

Every change gets one **release gate**: the smallest set of cases that answers two questions, "do the fixes work?" and "did the change break anything that already worked?". It is usually 5 to 8 cases. The exit criteria below are measured against this set.

- **Build it from risk**: take the cases that cover the changed behavior, plus the neighboring behavior with the highest risk level in the register. A case belongs in the gate only if its failure would stop the release.
- **Show it as one table**: gate cases listed together (ID, what it proves, result), so a reviewer sees in one place what has to pass. Keep it apart from the longer list of analysis cases.
- **The broader analysis is still written down**: exploratory findings, edge cases and extra scenarios are where defects are found, and they are recorded. They do not gate the change.
- **Findings the change did not cause never gate it.** Log each one as its own ticket (see `/qa-defect`) and link it from the plan. A defect that existed before the change stays out of the gate's pass/fail.
- **A failed gate case blocks; a failed analysis case informs.** If an analysis finding turns out to be caused by the change, move its case into the gate and say so in the plan, with the date.

### 1. Entry Criteria for System-Level Test Execution (When to START Testing)

Test analysis, reviews and test design start earlier, at refinement (`/qa-static`, `/qa-bdd`).

- [ ] Feature is fully implemented and state is "Ready for QA" (ADO/JIRA)
- [ ] Code is compiled, built, and merged with zero compilation/linting errors
- [ ] Environment is successfully deployed and accessible
- [ ] Required test data is seeded or generator scripts are ready
- [ ] Target elements have explicit `data-testid` properties per code style rules

### 2. Standard Exit Criteria (When to STOP Testing & Release)

- [ ] Every release gate case executed and passing
- [ ] 100% of P0 test cases executed and passing
- [ ] 100% of P1 test cases executed and passing, or each failure has a recorded Product Owner exception
- [ ] Zero open Critical-severity defects
- [ ] Zero open High-severity defects (or recorded Product Owner exceptions)
- [ ] Smoke regression suite passes on all supported target browsers
- [ ] Test summary signed off by QA Lead and Product Owner

---

## 📈 Test Monitoring, Control & Completion

Monitoring gathers information about testing to judge progress and whether the exit criteria, or the tasks tied to them, are met. Control uses that information to issue corrective directives. Completion collects the experience and testware when a test level, iteration, project or release ends (CTFL v4.0 §5.3).

### Monitor: Choose Metrics Up Front

Name the metrics in the plan so progress can be judged against something (CTFL v4.0 §5.3.1). Pick a few that answer a decision; do not collect all of them.

- **Test progress**: cases implemented, run / not run, passed / failed, execution time.
- **Defect**: defects found and fixed by priority, defect density, defect detection percentage.
- **Coverage**: requirements coverage, risk coverage, code coverage where available.
- **Risk**: residual risk level, taken from the register.
- **Project and cost**: task completion, resource usage, test effort against the estimate from Step 4.

### Control: Directives Follow from the Numbers

When monitoring shows a deviation, record the directive and its reason (CTFL v4.0 §5.3). Examples from the syllabus:

- Reprioritize tests when an identified risk becomes an issue.
- Re-evaluate whether a test item meets entry or exit criteria after rework.
- Adjust the schedule to a delayed test environment.
- Add resources where needed.

### Report: Match the Report to the Audience

- **Progress report**: supports ongoing control and is issued regularly (daily, weekly). Typical content: testing period, progress against plan with notable deviations, impediments and workarounds, metrics, new and changed risks, testing planned for the next period (CTFL v4.0 §5.3.2).
- **Completion report**: summarizes a finished test level, cycle, iteration or project. Typical content: test summary, evaluation against the plan's objectives and exit criteria, deviations from plan, impediments and workarounds, metrics, unmitigated risks and defects not fixed, lessons learned (CTFL v4.0 §5.3.2).

**Report every case's outcome, one case per row.** A completion report that gives totals and names only the failures hides what was never looked at. List each case with its outcome (pass, fail, blocked, not run, verified by a developer, dropped), what it proves, and where it was checked (environment and build). End with a **"Not run — resume point"** section: for each case not run, blocked or dropped, what is needed and where to pick it up. The results page title repeats the ticket's summary verbatim, so the tracker and the documentation stay traceable. Call a test "automated" only when it is a test in the team's automation suite; a script QA wrote to drive one run is a scripted run. `/qa-cases` has the row format.

Reporting inside the team is frequent and informal; completion reporting follows a template and happens once (CTFL v4.0 §5.3.2). Status can be communicated verbally, on dashboards, by chat or email, in online documentation, or in formal reports, and different stakeholders need different content (CTFL v4.0 §5.3.3).

### Complete: Close the Loop

At each milestone (test level done, iteration finished, release shipped) the completion activities consolidate what was learned: finalize the completion report, record unmitigated risks and defects not fixed, and keep the testware that the next cycle will reuse (CTFL v4.0 §5.3).

---

## 🧱 Suite-Level Artifacts

Beyond the documents of one ticket, a suite that lives longer than a release keeps these as deliverables. Each is one living document, filterable by suite, that carries the same fields in every row (`N/A: <why>` when empty, as above):

- **Master test plan**: the plan fields above, for the product rather than for one change; ticket plans link to it and state only their deviations.
- **Risk register**: one register for the suite, re-scored when facts change (see the register schema above); ticket-level risks roll up into it.
- **Tagging standard**: the suite, level, priority, automation status and feature tags in use, with the one meaning each has here.
- **Traceability matrix**: requirement or ticket to test cases to latest result, in both directions, so an uncovered requirement and an orphan case are both visible (CTFL v4.0 §1.4.4).
- **Status matrix**: for each ticket or feature, the outcome counts per suite and the date and build they were obtained on, plus the next resume point.

Build these from the tracker's current state, not from memory of what was tested.

---

## 🧪 Test Data as a Documented Fixture Set

Tests that share an environment depend on records that other people can change. Keep one **fixture set** document, so a test starts from known data and does not disturb shared state:

- **Which records exist**: an identifier and a one-line description for each (never credentials; point to where those are kept).
- **What state each is in**: the state the tests assume, and the state a test must leave it in.
- **What may be changed**: records a test may write to, records it must only read, and records that are off limits. A change to shared state is a write: log it and restore it.
- **How to rebuild**: how to recreate a record that was damaged, or a note that nobody can.

A case's **Precondition** names the fixture it needs. When a fixture is missing or in the wrong state, the case is blocked, not failed.

---

## 🤝 Handover-Ready State

Keep the work in a state someone else could pick up today: an index of what exists, the current status of each item, and a resume point for everything unfinished.

---

## 🗂️ Configuration Management for Testware

Configuration management (CM) identifies, controls and tracks work products such as test plans, test strategies, test conditions, test cases, scripts, results, logs and reports as configuration items (CTFL v4.0 §5.4). State in the plan how this is done:

- [ ] Every configuration item, including each test item (an individual part of the test object), is uniquely identified, version controlled, tracked for change, and linked to related items so traceability holds through the test process.
- [ ] Testware refers to documentation and software items unambiguously, by identifier and version, never "the latest build".
- [ ] A complex item such as a test environment records its components, their relationships and versions. Once approved for testing it becomes a baseline, changed only through a change control process.
- [ ] A previous baseline can be restored, so earlier test results can be reproduced.
- [ ] In a CI/CD pipeline, CM is normally automated as part of the pipeline.

Practical check: every result in the plan or report names the build and environment version it was obtained on. A result without that is not reproducible.

---

## 📝 Test Plan Output: Every Field Appears

A test plan describes the test objectives, resources and processes for a test project (CTFL v4.0 §5.1.1). Produce it with every field below, in this order, unless the target repository already has a plan template: in that case its template owns field names and order, and this list only checks that nothing is missing.

1. Context of testing: scope, objectives, test basis
2. Assumptions and constraints
3. Stakeholders: roles, responsibilities, relevance to testing
4. Communication: forms and frequency, document templates
5. Risk register: product and project risks
6. Test approach: levels, types, techniques, deliverables, entry and exit criteria, release gate, independence of testing, metrics to collect, test data and environment requirements, deviations from the test policy and strategy
7. Estimate: technique used, figure with its range, assumptions
8. Budget and schedule
9. Configuration management of testware

(Items 1 to 6 and 8 are the typical content in CTFL v4.0 §5.1.1; items 7 and 9 come from §5.1.4 and §5.4.)

**A field with nothing to put in it stays in the plan.** Write `N/A` or `N/A: <why>` (for example "N/A: no external suppliers, all components are in-house"). A field silently missing from a generated plan is a defect in the plan, not a shortcut, because the reader cannot tell "considered and empty" from "forgotten". Apply the same rule to every row of the risk register schema and to every column of the release gate table.

### Corrections: Correct, Don't Delete

Nothing found wrong in a plan that has already been shared is deleted. Correct it in place in one of two ways:

- **A dated, attributed correction note** next to the original: `Correction, YYYY-MM-DD, <author or agent>: <what was wrong and what is right>`.
- **Strike-through with a reason**: `~~original text~~ (superseded YYYY-MM-DD: <why>)`.

This applies to risk scores that are re-assessed, estimates that are revised, gate cases that move in or out of the gate, and criteria that are changed. The history of what was believed and when is part of the plan: it is what lets a later reader audit a decision. Before the plan is first shared, ordinary editing is fine.
