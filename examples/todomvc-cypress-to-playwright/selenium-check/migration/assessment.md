# Migration assessment (phase 1, read-only)

Source: `src/test/java/todomvc/TodoTest.java` (Java, TestNG, Selenium WebDriver). Target: Playwright Test.
App: TodoMVC React/TypeScript in `app/` (built; `app/js/bundle.js`). Served for this migration at http://localhost:8889
(the Java suite expects http://localhost:8888, hard-coded in `setUp()`).

## What was run and what was only read

- **Only read:** the whole Java suite. Java is not installed on this machine, there is no build file (no pom.xml / build.gradle),
  so the old runner's list or dry-run mode could not be used. Every old-suite count below comes from reading the code.
- **Run:** the migrated Playwright specs only (see `run-output/`).

## Context discovery (context-discovery.md)

- Tier 1 (executable truth): the old suite; the app source `app/js/*.tsx|js` (selectors, key handling, trimming, pluralisation);
  the built `app/js/bundle.js`; `app/cypress/e2e/app.cy.js` (32 `it(` blocks, an unrelated Cypress suite shipped inside the app; **not in scope**, not counted in the baseline).
- Tier 2: no CI config for the Java suite found in the target directory (`app/circle.yml` belongs to the app and is not read as the Java suite's CI).
- Tier 3/4: `app/README.md` not relied on. No ticket, no spec directory.
- Deployed state: the build served is the one in `app/`; the Java suite's target (8888) is another process whose build is not known. Parity is therefore against this build only.
- Selectors found in the app: `.new-todo` (input, placeholder "What needs to be done?"), `.todo-list li`, `.toggle` (checkbox, **no label, no accessible name**),
  `li label` (double-click to edit), `.edit` (input), `.destroy`, `.todo-count`, `.filters a`, `.clear-completed`.
  There is no `data-testid` anywhere.

## Inventory

| Item | Value |
| --- | --- |
| Class | `TodoTest` (1 file, 95 lines) + package-private `TodoPage` page object in the same file |
| `@Test` methods | **5** |
| Executions | **7** (`addsATodo` runs once per `titles` data-provider row: 3) |
| Skipped / `enabled=false` / `@Ignore` | none |
| `.only` equivalent | none |
| Groups | `smoke` (addsATodo), `regression` (4 others). No priority, level or status tags |
| Runtime | unknown (could not run) |
| Known-flaky | no CI history exposed. **Suspected:** `completesATodo` (contains `Thread.sleep(500)`), plus the `static WebDriver driver` / `static TodoPage todo` fields (shared mutable state; unsafe under parallel TestNG) |

## Shared infrastructure

- `@BeforeMethod setUp`: new `ChromeDriver` per test, `implicitlyWait(5s)`, `driver.get("http://localhost:8888")`, builds `TodoPage`.
- `@AfterMethod tearDown`: `driver.quit()`.
- `@DataProvider titles`: `"buy some cheese"`, `"feed the cat"`, `"  trims spaces  "`.
- `TodoPage.add(title)`: type into `.new-todo`, press Enter. `TodoPage.assertCount(n)`: **asserts inside the page object**.
- No authentication, no fixtures files, no environment variables, no data setup other than the browser's empty localStorage (a fresh driver is a fresh profile).
- CI stages / reports / parallelism: none visible.

## Behaviour the old tests do not check (the migration must not claim it)

- `addsATodo`: that the input is cleared after Enter; that the footer appears; the empty/whitespace-only title (app ignores it).
- `completesATodo`: un-completing; the footer count for more than one item; persistence across reload.
- `editsATodoOnDoubleClick`: Escape to cancel; blur to save; an empty edit deleting the todo; that the edit box closes.
- `filtersActiveTodos`: the Completed and All filters; the `selected` class; the URL hash.
- `clearsCompletedTodos`: **which** item remains (only the count is asserted); the `Clear completed` button disappearing.
- Not tested anywhere: toggle-all, destroy (x) button, singular "1 item left", localStorage persistence, accessibility.

## Risk list (CTFL v4.0 section 6.2 test-automation risks)

1. Unrealistic expectations: Playwright does not make the 5 tests catch more; it removes the wait idioms and the shared static driver.
2. Inaccurate effort estimate: small here (5 tests), but a bigger suite should not be extrapolated from it.
3. Over-reliance on a tool: the new suite checks exactly what the old one checked (see list above); green does not mean TodoMVC works.
4. Open-source dependency: `@playwright/test` 1.64.0 pinned by `package-lock.json`; browser binaries are installed separately.
5. Migration-specific: the old suite cannot be run here, so "old behaviour" is read, not observed. A defect in how I read it would not be caught by a parity table.
6. The app has no role/label/test id for `.toggle`; locators for it rely on position within a list item (see backlog notes).

## Count baseline

**old tests = 5 `@Test` methods (7 executions).** The parity table reconciles at the method level (5) and states the executions (7) in the cell.
