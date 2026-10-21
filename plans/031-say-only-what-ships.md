# Plan 031: The README and the `/qa` router say only what the package ships

> **Executor instructions**: Do this plan **after** plans 026-030 have merged, so the docs describe
> the fixed package. Run every verification command. If anything in "STOP conditions" occurs, stop
> and report. When done, update this plan's row in `plans/README.md`.
>
> **Drift check (run first)**: `git diff --stat 5b45cfa..HEAD -- README.md CLAUDE.md .claude/commands/qa.md DISTRIBUTION_GUIDE.md USAGE_EXAMPLES.md QA_SKILL_TESTS.md .npmignore`
> Some drift is expected (plans 026-030 may touch these). Re-read each section before editing it.

## Status

- **Priority**: P1 (the README is the public page of a package about to go public)
- **Effort**: M
- **Risk**: LOW
- **Depends on**: plans 026-030
- **Category**: docs
- **Planned at**: commit `5b45cfa`, 2026-10-13 (audit after 4.0.0)
- **Decision for Marco**: what to do with the three stale root guides (step 5); default below.

## Why this matters

The README is what a user, a reviewer of Marco's monograph, or a directory listing reads first. An
audit after 4.0.0 found claims the shipped files do not back: a tools table naming Pact, Mockito,
WireMock, MSW, Testcontainers, Rest Assured, Supertest, Postman/Newman and Spring test annotations,
none of which appears in any shipped file since the content was removed on 2026-05-22 (commit
`331fce6`); a CTFL coverage table showing "—" under "Not yet covered" for all six chapters while
test levels, test types, white-box coverage and more are absent; a size column that is stale and
mislabelled; a "light on context" claim that is true only for Claude Code; and a Contributing step
that tells people to run `bem-te-vi link`, which (before plan 026 item 1) led `uninstall` to delete
the package's own files. The `/qa` router, the package's entry point, has its command table in
Portuguese, no route for the `qa-migrate` skill, and a leftover "ADO check" trigger.

## Current state

- `README.md:88`: "**Grounded in the ISTQB CTFL v4.0 syllabus**, with section citations beside the
  concepts it uses." True for `/qa-static`, `/qa-trace`, the `qa-plan` skill and the tools
  reference; not for the seven principles, the technique table, `/qa-bdd`, `/qa-tdd`,
  `/qa-refinement`, `qa-explore` or `/qa-defect`.
- `README.md:97-98`: "**Light on context**: about 24 KB of rules load into every conversation; the
  long templates and examples load only when a task needs them." In Cursor, Windsurf, Copilot, Cline
  and Antigravity the whole package is one generated adapter of about 222 KB
  (`ls -l adapters/*/*`), loaded as one file.
- `README.md:172-186`: column headed "Tokens" holding KB values, stale (actual bytes at
  `5b45cfa`: `qa.md` 10,361; `qa-cases.md` 19,320; `qa-defect.md` 19,510; `qa-static.md` 17,701;
  `qa-automate.md` 20,948; `qa-agentic.md` 3,589). The same stale numbers are in
  `.claude/commands/qa.md:30-41` under "Target Size".
- `README.md:198`: "**Testing Rules** | Always loaded — ISTQB principles, the test pyramid, the
  tagging taxonomy". The pyramid moved to `qa-reference/references/testing-design.md` (plan 021).
- `README.md:403-414`: the "ISTQB CTFL v4.0 — Coverage" table; every "Not yet covered" cell is "—".
  Absent or only partly covered, measured against the official v4.0.1 syllabus: test levels and test
  types (§2.2.1-2.2.2); confirmation, regression and maintenance testing (§2.2.3, §2.3); DevOps,
  shift-left practices and retrospectives (§2.1.4-2.1.6); white-box testing and statement/branch
  coverage (§4.3); coverage items for the black-box techniques (§4.2); checklist-based testing
  (§4.4.3); the 3 Cs and acceptance-criteria formats (§4.5.1-4.5.2); test case prioritisation
  strategies and the testing quadrants (§5.1.5, §5.1.7); roles and independence of testing (§1.4.5,
  §1.5.3). Row 6 lists "automation ROI scoring, flaky-test handling", which are package features,
  not syllabus content. Row 3 lists "static analysis", which in CTFL is tool-based; the package's
  `qa-engineer` agent is an AI code review.
