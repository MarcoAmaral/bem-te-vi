# prompt-history — QA Conversation Store

This directory stores QA session logs from Claude `/qa` interactions. It serves as a **local memory system** — past sessions can be retrieved to provide context in future conversations (reuse generated test cases, track decisions, avoid repeating analysis).

---

## File Naming Convention

```text
YYYY-MM-DD_HH-MM_<slug>.md
```

Examples:

```text
2026-03-24_14-30_login-user-story-review.md
2026-03-24_16-00_checkout-api-postman.md
2026-03-25_09-15_sprint-4-risk-analysis.md
```

- **Date + time**: ISO 8601 date and 24h time (UTC or local, be consistent)
- **Slug**: kebab-case short description of the session topic (3–5 words)

---

## Session File Structure

Every session file uses the following template (see `_TEMPLATE.md`):

```markdown
---
id: YYYY-MM-DD_HH-MM_slug
date: YYYY-MM-DD
time: HH:MM
topic: <short description>
module: <feature / component / epic name>
tags: [<tag1>, <tag2>]
artifacts: [test-cases, defect-report, risk-matrix, postman-collection, ...]
status: complete | in-progress | abandoned
---

## Context

<What triggered this session — user story, bug, sprint goal, etc.>

## Inputs

<Pasted user stories, ADO work items, requirements, code snippets, etc.>

## Artifacts Generated

<Everything produced: test cases, scripts, templates, matrices, reports>

## Decisions & Rationale

<Key choices made and why — tool selection, scope, tradeoffs>

## Open Issues / Follow-ups

<Anything unresolved, questions to raise with PO, next steps>
```

---

## INDEX.md

`INDEX.md` in this directory is the **searchable catalog** of all sessions. Update it every time you save a new session file. The index columns are:

| Date | Slug | Topic | Module | Tags | Artifacts |
| ---- | ---- | ----- | ------ | ---- | --------- |

---

## How to Retrieve Context

When starting a new `/qa` session related to an existing topic:

1. Check `INDEX.md` for relevant sessions by topic, module, or tag.
2. Open the session file(s) and review **Artifacts Generated** and **Decisions & Rationale**.
3. Reference prior decisions to avoid re-doing analysis and to build on existing test cases.

Example prompt:

```text
/qa continue from session 2026-03-24_login-user-story-review — I now need to write the Playwright tests for the login scenarios we identified.
```

---

## Tags Reference

Use these tags to categorize sessions for faster retrieval:

| Tag            | Meaning                                       |
| -------------- | --------------------------------------------- |
| `requirements` | User story / acceptance criteria review       |
| `test-design`  | EP, BVA, decision tables, state transition    |
| `automation`   | Test automation strategy, decision matrix     |
| `postman`      | API tests with Postman/Newman                 |
| `junit`        | Unit tests with JUnit/Mockito                 |
| `playwright`   | E2E tests with Playwright                     |
| `pytest`       | Unit/integration tests with pytest            |
| `csharp`       | C# tests with NUnit/xUnit                     |
| `risk`         | Risk analysis, risk matrix                    |
| `defect`       | Defect report or defect analysis              |
| `bdd`          | BDD/Gherkin scenarios                         |
| `ci-cd`        | Pipeline configuration                        |
| `ado`          | Azure DevOps work item review                 |
| `nft`          | Non-functional testing (perf, security, a11y) |
| `sprint-N`     | Sprint-specific sessions                      |
