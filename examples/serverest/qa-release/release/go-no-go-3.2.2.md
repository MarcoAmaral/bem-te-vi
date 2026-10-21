# Go/No-Go Record: ServeRest API 3.2.2

## Candidate

| Field | Value |
| ----- | ----- |
| Version | 3.2.2 |
| Build | N/A — a public service publishes a version, not a build identifier; the version string is the only identity available |
| Environment | `https://serverest.dev`, the one public instance |
| Version confirmed from | The `version` field the service itself returns at `https://serverest.dev/` on 2026-10-18 (the deployment record for a service we do not run) |
| Date | 2026-10-18 |
| Gate loaded from | `qa-plan`, Quality Gates: the release gate and the standard exit criteria. The repository under test has no Definition of Done of its own |
| Who decides | N/A — no stakeholder: a public practice API has no Product Owner or QA Lead for this record |

## Criteria

One row per criterion of the standard exit criteria. Run evidence is [`../run-output.txt`](../run-output.txt) (2026-10-18: 15 passed, 1 failed). Case IDs and tags are from [`testcases.md`](../../qa-agentic/cart-no-duplicate-product/testcases.md).

| # | Criterion | Evidence | Build | Status |
| - | --------- | -------- | ----- | ------ |
| 1 | Every release gate case executed and passing | No case in `testcases.md`, `checklist.md` or `requirements.md` carries `@gate`, so there is no gate set to evaluate | 3.2.2 | **Not met: no evidence** |
| 2 | Every P0 test case executed and passing | 8 cases are tagged `@p0` (TC-CART-001, 002, 003, 014, 018, 019, 020, 021). 3 were run and passed (001, 002, 019); 5 were never run | 3.2.2 | **Not met**: 5 of 8 not executed |
| 3 | Every P1 test case executed and passing, or each failure has a recorded Product Owner exception | 18 cases are tagged `@p1`. 11 were run and passed; 7 were never run (TC-CART-005, 008, 010, 012, 017, 023, 029). No P1 case failed, so no exception is needed for a failure | 3.2.2 | **Not met**: 7 of 18 not executed |
| 4 | Zero open Critical-severity defects | One known defect, SR-005 (string `quantidade` accepted, TC-CART-030 fails). No defect report was ever written for it, so it has no severity as a defect. The static review rated the finding Major, which is a finding rating, not a defect severity | 3.2.2 | **Not met: no evidence** (severity not recorded) |
| 5 | Zero open High-severity defects, or recorded Product Owner exceptions | Same as row 4. No exception recorded | 3.2.2 | **Not met: no evidence** (severity not recorded) |
| 6 | Smoke regression suite passes on all supported target browsers | The smoke cases are the 8 `@p0` cases above, 3 run and passed, and all are API tests. No list of supported browsers exists and the front end `https://front.serverest.dev` was not exercised | 3.2.2 | **Not met**: smoke incomplete; browsers N/A — API only |
| 7 | Test summary signed off by QA Lead and Product Owner | Nobody holds either role for this record | 3.2.2 | **Not met**: no sign-off; N/A — no stakeholder |

## Gate cases

| ID | What it proves | Result |
| -- | -------------- | ------ |
| N/A — none marked | No case was tagged `@gate` when the cases were written ([`testcases.md`](../../qa-agentic/cart-no-duplicate-product/testcases.md)), so the gate as `qa-plan` defines it does not exist for this candidate | N/A — not evaluable |

For reference only, and not the gate: the 16 cases that were run are TC-CART-001, 002, 004, 006, 009, 011, 013, 015, 016, 019, 022, 024, 025, 026, 028 and 030. 15 passed. TC-CART-030 failed.

## Exceptions

| Criterion | Accepted by | Date | Risk accepted |
| --------- | ----------- | ---- | ------------- |
| N/A — none recorded | N/A — no stakeholder | N/A | N/A |

## Residual risks

| Risk | Covered by | State |
| ---- | ---------- | ----- |
| `quantidade` sent as a string is accepted and `quantidadeTotal` comes back as a string (`"02"`) | TC-CART-030 (`@p2`) | Open, test fails today |
| 17 of 33 cases never run, including 5 of 8 `@p0` | N/A — nothing covers them | Open |
| Cart behaviour through the browser front end | N/A — no case written | Not assessed |
| No risk register exists for this candidate | N/A | The residual-risk list above is built from the cases only |
| Rollback plan | N/A — not ISTQB content | Not asked: there is no team to ask for a public service |

## Defects not fixed

| ID | Severity | Caused by the change |
| -- | -------- | -------------------- |
| SR-005 (finding in [`review.md`](../../qa-static/review.md); no `DR-` report exists) | N/A — never recorded as a defect severity | N/A — no change is under test; whether it predates 3.2.2 is unknown |

## Not caused by the change

N/A — no change is under test, so nothing can be separated out as pre-existing. The other 13 findings in [`review.md`](../../qa-static/review.md) are about the documentation or are questions, and none was verified as a software defect.

## Not run

| Case | Why | Resume point |
| ---- | --- | ------------ |
| TC-CART-003, 014, 018, 020, 021 (`@p0`) | Not automated or run | Automate and run; 018 and 020 need two products and a second cart |
| TC-CART-005, 008, 010, 012, 017, 023, 029 (`@p1`) | Not automated or run | Same |
| TC-CART-007, 027, 031, 032 (`@p2`) | Not automated or run | Same |
| TC-CART-033 (`@manual`) | Exploratory charter, no session was held | Hold the session |

## Recommendation

**NO-GO.** Every one of the seven criteria is not met, and the first has no gate set to measure. The reason is missing evidence, not a failing build: 15 of the 16 cases that were run passed, and the one failure is a `@p2` case, which the P1 criterion does not count. To change the recommendation: tag the gate cases, run the 5 unrun `@p0` and 7 unrun `@p1` cases, file SR-005 as a defect report with a severity, and name who signs off.

QA recommends. No stakeholder decided: this is a public practice API and there is no one to accept the risk.
