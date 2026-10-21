# Plan 023: The `qa-migrate` skill (Cypress / Selenium to Playwright)

> **Executor instructions**: This plan is **not approved**. Marco reads it and decides before any
> file named in it is created (see "Approval gate"). When approved, work on a `feat/qa-migrate`
> branch: first the skill, with its frontmatter check passing; then adapters; then the example;
> then the dry run. One concern per commit.

## Status

- **Priority**: P2
- **Effort**: L
- **Depends on**: plan 019 phase 3 (frontmatter, merged), phase 11 (`examples/` layout), plan 020
  (the Bem-te-vi rename; new text uses the new name)
- **Planned at**: 2026-10-08
- **Source**: plan 019 phase 13, the first of five suggested skills

## Why this matters

Plan 019 phase 13 says each new skill should back a service Marco sells, so that it doubles as a
portfolio piece, and that `qa-migrate` comes first because it backs his most distinctive offer:
moving an existing Cypress or Selenium suite to Playwright. The package already generates new
Playwright tests (`/qa-automate`) and states how they should look (`code-style-qa.md`). It has
nothing for the harder, more common job: an existing suite, with its own conventions, that has to
keep protecting the product while it is being replaced.

The failure this skill exists to prevent is silent coverage loss. Twenty old tests become fifteen
new ones, a flaky test is reproduced faithfully as a flaky test, and the old suite is deleted
before the new one has proven anything.

## What the skill does

Given an existing Cypress or Selenium WebDriver suite (any language binding), it takes the user
through six phases and produces one artefact per phase, so the work can be resumed in a later
session.

| Phase | Output | Notes |
| --- | --- | --- |
| 1. Assess | `migration/assessment.md`: inventory by spec/class, size, runtime, skipped and known-flaky tests, shared infrastructure (custom commands, page objects, fixtures, plugins), CI stages | Read-only. Applies `context-discovery.md` to the old suite and the app |
| 2. Prioritise | Ordered backlog: critical journeys first, then high-failure tests, then the rest; a "do not migrate" list with a reason for each (duplicate, obsolete, disabled) | Dropping a test is a documented decision, not an omission |
| 3. Set up | `playwright.config.ts`, a separate test directory, a non-blocking CI job beside the old one, one smoke spec | The old suite keeps running untouched |
| 4. Migrate infrastructure | Auth (`storageState`), fixtures, page objects, data helpers, in that order, before the specs that use them | One **golden reference** spec is hand-migrated first and committed; later specs are checked against it |
| 5. Migrate specs | One spec at a time, re-derived rather than line-translated, each with a parity-table row | See the parity check below |
| 6. Decommission | A go/no-go checklist, then removal of the old framework | Only after the parity gate passes; deletion is a separate commit |

### Concept mapping (the part the skill must get right)

Ship these as compact tables inside `SKILL.md`. Every row maps to the Playwright idiom, not a
literal translation.

| From | To | Pitfall to name in the skill |
| --- | --- | --- |
| `cy.get(css)`, `cy.contains` | `getByRole`, `getByLabel`, `getByTestId` per `code-style-qa.md` locator order | A CSS selector copied across stays fragile and breaks the repo's own locator rule |
| Cypress command queue and implicit retry | `await` plus auto-waiting actions and web-first `expect` | Cypress commands are not promises; a missing `await` in Playwright fails silently or races |
| `cy.wait(ms)`, `Thread.sleep`, `implicitlyWait`, `WebDriverWait`, `FluentWait` | Delete; rely on auto-wait or a web-first assertion | Hard sleeps are forbidden by `code-style-qa.md`; do not carry them over |
| `cy.intercept` (stub or spy) | `page.route` (stub), `page.waitForResponse` (spy/wait) | Start the wait before the action that triggers the request |
| `cy.fixture` | JSON imported in the spec, or a Playwright fixture | Fixtures in the two tools are different things |
| `Cypress.Commands.add` (custom commands) | Playwright test fixtures or page-object methods | Commands that hide assertions must be split: assertions belong in the test |
| `cy.session`, login-in-`beforeEach` | `storageState` produced once in a setup project | The most common silent-breakage point |
| Selenium `By.*`, `findElement` | Locator hierarchy as above | Never port `By.xpath` or index-based locators |
| Selenium page objects | Playwright page objects without assertions | Selenium POMs often assert; move assertions into the test |
| `driver.switchTo()` windows and frames | `context.waitForEvent('page')`, `frameLocator` | |
| Cypress multi-origin limits, `cy.origin` | Playwright handles multiple origins natively; simplify, do not port the workaround | |
| `cypress run --record`, Dashboard parallelism | `fullyParallel`, `--shard`, the HTML report and trace viewer | |

### Incremental migration with both suites running

