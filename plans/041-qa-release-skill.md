# Plan 041: The `qa-release` skill (release readiness and go/no-go sign-off)

> **Executor instructions**: This plan is approved (see "Approval gate"). Work
> on `feat/qa-release-skill`. One concern per commit. Run every verification command and read its
> output. If anything in "STOP conditions" occurs, stop and report. When done, update this plan's row
> in `plans/README.md`.
>
> **Drift check (run first)**: `git diff --stat a2f08e7..HEAD -- .claude/skills/qa-plan/SKILL.md .claude/rules/testing-guidelines.md .claude/commands/qa-cases.md .claude/commands/qa-defect.md .claude/commands/qa-automate.md .claude/commands/qa.md .claude/skills .claude-plugin README.md examples plans/034-*.md`
> Any change to the release gate text (`qa-plan/SKILL.md:104-137`, `testing-guidelines.md:82,105-106,120`)
> since planning is a STOP: re-read it before anything else.

## Status

- **Priority**: P3 (P2 in plan 019; lowered because most of it exists, see "Verdict")
- **Effort**: S
- **Risk**: MED (a second statement of the release gate is the exact defect plan 029 removed)
- **Depends on**: plan 029 (the one release gate, merged as #124), plan 032 (see "Known hashes"),
  plan 034 (reference placement)
- **Category**: feature (new shipped skill), or docs if folded into `qa-plan` (decision 1)
- **Planned at**: commit `a2f08e7` (`github/main`), 2026-10-14
- **Decided by Marco, 2026-10-14**: approved as option A, a thin skill (see "Approval gate").
- **Source**: plan 019 phase 13, row `qa-release`
- **Implemented**: in this private repository, before plan 020 part B's public cut-over

## Why this matters

Before plan 029 the package had three different P1 release gates; an assistant reading two files
could pass or fail the same release (`plans/029-one-gate-one-taxonomy.md`, "Why this matters"). Plan
029 made one gate. A `qa-release` skill is useful only if it **applies** that gate at the moment of
decision and produces the record a reader can audit: which criterion, what evidence, from which
build, what is still open, who accepted which risk. It is harmful if it states its own criteria.

## Current state (overlap check)

**The one release gate, as plan 029 left it** (quoted, `github/main` @ `a2f08e7`):

- Definition and sizing: `.claude/skills/qa-plan/SKILL.md:108-116` — "Every change gets one
  **release gate**: the smallest set of cases that answers two questions, 'do the fixes work?' and
  'did the change break anything that already worked?'"; "A failed gate case blocks; a failed analysis
  case informs"; "Findings the change did not cause never gate it."
- Exit criteria: `qa-plan/SKILL.md:128-137` — every gate case passing; 100% of P0; "100% of P1 test
  cases executed and passing, or each failure has a recorded Product Owner exception"; "Zero open
  Critical-severity defects"; "Zero open High-severity defects (or recorded Product Owner
  exceptions)"; smoke on all supported browsers; "Test summary signed off by QA Lead and Product Owner".
- Policy lines in the always-loaded rule: `testing-guidelines.md:82` (`@p1` "Release blocker"),
  `:105` (smoke failure "STOP LINE"), `:106` ("P0/P1 Failures: Release block … or formal exception
  approved by PO"), `:120` (no open Critical/High-severity defects or a recorded PO exception).
- Pointers that defer to it: `qa-cases.md:30-36` ("The gate is defined, sized and kept separate from
  the full analysis in `skills/qa-plan`; follow it there"), `qa-cases.md:230-231`, `qa-automate.md:572`
  ("see the release gate in `testing-guidelines.md`").

The gate is **not** in `.claude/skills/qa-reference/references/repo-conventions.md` (that file holds
commit and lint conventions only, `:9-111`); `grep -rn "release gate" .claude` at planning shows the
sources above.

**What else exists:** completion report content and "one case per row … 'Not run — resume point'"
(`qa-plan/SKILL.md:163-176`, CTFL §5.3.2); residual risk from the register (`:69-102`); "every result
… names the build and environment version" (`:211-223`); deployed state from the deployment record
(`context-discovery.md:36-40`); migration decommission go/no-go (`qa-migrate/SKILL.md:67-78`, a
different decision, not a release).

**A conflict found while planning** (now fixed by plan 034 step 2, not here): `.claude/commands/qa-defect.md:117-118`
defines defect priority **P1 "Fix immediately, block release"** and **P2 "Fix before release"**, while
plan 029's decision says "Defect *priority* (P1–P4) is a scheduling field and is not used in gates"
and the gate counts Critical/High **severity**. A release skill reading both would block on priority.
This needs a one-line `fix:` in `qa-defect.md` (its own branch and commit, or added to plan 028/029's
follow-ups). The skill must use severity only.

**What is genuinely missing:** the go/no-go **record** itself: the gate's criteria listed with, for
each, the evidence (link, build, environment, date), the status (met / not met / exception), the
exceptions with who accepted them and the risk accepted, residual risks from the register, defects
not fixed, and a recommendation (GO, NO-GO, or GO with recorded exceptions), stating that QA
recommends and the stakeholders named in the plan decide (CTFL §5.1.3: ending testing early is
acceptable only "if the stakeholders have reviewed and accepted the risk").

**Verdict: shrink — and decide between two forms.** About 80% of a release-readiness skill is
already in `qa-plan`. Two options, both ≤ ~5 KB of new text:

- **A (recommended): a thin skill** `qa-release` that **evaluates** the gate defined in `qa-plan`
  and writes `release/go-no-go-<version>.md`. It owns no criterion. Its value is the trigger ("are
  we ready to ship?" is not "write a test plan") and the record format.
- **B: no new skill.** Add a "Go/No-Go Record" subsection to `qa-plan/SKILL.md` §Quality Gates, and a
  routing row in `qa.md` for "go/no-go", "release readiness" → Planning Skill. Cheaper (no new
  skill in every adapter) but `qa-plan` is already 18.7 KB and its description would have to carry
  a second trigger.

**Drop** if Marco judges the completion report (`qa-plan:166`) already serves as the release record
in his practice. The evidence for dropping: the gate, the exit criteria and the sign-off line all
exist; only the record template and the trigger are new.

Package plumbing (as in plan 039): discovery by folder (`generate-adapters.sh:69-91`,
`.claude-plugin/plugin.json`); `adapters/` gitignored (`.gitignore:33-34`); router
`qa.md:58-61,82-84`; README `:153`, `:196-198`, `:442`; examples table `examples/README.md:7-12`.
Trigger collision: `qa-plan`'s description already says "Use when asked for … release criteria"
(`qa-plan/SKILL.md:3`). Option A's description must say "evaluates existing criteria at the release
decision; to define criteria, use the planning skill".

## ISTQB CTFL v4.0.1 grounding

Verified against `<local copy of ISTQB_CTFL_Syllabus_v4.0.1.pdf>` (v4.0.1,
2024-09-15), section text read on 2026-10-14:

| Section | What it supports |
| --- | --- |
| §1.2.1 Testing's Contributions to Success | Testing's measures contribute "to decisions to move to the next phase of the SDLC, such as the release decision": testing informs the decision, it does not take it |
| §1.1.1 Test Objectives | "Providing information to stakeholders to allow them to make informed decisions" |
| §5.1.3 Entry Criteria and Exit Criteria | Exit criteria (thoroughness measures and binary yes/no criteria); running out of time or budget is acceptable "if the stakeholders have reviewed and accepted the risk to go live"; in Agile, exit criteria are the Definition of Done |
| §5.3 / §5.3.2 Test Monitoring, Control, Completion; Test Reports | Completion occurs when "a software system is released"; a completion report holds the summary, evaluation against exit criteria, deviations, impediments, metrics, "unmitigated risks, defects not fixed", lessons learned |
| §5.3.3 Communicating the Status of Testing | Tailor the record to the audience; formal report vs dashboard |
| §1.4.4 Traceability | "Traceability of test results to risks can be used to evaluate the level of residual risk" |
| §5.2.1, §5.2.4 | Risk level from likelihood and impact; risk control, including accepting a risk |
| §5.4 Configuration Management | Results reference the build unambiguously; a baseline can be restored to reproduce results |
| §2.2.1 Test Levels | Acceptance testing focuses on "demonstrating readiness for deployment" |

**Not cited, because the syllabus does not say it:** "go/no-go", rollback criteria, staged or canary
rollouts, feature-flag release. They are release-engineering practice. The skill may mention a
rollback plan as a question for the team (it is in `/qa-refinement`'s advisory scope already, see
`README.md` row for `/qa-refinement`, "rollback planning"), marked as not ISTQB content.

## Research basis

Read for scope, never copied; headings and descriptions only, 2026-10-14:

- `petrkindlmann/qa-skills` (MIT) `skills/release-readiness/SKILL.md` (443 lines: go/no-go checklist,
  smoke suite design, staged rollout, rollback criteria). Most of its length is rollout and smoke
  design; out of scope here.
- `QAIA-Project/QAIA` (MIT) `plugins/qaia-score/skills/judge/SKILL.md` ("PASS/CONCERNS/FAIL gate
  with its reason named", judges a suite or release candidate) and
  `plugins/qaia-core/skills/test-plan-and-closure/SKILL.md` (plan and closure report).

Difference kept: no criteria of our own; every line of the record traces to the one gate.

## What the skill does (option A)

`.claude/skills/qa-release/SKILL.md`, target ≤ 5 KB:

1. **Identify the candidate**: version, build, environment, from the deployment record, not a
   branch name (`context-discovery.md:36-40`). No identified build → NO-GO "cannot evaluate".
2. **Load the gate**: the team's own DoD or exit criteria if the repo has them ("Derive, Don't
   Override", `context-discovery.md`); otherwise `qa-plan`'s gate and exit criteria, **quoted by
   reference** (section name), never re-typed with different values.
3. **Collect evidence per criterion**: run results (with build), open defects by **severity**,
   exceptions (who, when, which risk accepted), residual risks from the register, gate cases from
   `/qa-cases` `@gate` tags. A criterion with no evidence is "not met: no evidence", never assumed.
4. **Write the record** `release/go-no-go-<version>.md`: one row per criterion (criterion, evidence
   link, build, status), exceptions, residual risks, defects not fixed, findings the change did not
   cause (listed, not gating, per `qa-plan:115`), and the recommendation with its reason. State who
   decides. Corrections follow "Correct, Don't Delete" (`qa-plan/SKILL.md:243-250`).

## Commands you will need

| Purpose | Command | Expected |
| --- | --- | --- |
| No second gate | `grep -rn "95%\|P1/P2\|block release" .claude` | only `qa-defect.md:117` (the known conflict) until it is fixed; nothing in the new skill |
| Frontmatter | `./tests/test-frontmatter.sh` | exit 0 |
| Reference pointers | `./tests/test-reference-links.sh` | exit 0 |
| Adapters | `./generate-adapters.sh --clean && ./tests/verify-adapters.sh` | exit 0 |
| Plugin | `./tests/plugin/verify-plugin.sh` | exit 0 |
| Known hashes | `./generate-known-hashes.sh --check` | exit 0, unchanged |
| Lifecycle, conformance | `./tests/test-lifecycle.sh`, `./tests/conformance/run.sh` | pass |
| Markdown lint | `npx --yes markdownlint-cli@0.49.1 --dot <changed .md files>` | no output |

## Scope

**In scope (A)**: `.claude/skills/qa-release/SKILL.md`; `qa.md` (skill line, routing row);
`README.md`; `examples/serverest/qa-release/`; `examples/README.md`; `plans/README.md`.
**In scope (B)**: `qa-plan/SKILL.md` (one subsection), `qa.md` (one routing row), the same example.

**Out of scope**: any change to the gate's criteria or values; the `qa-defect.md:117-118` fix (its
own commit/branch; see "Current state"); smoke-suite design; rollout and rollback procedure;
installers.

## Git workflow

Branch `feat/qa-release-skill` (A) or `feat/go-no-go-record` (B). **No AI attribution lines.**

- A: 1. `feat: add the qa-release skill for go/no-go records`; 2. `docs: list the qa-release skill in the README`;
  3. `docs: add the qa-release worked example on ServeRest`; 4. `docs(plans): record plan 041 outcome`.
- B: 1. `feat: add a go/no-go record to the planning skill`; then 3 and 4 as above.

## Steps

### Step 1: re-check the one gate

Re-read every line in "Current state". If the gate changed, the new text is the gate. If a second
gate has appeared anywhere, **STOP**: the fix is to remove it, not to build on it.

### Step 2: placement

No reference file is planned. Plan 034 (`plans/034-public-content-and-structure.md`, drafted in
parallel, read at the end of this planning session) sets the pointer convention the skill must use
(034 step 3): "the release gate in the planning skill (`qa-plan`), §Quality Gates", rules by name,
commands by slash name, no `.claude/...` paths. 034 step 6 also splits `/qa-defect` into a generic
command plus references, so the `qa-defect.md:117-118` line reference above may move; the conflict
it records is about the priority table's wording, wherever it lands. Implement after 034's PR B.

### Step 3: write it

Option A frontmatter draft (≤ 1024 characters):

```yaml
---
name: qa-release
description: "Evaluates a release candidate against the release gate and exit criteria already defined in the test plan (or the team's own Definition of Done), collects evidence per criterion with the build it came from, and writes a go/no-go record with exceptions, residual risks and defects not fixed, for the stakeholders who decide. Defines no criteria of its own. Use when asked whether a release is ready, for a go/no-go, release sign-off or readiness review; to define the criteria, use the planning skill."
---
```

The body's first rule: "This skill owns no criterion. The gate is `qa-plan` §Quality Gates; if the
team has its own, that one." Route in `qa.md`: `"go/no-go", "release readiness", "ready to ship",
"sign-off"` → this skill; leave "test plan" on `qa-plan`. Commit 1.

### Step 4: README (A only)

Commit 2.

### Step 5: worked example on ServeRest

Release candidate: ServeRest API **3.2.2** at `https://serverest.dev` (version from its OpenAPI
document, `examples/serverest/qa-automate/behaviour-profile.md:3`). Evidence: the package's own
earlier outputs on it — `qa-static/review.md` (14 findings), `qa-agentic/…/testcases.md` (33 cases),
`qa-automate/run-output.txt` (15 passed, 1 failed: TC-CART-030, a real defect) — **re-run on the
example date** so the evidence names today's build; the 2026-10-08 run is history, not evidence.

Success criteria, written before running:

- Every gate criterion appears with evidence or "not met: no evidence"; none is invented.
- The `@gate` cases are the ones marked in the agentic test cases, or the record says none were
  marked and that the gate therefore cannot be evaluated as defined (an honest NO-GO reason).
- TC-CART-030's failure is evaluated by its priority tag and the defect's **severity**, not by a
  defect priority.
- The recommendation is stated with its reason, and the record says no stakeholder decided (there is
  none for a public practice API).
- Fresh run output is kept beside the record. No screenshots expected.

Kept: `README.md` (prompt, model, date, version, honest limits), `release/go-no-go-3.2.2.md`, the
fresh `run-output.txt`. Row in `examples/README.md`. Commit 3.

### Step 6: verify and record

Run the commands table, write an "Outcome" section here and update `plans/README.md`. Commit 4.

## Known hashes and plan 032

A new unreleased file changes nothing in `.qa-skills-known-hashes` (`generate-known-hashes.sh:36-50`);
option B edits a released file (`qa-plan/SKILL.md`), which is also fine (older hashes stay listed).
Plan 032 keeps its frozen list open until the cut-over (`# state: open`), so a private release of this skill is added to it by the release workflow's refresh step; nothing extra is needed.

## Done criteria

- [ ] The new text contains no percentage, severity threshold or priority rule of its own
      (`grep -nE "[0-9]+%|Critical|High|P[0-4]" .claude/skills/qa-release/SKILL.md` → only
      references to the gate's section, read and justified in the PR).
- [ ] All commands pass; outputs in the PR.
- [ ] The example meets its criteria or its README says which failed.
- [ ] The `qa-defect.md:117-118` conflict is reported to Marco (PR description) with a proposed fix.
- [ ] `plans/README.md` row for 041 added and updated.

## STOP conditions

- The gate text changed or a second gate exists (Step 1).
- Writing the skill seems to need a criterion the gate lacks (e.g. performance budget, rollback
  readiness): propose it as a change **to the gate in `qa-plan`**, in its own plan; do not put it
  in this skill.
- Marco chooses "drop": record the decision and the evidence in this plan's Outcome and stop.
- ServeRest unreachable on the run date: report; do not substitute.

## Rejected approaches

- **A full release-readiness skill with its own checklist** (competitor scope): re-creates the
  multiple-gate defect plan 029 fixed.
- **Smoke-suite design and staged rollout in this skill**: smoke is defined in the rule
  (`testing-guidelines.md:67`); rollout is release engineering, not CTFL content, and a separate
  topic in the audit backlog ("chapters 3 and 10").
- **A numeric readiness score**: a score hides which criterion failed; the record shows each one.

## Approval gate

Approved by Marco on 2026-10-14. Decisions:

1. Option A, a thin skill.
2. The `qa-defect.md:117-118` wording is fixed by plan 034 step 2, not here.
3. Released before the public cut-over.

## Outcome

Implemented 2026-10-18 on `feat/qa-release-skill`, option A (a thin skill).

**Default used (Marco asked for all remaining work on 2026-10-18):** the plan's approval gate was
already passed on 2026-10-14 (option A, thin skill); nothing else needed a default.

- **Drift check** (`git diff --stat a2f08e7..HEAD` on the listed files): files changed, but the
  release gate text (`qa-plan` Quality Gates, `testing-guidelines`) did not. The only differences are
  wording: the corrections section is now "Corrections" and points to `qa-reference/references/written-records.md`
  (the skill points there instead of the old "Correct, Don't Delete" heading). The `qa-defect.md`
  priority conflict is fixed (it now says priority "is not a release gate"). No second gate found.
- **Skill**: `.claude/skills/qa-release/SKILL.md`, 4.2 KB. It owns no criterion; the grep for
  percentages, severity names and priority tags in it returns nothing.
- **Plumbing**: one skill line and one routing row in `/qa`, one README table row, the "five skills"
  sentence and the structure comment. Skills are discovered by folder, so no generator or manifest
  change was needed.
- **Example**: `examples/serverest/qa-release/`. ServeRest 3.2.2 was reachable on 2026-10-18; the
  16 tests were re-run (15 passed, 1 failed, TC-CART-030, as on 2026-10-08). Result: NO-GO, because no
  case carries `@gate`, 5 of 8 `@p0` and 7 of 18 `@p1` cases were never run, and SR-005 has no defect
  severity. Each success criterion above is met: criteria listed with evidence or "not met: no
  evidence", gate absence stated, TC-CART-030 judged by its tag and by severity not priority, no
  stakeholder invented.
- **For Marco (done criterion on `qa-defect.md`)**: the conflict named in "Current state" no longer
  exists on `next` (plan 034 step 2 fixed it); nothing to propose.
- **Not run locally**: Windows PowerShell and GitHub CI are covered in the PR.
