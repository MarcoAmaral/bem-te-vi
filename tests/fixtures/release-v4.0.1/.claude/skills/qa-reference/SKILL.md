---
name: qa-reference
description: "Bem-te-vi's on-demand QA reference: the test pyramid and ISTQB design techniques, CI/CD tag filters, Playwright/Vitest assertion examples, Git and pre-push standards, the axe-core accessibility template, the XSS payload spec and security checklists, screenshot and recording evidence procedure, test tool selection, and commit and lint conventions for the target repository. Use when writing or reviewing test automation, an accessibility or security test, test evidence, a tag filter, or when recommending a test tool."
---
# Skill: QA Reference (Read on Demand)

> **Bem-te-vi** | Templates, examples and procedures behind the always-on rules

The rules in `.claude/rules/` hold the short must-lists that apply to every conversation. The
detail behind them lives here and costs nothing until it is needed: read the one file the task
calls for, not all of them.

## Contents

| File | Holds | Read it when |
| --- | --- | --- |
| `references/testing-design.md` | Adaptive test pyramid, coverage targets, mocking matrix, localhost dry runs, ISTQB test design techniques, field heuristics, CI/CD tag-filter syntax | Choosing test levels or techniques, testing on a shared environment, writing a `--grep` or `testNamePattern` filter |
| `references/automation-code.md` | Arrange-Act-Assert and Page Object Model detail, Playwright and Vitest assertion examples, atomic commits, pre-push verification, red-green proof, parallel ticket work | Writing or reviewing automation code, committing, or claiming a spec passes or a bug is fixed |
| `references/accessibility-checks.md` | Full WCAG 2.2 AA criteria, the `@axe-core/playwright` audit template, the manual a11y checklist | Writing an accessibility audit or a manual a11y test plan |
| `references/security-checks.md` | Full OWASP client-side verification, the `npm audit` gate, the Playwright XSS payload spec, the manual security checklist | Writing a security test, a payload spec or a security test plan |
| `references/evidence-capture.md` | Viewport screenshots with code, visible pointer and case label, opening recordings, the skipped-test recording trap, pacing, ASCII names, the evidence checker | Writing automation that captures screenshots or video, or handing evidence to a reviewer |
| `references/context-sources.md` | How to read the sources context discovery names: a spec directory, the tracker as the record of what was tested, feature-area knowledge files; the before-you-ask steps; the lint, review, build, verify publishing pipeline | Grounding tests or a review in a spec directory or feature-area notes; deciding what was already tested; before asking anyone a question; publishing a document to a shared platform |
| `references/test-tools.md` | CTFL v4.0 tool categories, benefits and risks of test automation, how to recommend a tool | Recommending, justifying or introducing a test tool, or proposing to automate manual tests |
| `references/repo-conventions.md` | Full Conventional Commits rules (types, atomic commits, breaking-change notation) and the linting rules (detect and respect the repository's config, no invented style) | Committing on behalf of the user, or writing or editing code in the target repository |

## How to use

1. Apply the matching rule in `.claude/rules/` first; it says what must hold.
2. Open the reference above for the template, example or procedure, and follow it.
3. When a reference and a rule seem to disagree, the rule wins; report the conflict.
