# Flaky test ledger

Kept by the `qa-flaky` skill. Dates are 2026-10-18. Nothing here was applied to the example suites:
the skill proposes, a team decides, and these suites belong to other projects. Where a row says
"proposed", no tag was added and no test was moved.

## Detection runs

| Target | Command | Executions | Failures | Commit |
| --- | --- | --- | --- | --- |
| ServeRest cart suite (16 tests) | `npx playwright test --repeat-each=10` (2 workers, from the config) | 160 | 32 | package `71312a3`, suite as committed in `examples/serverest/qa-automate/` |
| ServeRest cart suite | `npx playwright test --repeat-each=10 --workers=1` | 160 | 10 | same |
| TodoMVC migrated suite (32 tests) | `npx playwright test --repeat-each=20 --workers=4` | 640 | 0 | upstream `4000662` plus `upstream-changes.diff` |
| Seeded flake (1 test) | `npx playwright test seeded-flake --repeat-each=20 --workers=4` | 20 | 2 | `seeded/seeded-flake.spec.ts` |

"0 failures in 640 executions" bounds the TodoMVC failure rate. It does not prove the suite is
stable: Chromium only, one machine, one day.

## Not flaky: a deterministic failure

| Test | Executions | Result | Note |
| --- | --- | --- | --- |
| `quantidade as the string '2' is rejected` (TC-CART-030) | 10 | 8 failed on the assertion (`400` expected, `201` received); 2 failed in setup on HTTP 429 | The same failure every time the assertion was reached. It is the defect already reported as SR-005 in `examples/serverest/qa-static/review.md`. With `--workers=1`: 10 of 10 on the assertion. Report it as a defect; do not quarantine it as flaky |

## Flaky tests found (ServeRest, 2 workers)

Per-test counts are in `runs/serverest-repeat10-summary.txt`. All nine are in the same cart suite.

| Test | Runs | Failures | Cause class | Evidence | Defect report | Owner | Quarantined on | Deadline | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| rejects the same product listed twice (TC-CART-001) | 10 | 3 | Environment | `user setup` or `product setup` got HTTP 429 | None filed (example) | None (example) | Not applied | Not applicable | Proposed |
| accepts the same product listed once (TC-CART-002) | 10 | 4 | Environment | `user setup` got 429 | None filed | None | Not applied | Not applicable | Proposed |
| duplicate rejection carries the exact message (TC-CART-004) | 10 | 3 | Environment | `user setup` got 429 | None filed | None | Not applied | Not applicable | Proposed |
| duplicate rejection lists the repeated id (TC-CART-006) | 10 | 4 | Environment | `user setup` got 429 | None filed | None | Not applied | Not applicable | Proposed |
| rejects the same product with different quantities (TC-CART-009) | 10 | 2 | Environment | `user setup` got 429 | None filed | None | Not applied | Not applicable | Proposed |
| rejected duplicate request leaves the user without a cart (TC-CART-011) | 10 | 2 | Environment | `user setup` got 429 | None filed | None | Not applied | Not applicable | Proposed |
| request without an Authorization header is rejected (TC-CART-028) | 10 | 2 | Environment | `login setup` got 429 | None filed | None | Not applied | Not applicable | Proposed |
| new cart with the product of a cancelled cart is accepted (TC-CART-026) | 10 | 1 | Environment | `first cart setup` got 429 | None filed | None | Not applied | Not applicable | Proposed |
| cancelling a cart restores stock (TC-CART-025) | 10 | 1 | **Unknown**, probably environment | `quantidade` was `undefined` on the product read; that call's status is not asserted, so a 429 body is likely but not shown | None filed | None | Not applied | Not applicable | Proposed |

What decides the unknown: assert the status of the product read in that test, then repeat. Until
then it stays "unknown".

What the skill does with this table:

- One cause, nine tests. 21 of the 22 failures are HTTP 429 from the shared public service, all in
  setup (creating a user, a product or a login), none on an assertion about the cart. With
  `--workers=1` the same 160 executions had no 429 (see `runs/serverest-repeat10-workers1.txt`: 150
  passed, and the 10 failures are the deterministic TC-CART-030). That supports the environment
  class; it does not prove it, since the service's limit is not documented here.
- Quarantining all nine would put 9 of 16 tests (56%) in `@quarantine`, far above the protocol's
  escalation threshold, to hide one cause that the tests did not create. The proposed action is one
  environment fix (run the suite with one worker, or make the setup helper wait and retry on 429),
  decided by the suite's owner, and not nine quarantines. Raising `retries` is the move the skill
  refuses.
- No product defect is suspected: no failure happened with a successful setup.

## Seeded flake (stands for a found one, never presented as found)

Not a TodoMVC defect. `seeded/seeded-flake.spec.ts` was written for this example; its README
section says how the race is simulated.

| Test | Runs | Failures | Cause class | Evidence | Defect report | Owner | Quarantined on | Deadline | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| a newly added todo is shown in the list (seeded) | 20 | 2 | Test timing | Non-retrying `isVisible()` read straight after `Enter`; the page shows the row after a random 0 to 10 ms | None (seeded) | None (example) | 2026-10-18, illustrative: no tag was applied | The date plus the protocol's period; no sprint calendar exists for this example | Retired (fixed) |

Exit proof, on the fixed spec (`seeded/seeded-flake.fixed.spec.ts`):

1. Repeat run of the agreed size, 100: **100 passed** (`runs/seeded-fixed-repeat100.txt`). The
   size was raised from the 20 used to detect it, because a flake failing 1 run in 10 passes 20
   clean runs about 12% of the time by luck.
2. Red-green: with the behaviour the test checks broken (`BREAK_RENDER=1`, the row never shown
   again) the fixed spec **fails** on `toBeVisible` (`runs/seeded-fixed-behaviour-broken.txt`). The
   fix did not turn the test into one that cannot fail.
3. `retries` stayed `0`.
