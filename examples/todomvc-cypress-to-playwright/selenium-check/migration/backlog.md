# Migration backlog (phase 2)

Priorities are my assignment: the old suite has only `smoke` and `regression` groups, so `@p0`..`@p3` do not exist
in the source and no business owner was available to confirm them. Treat them as assumptions.

| Order | Old test | Suite tag | Priority (assumed) | Why this order |
| --- | --- | --- | --- | --- |
| 1 | `addsATodo` (3 data rows) | `@smoke` (from group `smoke`) | `@p0` | Critical journey: nothing else works without adding; stable; becomes the **golden reference** |
| 2 | `completesATodo` | `@regression` | `@p1` | Core action. Contains `Thread.sleep(500)`, so it is a suspected-flaky test and is **re-derived**, not copied. Per the skill, flaky tests go last, so it is ordered after the stable ones |
| 3 | `filtersActiveTodos` | `@regression` | `@p1` | Core navigation |
| 4 | `clearsCompletedTodos` | `@regression` | `@p2` | Secondary action |
| 5 | `editsATodoOnDoubleClick` | `@regression` | `@p2` | Secondary action |
| last | `completesATodo` (suspected flaky) | | | Migrated after 1, 3, 4, 5; see parity |

Actual order of migration: 1, 3, 4, 5, then `completesATodo`.

## Do not migrate

None. No duplicate, disabled or obsolete tests. (`TodoPage.assertCount` is a helper, not a test; it is replaced by an assertion in the specs.)
Not-in-scope: the Cypress suite in `app/cypress/`.
