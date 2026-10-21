# Parity table

Old suite was **read, not run** (no Java on this machine). "Repeat run" is the new suite only: `npx playwright test <spec> --repeat-each=5`, outputs in `run-output/repeat5-*.txt`.
Mutations were applied to a copy-restored `app/js/bundle.js` (sha256 verified identical after restore); outputs in `run-output/mutation-*.txt`.
Priorities are assumed (see backlog.md). No git repository exists here, so no commits were made ("same commit" rule not applicable).

| Old test | New test | Same assertions? | Mutation check | Repeat run | Status |
| --- | --- | --- | --- | --- | --- |
| `addsATodo` (3 data rows = 7 executions overall) | `playwright-tests/add-todo.spec.ts` (3 generated tests) | Yes: count = 1 and label text = `title.trim()`. Old used `By.xpath(...li[1]//label)` + `getText()`; new `toHaveText(title.trim())` on the first row (whitespace-normalised, like `getText()`). Page-object `assertCount` moved into the test | `@p0`: M1 removed `.trim()` in the add handler: **new test still passed (3 passed)**. Cause confirmed by `run-output/probe-trim-*.txt`: DOM `textContent` keeps the spaces, rendered text does not, and `toHaveText` (like Selenium `getText()`) compares rendered text. So the `"  trims spaces  "` row cannot detect a missing trim, in the new suite and (by the same reading) the old one. Not fixed here; see report | 15 passed (3 tests x 5) | migrated, **surviving mutant on the trim row** |
| `completesATodo` | `playwright-tests/complete-todo.spec.ts` | Yes: row has class `completed`; count text `0 items left`. `Thread.sleep(500)` dropped | `@p1`: M2 forced `completed: false` in the row class: failed on `toHaveClass(/completed/)`, received `""` | 5 passed | migrated |
| `editsATodoOnDoubleClick` | `playwright-tests/edit-todo.spec.ts` | Yes: label becomes the new text. Old: `Ctrl+A` then type; new: `fill` replaces | `@p2` (not required): M5 save ignored new title: failed, received "book a doctors appointment" | 5 passed | migrated |
| `filtersActiveTodos` | `playwright-tests/filter-todos.spec.ts` | Yes: 1 row, text `two` | `@p1`: M3 Active filter returns all: failed, expected 1 received 2 | 5 passed | migrated |
| `clearsCompletedTodos` | `playwright-tests/clear-completed.spec.ts` | Yes: remaining count = 1 (**not** which todo; same gap as old) | `@p2` (not required): M4 clear-completed no-op: failed, expected 1 received 2 | 5 passed | migrated |

## Reconciliation

Baseline (assessment.md): old = 5 `@Test` methods (7 executions).
migrated 5 + dropped 0 + remaining 0 + quarantined 0 = **5**. Equal to baseline.
Executions: new suite has 7 tests (3 + 1 + 1 + 1 + 1); full run with `--repeat-each=5` = 35 passed (`run-output/repeat5-all.txt`) = 7 x 5.

## What this table cannot show

- Behaviour neither suite checks (assessment.md list).
- That the new tests behave like the old ones in the old environment: the Java suite was never run, against port 8888 or any build.
- The Selenium path itself: no Selenium suite was run.
- Phase 3 smoke spec and CI job and phase 6 decommission were not done (out of the request's scope).
