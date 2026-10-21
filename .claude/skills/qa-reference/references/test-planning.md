---
id: ref-test-planning
---
# Test Planning Reference

> **Read on demand** | Detail behind the `qa-plan` skill | Part of the `qa-reference` skill

Read the section the plan has reached: the testing quadrants before writing the test approach, the estimation techniques before estimating the test effort,
the execution orderings before writing the order under the release gate, the suite-level artifacts
before building a document that outlives one release, roles and independence before filling item
6 of the test plan, and the configuration management checklist before filling item 9. The plan's fields, the risk register and the quality gates are in the `qa-plan`
skill; when this file and the skill seem to disagree, the skill wins.

---

## Testing Quadrants (CTFL v4.0 §5.1.7)

The pyramid sets proportions; the testing quadrants (Brian Marick's model) check that no kind of testing is missing. They cross two viewpoints: a test is **business facing** or **technology facing**, and it either **supports the team** (guides development) or **critiques the product** (measures its behavior against expectations). The model also relates test types to test levels, since some types matter more at certain levels.

| Quadrant | Viewpoints | Typical content | In this package |
| :------- | :--------- | :-------------- | :-------------- |
| Q1 | Technology facing, supports the team | Component and component integration tests, automated and run in CI | `@unit`, `@integration`; `/qa-tdd` |
| Q2 | Business facing, supports the team | Functional tests, examples, user story tests, user experience prototypes, API testing, simulations; they check the acceptance criteria, manually or automated | `/qa-bdd`, `/qa-cases`, `@api` |
| Q3 | Business facing, critiques the product | Exploratory testing, usability testing, user acceptance testing; user-oriented and often manual | The `qa-explore` skill; accessibility checks (part of usability); acceptance testing |
| Q4 | Technology facing, critiques the product | Smoke tests and non-functional tests other than usability; often automated | `@smoke`; security (the `security-qa` rule); performance: not covered yet |

A plan with nothing in one quadrant says why, in its test approach (item 6 of the test plan in the `qa-plan` skill).

---

## Estimation Techniques (CTFL v4.0 §5.1.4)

An estimate is a prediction built on assumptions and is always subject to error (CTFL v4.0 §5.1.4). State the assumptions next to the number, and say which technique produced it. Estimating a small task is usually more accurate than estimating a large one, so decompose large work into smaller tasks and estimate those (CTFL v4.0 §5.1.4).

- **Estimation by ratios** (metrics-based): apply a ratio taken from earlier projects of the same organization, e.g. a development-to-test effort ratio of 3:2 (CTFL v4.0 §5.1.4). Fits when historical data exists for a similar project.
- **Extrapolation** (metrics-based): measure early in the current project, then extend the data, e.g. the average effort of the last three iterations (CTFL v4.0 §5.1.4). Fits iterative delivery with several finished iterations.
- **Wideband Delphi** (expert-based): experts estimate in isolation, discuss estimates that deviate beyond agreed bounds, then re-estimate until they converge; Planning Poker is a variant (CTFL v4.0 §5.1.4). Fits new work with no history, when a group can discuss.
- **Three-point estimation** (expert-based): optimistic (a), most likely (m) and pessimistic (b) estimates give E = (a + 4m + b) / 6 and SD = (b − a) / 6 (CTFL v4.0 §5.1.4). Fits when one estimator is available and the margin of error must be shown.

Worked example (CTFL v4.0 §5.1.4): a = 6, m = 9, b = 18 person-hours gives E = 10 and SD = 2, reported as "10 ± 2 person-hours (between 8 and 12)".

Report the estimate as a range with its assumptions, not as a single figure. When the plan carries a risk register, the risk level of each item also feeds the effort assigned to it (see Risk-Based Testing in the `qa-plan` skill).

---

## Test Execution Order (CTFL v4.0 §5.1.5)

Once the cases are grouped into suites, a test execution schedule fixes the order they run in. Risk is one way to set it; the syllabus names three. Say in the plan which one each suite uses.

- **Risk-based**: the cases covering the most important risks run first, in the order the register gives. The default for the release gate, which is built from risk.
- **Coverage-based**: the cases achieving the highest coverage (statement coverage, for example) run first. In the **additional coverage** variant, the case with the highest coverage runs first, and each next case is the one adding the most coverage not yet achieved. Useful for a long regression run that may be cut short.
- **Requirements-based**: the cases run in the order of the priorities stakeholders gave to the requirements they trace to. Useful when the requirements are ranked and the risk analysis is thin.

Two things override the priority order:

- **Dependencies**: when a higher-priority case depends on a lower-priority one (it needs the record the other creates), the lower-priority case runs first.
- **Resources**: a tool, test environment or person available only in a given time window fixes when the cases that need it can run.

Write the resulting order as a numbered list under the release gate table, with the reason wherever a dependency or a resource window moved a case.

---

## Suite-Level Artifacts

Beyond the documents of one ticket, a suite that lives longer than a release keeps these as deliverables. Each is one living document, filterable by suite, that carries the same fields in every row (`N/A — <why>` when empty, as the `qa-reference` skill's `references/written-records.md` spells it):

- **Master test plan**: the plan fields of the `qa-plan` skill, for the product rather than for one change; ticket plans link to it and state only their deviations.
- **Risk register**: one register for the suite, re-scored when facts change (see the register schema in the `qa-plan` skill); ticket-level risks roll up into it.
- **Tagging standard**: the suite, level, priority, automation status and feature tags in use, with the one meaning each has here.
- **Traceability matrix**: requirement or ticket to test cases to latest result, in both directions, so an uncovered requirement and an orphan case are both visible (CTFL v4.0 §1.4.4).
- **Status matrix**: for each ticket or feature, the outcome counts per suite and the date and build they were obtained on, plus the next resume point.

Build these from the tracker's current state, not from memory of what was tested.

---

## Roles and Independence (CTFL v4.0 §1.4.5, §1.5.3)

Two roles share the testing work. The **test management role** owns the test process, the test team and the leadership of the test activities, mainly planning, monitoring and control, and completion. The **testing role** owns the engineering side: test analysis, design, implementation and execution. They are roles, not job titles: a team leader, a test manager or a development manager can hold the first, an Agile team may take on part of it, and one person can hold both at once.

Independence is a matter of degree, set by who tests the work product:

| Degree | Who tests |
| :----- | :-------- |
| None | The author |
| Some | A peer from the author's team |
| High | Testers from outside the author's team, within the organization |
| Very high | Testers from outside the organization |

Most projects mix degrees across levels: for example, developers at component and component integration level, a test team at system and system integration level, business representatives at acceptance.

- **What independence brings**: testers with a different background, technical perspective and biases recognize failures the author would not, and can challenge the assumptions made in the specification and the implementation.
- **What it can cost**: isolation from the development team (less collaboration, communication problems, an adversarial relationship), developers losing their sense of responsibility for quality, and testers seen as a bottleneck or blamed for late releases.
- **It does not replace familiarity**: developers find many defects in their own code efficiently. Where the whole-team approach applies, everyone is responsible for quality, yet safety-critical work may still need a high degree of independence (CTFL v4.0 §1.5.2).

In item 6, state for each test level who tests, at which degree of independence, and why that degree fits the risk.

---

## Configuration Management for Testware

Configuration management (CM) identifies, controls and tracks work products such as test plans, test strategies, test conditions, test cases, scripts, results, logs and reports as configuration items (CTFL v4.0 §5.4). State in the plan how this is done:

- [ ] Every configuration item, including each test item (an individual part of the test object), is uniquely identified, version controlled, tracked for change, and linked to related items so traceability holds through the test process.
- [ ] Testware refers to documentation and software items unambiguously, by identifier and version, never "the latest build".
- [ ] A complex item such as a test environment records its components, their relationships and versions. Once approved for testing it becomes a baseline, changed only through a change control process.
- [ ] A previous baseline can be restored, so earlier test results can be reproduced.
- [ ] In a CI/CD pipeline, CM is normally automated as part of the pipeline.

Practical check: every result in the plan or report names the build and environment version it was obtained on. A result without that is not reproducible.
