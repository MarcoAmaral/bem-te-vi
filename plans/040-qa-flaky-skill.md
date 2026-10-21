# Plan 040: The `qa-flaky` skill (detect, quarantine and fix flaky tests)

> **Executor instructions**: This plan was approved by Marco on 2026-10-14 (see "Approval gate"). Work on `feat/qa-flaky-skill`:
> first the skill with its frontmatter check passing, then the pointer updates, then the README, then
> the worked example. One concern per commit. Run every verification command and read its output. If
> anything in "STOP conditions" occurs, stop and report. When done, update this plan's row in
> `plans/README.md`.
>
> **Drift check (run first)**: `git diff --stat a2f08e7..HEAD -- .claude/rules/testing-guidelines.md .claude/commands/qa-automate.md .claude/commands/qa-defect.md .claude/commands/qa.md .claude/skills .claude-plugin generate-adapters.sh README.md examples plans/034-*.md`
> A change to any of these since planning means a line reference below may be stale: re-read it
> before relying on it. A change to the flaky protocol (`testing-guidelines.md:103-111`) is a STOP.

## Status

- **Priority**: P2
- **Effort**: S (shrunk from the plan 019 row; see "Verdict")
- **Risk**: LOW-MED (must not contradict an always-loaded rule)
- **Depends on**: plan 032 (see "Known hashes"), plan 034 (reference placement), plan 029 (the tag
  taxonomy that lists `@flaky` and `@quarantine` as optional tags, merged)
- **Category**: feature (new shipped skill)
- **Planned at**: commit `a2f08e7` (`github/main`), 2026-10-14
- **Decided by Marco, 2026-10-14**: approved as a short skill (see "Approval gate").
- **Source**: plan 019 phase 13, row `qa-flaky`
- **Implemented**: 2026-10-18, PR #152, in this private repository, before plan 020 part B's public cut-over

## Why this matters

A flaky test is one whose verdict changes on unchanged code. Each one teaches the team to re-run
instead of read, and a suite that is re-run until green has stopped being a regression safety net.
The package already says what to do with a flaky test (the protocol in the always-loaded rule) and
how to hunt one in Playwright, but nothing **finds** them across runs, tells a timing bug in the test
from a real intermittent defect in the product, or keeps the quarantine honest over the two sprints
the rule allows. The failure the skill prevents is **quarantine as a graveyard**: tests tagged
`@quarantine`, excluded from every run, never fixed, and the real defect some of them were catching
never reported.

## Current state (overlap check)

The protocol and most of the procedure already exist. The skill must **reuse them verbatim by
pointer and contradict nothing**:

| Content | Where | Text (quoted or summarised) |
| --- | --- | --- |
| The protocol (the one source of truth) | `.claude/rules/testing-guidelines.md:103-111` | "Identify flaky test → Tag with `@flaky` and open a Defect Report"; "Move test to `@quarantine` immediately (excludes it from `@smoke` and `@regression` runners)"; "Resolve or delete the test within **2 sprints**"; "If more than 5% of the suite is quarantined, escalate to the Development Lead" |
| Tags | `testing-guidelines.md:97-99` | `@flaky`, `@quarantine` are optional tags (plan 029 step 3) |
| Hunting steps in Playwright | `.claude/commands/qa-automate.md:500-520` | Trace viewer; remove `waitForTimeout`; wait for the network response; `--repeat-each=100` on one spec |
| No sleeps, web-first assertions, isolation | `.claude/rules/code-style-qa.md`; `automation-code.md:29-44` | The usual root-cause fixes |
| Retries policy | `qa-automate.md:226` (`retries: process.env.CI ? 1 : 0`), `qa-migrate/SKILL.md:57` ("retries are for CI noise after the fact, not a fix") | |
| Migration-time flakiness | `.claude/skills/qa-migrate/SKILL.md:138-147` | Repeat-run before "migrated"; quarantine, not retries. Line 147: "A dedicated flaky-test skill is not part of this package yet" |
| Pointer for tools | `.claude/skills/qa-reference/references/test-tools.md:70` | "For handling non-deterministic tests, see the flaky-test steps in `/qa-automate` and the quarantine protocol" |
| Intermittent defects in reports | `.claude/commands/qa-defect.md:175` | "Test 3-5 times before claiming 'Always' — intermittent bugs need retry count" |
| Tag-filter syntax (exclusion) | `testing-design.md` "CI/CD Pipeline & Filtering Reference" | `--grep-invert` example |

