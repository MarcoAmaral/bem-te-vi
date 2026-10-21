# Example: `qa-flaky` on two public suites

The `qa-flaky` skill's four steps (detect, classify, quarantine, exit) applied to two suites already
in this repository: the ServeRest cart API suite and the migrated TodoMVC suite. Nothing new was
introduced as a target, and neither suite was edited.

```text
flaky/
├── README.md
├── flaky/ledger.md                 # the ledger the skill keeps: runs, causes, proposals, exit proof
├── seeded/
│   ├── seeded-flake.spec.ts        # a flake written on purpose (see "The seeded flake")
│   └── seeded-flake.fixed.spec.ts  # its fix, with a switch that breaks the behaviour under test
└── runs/                           # the real outputs the ledger cites
```

## Prompt

```text
Use the qa-flaky skill on examples/serverest/qa-automate (repeat each test 10 times) and on
examples/todomvc-cypress-to-playwright (repeat each test 20 times, 4 workers). Keep the ledger in
flaky/ledger.md.
```

## Run details

| Item | Value |
| ---- | ----- |
| Date | 2026-10-18 |
| Package version | 4.0.1 plus the unreleased `qa-flaky` skill |
| Files followed | `.claude/skills/qa-flaky/SKILL.md`, the `testing-guidelines` rule |
| Model | An AI coding assistant following the skill file (Claude Sonnet 5.5, `claude-sonnet-5-5`) |
| Tooling | Node v24.16.0, `@playwright/test` 1.64.1 (ServeRest) and 1.64.0 (TodoMVC), Chromium |
| Targets | `https://serverest.dev` (live, shared); TodoMVC upstream `4000662` plus `upstream-changes.diff`, built locally |

The prompt above is the request as it was carried out. The assistant read the skill and executed its
steps by hand; the skill is a procedure, not a script, and nothing was triggered by the skill
loader.

## Result

| Target | Executions | Failures | Verdict |
| --- | --- | --- | --- |
| ServeRest, 2 workers | 160 | 32 | 9 flaky tests, all from one cause (HTTP 429 in setup), plus 1 deterministic defect |
| ServeRest, 1 worker | 160 | 10 | No 429; the 10 are the deterministic defect (TC-CART-030) |
| TodoMVC, 4 workers | 640 | 0 | No flake seen: 0 failures in 640 executions (20 per test) |
| Seeded flake | 20, then 100 fixed | 2, then 0 | Detected, classified as test timing, fixed with proof |

- **A deterministic failure is not a flake.** TC-CART-030 (a string `quantidade` accepted with
  `201`) failed on its assertion every time it got that far. It is listed apart and stays a defect.
  Two of its ten executions failed earlier, in setup, on 429: the noise hid the defect in those runs.
- **One cause behind nine flaky tests.** 21 of the 22 other failures are HTTP 429 returned by the
  shared service while a test created its user, product or login. The skill's classification
  (environment, not a product defect, not nine test defects) points at one fix in the suite's
  setup, not at nine quarantines. Quarantining them would have put 9 of 16 tests out of the
  `@smoke` and `@regression` runs, far above the protocol's escalation threshold.
- **One unknown stays unknown.** `cancelling a cart restores stock` failed once with `quantidade`
  `undefined` on a read whose status the test does not assert. A 429 body is likely; it is not shown.
- **The TodoMVC bound.** "0 failures in 640" is a bound for Chromium on one machine in one run, not
  proof of stability.

## The seeded flake

TodoMVC showed no flake, so steps 2 to 4 are demonstrated on one flake written for this example.
**It is not a TodoMVC defect and was not found.** `seeded/seeded-flake.spec.ts` adds a todo and
reads the row with a non-retrying `isVisible()`. An in-page script hides the new row and shows it
again after a random 0 to 10 ms, standing in for a slow render. The race is simulated; the fault
(a non-retrying check after an action) is the common real one.

1. Detect: 2 failures in 20 runs.
2. Classify: test timing (non-retrying read; the product is behaving as designed).
3. Quarantine: the ledger row shows what the skill records; the tags were not applied to a real suite.
4. Exit: the fixed spec uses a web-first `toBeVisible()`. It passed 100 of 100 repeats, and failed
   when the row was never shown again (`BREAK_RENDER=1`), so it still catches the behaviour it names.

To reproduce, copy a spec into `playwright/tests/` of the TodoMVC working copy described in
[`../todomvc-cypress-to-playwright/README.md`](../todomvc-cypress-to-playwright/README.md), and run
`npx playwright test seeded-flake --repeat-each=20 --workers=4`. The seeded specs import
`../fixtures` from that suite.

## Honest limits

- **The ledger is a proposal.** No test was tagged, excluded or deleted; the ServeRest suite
  belongs to its own example and TodoMVC had nothing to quarantine. Owners and deadlines read "none"
  or "not applicable" because there is no team and no sprint calendar.
- **The 429 diagnosis is supported, not proven.** With one worker the 160 executions had no 429 in
  `runs/serverest-repeat10-workers1.txt`; the service's rate limit is not documented in this
  repository, and one run of each is a small sample. Only the 2-worker run failed on 429, but the two
  runs were minutes apart and the service state in between is unknown.
- **ServeRest is shared and live.** A run on another day may give other numbers, which is the point
  of the example and also why its counts are not reproducible.
- **Per-execution data for the 2-worker run came from Playwright's JSON reporter**, summarised by a
  small throwaway script into `runs/serverest-repeat10-summary.txt`; the raw JSON was not kept.
  The other runs are the list reporter's console output, unedited apart from ANSI colour codes and
  the temporary directory, replaced by `<run-dir>` and `<todomvc>`.
- **The seeded flake is artificial.** Its 10% failure rate comes from the simulated delay and says
  nothing about real flake rates.
- **Chromium only, one machine.** No Firefox or WebKit, no CI history, no JUnit XML across runs: the
  skill's CI-history source was not exercised, only repeat runs.
- **Evidence rule.** No screenshots or recordings were taken, so `test-evidence.md` has nothing to
  check here.