- `README.md:416-426`: "Supported Frameworks & Tools" (quoted in "Why this matters"). Shipped files
  give real guidance for Playwright, Vitest (with React Testing Library setup), Cucumber/Gherkin step
  definitions (TypeScript, Java glue, C#), `@axe-core/playwright`, and Cypress/Selenium only as
  migration sources in `qa-migrate`.
- `README.md:430-446` "Project Structure": skills "(planning, exploratory)" (there are four:
  `qa-plan`, `qa-explore`, `qa-migrate`, `qa-reference`); agents "QA Engineer subagent for code
  reviews" (there are four); hooks "test case format checker" (there are two); CLI "(init,
  uninstall, link, unlink)" (there is also `update`).
- `README.md:452-458` Contributing step 4: "Test your changes locally with `bem-te-vi link`".
- `README.md:462-466` Credits name Postman and Pact documentation, and the syllabus without its
  copyright owner.
- `.claude/commands/qa.md:30-41`: the "Specialized Active Commands" table is in Portuguese
  ("Escrever test cases…", "Gerar cenários BDD…"). `qa.md` §"Smart Routing" (about lines 67-83) has
  no row for the `qa-migrate` skill and keeps an "ADO check" trigger from the removed `/qa-ado`
  command. `qa.md:49-53` lists 5 of the 9 rules.
- `DISTRIBUTION_GUIDE.md` describes v1.2.0 (`:94`, `:457-464`) including generator flags that do
  not exist (`:489-501`); `USAGE_EXAMPLES.md` teaches `@critical`, `/57.5` and a "Jest" example using
  `vi.fn()`; `QA_SKILL_TESTS.md:13` records one run, on v1.1.0. None is linked from `README.md` or
  `CONTRIBUTING.md`; all three are excluded from the npm package by `.npmignore:9-11`; `CLAUDE.md:25-27`
  lists them in the repository structure.

## Commands you will need

| Purpose | Command | Expected |
| --- | --- | --- |
| Markdown lint | `npx --yes markdownlint-cli@0.49.1 --dot README.md CLAUDE.md .claude/commands/qa.md` | no output |
| Claimed tools present | `grep -rlE '<tool name>' .claude` | at least one file for every tool left in the table |
| Adapters | `./generate-adapters.sh --clean && ./tests/verify-adapters.sh` | exit 0 |
| Frontmatter | `./tests/test-frontmatter.sh` | exit 0 |
| File sizes | `wc -c .claude/commands/*.md` | numbers for the size column |

## Scope

**In scope**: `README.md`, `.claude/commands/qa.md`, `CLAUDE.md` (repository-structure block only),
`DISTRIBUTION_GUIDE.md`, `USAGE_EXAMPLES.md`, `QA_SKILL_TESTS.md`, `.npmignore` (only if a file is
removed), `plans/README.md`.

**Out of scope**: writing the missing CTFL or tool content (listed as follow-ups in
`plans/README.md`); `CHANGELOG.md` (Release Please owns it); any shipped command other than `qa.md`.

## Git workflow

Branch `docs/say-only-what-ships`; Conventional Commits (`docs:`), one concept per commit (one
commit per step below). Never add AI attribution lines.

## Steps

### Step 1: tools table

Replace `README.md:416-426` with a table of what the shipped files teach (Playwright; Vitest with
React Testing Library; Cucumber/Gherkin step definitions; `@axe-core/playwright`; Cypress and
Selenium as migration sources), followed by one sentence: "Other frameworks work through the
assistant's general knowledge; Bem-te-vi has no dedicated guidance for them yet." Trim the Credits
line to the tools that remain, and add after the syllabus credit: "ISTQB® is a registered trademark
of the International Software Testing Qualifications Board; syllabus content is used with
acknowledgement of the ISTQB as source and copyright owner."

**Verify**: for every tool name left in the table, `grep -rl '<name>' .claude` returns a file.

### Step 2: CTFL coverage table

Fill "Not yet covered" with the absent topics listed in "Current state" (one short phrase each,
grouped per chapter). Move "automation ROI scoring, flaky-test handling" out of the table into a
sentence below it ("Package additions beyond the syllabus: …"). In row 3 replace "static analysis"
with "code review by an AI agent; tool-based static analysis is not covered". Change the closing line
to point at `plans/README.md` §"Backlog — audit after 4.0.0".

### Step 3: other README claims

- `:88` → "Grounded in the ISTQB CTFL v4.0 syllabus; `/qa-static`, `/qa-trace`, the planning skill
  and the tools reference cite syllabus sections."
- `:97-98` → "**Light on context in Claude Code**: about N KB of rules load into every conversation
  (run `./tests/test-rules-size.sh` for N); templates load only when needed. Other editors receive
  one generated file of about M KB." Take M from `wc -c adapters/cursor/qa.mdc`.
- `:172-186`: rename the column "Size", fill it from `wc -c` rounded to whole KB.
- `:198` → "Always loaded — ISTQB principles, testing vs QA, the tagging taxonomy".
- `:430-446`: correct the four comments (skills, agents, hooks, CLI commands).
- `:452-458` step 4 → "Test your changes locally with `bem-te-vi init` in a scratch project (or
  `bem-te-vi link`, then `bem-te-vi unlink` before any `uninstall`)". If plan 026 item 1 has merged,
  the parenthesis can go.