Measured gap (`grep -rn -i "flak\|quarantin\|repeat-each\|retries" .claude --include=*.md`, planning
time): nothing on (a) detecting flakiness from run history (verdict variance across runs of the same
commit, Playwright's own `flaky` outcome when a retry passes, JUnit XML across CI runs); (b)
classifying a flake's cause, and in particular separating **test** defects (timing, order dependence,
shared data) from **product** intermittent defects (races, eventual consistency) and **environment**
causes; (c) running the quarantine as a ledger with owner, opened date, the 2-sprint deadline and the
5% ratio computed, not estimated; (d) the exit: fix proven by repeat runs, or deletion recorded.

**Verdict: shrink.** The plan 019 row ("detect, quarantine, fix") would mostly restate the rule and
`qa-automate.md:500-520`. Build a short skill (target ≤ 7 KB `SKILL.md`, no reference file) that adds
only (a)-(d) and points to the rest. If Marco prefers, the alternative is no skill at all: a
"Flaky tests" reference file under `qa-reference` with the same (a)-(d) content (decision 1); the
plan's steps are written so either can be done.

Package plumbing (same facts as plan 039, "Current state"): skills are discovered by folder
(`generate-adapters.sh:69-91`, `.claude-plugin/plugin.json` `"./.claude/skills/"`); `adapters/` is
gitignored (`.gitignore:33-34`); router at `.claude/commands/qa.md:58-61,82-87`; README at `:153`,
`:196-198`, `:442`; examples table `examples/README.md:7-12`.

## ISTQB CTFL v4.0.1 grounding

Verified against `<local copy of ISTQB_CTFL_Syllabus_v4.0.1.pdf>` (v4.0.1,
2024-09-15), section text read on 2026-10-14. Cite only these:

| Section | What it supports |
| --- | --- |
| §1.2.3 Errors, Defects, Failures, and Root Causes | Some defects "only result in a failure in specific circumstances"; "Failures can also be caused by environmental conditions". A flake is a failure whose cause is still unknown: it may be a test defect, a product defect or the environment. Root cause analysis is the step that decides |
| §1.1.2 Testing and Debugging | Finding the cause of a failure is debugging (reproduction, diagnosis, fixing); confirmation testing then checks the fix. The skill's "repeat-run until it fails, then diagnose" is reproduction and diagnosis |
| §5.5 Defect Management | Reported anomalies "may turn out to be real defects or something else (e.g., false-positive result…)"; a defect report carries the test environment, logs and status (including "deferred"). The `@flaky` defect report the rule requires follows this |
| §2.2.3 Confirmation Testing and Regression Testing | Regression suites "are run many times" and are a strong candidate for automation; with CI it is good practice to include automated regression tests. Context for why an untrustworthy regression suite is costly — not a claim the syllabus makes about flakiness |
| §6.2 Benefits and Risks of Test Automation | Benefit: information about "failure rates"; risk: relying on a tool too much, ignoring critical thinking (auto-retry as a fix is that risk) |

**Not cited, because the syllabus does not say it:** flaky tests, quarantine, retries, flake rate.
"flaky", "intermittent" and "non-determin*" do not occur in the extracted text. The skill says so,
as `qa-migrate/SKILL.md:28` does.

## Research basis

Read for scope, never copied; descriptions and headings only, 2026-10-14:

- `petrkindlmann/qa-skills` (MIT) `skills/test-reliability/SKILL.md` (407 lines: flake
  classification, environment-aware and data "healing", self-healing locators, quarantine lifecycle).
- `QAIA-Project/QAIA` (MIT) `plugins/qaia-playwright/skills/flaky-detect/SKILL.md`: detect verdict
  variance from JUnit XML / Cucumber JSON across 3+ runs; "flags with evidence only — never retries,
  quarantines, or fixes automatically".

Deliberately not adopted: **self-healing locators**. A test that repairs its own selector can turn a
real UI regression into a pass, against the red-green rule (`automation-code.md:88-94`).

## What the skill does

`.claude/skills/qa-flaky/SKILL.md`, four steps, with one living file `flaky/ledger.md`:

