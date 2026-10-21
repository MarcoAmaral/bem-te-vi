# Phase 1: Assessment (read-only)

Project: `cypress-example-todomvc` at commit `40006623c2d5ed80bddafa6f16e50d6922936e27` (Cypress 15.4.0, React 16 app built with `tsc` + `browserify`, served by `node serve.js` on port 8888).
Date: 2026-10-13. Nothing in the old suite or the app was changed by this phase.

## What was run and what was only read

| Item | Run or read |
| --- | --- |
| Old suite, once before this work | Run: `run-output/cypress-baseline.txt` (32 passing) |
| Old suite, two more runs for timing and flakiness | Run: `run-output/cypress-rerun-1.txt`, `run-output/cypress-rerun-2.txt` (32 passing each) |
| `npm run types`, `npm run lint` before any change | Run: `run-output/baseline-types-lint.txt` (both exit clean; `lint` uses `--fix`, it changed no file) |
| `circle.yml`, `.github/workflows/main.yml`, `cypress.config.ts`, `package.json`, `README.md` | Read |
| `js/*.tsx`, `js/todoModel.ts` (app source) | Read |
| CI history, Cypress Cloud recordings, flaky-test dashboards | Not available: not exposed in the repository |

## Sources used for ground truth (context-discovery search order)

1. Tier 1, executable truth: `cypress/e2e/app.cy.js` (680 lines, the only spec), `cypress/support/*`, the three Cypress runs, the app source (`js/app.tsx`, `todoItem.tsx`, `footer.tsx`, `todoModel.ts`). The selectors and the accessible names used by the new suite were taken from the app source, not invented, and confirmed by running the new tests.
2. Tier 2, configuration: `cypress.config.ts`, `circle.yml`, `.github/workflows/main.yml`, `package.json` scripts.
3. Tier 3, declared intent: `README.md`.
4. Tier 4: git log only (last commits are dependency bumps).

Documentation drift found: `README.md` says each test "covers the same functionality found in the official TodoMVC tests". That upstream suite was not fetched, so the claim is unverified here. One concrete gap against it is listed under "Behaviour the old tests do not check" (the delete button).

## Inventory

| Spec | Tests | Size | Runtime | Skipped / `.only` |
| --- | --- | --- | --- | --- |
| `cypress/e2e/app.cy.js` | 32 | 680 lines | 28 s, 28 s, 31 s (three runs, Electron 138, headless) | none (`grep` for `.only`, `.skip`, `xit`: no hits; the run reports Pending 0, Skipped 0) |

Count method. Cypress has no list or dry-run mode, so the count comes from the runner's own result table (`Tests: 32`, `Passing: 32`) and was cross-checked by counting `it(` blocks (`grep -cE "^\s*it\(" cypress/e2e/app.cy.js` gives 32). The two agree.

Tests by context: top level 1, When page is initially opened 1, No Todos 1, New Todo 6, Mark all as completed 3, Item 3, Editing 5, Counter 1, Clear completed button 3, Persistence 1, Routing 5, Contrast 2 = 32.

Known-flaky tests: none known. Three local runs, 96 test executions, 0 failures. One outlier: `should cancel edits on escape` took 4017 ms in the first run and about 1.1 s in the next two. No CI history is exposed, so this is local evidence only and does not clear any test of flakiness.

## Shared infrastructure

| Piece | Where | Notes |
| --- | --- | --- |
| Custom command `createDefaultTodos` | `cypress/support/commands.js` | Types three todos through the UI, then queries `.todo-list li`. The query is an implicit wait for the list; it asserts nothing explicit. Used in 6 places (4 `beforeEach` hooks and 2 tests) |
| Custom command `createTodo` | same | Types one todo, then waits for the matching `li`. Same implicit wait |
| Custom command `addAxeCode` | same | Injects `node_modules/axe-core/axe.min.js` (axe-core 4.10.3) into the page |
| `cypress-axe` `checkA11y` | `cypress/support/e2e.js` | Loaded for the Contrast context |
| Type declarations | `cypress/support/index.d.ts` | Declares the three commands |
| Fixture | `cypress/fixtures/example.json` | Unused: `cypress.config.ts` sets `fixturesFolder: false` and no test calls `cy.fixture` |
| Plugins / `setupNodeEvents` | `cypress.config.ts` | Empty |
| Authentication, sessions, network stubs (`cy.intercept`), environment variables | - | None. The app has no login and no API: all state is `localStorage` key `react-todos` |
| Data setup | in the tests | Through the UI. Cypress clears `localStorage` before each test automatically |
| Hooks | `app.cy.js` | `beforeEach`: `cy.visit('/')`. `afterEach`: blur the active element (comment says it is a Firefox workaround for blur handlers firing on navigation) |

## CI stages

| File | Job | What it does |
| --- | --- | --- |
| `circle.yml` | `Linux test` | Orb `cypress-io/cypress@1`, image `cypress/base:22.13.0`, `record: true`, `start: npm start` |
| `circle.yml` | `Mac test`, `Windows test` | Same, on macOS (xcode 15.3.0, M1) and Windows (`win/default`, bash) |
| `circle.yml` | `lint` | Requires `Linux test`; runs `npm run types` and `npm run lint` |
| `.github/workflows/main.yml` | `cypress-run` | `cypress-io/github-action@v6` on `ubuntu-22.04`, `start: npm run start`, `wait-on: http://localhost:8888`. Second, parallel CI definition of the same suite |

