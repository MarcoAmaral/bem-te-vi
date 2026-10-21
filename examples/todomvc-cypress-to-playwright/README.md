# Example: `qa-migrate` on a public Cypress suite

The `qa-migrate` skill run against the 32-test Cypress suite of [`cypress-io/cypress-example-todomvc`](https://github.com/cypress-io/cypress-example-todomvc) at commit [`4000662`](https://github.com/cypress-io/cypress-example-todomvc/tree/40006623c2d5ed80bddafa6f16e50d6922936e27) (2025-10-08). The upstream repository was archived by its owner on 2025-10-10 and is read-only. Its old spec is linked here, not copied: [`cypress/e2e/app.cy.js`](https://github.com/cypress-io/cypress-example-todomvc/blob/40006623c2d5ed80bddafa6f16e50d6922936e27/cypress/e2e/app.cy.js).

A second, smaller run on a Selenium suite checks that the skill's tables are not fitted to one suite: see [`selenium-check/`](#second-target-a-selenium-suite).

```text
todomvc-cypress-to-playwright/
├── migration/
│   ├── assessment.md        # phase 1: inventory, infrastructure, CI, unchecked behaviour, risks
│   ├── backlog.md           # phase 2: order, priorities, the one dropped test
│   ├── parity.md            # phase 5: one row per old test, mutation and repeat results
│   ├── decommission.md      # phase 6: the go/no-go checklist (verdict: NO-GO)
│   ├── mutate.sh            # the 33 source mutations, M01-M33
│   └── run-output/          # 92 raw runs the documents cite
├── playwright.config.ts     # phase 3
├── playwright/              # phase 4-5: fixtures, page object, data, 11 spec files
├── upstream-changes.diff    # the skill's edits to upstream files (circle.yml, .gitignore, package.json)
├── review/                  # runs made afterwards by the reviewer, not by the skill
├── selenium-check/          # the second target
└── LICENSE-cypress-example-todomvc
```

## Headline result

- **Counts reconcile:** 32 old tests = 31 migrated + 1 dropped as a duplicate, with its reason recorded. The new suite lists 32 tests: the 31 plus a smoke spec.
- **Repeat runs:** every new test passed 10 of 10 repeats.
- **Mutation check:** 33 mutations of the app source were run. Every `@p0` and `@p1` test failed under at least one of them, for the reason the test is named after.
- **Four old tests could never fail.** Four of the mutations were also run against the old Cypress suite, and it **passed 32 of 32** under three of them. For example, with the "clear the input after adding" code deleted, every old test is still green. The old test asserted `have.text ''` on an `<input>`, and an input's text is always empty. The new suite catches all four.
- **Decommission verdict: NO-GO.** The new suite has never run in CI. The Cypress Cloud dashboard and the macOS and Windows jobs have no replacement, and no one has accepted their loss in writing. The skill refused to declare the migration finished, which is what it is for.

## Prompt

The skill was run by a subagent given this prompt. Absolute paths are replaced by `<…>` placeholders; the text is otherwise verbatim.

```text
You are executing a QA skill exactly as written, as a dry run whose output will be published unedited as a worked example. Do not improve, rewrite or "fix" the skill file; follow it.

## The user's request

"Migrate our Cypress end-to-end suite to Playwright. Run phases 1 to 5 of the qa-migrate skill, and write the phase 6 decommission checklist with today's answers, but do not remove Cypress."

## The skill and the rules it points to

- Skill: <bem-te-vi>/.claude/skills/qa-migrate/SKILL.md — read it fully first.
- Every file it references (`.claude/rules/*.md`, `.claude/skills/qa-reference/references/*.md`, `.claude/hooks/check-test-evidence.sh`) lives under <bem-te-vi>/. Read the ones the skill tells you to read.
- Do not edit anything under that directory.

## The project being migrated

- Working copy: <todomvc> — a git clone of the public repository cypress-io/cypress-example-todomvc at commit 40006623c2d5ed80bddafa6f16e50d6922936e27. Work only inside this directory. Its `node_modules` are installed and `js/bundle.js` is built (`npm run build` rebuilds it after a source change).
- Serve the app with `node serve.js` (port 8888) from the working copy, in the background; stop it when done. Do not use `pkill -f` with a pattern that also matches your own shell command.
- The old suite was already run once at this commit: its full output is in <scratchpad>/work/cypress-baseline.txt. You may run it again: Cypress needs `env -u ELECTRON_RUN_AS_NODE npx cypress run --browser electron`, because this shell exports ELECTRON_RUN_AS_NODE=1.
- Playwright: install `@playwright/test` and `@axe-core/playwright` as devDependencies in the working copy (`npm install -D ... --ignore-scripts`). Chromium browsers are already cached in ~/.cache/ms-playwright; if the installed version needs a different build, run `npx playwright install chromium`.
- The mutation check: use a throwaway git branch in the working copy, change the app source, `npm run build`, run the relevant new test, record the result, then return to the main branch and rebuild. Leave the app source unchanged at the end.

## Output

- Put every artefact the skill asks for where the skill says (`migration/*.md`, `playwright.config.ts`, the new test directory, the CI job file). The working copy uses CircleCI (`circle.yml`); add the new job wherever the skill's phase 3 says.
- Save the raw output of every test run you rely on (Playwright `--repeat-each`, each mutation run, the evidence checker) as text files under `migration/run-output/`, named for what they are. Use the list reporter.
- Do not commit anything to git except on the throwaway mutation branch; the files are collected afterwards.

## Final report (your reply)

1. The files you created, with one line each.
2. Every command you ran that a claim depends on, with its result (counts, pass/fail).
3. Where you deviated from the skill, and why.
4. Where the skill was unclear, silent or wrong for this project: be specific and honest; this list goes into the published README as limits.
5. Anything you could not do.
```

## Run details

| Item | Value |
| ---- | ----- |
| Date | 2026-10-13 |
| Package version | Unreleased, after 3.0.0 (the skill ships in 4.0.0) |
| Skill file | `.claude/skills/qa-migrate/SKILL.md` as added in commit `7af997e`, before the dry-run findings were folded into it |
| Files followed | `SKILL.md`, `code-style-qa.md`, `context-discovery.md`, `testing-guidelines.md`, `test-evidence.md`, `qa-reference/references/automation-code.md` |
| Model | An AI coding assistant following the skill file (Claude Sonnet 5.5, `claude-sonnet-5-5`) |
| Tooling | Node v24.16.0, `@playwright/test` 1.64.0 (Chromium), `@axe-core/playwright` 4.13.0; old suite Cypress 15.4.0 on Electron 138 |
| Duration | About 30 minutes |

## What the reviewer checked

These checks were run afterwards on the skill's output. They are in [`review/`](review/).

- **Repeat run:** `npx playwright test --repeat-each=5` gave **160 passed** (32 × 5). Plan 023's success criterion asks for 5 repeats; the skill itself ran 10.
- **Mutation M02 by hand** (the input field is no longer cleared after adding a todo):
  - New suite: 1 failed, `should clear text input field when an item is added`, on `toHaveValue`.
  - Old Cypress suite: **32 of 32 passed**.
  - The app was restored and rebuilt afterwards.
- **Upstream code untouched:** after the run, `git diff -- js cypress` in the working copy was empty.
- **Evidence:** `.claude/hooks/check-test-evidence.sh playwright/tests` reported "clean".
- **The only edit to the skill's output:** absolute local paths in the run output were replaced with `<todomvc>`, `<scratchpad>` and `<bem-te-vi>`. That includes two Cypress lines where a long screenshot path wrapped. One `markdownlint-disable-next-line MD036` comment was added above the bold count line in `assessment.md`, so the repository's Markdown lint passes. Nothing else was changed.

To reproduce, clone upstream at the pinned commit, copy `playwright.config.ts` and `playwright/` into it, apply `upstream-changes.diff`, then run `npm install`, `npm run build` (upstream does not commit `js/bundle.js`) and `npx playwright test`; Playwright starts the app itself. This was checked on a fresh copy: 32 passed.

## Honest limits

The skill, as run, was wrong or silent in these places. Most are now addressed in `SKILL.md`; the run above predates that.

- **Counting old tests.** The skill said to use the old runner's list or dry-run mode. Cypress has neither, so the count came from a full run's result table plus a `grep` of `it(`.
- **The old suite was not checked for tests that cannot fail.** The skill applied the mutation check only to the new tests. That was the largest finding: comparing assertions as written would have copied four vacuous old tests faithfully. The skill's agent mutated the old suite on its own initiative.
- **`toHaveText` with a string normalises whitespace**, so a trim test needs a regular expression. A role query skips hidden elements unless given `includeHidden`. Neither pitfall was in the table.
- **"Non-blocking CI job" is not portable.** GitHub Actions has `continue-on-error`. CircleCI has no per-job allow-failure, so the job went in a separate workflow that must stay out of required checks. The repository has a second CI system (`.github/workflows/main.yml`) that the run did not extend.
- **`retries: 0` with `trace: "on-first-retry"` never records a trace.** The run used 1 retry in CI only.
- **No `data-testid` was added.** The skill says to add one when nothing better identifies an element, but the prompt forbade product changes. Todo rows are therefore found as "list items that contain no link", a structural workaround that `parity.md` flags.
- **Tags were invented, not carried over.** The old tests had none. The priorities are the migrator's assignment and are stated as such in `backlog.md`.
- **"Two release cycles" means nothing here:** the repository has no releases (`0.0.0-development`).
- **The evidence check is vacuous:** the new specs capture no screenshots or video, so "clean" proves only that.
- **The new suite is stricter than the old one in places**, so "all green" in both suites is not the same statement. `parity.md` marks each stricter test.
- **Not run:** the new CI job itself (the YAML parses, and a local `CI=1` run passed), Firefox and WebKit, and any CI history. The known-flaky inventory rests on three local runs.
- **Found outside the suite:** `serve.js` (node-static 0.7.11) crashes on a `HEAD` request under Node 24. The repository pins Node 22.13.0.

## Second target: a Selenium suite

[`selenium-check/`](selenium-check/) runs the skill on [`TodoTest.java`](selenium-check/src/test/java/todomvc/TodoTest.java), a Java/TestNG Selenium suite of 5 test methods (7 executions, because of a data provider) against the same app. **The reviewer wrote that suite for this check.** It deliberately uses the idioms the Selenium table covers: a static shared driver, a page object that asserts, `implicitlyWait`, `Thread.sleep`, XPath and index locators, `Actions` and a `@DataProvider`. Being purpose-written, it can only show where the table is thin, not that the table is complete.

The prompt was built the same way as above. The request was: "Migrate this Selenium suite to Playwright with the qa-migrate skill. Do phases 1, 2, 4 and 5; for phase 3 just write the Playwright config and the test directory, no CI job."

- **Result:** 5 of 5 methods were migrated. The 7 new tests passed 35 of 35 under `--repeat-each=5`, and the reviewer re-ran them with the same result.
- **Mutations:** 4 of 5 were caught. The surviving one is real: the data row `"  trims spaces  "` cannot detect a missing trim, because Selenium's `getText()` and Playwright's `toHaveText` both compare rendered, whitespace-normalised text. The old suite had the same blind spot.
- **Not run:** Java is not installed here, so the old suite never ran, and its count comes from reading the code.
- **Where the table was thin:**
  - `implicitlyWait` and `Thread.sleep` appeared only in the Cypress table's sleep row.
  - `Actions.doubleClick`, the `Keys.chord(CONTROL, "a")` select-all and `getAttribute("class")` had no Selenium row.
  - The table didn't say whether a data-provider test counts once or once per row.

## Licence

The migrated specs are derived from `cypress-example-todomvc`, Copyright (c) 2015 Cypress.io, LLC, under the MIT licence, reproduced in [`LICENSE-cypress-example-todomvc`](LICENSE-cypress-example-todomvc).
