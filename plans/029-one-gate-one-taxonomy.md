# Plan 029: Free the rules budget, then give the package one release gate and one tag taxonomy

> **Executor instructions**: Do the steps in order; step 1 must merge before any other step, because
> every later step edits an always-loaded rule. One PR per step. Run every verification command. If
> anything in "STOP conditions" occurs, stop and report. When done, update this plan's row in
> `plans/README.md`.
>
> **Drift check (run first)**: `git diff --stat 5b45cfa..HEAD -- .claude/rules .claude/skills/qa-reference .claude/skills/qa-plan/SKILL.md .claude/commands/qa-cases.md .claude/commands/qa-refinement.md .claude/commands/qa.md .claude/commands/qa-automate.md .claude/agents generate-adapters.sh generate-adapters.ps1 install.sh`
> On a mismatch with the excerpts below, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: M
- **Risk**: MED (changes policy text users' assistants follow in every conversation)
- **Depends on**: none to start; plans 028 (item 5) and 030 benefit from step 1's freed budget
- **Category**: tech-debt, docs
- **Planned at**: commit `5b45cfa`, 2026-10-13 (audit after 4.0.0)
- **Decisions for Marco**: the defaults marked **Decision** below. Execute with the defaults; Marco
  confirms or changes them when he approves each PR.

## Why this matters

`.claude/rules/*.md` load into every conversation of an installed project, so they are the package's
most-read text. They total **24,696 bytes against the 25,000-byte cap** enforced by
`tests/test-rules-size.sh`: any correction that adds a line fails CI. Meanwhile the rules and the
commands disagree with each other on the questions a QA analyst asks most: *does a failing P1 test
block the release, which defects block it, and which tags must a test carry?* An audit after 4.0.0
found three different P1 release gates, two defect priority scales used interchangeably, five
versions of the "required tags", a rule claiming "ISTQB CTFL v4.0 Certified" (certification is
earned by people, by exam), and syllabus principles paraphrased into claims the syllabus does not
make. An assistant reading two of these files can pass or fail the same release.

## Current state (quoted from the files)

**Rules size** (`./tests/test-rules-size.sh`): `testing-guidelines.md` 7,497 B,
`context-discovery.md` 5,441, `conventional-commits.md` 2,509, `code-style-qa.md` 2,388,
`linting-standards.md` 1,833, `accessibility-qa.md` 1,510, `test-evidence.md` 1,458,
`security-qa.md` 1,340, `test-tools.md` 720. The test counts every `.md` in `.claude/rules/`,
with or without frontmatter. `generate-adapters.sh` strips a rule's leading frontmatter.

`conventional-commits.md` and `linting-standards.md` govern only committing and editing code in the
target repository. They are referenced by `context-discovery.md:73`, `qa.md:52-53` and `CLAUDE.md:121-122`.

**The pattern to follow** (plan 021): a rule keeps a short core and a pointer; detail lives in
`.claude/skills/qa-reference/references/<name>.md`, listed in `.claude/skills/qa-reference/SKILL.md`.
See `.claude/rules/security-qa.md` (17 lines) and its reference `security-checks.md`.

**Release gates today:**

- `testing-guidelines.md:82`: `` `@p1` (High): Major functionality broken, no workaround. Release blocker. ``
- `testing-guidelines.md:101`: `2. **P0/P1 Failures**: Release block. No code promotes to Production until resolved or formal exception approved by PO.`
- `qa-cases.md:230-231`: `` `@p0`: 100% must pass before release `` / `` `@p1`: 95%+ must pass (or PO-approved exception) ``
- `qa-plan/SKILL.md:129-132`: `100% of P0 test cases executed and passing`, `95%+ of P1 test cases executed and passing`, `Zero open P0 (Critical) defects`, `Zero open P1 (High) defects (or formally approved Product exceptions)`
- `testing-guidelines.md:117`: `2. **Zero P1/P2 Defects**: No critical or high-severity bugs remain open.`
- `qa-defect.md:112-121`: defect **priority** is P1 (fix immediately) to P4; **severity** is a separate field (Critical/High/Medium/Low).
- `testing-guidelines.md:110-122`: "Phase X: Strict Definition of Done (DoD) ... a mandatory, non-negotiable Quality Gate", including `Lighthouse Audit (Performance, SEO)` and `touch targets valid` for every ticket — while principle 6 (`:18`) says testing is context-dependent and `context-discovery.md` §"Derive, Don't Override" says the team's own schema owns its artifacts.
- `qa-plan/SKILL.md:118-121`: entry criteria "Feature is fully implemented and state is 'Ready for QA'", while `/qa-static`, `/qa-bdd` and `/qa-tdd` test before implementation (principle 3).

**Tags today:**

- `testing-guidelines.md:63`: "one tag from each of the first four categories" (suite, level, priority, status); feature tags are a fifth, project-defined category (`:94-96`). Status values: `@automated`, `@candidate`, `@manual-only`.
- `qa-cases.md:212-220` and `:323`: "one tag from each category" with **five** categories, "all 5 categories required"; status adds `@deferred`.
- Off-list tags used elsewhere: `@flaky`, `@quarantine` (`testing-guidelines.md:103-104`), `@slow` (`qa-automate.md:489`), `@gate` (`qa-cases.md:33`).
- `testing-guidelines.md:69`: `` `@regression`: Comprehensive verification. Run nightly or pre-release. `` CTFL v4.0.1 §2.2.3 defines regression testing by purpose: confirming that a change has not caused adverse effects.

**Wording problems in the always-loaded rule and persona:**

- `testing-guidelines.md:3`: `> **ISTQB CTFL v4.0 Certified** | Standards & Tagging Taxonomy | Release Gate Policies`
- `qa.md:9`: "with ISTQB CTFL v4.0 certification"; the adapter descriptions say "ISTQB CTFL v4.0 certified with expertise in Postman, JUnit, … Kotlin" at `generate-adapters.sh:164,209`, `generate-adapters.ps1:149,158`, `install.sh:260`.
- `testing-guidelines.md:14`: "Testing everything is mathematically infeasible" (syllabus §1.3: not feasible except in trivial cases).
- `:16`: "Pareto Principle – 80% of defects are typically found in 20% of modules" (the syllabus gives no figure: a small number of components usually contain most of the defects).
- `:17`: "Repeating the same tests will not find new bugs" (the syllabus: they become increasingly ineffective, and repetition can be beneficial, e.g. in automated regression testing).
- `:19`: "Fixing all bugs is useless if …" (the syllabus: fixing all defects may still produce a system that does not fulfil users' needs).
- `:103`: a LaTeX arrow `$\rightarrow$` in a Markdown rule.

**Same idea, different values:**

- `qa-refinement.md:86` INVEST "Small — Can fit in 1-2 sprints?" vs `:135` DoR "Story fits within one sprint".
- `qa-refinement.md:96`, `:128` require acceptance criteria "in Given/When/Then format"; `qa-static.md:107` accepts "Given/When/Then or a measurable sentence"; CTFL §4.5.2 names scenario-oriented and rule-oriented formats as the two common ones.
- CI retries: `qa-automate.md:227` `retries: process.env.CI ? 2 : 0`; `qa-migrate/SKILL.md:57` says `1` in CI.

## Commands you will need

| Purpose | Command | Expected |
| --- | --- | --- |
| Rules size | `./tests/test-rules-size.sh` | `✔ … total N bytes (cap 25000)` |
| Reference pointers | `./tests/test-reference-links.sh` | `✔ All N reference pointers resolve.` |
| Adapters | `./generate-adapters.sh --clean && ./tests/verify-adapters.sh` | exit 0 |
| Frontmatter | `./tests/test-frontmatter.sh` | exit 0 |
| Contracts | `./tests/test-tc-contracts.sh` | exit 0 |
| Lifecycle (installs the rules) | `./tests/test-lifecycle.sh` | `100% GREEN` |
| Markdown lint | `npx --yes markdownlint-cli@0.49.1 --dot <files>` | no output |

## Scope

**In scope**: `.claude/rules/*.md`, new `.claude/skills/qa-reference/references/repo-conventions.md`,
`.claude/skills/qa-reference/SKILL.md`, `.claude/skills/qa-reference/references/testing-design.md`,
`.claude/skills/qa-plan/SKILL.md`, `.claude/commands/qa-cases.md`, `.claude/commands/qa.md`,
`.claude/commands/qa-refinement.md`, `.claude/commands/qa-automate.md` (line 227 only),
`.claude/agents/qa-designer.md` (tag list only), `generate-adapters.sh`, `generate-adapters.ps1`,
`install.sh` (description string only), `CLAUDE.md` §6 (the two rule paths, only if they move),
`plans/README.md`.

**Out of scope**: `/qa-agentic` stage contracts and `/qa-trace` (plan 030); README claims (plan 031);
the TC template's fields; renaming any tag (installed suites filter on them).

## Git workflow

Branches `refactor/rules-budget`, `fix/one-release-gate`, `fix/one-tag-taxonomy`,
`fix/principles-wording`, `fix/same-values`. Conventional Commits, atomic. Never add AI attribution
lines. Merge only with Marco's approval.

## Steps

### Step 1: move the commit and lint rules' detail on demand

1. Create `.claude/skills/qa-reference/references/repo-conventions.md` holding the full current text
   of `conventional-commits.md` and `linting-standards.md` (two H2 sections; keep their wording).
2. Reduce each rule to a stub of at most ~500 bytes: its H1, a one-line scope ("commits the AI makes
   in this repository" / "code the AI writes in this repository"), the two or three must-follow
   lines (for commits: Conventional Commits types, one concept per commit, `!`/`BREAKING CHANGE:`;
   for linting: detect and follow the repository's existing lint/format config, never invent one),
   and the pointer `Detail: .claude/skills/qa-reference/references/repo-conventions.md`.
3. List the new reference in `.claude/skills/qa-reference/SKILL.md` beside the others.

**Verify**: `./tests/test-rules-size.sh` → total ≤ 21,500 B; `./tests/test-reference-links.sh`,
`./tests/verify-adapters.sh` (after regenerating) and `./tests/test-lifecycle.sh` pass.

### Step 2: one release gate

**Decision (default)**: a release is blocked by any failing `@p0` or `@p1` test and by any open
defect of **Critical or High severity**, unless a PO exception is recorded. Defect *priority*
(P1–P4) is a scheduling field and is not used in gates.

- `qa-cases.md:231` → `` `@p1`: 100% must pass before release, or each failure has a recorded PO exception ``.
- `qa-plan/SKILL.md:130` → `100% of P1 test cases executed and passing, or each failure has a recorded Product Owner exception`;
  `:131-132` → `Zero open Critical-severity defects` / `Zero open High-severity defects (or recorded Product Owner exceptions)`.
- `testing-guidelines.md:117` → `2. **No open Critical/High-severity defects** (or a recorded PO exception).`
- `testing-guidelines.md:110-122`: rename the heading to `## 🛑 Definition of Done: QA's Contribution`
  and make the first sentence: "Adopt the team's own DoD; where it is silent, QA checks these
  before a ticket closes (the DoD is a story's exit criteria, CTFL §5.1.3):". Make item 3 conditional:
  "NFRs that apply to this change are validated (e.g. security scan; accessibility and Lighthouse
  for web UI)". Keep the byte count no higher than today.
- `qa-plan/SKILL.md:118-121`: retitle "Entry Criteria for System-Level Test Execution" and add one
  line: "Test analysis, reviews and test design start earlier, at refinement (`/qa-static`, `/qa-bdd`)."

**Verify**: `grep -rn '95%+' .claude` → no matches; `grep -n 'P1/P2' .claude/rules/testing-guidelines.md` → no match.

### Step 3: one tag taxonomy

**Decision (default)**: four required categories (suite, level, priority, status) as the rule
already says; the feature tag is recommended; status gains `@deferred` (already used by
`/qa-cases`); `@flaky`, `@quarantine`, `@slow` and `@gate` are listed as optional tags.

1. In `testing-guidelines.md` §"Test Tagging Taxonomy": add `@deferred` to the status list; under
   "5. Feature Tags" say "recommended"; add "6. Optional tags: `@flaky`, `@quarantine` (see the
   protocol below), `@slow`, `@gate` (a release-gate case)". Redefine `@regression` as
   "Re-run after changes to catch unintended side effects (CTFL §2.2.3); usually nightly or
   pre-release."
2. In `qa-cases.md:212-220,323`, `qa.md`, `qa-designer.md:31,45-51`: replace the restated
   taxonomy with a pointer to the rule section and fix "all 5 categories" to "the four required
   categories, plus the feature tag where the project defines one". Make every example carry one
   suite tag (the `@smoke @sanity` examples at `qa-cases.md:266,284` and `qa-automate.md:373`
   keep one).
3. In `testing-design.md`, add a short table mapping the level tags to CTFL test levels (§2.2.1):
   `@unit` → component; `@integration` → component integration (collaborating units; mocked external
   systems); `@api` and `@e2e` → system or system integration; acceptance → via `/qa-bdd` (ATDD). Say
   that `@manual` is an execution mode, not a level.

**Verify**: `grep -rn 'all 5 categories' .claude` → no matches; `./tests/test-tc-contracts.sh` passes;
rules size still under the cap.

### Step 4: principle wording and the certification claim

1. `testing-guidelines.md:3` → `> **Aligned with ISTQB CTFL v4.0 (syllabus v4.0.1)** | Standards & Tagging Taxonomy | Release Gate Policies`.
2. Rewrite principles 2, 4, 5 and 7 in the syllabus' sense (see "Current state"), keep the short
   "what to do" sentence after each, and add `(CTFL §1.3)` to the heading. Keep "Pesticide Paradox"
   only as "formerly called the pesticide paradox". Replace `$\rightarrow$` with `→`.
3. `qa.md:9` → "You are a **Senior QA Analyst and QA Engineer** working to the ISTQB CTFL v4.0
   syllabus, with hands-on expertise in modern software testing."
4. Adapter descriptions (`generate-adapters.sh:164,209`, `generate-adapters.ps1:149,158`,
   `install.sh:260`): `"Senior QA Analyst + QA Engineer — aligned with ISTQB CTFL v4.0; Playwright, Vitest, BDD and CI/CD"`
   (keep `$EmDash` in the PowerShell strings). Keep the sh and ps1 strings identical in content.

**Verify**: `grep -rniE 'ctfl v4\.0 certifi' .claude generate-adapters.* install.sh` → no matches;
`./generate-adapters.sh --clean && ./tests/verify-adapters.sh` passes.

### Step 5: same idea, same value

- `qa-refinement.md:86` → "**S**mall — fits in one sprint (ideally a few days); larger items are epics".
- `qa-refinement.md:96,128,146`: "Acceptance criteria are testable — scenario-oriented
  (Given/When/Then) or rule-oriented (a measurable statement) — CTFL §4.5.2".
- `qa-automate.md:227`: `retries: process.env.CI ? 1 : 0,` to match `qa-migrate`, with the
  existing comment style.

**Verify**: `grep -n '1-2 sprints' .claude/commands/qa-refinement.md` → no match.

## Done criteria

- [ ] `./tests/test-rules-size.sh` passes, total ≤ 22,000 B after all steps.
- [ ] `grep -rn '95%+\|all 5 categories\|CTFL v4.0 Certified\|1-2 sprints' .claude` → no matches.
- [ ] All commands in the table pass; adapters regenerated and verified.
- [ ] Each PR body lists the decision it implements so Marco can confirm it.
- [ ] `plans/README.md` row for 029 updated.

## STOP conditions

- Step 1 cannot reach ≤ 21,500 B without removing a rule's must-follow content.
- Marco rejects a default decision: implement his choice, then check every file listed for that step.
- A tag rename seems necessary (it is not part of this plan).
- `tests/verify-adapters.sh` checks for an exact description string you changed: update the check in
  the same commit only if it is a pure string match; otherwise stop.

## Maintenance notes

- After this plan, the rules carry policy and the references carry procedure. Keep that split: a new
  rule line should be a "must", and anything longer goes to a reference.
- `tests/test-rules-size.sh`'s comment says rules with `paths:` frontmatter are not always loaded,
  but the test counts them. If a future change relies on `paths:` scoping, update the test first.

## Outcome (2026-10-14)

Merged as #124, released in 4.0.1. Marco accepted both default decisions (the release gate and the
four required tag categories) by merging the PR unchanged.