The old suite stays in CI, non-blocking once the new job exists, until the parity gate passes.
A migrated test is tagged in the old suite ("migrated to `<new path>`") but not deleted until the
new one has passed in CI for an agreed period (default: two release cycles; Marco's call).

### Parity checks

A migration is not done when the new tests are green; it is done when they are shown to cover the
old ones. The skill maintains `migration/parity.md`, one row per old test:

| Old test | New test | Same assertions? | Mutation check | Status |
| --- | --- | --- | --- | --- |

- **Same assertions?** Compare what each test verifies, not how it is written. A test that
  asserted four things and now asserts two is a regression of the suite.
- **Mutation check**: for each Critical and High test, break the behaviour it covers (comment out
  the validation, change the expected value in a throwaway branch) and confirm the new test fails.
  A migrated test that cannot fail is not a test. This is the same red-green idea as the repo's
  rule for regression specs in `code-style-qa.md`, applied to migration.
- **Counts reconcile**: old tests = migrated + intentionally dropped (with reasons) + remaining.
  The totals must add up, and the skill refuses to declare completion if they do not.
- Optionally compare line/route coverage before and after, when the project already measures it.
  Coverage is a guide, not a goal (`testing-guidelines.md`).

### Flaky tests during migration

Migrating a flaky test reproduces the flakiness. The skill:

1. Marks tests the assessment found flaky, and reports their failure history if CI exposes it.
2. Migrates them last, re-derived from what they are meant to verify, never copied.
3. Runs each migrated test repeatedly (`--repeat-each`) before it counts as migrated, and records
   the result in the parity table.
4. Applies the quarantine protocol in `testing-guidelines.md` (tag, defect report, deadline) to a
   test that still flakes, rather than adding retries. `retries` in the config is for CI noise
   after the fact, not a fix.

A dedicated `qa-flaky` skill is a separate item in plan 019 phase 13; `qa-migrate` only handles the
migration-time case and points to it later.

## Command or skill: skill

**Decision: `.claude/skills/qa-migrate/SKILL.md`.** The reasons:

- It is a multi-session, multi-artefact workflow, not a single-shot generation. The existing
  commands (`/qa-cases`, `/qa-automate`, `/qa-defect`) each turn one input into one output; a
  migration spans assessment, setup, dozens of specs and a decommission decision, and must resume
  from files on disk. That is how `qa-plan` and `qa-explore` are already shaped.
- It should trigger on intent ("move our Cypress tests to Playwright"), which is what a skill's
  `description` is for, instead of requiring the user to know a command name.
- The package's compiler (`generate-adapters.sh`) includes `SKILL.md` files from `.claude/skills/`
  but only that filename: a `references/` folder next to it would not be compiled into the
  adapters. So the skill must be **one self-contained file**, with the mapping tables inline.
  If it outgrows that (a competitor's equivalent is long), the answer is a follow-up to extend
  the compiler, not splitting content out silently. Size target: under 300 lines, comparable to
  `qa-plan` (213).

A thin `/qa-migrate` command that loads the skill is not planned: `/qa-*` commands in this package
are self-contained prompts, and a wrapper adds a second place to keep in sync.

## Frontmatter

Per `tests/test-frontmatter.sh` and the Agent Skills specification (name equal to the folder, 1-64
lowercase letters, digits and single hyphens; description non-empty, at most 1024 characters):

```yaml
---
name: qa-migrate
description: "Migrates an existing Cypress or Selenium WebDriver test suite to Playwright incrementally, with both suites running until a parity table shows the new one covers the old. Assesses the suite, maps commands, waits, intercepts, fixtures and page objects to Playwright idioms, and handles flaky tests. Use when asked to migrate, port or switch end-to-end tests to Playwright."
---
```

(About 380 characters at planning time; the check enforces the limit.)

## Reuse, not duplication

The skill must **reference** these files and restate none of their rules:

- `.claude/rules/code-style-qa.md`: locator order, AAA, Page Object Model with no assertions,
  web-first assertions, no hard sleeps, test isolation. The mapping tables name the target idiom
  and say "per `code-style-qa.md`", they do not re-explain it.
- `.claude/rules/test-evidence.md`: when the parity table or the example captures screenshots or
  video of old and new runs side by side, they follow that rule (fixed viewport, visible pointer
  and case label, recordings opened, ASCII-only names), and `check-test-evidence.sh` runs on the
  migrated specs.
- `.claude/rules/context-discovery.md`: phase 1 uses it to find the old suite's real behaviour
  and the app's real selectors; no selector is invented.
- `.claude/rules/testing-guidelines.md`: tags (`@smoke` etc.) carry over to the new specs; the
  quarantine protocol is the flaky-test route.

Only the migration-specific content lives in `SKILL.md`: the phases, the old-to-new tables, the
parity table and the decommission gate.

## ISTQB CTFL v4.0 citations

Verified against the official syllabus PDF (v4.0.1, 2024-09-15,
`https://istqb.org/wp-content/uploads/2024/11/ISTQB_CTFL_Syllabus_v4.0.1.pdf`), by reading the
section text, on 2026-10-08. Cite only these:

| Section | What it supports in the skill |
| --- | --- |
| §2.3 Maintenance Testing | A migration of the test tool is not a change to the product, but the product-side analogue applies: its triggers include "upgrades or migrations of the operational environment", and maintenance testing covers both the change and regressions in the unchanged remainder. Use it to justify running both suites until parity, and impact analysis (this section and §2.2.3) to prioritise |
| §2.2.3 Confirmation Testing and Regression Testing | Regression suites grow and are "a strong candidate for automation"; impact analysis first. Frames why the old suite is a safety net until replaced |
| §1.4.3 Testware | The old suite, its fixtures and page objects are testware being replaced |
| §1.4.4 Traceability between the Test Basis and Testware | The parity table is traceability from old test to new test; a dropped test needs a recorded reason |
| §6.2 Benefits and Risks of Test Automation | The decision to migrate is a tool change: the listed risks (unrealistic expectations, inaccurate effort estimates, relying on a tool too much, open-source dependency) belong in the assessment's risk list |

**Not cited, because the syllabus does not say it:** flaky tests, test-suite migration between
frameworks, and mutation checks. The words "flaky" and "migration of a test suite" do not appear
in the syllabus text; §2.3's migration is about the operational environment. The skill treats
flakiness and migration as good practice drawn from the sources below, not as ISTQB content, and
must say so rather than imply a citation.

## Research basis

Read for scope, not copied.

- Competitor reference: `petrkindlmann/qa-skills`, `skills/test-migration/SKILL.md`
  (`https://github.com/petrkindlmann/qa-skills/tree/main/skills/test-migration`, MIT, read
  2026-10-08). Useful ideas: incremental over big-bang; parallel run until parity; highest-value
  tests first; re-derive rather than translate; migrate shared infrastructure before specs;
  capture `storageState` early; one hand-migrated "golden reference" test. It covers several
  framework pairs (Jest to Vitest, Mocha to Vitest, Protractor). We narrow to two sources and one
  target, and add the mutation-check parity gate and the repo-rule reuse, which that skill lacks.
- Official Playwright migration guides that exist today: Puppeteer
  (`https://playwright.dev/docs/puppeteer`), Protractor (`https://playwright.dev/docs/protractor`),
  Testing Library (`https://playwright.dev/docs/testing-library`). **There is no official
  Playwright guide for Cypress or Selenium**: `playwright.dev/docs/cypress` and `/docs/selenium`
  both return 404 (checked 2026-10-08). The skill's tables therefore rest on Playwright's
  reference pages for the target idioms, not on a vendor-published mapping:
  locators (`https://playwright.dev/docs/locators`), assertions
  (`https://playwright.dev/docs/test-assertions`), network (`https://playwright.dev/docs/network`),
  mocking (`https://playwright.dev/docs/mock`), authentication
  (`https://playwright.dev/docs/auth`), fixtures (`https://playwright.dev/docs/test-fixtures`).
  The Puppeteer and Protractor guides are useful as models of how the vendor frames a migration.
- Converter tooling named by the competitor, **not independently verified**: the `cy2pw` web
  converter (`https://demo.playwright.dev/cy2pw/` returns HTTP 200, but its behaviour and
  provenance were not checked) and a community CLI. The skill should treat any converter output as
  a first pass, and the plan does not depend on either.

## The example

Per plan 019 phase 11, committed **unedited** with a `README.md` stating the exact prompt, model,
date, package version, and honest limits.

- **Subject**: `cypress-io/cypress-example-todomvc` (`https://github.com/cypress-io/cypress-example-todomvc`),
  MIT, with its specs under `cypress/e2e/`. It is small, public and well known. Note that it was
  **archived by its owner on 2025-10-10** (read-only); that does not stop us reading and migrating
  it, but the README must say so and must pin the commit used.
- **Location**: `examples/todomvc-cypress-to-playwright/` holding `assessment.md`, `parity.md`,
  the migrated Playwright specs, and a `README.md`. The old specs are linked by commit, not copied
  in, so the example does not republish someone else's repository.
- **Selection**: if the spec turns out too small to show custom commands, intercepts and fixtures,
  fall back to a second public repository chosen at implementation time (candidates to evaluate:
  `cypress-io/cypress-realworld-app` for intercepts and auth). Decide on evidence from the dry run;
  do not widen scope before it.
- **Selenium**: no Selenium example in this plan. The Selenium rows in the tables are covered by
  the review of the skill text only, and the README of the skill says the Cypress path was the one
  exercised. Adding a Selenium example is a follow-up if Marco wants it.
- Licensing: the MIT notice of the source repository is reproduced in the example's README.

## Verification

Each item is a command with output read, not a claim.

1. `tests/test-frontmatter.sh` passes, and now counts the new skill.
2. `./generate-adapters.sh` then `tests/verify-adapters.sh`: the skill appears in every adapter,
   and `./generate-known-hashes.sh --check` is unaffected (a new unreleased file).
3. `./tests/test-lifecycle.sh` and `./tests/conformance/run.sh` still pass: the new skill is
   installed and uninstalled like `qa-plan`.
4. `markdownlint` clean on `SKILL.md`, the example and this plan.
5. **Dry run on the real public repository**: run the skill (phases 1, 2, 3, 4 and 5) against the
   pinned `cypress-example-todomvc` commit. Success criteria, written before running:
   - the assessment's test count equals the repository's actual count;
   - every old test has a parity row, and counts reconcile;
   - the migrated specs pass headless, repeated (`--repeat-each=5`), with zero failures;
   - the mutation check fails for at least the Critical-tier tests;
   - `.claude/hooks/check-test-evidence.sh` reports nothing on the migrated specs;
   - the skill's output is committed unedited, with whatever a human had to fix listed in the
     example's README.
6. The skill is run once on a **different** target (a second public repository, or a deliberately
   Selenium-flavoured snippet) to check the tables are not fitted to one suite. A failure there is
   reported, not hidden.

## Portfolio value

The skill and its example are a public, inspectable demonstration of the migration service:
a method (assess, prioritise, migrate under parallel run, prove parity, decommission), tooling
that makes the method repeatable, and a worked example with its limits stated. The assessment and
parity documents double as client deliverables: they are the evidence a buyer wants that coverage
was preserved. The mutation-check parity gate is the differentiator, because the common failure of
a migration is a green suite that no longer detects anything. Nothing in the skill, the example or
the README should name a marketplace or a gig; they describe the work, and any listing text is
written separately by Marco.

## Rejected approaches

- **A `/qa-migrate` slash command only**: a command is one prompt; a migration is a multi-session
  workflow with files that persist between sessions. It would also not trigger on plain-language
  requests.
- **A skill plus a `references/` folder**: cleaner to read, but the compiler only picks up
  `SKILL.md`, so adapters for other editors would lose the content. Revisit only together with a
  compiler change, which is out of scope here.
- **Covering Jest, Mocha, Vitest and Protractor too, as the competitor does**: dilutes the
  Playwright service the skill backs, and each pair needs its own verified mapping. Protractor is
  end-of-life and has an official Playwright guide to follow; it can be a later addition.
- **A codemod or converter bundled in the package**: the package is Markdown plus installers and
  is model-agnostic; shipping executable migration code adds a maintenance and security surface.
  The skill may *recommend* converters as a first pass, flagged as unverified.
- **Translate line by line**: fastest, but reproduces bad waits, fragile selectors and flakiness.
  Re-deriving each test from what it verifies is the point.
- **Big-bang rewrite then delete the old suite**: removes the safety net before the replacement is
  proven (§2.2.3 on why regression suites are kept and trusted).
- **Citing ISTQB for flakiness and tool migration**: the syllabus has no such text; see the
  citation table.

## Risks

- **The skill is long.** Mitigation: the 300-line target, tables over prose, and rule reuse.
- **Converter and tool claims age quickly.** Mitigation: say "verified on" dates in the skill, and
  re-check on each release.
- **The example's source is archived.** Mitigation: pin the commit; fall back to a second target.
- **One Cypress example does not prove the Selenium path.** Stated openly in the skill and README.

## Could not be verified

- The content of the competitor's `references/` files and the behaviour or provenance of the
  `cy2pw` converter and the community CLI; only the competitor's `SKILL.md` was read.
- Whether the todomvc spec is large enough to exercise intercepts, fixtures and custom commands;
  decided by the dry run.
- The exact number and last-commit date of the todomvc repository's specs; to be read at pin time.

## Approval gate

**STOP: Marco approves before implementation.** Open decisions for Marco:

1. Command-vs-skill: skill, single file (as above)?
2. Scope: Cypress and Selenium to Playwright only, with a Cypress-only worked example?
3. Is the default "two release cycles" before deleting an old test the right default?
4. Is an archived upstream acceptable for the example, or should the dry run start from
   `cypress-realworld-app`?
5. Does this go before or after plan 020's cut-over to the public repository? Implementing after
   is cleaner, since the new skill's text and the example's package version carry the Bem-te-vi
   name.