1. **Detect.** From evidence, never memory: (a) the CI history the repository exposes (JUnit XML or
   the runner's JSON across runs of the **same commit**); (b) Playwright's `flaky` outcome (failed,
   then passed on retry: it is in the report even when the run is green); (c) a repeat run of a
   suspect spec, `--repeat-each=N` with `--workers` matching CI. Record runs, failures and commit.
   Say the limit: zero failures in N runs bounds the failure rate, it does not prove zero.
2. **Classify the cause** (one row each): test timing (sleep, missing web-first wait), order or
   shared-state dependence (passes alone, fails in the suite, or the reverse with `--workers=1`),
   test data collision on a shared environment, environment (rate limit, slow dependency, resource
   contention), **product intermittent defect** (race, eventual consistency, caching). The last goes
   to `/qa-defect` as a product defect with the observed frequency (`qa-defect.md:175`), not to
   quarantine alone.
3. **Quarantine per the rule**, and keep the ledger: test ID, cause class, defect report link, owner,
   date quarantined, deadline (= date + 2 sprints, the team's sprint length), status. Compute the
   quarantined share from the runner's test count (`npx playwright test --list`), and when it is
   above 5% say so and name who to escalate to (the rule's "Development Lead"). The exclusion is a
   `--grep-invert @quarantine` on the `@smoke` and `@regression` jobs (`testing-design.md` filter
   syntax), and a separate non-blocking job keeps running the quarantined tests so a fix is visible.
4. **Exit.** A fix counts when the spec passes a repeat run of the agreed size on the fix commit
   **and** still fails when the behaviour it checks is broken (red-green). Otherwise, at the
   deadline: delete it with the reason recorded in the ledger, or extend it with a recorded decision.
   Never close by raising `retries`.

## Commands you will need

| Purpose | Command | Expected |
| --- | --- | --- |
| Frontmatter | `./tests/test-frontmatter.sh` | exit 0, counts the new skill |
| Reference pointers | `./tests/test-reference-links.sh` | exit 0 |
| Adapters | `./generate-adapters.sh --clean && ./tests/verify-adapters.sh` | exit 0 |
| Plugin | `./tests/plugin/verify-plugin.sh` | exit 0 |
| Known hashes | `./generate-known-hashes.sh --check` | exit 0, unchanged |
| Lifecycle, conformance | `./tests/test-lifecycle.sh`, `./tests/conformance/run.sh` | pass |
| Rules size | `./tests/test-rules-size.sh` | unchanged (no rule edited) |
| Protocol untouched | `git diff a2f08e7 -- .claude/rules/testing-guidelines.md` | empty |
| Markdown lint | `npx --yes markdownlint-cli@0.49.1 --dot <changed .md files>` | no output |

## Scope

**In scope**: `.claude/skills/qa-flaky/SKILL.md`; `.claude/commands/qa.md` (skill line and routing
row); the two stale pointers `qa-migrate/SKILL.md:147` and `references/test-tools.md:70` (point them
at the new skill); `README.md`; `examples/flaky/` (or a subfolder of an existing example, Step 5);
`examples/README.md`; `plans/README.md`.

**Out of scope**: the protocol text in `testing-guidelines.md` (any change is a rule change, its own
plan, with the rules-size cap); `qa-automate.md:500-520` (stays; the skill points to it); retries
defaults; CI templates.

## Git workflow

Branch `feat/qa-flaky-skill`. Conventional Commits, one concept each, **no AI attribution lines**:

1. `feat: add the qa-flaky skill for detecting and retiring flaky tests` (skill + `qa.md` router lines)
2. `fix: point the migration and tool references at the qa-flaky skill` (the two stale sentences:
   `qa-migrate/SKILL.md:147` says no such skill exists, which becomes false)
3. `docs: list the qa-flaky skill in the README`
4. `docs: add the qa-flaky worked example`
5. `docs(plans): record plan 040 outcome`

## Steps

### Step 1: re-run the overlap check

Repeat the grep and the table above. **STOP** if the protocol changed, or if another file now covers
detection across runs or the ledger.

### Step 2: placement

Plan 034 (`plans/034-public-content-and-structure.md`, drafted in parallel, read at the end of this
planning session) changes two things here; implement after its PR B merges:

- It **moves** "Flakiness hunting" (`qa-automate.md:500-521`) verbatim into
  `qa-reference/references/automation-ci.md` (034 step 5). The skill points there, not to
  `/qa-automate`, and the `references/test-tools.md:70` pointer this plan fixes must name the new
  file too.
- **Pointer convention** (034 step 3): rules by name ("the `testing-guidelines` rule, Flaky Test &
  Failure Protocols"), references as `qa-reference/references/<file>.md`, commands by slash name,
  scripts by name with a fallback. No `.claude/...` paths.

No reference file is planned. If 034 is rejected or changed, follow what merged.

### Step 3: write the skill

Frontmatter draft (check against the finished body; ≤ 1024 characters):

```yaml
---
name: qa-flaky
description: "Finds flaky tests from run history and repeat runs, classifies each by cause (test timing, order or shared data, environment, or a real intermittent product defect), quarantines it under the package's flaky-test protocol with an owner and deadline in a ledger, and retires it only with a repeat-run and red-green proof. Use when tests pass and fail on the same code, when asked about flaky, intermittent or quarantined tests, or about retries in CI."
---
```

The body opens with: "The protocol is `testing-guidelines.md` §Flaky Test & Failure Protocols; this
skill applies it and adds nothing that contradicts it." No number from the protocol (2 sprints,
5%) is restated as a different value; quote it or point to it.

### Step 4: route and repoint

`qa.md`: skill-list line beside `:60`; routing row `"flaky", "intermittent", "quarantine",
"retries"` → **Flaky Test Skill** (`skills/qa-flaky/`). Commit 1. Then the two pointer sentences.
Commit 2.

### Step 5: worked example

Two real public targets already in `examples/`, so nothing new is introduced:

- **ServeRest API suite** (`examples/serverest/qa-automate/`, 16 tests, `retries: 0`, against a
  shared public service whose README already warns "A run on another day may fail for reasons
  outside the suite"). Run it with `--repeat-each=10` (160 executions; the README notes about 2 s per
  test, so roughly 6 minutes; Marco may lower N). Expected: TC-CART-030 fails every time (a
  **deterministic** failure, a real defect, `run-output.txt`): the skill must classify it as *not*
  flaky. Any other variance is real flakiness to classify.
- **TodoMVC migrated suite** (`examples/todomvc-cypress-to-playwright/`), which already has
  `repeat10-*.txt` outputs (e.g. `repeat10-editing.txt`: "50 passed"). Re-run with `--repeat-each=20
  --workers=4` to look for order or parallelism effects.

Success criteria, written before running:

- The ledger lists every test with a non-constant verdict, with runs/failures/commit; deterministic
  failures are listed separately as not flaky.
- If **no** flake appears, the example says so, gives the bound ("0 failures in N runs"), and then
  exercises steps 2-4 on **one seeded flake** in a clearly named file (`seeded-flake.spec.ts`, with a
  timing race introduced on purpose and stated in the README), so the classify, quarantine and exit
  steps are shown. A seeded flake is never presented as found.
- The exit proof for the fixed flake is kept: repeat-run output and a red-green run.
- No screenshots or recordings are needed; if any are kept, `test-evidence.md` applies and
  `.claude/hooks/check-test-evidence.sh` runs clean.

Kept: `README.md` (prompt, model, date, version, tooling, honest limits), `flaky/ledger.md`, the
run outputs, any seeded spec. Unedited apart from redacted scratch paths. Row in
`examples/README.md`. Commit 4.

### Step 6: verify and record

Run the commands table; write an "Outcome" section here and update `plans/README.md`. Commit 5.

## Known hashes and plan 032

A new unreleased file changes nothing in `.qa-skills-known-hashes` (built from tags only,
`generate-known-hashes.sh:36-50`). **But** commit 2 edits two **released** files
(`qa-migrate/SKILL.md`, `references/test-tools.md`). That is normal (older hashes stay in the list,
so an untouched older copy is still adopted; conformance case 003 covers it), and `--check` must
still pass without regenerating. Plan 032 keeps its frozen list open until the cut-over (`# state: open`), so a private release of this skill is added to it by the release workflow's refresh step; nothing extra is needed.

## Done criteria

- [ ] All commands pass; outputs in the PR.
- [ ] `git diff a2f08e7 -- .claude/rules/testing-guidelines.md` is empty.
- [ ] `grep -rn "not part of this package yet" .claude/skills/qa-migrate` → no match.
- [ ] `SKILL.md` ≤ 7 KB, no restated protocol values that differ from the rule.
- [ ] The example meets its criteria or its README says which failed.
- [ ] `plans/README.md` row for 040 added and updated.

## STOP conditions

- The protocol in `testing-guidelines.md:103-111` changed since planning, or the skill seems to need
  a different value (another deadline, threshold or tag): that is a rule change; stop and report.
- The overlap check finds detection or a ledger already covered: shrink to a pointer edit.
- The example's public targets are unreachable on the run date: report; do not substitute.
- Marco picks the "reference file, no skill" alternative: drop Steps 3-4's skill and router parts,
  keep the content as a `qa-reference` reference (listed in `qa-reference/SKILL.md`).

## Rejected approaches

- **Restate the protocol in the skill**: two copies drift; plan 029 spent a PR undoing exactly that
  for the release gate and tags.
- **Self-healing locators and automatic retries as the fix**: both hide failures; see "Research basis".
- **Auto-quarantine by a script**: the rule requires a defect report and a human decision; the skill
  proposes, the team decides (QAIA's flaky-detect makes the same call).
- **Cite ISTQB for flakiness**: the syllabus has no such text.

## Maintenance notes

- If the protocol's numbers change, the skill needs no edit as long as it only points to them;
  check that it still does.

## Approval gate

Approved by Marco on 2026-10-14. Decisions:

1. A short skill.
2. Repeat counts as proposed: 10 for ServeRest, 20 for TodoMVC.
3. Released before the public cut-over.

## Outcome

Implemented 2026-10-18 on `feat/qa-flaky-skill`, PR #152. Marco asked on 2026-10-18 for all the
remaining work; the approval gate already held his three decisions, so no default was needed
("Default used" does not apply).

### Drift check and overlap check (Step 1)

- `git diff --stat a2f08e7..HEAD` over the listed paths showed plan 034's moves (many lines). The
  flaky protocol text (`testing-guidelines.md`, "Flaky Test & Failure Protocols") is **unchanged**:
  the only diff to that file since `a2f08e7` is one pointer sentence in "Test Design Reference".
  No STOP.
- Line references in this plan are stale after plan 034. The skill therefore points by name: the
  hunting steps moved to `qa-reference/references/automation-ci.md` ("Flakiness Hunting"), and
  `references/test-tools.md` already pointed there; it now also names the skill.
- The grep showed no detection-across-runs text and no ledger anywhere in `.claude`: no shrink to a
  pointer edit.

### What was built

- `.claude/skills/qa-flaky/SKILL.md` (about 6 KB, no reference file). It restates no number from the
  protocol: the deadline and the escalation share are read from the rule.
- `/qa`: a skill line and the routing row for "flaky", "intermittent", "quarantine", "retries".
- `qa-migrate/SKILL.md`: the sentence "A dedicated flaky-test skill is not part of this package yet"
  became false and now points at the skill (grep for "not part of this package yet" in `qa-migrate`
  returns nothing).
- README: skills line (four to five), activation table row, project structure line.
- `examples/flaky/` with the ledger, run outputs and a seeded flake; `examples/README.md` row.

### Example result (2026-10-18)

- ServeRest, `--repeat-each=10`, 2 workers: 160 executions, 32 failures. TC-CART-030 is a
  deterministic defect (listed as not flaky). 21 of the other 22 failures were HTTP 429 in setup:
  nine tests, one environment cause. One failure stays "unknown". `--workers=1`: no 429.
- TodoMVC, `--repeat-each=20 --workers=4`: 640 executions, 0 failures. The plan's criterion "if no
  flake appears, say so, give the bound, then exercise steps 2 to 4 on one seeded flake" was
  applied to this target: `seeded-flake.spec.ts` (2 of 20 failures), fixed 100 of 100, red when the
  behaviour is broken. The seeded flake is labelled as seeded everywhere it appears.

### Decisions and findings recorded

- The plan's example criterion also implied quarantining what is found. For ServeRest the skill
  proposed one environment fix and **not** nine quarantines (9 of 16 tests would exceed the
  protocol's threshold to hide one cause). This is the sort of judgement the "proposes, team
  decides" line exists for. Nothing was applied to either suite.
- The plan said `repeat10-*.txt` outputs exist for TodoMVC; in the tree the outputs are under
  `migration/run-output/` and `review/`. Immaterial: the example re-ran the suite.
- The exit proof used 100 repeats, not the 20 used to detect: a flake at 1 run in 10 passes 20 clean
  runs about 12% of the time. The skill says "the agreed size" and leaves the number to the team.

### Verification

- Local Linux CI (`qa-ci-local.sh`): 16 of 17 steps pass. The single failure is lifecycle Test 20
  ("`.claude` survived uninstall after a no-manifest upgrade"), the known failure fixed by
  `fix/update-adopts-current-files`.
- Windows PowerShell and macOS not run locally (no PowerShell file touched).
- Known hashes: `./generate-known-hashes.sh --check` passes unchanged (step `known-hashes`).
