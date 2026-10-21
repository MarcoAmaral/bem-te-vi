---
id: ref-test-reporting
---
# Test Monitoring and Reporting Reference

> **Read on demand** | Detail behind the `qa-plan` skill and `/qa-cases` | Part of the `qa-reference` skill

Read this before choosing the metrics a plan names, recording a control directive, writing a progress
or completion report or any other report of test results, closing a milestone, or running a
retrospective.

Monitoring gathers information about testing to judge progress and whether the exit criteria, or the tasks tied to them, are met. Control uses that information to issue corrective directives. Completion collects the experience and testware when a test level, iteration, project or release ends (CTFL v4.0 §5.3).

## Monitor: Choose Metrics Up Front

Name the metrics in the plan so progress can be judged against something (CTFL v4.0 §5.3.1). Pick a few that answer a decision; do not collect all of them.

- **Test progress**: cases implemented, run / not run, passed / failed, execution time.
- **Defect**: defects found and fixed by priority, defect density, defect detection percentage.
- **Coverage**: requirements coverage, risk coverage, code coverage where available.
- **Risk**: residual risk level, taken from the register.
- **Project and cost**: task completion, resource usage, test effort against the estimate from Step 4 of the `qa-plan` skill.

## Control: Directives Follow from the Numbers

When monitoring shows a deviation, record the directive and its reason (CTFL v4.0 §5.3). Examples from the syllabus:

- Reprioritize tests when an identified risk becomes an issue.
- Re-evaluate whether a test item meets entry or exit criteria after rework.
- Adjust the schedule to a delayed test environment.
- Add resources where needed.

## Report: Match the Report to the Audience

- **Progress report**: supports ongoing control and is issued regularly (daily, weekly). Typical content: testing period, progress against plan with notable deviations, impediments and workarounds, metrics, new and changed risks, testing planned for the next period (CTFL v4.0 §5.3.2).
- **Completion report**: summarizes a finished test level, cycle, iteration or project. Typical content: test summary, evaluation against the plan's objectives and exit criteria, deviations from plan, impediments and workarounds, metrics, unmitigated risks and defects not fixed, lessons learned (CTFL v4.0 §5.3.2).

**Report every case's outcome, one case per row.** A completion report that gives totals and names only the failures hides what was never looked at. List each case with its outcome (pass, fail, blocked, not run, verified by a developer, dropped), what it proves, and where it was checked (environment and build). End with a **"Not run — resume point"** section: for each case not run, blocked or dropped, what is needed and where to pick it up. The results page title repeats the ticket's summary verbatim, so the tracker and the documentation stay traceable. Call a test "automated" only when it is a test in the team's automation suite; a script QA wrote to drive one run is a scripted run. The row format is in "Reporting Every Case" below.

Reporting inside the team is frequent and informal; completion reporting follows a template and happens once (CTFL v4.0 §5.3.2). Status can be communicated verbally, on dashboards, by chat or email, in online documentation, or in formal reports, and different stakeholders need different content (CTFL v4.0 §5.3.3).

## Complete: Close the Loop

At each milestone (test level done, iteration finished, release shipped) the completion activities consolidate what was learned: finalize the completion report, record unmitigated risks and defects not fixed, and keep the testware that the next cycle will reuse (CTFL v4.0 §5.3).

## Retrospectives: Turn the Lessons into Changes (CTFL v4.0 §2.1.6)

A retrospective is where the team looks back and decides what to change. It is held at the end of a project or an iteration, at a release milestone, or whenever it is needed; when and how depends on the SDLC model the team follows (CTFL v4.0 §2.1.6). It is a whole-team meeting, not a QA one: testers sit with developers, architects, the product owner and business analysts, and the meeting answers three questions:

1. What worked and should be kept?
2. What did not work and could be improved?
3. How will the improvements, and the successes, be carried into the next cycle?

Record the outcome; it normally goes into the completion report's lessons learned (CTFL v4.0 §5.3.2). Retrospectives are what continuous improvement rests on, and the syllabus stresses following up every improvement they recommend (§2.1.6).

What testing gains (§2.1.6): more effective and efficient testing, from acting on the suggested process improvements; better testware, from reviewing the test process together; team bonding and learning; a better test basis, when gaps in the extent and quality of the requirements are raised and fixed; and better cooperation between development and testing, because the collaboration itself is reviewed regularly.

Not ISTQB content, this package's practice for the tester's part:

- **Bring evidence, not impressions**: the monitoring metrics chosen above, defects found late or after release and where they could have been caught, cases blocked and why, tests quarantined as flaky, and gaps between the test basis and what was built.
- **Write each improvement as an action** with an owner and a date to check it, and open the next retrospective with last time's list.

---

## Reporting Every Case

When results are reported (a results page, a completion report, a ticket comment), list **every case, one per row**. A summary count with only the failures named hides what was never looked at.

```markdown
# [Ticket summary, copied verbatim]

| TC            | Outcome                                                              | What it proves                         | Where it was checked  |
| ------------- | -------------------------------------------------------------------- | -------------------------------------- | --------------------- |
| TC-AUTH-001   | Pass                                                                 | Sign-in overlay blocks the app         | Staging, build 4.2.1  |
| TC-AUTH-002   | Fail (DEF-31)                                                        | Valid credentials load the app         | Staging, build 4.2.1  |
| TC-AUTH-003   | Not run                                                              | Invalid credentials are rejected       | N/A — no test account |

## Not run — resume point

- TC-AUTH-003: needs a test account with an expired password. Ask for one, then run from step 1.
```

- **Outcome** is one of: pass, fail, blocked, not run, verified by a developer, dropped. Say why for every outcome except pass, and link the defect for a fail.
- **What it proves** is the behavior the case establishes, not its title repeated.
- **Where it was checked**: environment and build or version. A result without them cannot be reproduced.
- **Not run — resume point**: every case that is not run, blocked or dropped gets a line saying what is needed and where to pick it up, so someone else can continue without asking.
- **"Automated" means a test in the team's automation suite.** A script QA wrote to drive one run is a *scripted run*; do not report it as automated.
- **The page title repeats the ticket's summary verbatim**, so the tracker and the documentation stay traceable to each other.