### Step 4: the `/qa` router

In `.claude/commands/qa.md`: translate the command table to English, rename "Target Size" to
"Size" with current values; add a routing row "migrate / port Cypress or Selenium tests to
Playwright → `qa-migrate` skill" and a row "three amigos / pre-development review → `/qa-static`
(three amigos preset)"; remove the "ADO check" trigger; list all nine rules in §"rules" (one line
each, matching the existing format).

**Verify**: `grep -nE 'Escrever|Gerar|Rodar|ADO check' .claude/commands/qa.md` → no matches;
`./tests/test-frontmatter.sh` and adapters pass.

### Step 5: the three stale root guides

**Decision (default)**: delete `DISTRIBUTION_GUIDE.md` (the README's install section replaced it);
move `USAGE_EXAMPLES.md` and `QA_SKILL_TESTS.md` to a tracked `history/` folder at the repository
root (not `docs/`, which is gitignored here), each with a first line
"Historical: written for v1.x; not maintained." Update `CLAUDE.md:25-27` and `.npmignore:9-11` to
match.

### Step 6: record the follow-ups

Confirm the "Backlog — audit after 4.0.0" section in `plans/README.md` still lists the follow-ups
(it was written together with this plan); mark any that plans 026-030 resolved.

## Done criteria

- [ ] Every tool in the README tools table appears in a shipped file (`grep` per tool).
- [ ] No "Not yet covered" cell in the CTFL table is "—" unless the chapter's rows are all backed.
- [ ] `grep -n 'Tokens' README.md` → no match in the commands table header.
- [ ] `grep -nE 'Escrever|Gerar|Rodar|ADO check' .claude/commands/qa.md` → no matches.
- [ ] Markdown lint clean; adapters and frontmatter tests pass.
- [ ] `plans/README.md` row for 031 updated.

## STOP conditions

- A claim cannot be checked against a shipped file and you are tempted to keep it "because it is
  probably true": remove it or report it.
- Marco chooses to keep the root guides current instead of retiring them: that is a separate plan.
- Plans 026-030 have not merged.

## Maintenance notes

- Each new command or skill must add its README row, its `/qa` routing row and its size in the same
  PR. A small CI check that the README command table lists exactly the files in
  `.claude/commands/` would stop the drift found here.

## Outcome (2026-10-14)

Merged as #129, released in 4.0.1. Marco accepted step 5's default decision by merging the PR
unchanged. Every commit in #129 was typed `docs:`, but two of them change shipped files (the `/qa`
router and the installer messages), so they should have been `fix:` (CONTRIBUTING.md). Release
Please therefore listed nothing for #129; the three entries are added by hand to the 4.0.1 release
PR (#130) as its last commit. A `BEGIN_COMMIT_OVERRIDE` block on #129 was tried first and rejected: Release Please
applied it to each of the PR's eight commits, listing every entry eight times.
