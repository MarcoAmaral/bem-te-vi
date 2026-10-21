# Phase 2: Backlog

Order: critical journeys first (`@p0`), then the rest of the behaviour that has no workaround (`@p1`), then secondary checks (`@p2`). Flaky tests last: none is known flaky (assessment, "Known-flaky tests"), so the one test with a slow outlier run goes last as a watch item.

**Assumption, not a finding.** The old tests carry no tags, so there were no tags to carry over. Priorities below are assigned here from how much of the app's purpose a failure would break (a todo list that cannot add, complete, clear or keep items is unusable). No product owner confirmed them. Tag rule: one suite tag, one level tag, one priority tag and one automation-status tag per test (`testing-guidelines.md`), plus a feature tag. Suite tag: `@smoke` for `@p0`, `@regression` for the rest. Level: `@e2e`. Status: `@automated`. Tags are applied with Playwright's `tag` test option, so `--grep @smoke` works.

| # | Old test (context > title) | Priority | Feature tag | New spec |
| --- | --- | --- | --- | --- |
| 1 | New Todo > should allow me to add todo items | p0 | @todo-create | new-todo (golden reference) |
| 2 | New Todo > should append new items to the bottom of the list | p0 | @todo-create | new-todo |
| 3 | Item > should allow me to mark items as complete | p0 | @item | item |
| 4 | Persistence > should persist its data | p0 | @persistence | persistence |
| 5 | Clear completed button > should remove completed items when clicked | p0 | @clear-completed | clear-completed |
| 6 | New Todo > adds items | p1 | @todo-create | new-todo |
| 7 | New Todo > should clear text input field when an item is added | p1 | @todo-create | new-todo |
| 8 | New Todo > should trim text input | p1 | @todo-create | new-todo |
| 9 | Mark all as completed > should allow me to mark all items as completed | p1 | @mark-all | mark-all |
| 10 | Mark all as completed > should allow me to clear the complete state of all items | p1 | @mark-all | mark-all |
| 11 | Mark all as completed > complete all checkbox should update state when items are completed / cleared | p1 | @mark-all | mark-all |
| 12 | Item > should allow me to un-mark items as complete | p1 | @item | item |
| 13 | Item > should allow me to edit an item | p1 | @item | item |
| 14 | Editing > should hide other controls when editing | p1 | @editing | editing |
| 15 | Editing > should save edits on blur | p1 | @editing | editing |
| 16 | Editing > should trim entered text | p1 | @editing | editing |
| 17 | Editing > should remove the item if an empty text string was entered | p1 | @editing | editing |
| 18 | Counter > should display the current number of todo items | p1 | @counter | counter |
| 19 | Clear completed button > should display the correct text | p1 | @clear-completed | clear-completed |
| 20 | Clear completed button > should be hidden when there are no items that are completed | p1 | @clear-completed | clear-completed |
| 21 | Routing > should allow me to display active items | p1 | @routing | routing |
| 22 | Routing > should respect the back button | p1 | @routing | routing |
| 23 | Routing > should allow me to display completed items | p1 | @routing | routing |
| 24 | Routing > should allow me to display all items | p1 | @routing | routing |
| 25 | When page is initially opened > should focus on the todo input field | p2 | @focus | initial-state |
| 26 | No Todos > should hide #main and #footer | p2 | @initial-state | initial-state |
| 27 | New Todo > should show #main and #footer when items added | p2 | @todo-create | new-todo |
| 28 | Routing > should highlight the currently applied filter | p2 | @routing | routing |
| 29 | Contrast > has good contrast when empty | p2 | @a11y | contrast |
| 30 | Contrast > has good contrast with several todos | p2 | @a11y | contrast |
| 31 | Editing > should cancel edits on escape | p1 | @editing | editing (last: one 4017 ms outlier in the first Cypress run, 1.1 s in the next two) |

## Do not migrate

| Old test | Reason |
| --- | --- |
| (top level) adds 2 todos | Duplicate. The test's own comment calls it "a very simple example helpful during presentations". It types two todos and counts two rows; `adds items` types four and counts four, and `should allow me to add todo items` checks the text of both. Dropping it loses no behaviour. Decision recorded in `parity.md` |

## Not in the backlog on purpose

- A new smoke spec (`smoke.spec.ts`) was added in phase 3. It has no old counterpart and is not part of the 32.
- Gaps found in phase 1 (delete button, filtered URL on load, and the rest of the list in the assessment) are not added here. Adding tests for behaviour the old suite never checked is a separate decision, not part of making the new suite equal the old one.

Counts: 31 to migrate + 1 not migrated = 32 = the phase 1 baseline.
