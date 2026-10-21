# Phase 6: Decommission checklist

Date answered: 2026-10-13. Cypress is **not** removed and no old test has been marked as migrated.

## Verdict: NO-GO

Two of five conditions fail today. The old suite stays.

| | Condition | Today's answer | Evidence |
| --- | --- | --- | --- |
| [x] | Parity table complete; counts reconcile | Yes. 32 old = 31 migrated + 1 dropped + 0 remaining + 0 quarantined. `playwright test --list` shows 32 = 31 migrated + 1 smoke spec | `parity.md`, `run-output/playwright-list.txt` |
| [x] | Mutation check done for every Critical and High test | Yes. All 5 `@p0` and all 20 `@p1` migrated tests fail under at least one mutation for the reason named; the 6 `@p2` tests too. The smoke spec was not mutated: it has no old counterpart | `parity.md`, `run-output/mutation-M01..M33.txt` |
| [ ] | New suite passed in CI for the agreed period (default two release cycles) | **No.** The new suite has never run in CI. The `playwright` job in `circle.yml` was added but not executed: the YAML parses (`run-output/circle-yaml-parse.txt`), but the Docker image tag, `npm ci` inside it and the artifact path are untested. What was run: 32 of 32 passing locally with `CI=1` (Playwright starts the server itself, one retry allowed, none used; `run-output/playwright-ci-mode-run.txt`) and 10 consecutive repeats of every spec. The "agreed period" is also undefined: the repository has no release cycle (version `0.0.0-development`, dependency bumps only), so the team has to say what two cycles means here | Needs a decision from the team, then elapsed time |
| [x] | No test left in `@quarantine` without an owner and a deadline | Yes. No test is quarantined, none is tagged `@flaky`; `grep` for quarantine, flaky, skip, only, fixme under `playwright/` finds nothing | `run-output/repeat10-*.txt` (all 10/10) |
| [ ] | Reports, CI parallelism and any recording or dashboard have a replacement, or the loss is accepted in writing | **No.** Not replaced and not accepted by anyone. See below | |

### Detail for the last row

| Provided by the old suite | Replacement today | Gap |
| --- | --- | --- |
| Cypress Cloud recording (`record: true` on all three CircleCI jobs) | HTML report written to `playwright/report` and stored as a CircleCI artifact; traces on first retry | No dashboard, no run history, no flake analytics. The Cloud history is also the only possible source of CI flake data, so it should be exported before any removal |
| macOS and Windows runs (`Mac test`, `Windows test`) | None: the new job runs on Linux only | Real loss of OS coverage. Needs either two more jobs or a written acceptance |
| `.github/workflows/main.yml` (Cypress on GitHub Actions) | None: only `circle.yml` was extended | A second CI definition still runs only Cypress. It must be migrated or removed on purpose |
| `lint` job (`npm run types`, `npm run lint`) | Not applicable to the new files: `tsconfig.json` includes only `cypress/**/*.js` and `lint` targets only `cypress/e2e` and `cypress/support`. Type-checking the new TypeScript was run once by hand (`run-output/playwright-typecheck.txt`), and is not in CI | The new suite has no lint or type gate in CI |
| Parallelism | None existed (one spec file, no `parallel` option). The new suite uses `fullyParallel` | No gap |
| Browser | Electron 138 | Chromium 156 (Playwright). Different engine build, same family. Firefox and WebKit are not run by either suite |

## Findings the team should see before deciding

1. Four old tests could not fail for the reason in their name (`assessment.md`, items 2 to 5; `run-output/cypress-mutation-M02.txt`, `-M05`, `-M09`, `-M10`). With the field-not-cleared break in place, all 32 old tests still pass. Removing Cypress also removes those four, which is acceptable only because the new suite replaces them with tests that do fail.
2. The new suite is stricter than the old one in the places marked in `parity.md`. Removal is therefore a loss of nothing the old suite caught; the reverse is not true.
3. Nothing is covered by either suite for the delete button, filtered URLs on load, other browsers or other WCAG criteria. Decide separately whether to add those.

## If the answer becomes GO: steps for the removal (not done)

Each in its own commit, after the migration commits, never mixed with them:

1. Mark each migrated test in `cypress/e2e/app.cy.js` with a comment "migrated to `playwright/tests/<spec>`" (31 tests; `adds 2 todos` gets "dropped, see migration/parity.md"). Commit.
2. Remove `cypress/`, `cypress.config.ts`, the `cypress*` scripts, the `cypress`, `cypress-axe`, `eslint-plugin-cypress-dev` devDependencies and the `.eslintrc` and `lint` script that exist for them, the `cypress/videos` and `cypress/screenshots` lines in `.gitignore`, and the `tsconfig.json` `cypress` types. Decide what `npm run types` should check afterwards. Commit.
3. Remove the Cypress jobs and the orb from `circle.yml`, make the Playwright job part of the `build` workflow, and migrate or remove `.github/workflows/main.yml`. Commit.
4. Update `README.md`, which describes the repository as "tests written in Cypress". Commit.

## Commit plan for the work done so far (nothing was committed)

1. `chore(deps): add Playwright and axe-core/playwright` (`package.json`, `package-lock.json`)
2. `test: add Playwright config and smoke spec` (`playwright.config.ts`, `.gitignore`, `playwright/tests/smoke.spec.ts`)
3. `ci: add non-blocking Playwright workflow to CircleCI` (`circle.yml`)
4. `test: add Playwright fixtures, page object and golden reference spec` (`playwright/fixtures.ts`, `playwright/pages`, `playwright/data`, `playwright/tests/new-todo.spec.ts` first test)
5. One `test: migrate <area> specs from Cypress` commit per spec file, each with its rows in `migration/parity.md`
6. `docs: add migration assessment, backlog, mutation record and decommission checklist`
