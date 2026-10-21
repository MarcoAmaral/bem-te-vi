---
id: ref-test-case-writing
---
# Test Case Writing Reference

> **Read on demand** | Detail behind `/qa-cases` | Part of the `qa-reference` skill

Read the section the task calls for: the tracker table when linking an issue, a technique's worked
example when choosing the technique and writing a case's **ISTQB Technique** row, the runbook format
when writing the runbook a test-case file's `runbook` key points to. The test case format, its
required fields, the Source values and the tags are in `/qa-cases`; when this file and `/qa-cases`
seem to disagree, `/qa-cases` wins.

---

## Tracker Link Formats

Detect the tracker from the identifier format or from what the user mentions, and format the link
accordingly. `/qa-cases` ("Tracker Intelligence") has the rules for a full URL, a bare ID and no
tracker.

| Tracker                | Identifier format               | Example   | URL pattern                                             |
| ---------------------- | ------------------------------- | --------- | ------------------------------------------------------- |
| **Linear**             | `ABC-123` (prefix + number)     | `AUTH-12` | `https://linear.app/[team]/issue/AUTH-12`               |
| **Azure DevOps (ADO)** | `#NNNNNN` or bare number        | `#104476` | `https://[org].visualstudio.com/_workitems/edit/104476` |
| **Jira**               | `PROJ-NNN` (uppercase + number) | `QA-47`   | `https://[org].atlassian.net/browse/QA-47`              |
| **Shortcut**           | `sc-NNN` or `SC-NNN`            | `sc-3891` | `https://app.shortcut.com/[org]/story/3891`             |
| **GitHub Issues**      | `#NN` (short)                   | `#42`     | `https://github.com/[org]/[repo]/issues/42`             |
| **GitLab Issues**      | `#NN` or `!NN` (MR)             | `#18`     | `https://gitlab.com/[org]/[repo]/-/issues/18`           |

---

## ISTQB Test Design Techniques in TC Format

The coverage items of each technique, and what 100% means for it, are in
the `qa-reference` skill's `references/testing-design.md`.

### Equivalence Partitioning (EP)

Divide inputs into partitions. Test one representative value per partition (CTFL §4.2.1).

```text
Field: Version name (1–62 chars)
EP1 (valid):   1–62 chars  → "my_version"
EP2 (invalid): 0 chars     → ""
EP3 (invalid): 63+ chars   → "a" × 63
```

**In TC format:**

```markdown
| ISTQB Technique | EP — EP1 (valid), EP2 (invalid: empty), EP3 (invalid: too long) |
```

### Boundary Value Analysis (BVA)

Two-value BVA (CTFL §4.2.2): each boundary plus its closest neighbour in the adjacent partition — min-1, min, max, max+1. Three-value BVA also tests min+1 and max-1. Use three-value where an off-by-one in either direction is likely. BVA applies only to ordered partitions.

```text
Version name length: min=1, max=62 (three-value)
Test values: 0 (invalid), 1 (min), 2 (min+1), 61 (max-1), 62 (max), 63 (invalid)
```

### Decision Table

Model business rules with condition combinations (CTFL §4.2.3). Conditions take `T`, `F`, `–`
(irrelevant) or `N/A` (infeasible); actions take `X` (occurs) or blank (does not occur). Delete
infeasible columns, then write one case per remaining column: those columns are the coverage
items (the `qa-reference` skill's `references/testing-design.md`).

```markdown
| Condition              | R1  | R2  | R3  | R4  |
|------------------------|-----|-----|-----|-----|
| valid_session          |  T  |  T  |  F  |  F  |
| changes_in_version     |  T  |  F  |  T  |  F  |
| **Actions**            |     |     |     |     |
| Validation runs        |  X  |     |     |     |
| Error shown            |     |     |  X  |  X  |
```

R3 and R4 can merge into one column with `changes_in_version` = `–`: without a valid session the
outcome is the same either way.

### State Transition

Map the states and the valid transitions; a state table also shows the invalid ones, as empty
cells (CTFL §4.2.4). Cover at least every valid transition (0-switch coverage); for mission- or
safety-critical behavior, also attempt every invalid one (all transitions coverage).

```text
States: Unauthenticated → Authenticated → EditMode → ValidationPending → Done
Valid-transition TC: walk the valid path; one case may cover several transitions
Invalid-transition TC: one invalid transition per case, so one defect cannot mask another
                       (e.g., skip auth → locked out)
```

### Error Guessing

Apply experience to guess likely defects (CTFL §4.4.1):

- Race conditions (quick double-click, simultaneous tab events)
- Stale closures (captured sessionId from previous version)
- Off-by-one (62 vs 63 char limit)
- Empty state (no results, no selection, no data)
- Concurrent editing (two users same version)

---

## Runbook Format (`runbook`)

When also creating the runbook the `runbook` key points to, use this format.
In CTFL terms a runbook is a set of test procedures in the order of the test execution schedule (§5.1.5; listed as testware in §1.4.3).

```markdown
---
feature: [Feature Name]
feature_code: [CODE]
tc_ids: [TC-CODE-001, TC-CODE-002]
last_updated: YYYY-MM-DD
---

# Runbook — [Feature Name]

## How to use this runbook

Run each TC in the order listed. Record the result in each table.

## TC-[CODE]-001: [Title]

**Precondition:** [System state]
**Steps:**

1. [Action]
2. [Action]
   **Expected result:** [Observable behavior]
   **Actual result:** ******\_\_\_******
   **Status:** ☐ PASSED ☐ FAILED ☐ BLOCKED ☐ NOT RUN ☐ VERIFIED BY DEV ☐ DISCARDED
   **Notes:** ******\_\_\_******
```