Reports and parallelism: `record: true` sends runs to Cypress Cloud (needs a record key held outside the repository). No `parallel` or `group` option, so no Cypress-managed parallelism. The suite is one spec file, so it runs on a single machine per OS. `video` is off in run mode (`Video: false` in the results table); screenshots are Cypress's default on failure.

Two things the new suite must account for: the old suite runs on three operating systems, and its runs are recorded in a dashboard.

## Behaviour the old tests do not check (the migration must not claim to cover it)

Stated, not fixed. Items marked "weak" are old tests that run but cannot fail for the reason their name gives; the new suite strengthens them and says so in `parity.md`.

1. **The per-item delete button (`.destroy`) is never used.** `grep destroy cypress -r` finds nothing. Removing an item is only tested through the empty-edit route.
2. **Weak: `should clear text input field when an item is added`** asserts `have.text ''` on an `<input>`. An input has no text content, so this passes whether or not the field is cleared. Shown by mutation M02 (the field is no longer cleared) run against the old suite: all 32 old tests still pass, because the later tests type into a field that still holds the previous text and then assert with `contain` (`run-output/cypress-mutation-M02.txt`).
3. **Weak: `should trim entered text`** (edit) asserts `contain`, which still passes with the whitespace left in. Shown by mutation M10 (edited text is no longer trimmed) run against the old suite: 32 passing (`run-output/cypress-mutation-M10.txt`).
4. **Weak: `should cancel edits on escape`** asserts only that each row `contain`s its original text. A row that stays in edit mode keeps its text in a hidden label, so it passes when Escape does nothing. Shown by mutation M09 (Escape ignored) run against the old suite: 32 passing (`run-output/cypress-mutation-M09.txt`).
5. **Weak: `should allow me to clear the complete state of all items`** checks then unchecks toggle-all and asserts only "not completed". It never asserts "completed" after the check, so it also passes when toggle-all does nothing. Shown by mutation M05 (toggle-all does nothing) run against the old suite: 30 passing, 2 failing, and the two failures are the other two Mark-all tests, not this one (`run-output/cypress-mutation-M05.txt`).
6. No test for toggle-all while a filter is active; none for loading a filtered URL directly (`/#/active`); none for the counter at 0 items; none for state after reload while a filter is active; none for a todo title with HTML or very long text.
7. The Contrast tests check only axe's `cat.color` rules in three page states. They do not cover editing mode, the focus ring, keyboard operation, accessible names or any other WCAG criterion. In the two states with todos, axe reports `color-contrast` as `incomplete` for some nodes (it could not decide), and an incomplete result is not a failure in either suite (`run-output/axe-rules-compare.txt`).
8. One browser engine: Electron 138 (Chromium) only. The Firefox workaround in `afterEach` suggests Firefox was once a target, but no CI job runs it.
9. The accessible names in the app are poor: the per-item checkboxes and the edit field have no accessible name. This is a product finding, not a test gap; it is why the new page object scopes by row.

Product observation, not part of the suite: `serve.js` (node-static 0.7.11) crashes with `ERR_HTTP_HEADERS_SENT` on Node 24 when it answers a `HEAD` request (`curl -I`). `.node-version` pins 22.13.0. A `GET`-based readiness check (Playwright `webServer.url`, Cypress `wait-on`) is unaffected.

## Risk list (CTFL v4.0 section 6.2, applied to this migration)

| Risk | Here |
| --- | --- |
| Unrealistic expectations of the tool | Playwright does not make the suite better by itself: several old tests were weak (items 2 to 5 above) and a faithful port would have kept them. The parity table and the mutation check exist for this |
| Inaccurate effort estimate | The suite is small (32 tests, one spec, no auth, no network stubs), so this example understates what a real suite costs. The Cypress-to-Playwright effort is dominated by locator choice, not syntax |
| Over-reliance on the tool | Green Playwright runs say the assertions held, not that the app is right. A migrated test that cannot fail is not a test: mutation check |
| Open-source dependency | `@playwright/test` and `@axe-core/playwright` are pinned exactly (`.npmrc` has `save-exact`). `@axe-core/playwright` brings axe-core 4.13.0 while the Cypress side uses 4.10.3; same rules and same outcome were confirmed for the three Contrast states, but they can drift |
| Loss of CI coverage | The old suite runs on Linux, macOS and Windows with Cloud recording. A first Playwright job covers Linux only, with an HTML report. The loss is real until replaced or accepted in writing (phase 6) |
| Different engine | Electron 138 becomes Playwright's bundled Chromium 156 |
| Locators without test ids | The app has no `data-testid` and no landmark for the todo list. The page object relies on roles, names and one structural role filter. Any product change to those breaks the suite |
| Silent coverage loss | 20 tests becoming 15 is the failure this workflow prevents. Counter below |

## Count baseline

<!-- markdownlint-disable-next-line MD036 -->
**old tests = 32**

Every later count (parity table, `playwright test --list`, decommission checklist) reconciles to this number.
