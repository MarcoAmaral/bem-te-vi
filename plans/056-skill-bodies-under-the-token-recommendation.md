# Plan 056: Bring the `qa-plan` and `/qa-cases` bodies under the Agent Skills token recommendation

> **Executor instructions**: Branch `refactor/skill-bodies-under-limit` from `github/next`, one pull
> request into `next`. Read the current Agent Skills specification and Cline's skills page first and
> quote what they recommend; if neither recommends a body size any more, stop and report. Move
> detail only into references under `.claude/skills/qa-reference/references/`, the way plans 021,
> 034 and 043 did: a short pointer in the body at the point the detail is needed, the detail in a
> reference read on demand. Nothing is deleted: every rule, field, technique and example still
> exists in a file the body tells the model to read. Keep the TC format contract tests passing; if
> a check reads text that moves, change the check in the same commit. Run
> `bash ~/qa-ci-all.sh <worktree>` on all three platforms before reporting.

## Status

- **Priority**: P2 (the editors load the body anyway; the recommendation is about context cost)
- **Effort**: S
- **Risk**: LOW (text moves between shipped files; the format contract and its checks do not change)
- **Depends on**: plan 043 (references shipped beside each skill), plan 047 (every command becomes an
  Agent Skill outside Claude Code), plan 048 (the benchmark's condition D loads both files)
- **Category**: refactor, content
- **Planned at**: commit `a97162e` (`github/next`), 2026-10-19
- **Outcome**: done, branch `refactor/skill-bodies-under-limit` (into `next`), see "Outcome" below

## Why this matters

Plan 047 made every command, agent and skill an Agent Skill for Cursor, Windsurf, Copilot, Cline
and Antigravity, and recorded (plan 047, "Findings outside scope"; `plans/README.md`, "Backlog from
plan 047") that two of them are over the format's recommended body size.

What the documentation says, read on 2026-10-19:

- Agent Skills specification (agentskills.io/specification), "Progressive disclosure":
  "**Instructions** (< 5000 tokens recommended): The full `SKILL.md` body is loaded when the skill
  is activated", and "Keep your main `SKILL.md` under 500 lines. Move detailed reference material
  to separate files." Under "Body content": "Note that the agent will load this entire file once
  it's decided to activate a skill. Consider splitting longer `SKILL.md` content into referenced
  files."
- Cline (docs.cline.bot/features/skills), "Keeping Skills Focused": "Keep SKILL.md under 5k tokens.
  If your skill needs more content, split it into separate files in a `docs/` directory and
  reference them from the main instructions. Cline loads referenced files only when needed." Its
  progressive loading table gives the Instructions level "Under 5k tokens".

The sizes at the planning commit, with the repository's estimate (bytes / 4, the estimate
`tests/test-rules-size.sh` uses; bytes because `wc -c` is the same on every platform):

| File | Bytes | Tokens (bytes / 4) | Body without frontmatter | Lines |
| --- | --- | --- | --- | --- |
| `.claude/skills/qa-plan/SKILL.md` | 25,916 | about 6,479 | 25,458 (about 6,365) | 320 |
| `.claude/commands/qa-cases.md` | 22,168 | about 5,542 | 21,773 (about 5,443) | 405 |

Both are under 500 lines; both are over 5,000 tokens. Every other command, agent and skill is under
20,000 bytes.

## Steps

1. **Choose what moves.** Keep in the body what the model needs on every run: the output contract
   (frontmatter, the case table, the plan's nine fields), the required fields and their allowed
   values, the steps, and every rule a grader or a format check reads. Move long examples, tables
   of variants and procedures needed only in some runs. Target: each file under 4,500 tokens by
   bytes / 4, whole file, frontmatter included.
2. **Write the references.** One per concern, each with an `id: ref-<name>` frontmatter, a "Read on
   demand" header saying when to read it, a row in the `qa-reference` index and a line in
   `llms.txt`. Moved text is copied verbatim; only headings change level and pointers such as
   "above" or "Step 4" are made to resolve from the reference.
3. **Write the pointers.** At the place the detail was, a sentence that says when to read it and
   names the reference and its section in quotes, in the current pointer form
   (`qa-reference/references/<file>.md`, "<Section>").
4. **Keep the checks honest.** CTFL citations keep `§` on the same line as `CTFL`
   (`tests/test-ctfl-citations.sh`); an allowlist entry that no longer matches is removed.
5. **Add a static check** in place of an eval run: every Agent Skill source stays at most 20,000
   bytes (5,000 tokens), and for each moved section the body still points to it, the reference has
   the section, and the section holds the moved text's key terms.
6. **Sizes stated elsewhere**: the `/qa` router and the README command table give `/qa-cases` in
   KB; update both. The roadmap and the plans backlog drop the item.
7. **Benchmark**: condition D loads both files. Add a dated entry to `benchmark/DEVIATIONS.md`,
   rerun `node benchmark/build.js --check` and record the placebo's parity.

## Done criteria

- Both files under 4,500 tokens by bytes / 4, whole file.
- `tests/test-skill-bodies.sh` passes, and fails on the planning commit's tree.
- `tests/test-tc-contracts.sh`, `tests/test-validate-tc-format.sh`, `tests/test-ctfl-citations.sh`,
  `tests/test-frontmatter.sh`, `tests/test-reference-links.sh`, `tests/test-llms-txt.sh`,
  `tests/test-rules-size.sh`, `tests/verify-adapters.sh` and `node benchmark/build.js --check`
  pass; the bash and PowerShell generators stay byte-identical.

## STOP conditions

- The specification or Cline no longer recommends a body size: stop and report.
- The placebo's size leaves the 75% to 125% band of `benchmark/CONTROL.md`: stop and report; the
  placebo is rebuilt only under CONTROL.md's maintenance rule, never by this plan.
- Getting under the target would mean moving the output contract, a required field, or text a
  benchmark grader or a format check depends on out of the body: stop and report.

## Decisions

- **One reference per concern, all in `qa-reference`.** `test-case-writing.md` (tracker formats,
  technique worked examples, the runbook format), `test-planning.md` (quadrants, estimation,
  execution order, suite-level artifacts, roles and independence, configuration management) and
  `test-reporting.md` (monitoring, control, reports, the row format for every case, completion,
  retrospectives). Reporting is shared: `qa-plan` and `/qa-cases` each carried part of it, and
  `/qa-cases` is a single file in Claude Code with nowhere of its own for a reference.
- **The `/qa-cases` complete example stays in the body.** It is about 5,700 bytes, the largest
  single block, and the file would have met the target by moving it alone. It stays because it is
  the format the model imitates on every run (frontmatter, every row, `N/A — <why>`, both kinds of
  Source), `tests/test-tc-contracts.sh` checks it against the TC hook, and moving it as well as the
  conditional sections would have taken the placebo out of its band.
- **The quality gates, the risk register and the nine plan fields stay in the `qa-plan` body**, and
  so does the fixture-set section, which `qa-api` points to by name.

## Rejected approaches

- **Move only the complete example out of `/qa-cases`.** It gets the file under the target in one
  cut, but the example is what the model copies on every run, and the sections that are needed only
  sometimes (runbook, reporting, tracker variants) would have stayed.
- **A `references/` folder inside `qa-plan`.** The Agent Skills layout allows it, but every
  reference the package ships is in `qa-reference`, and `/qa-cases`, a command, cannot have one.
- **Point the tag section of `/qa-cases` at the `testing-guidelines` rule instead.** The rule holds
  the same taxonomy, but the tags are part of the output contract of every case.
- **Re-pad the example tables.** Narrower padding would save about 1,500 bytes with nothing moved,
  but it rewrites text that is not part of this change.

## Outcome (2026-10-19)

Implemented on branch `refactor/skill-bodies-under-limit`. No STOP condition fired: both pages
still give the 5,000-token figure (quoted above), and the placebo stayed in its band.

| File | Before | After | Body without frontmatter, after |
| --- | --- | --- | --- |
| `.claude/skills/qa-plan/SKILL.md` | 25,916 bytes, about 6,479 tokens | 17,699 bytes, about 4,425 tokens | 17,241 bytes, about 4,310 tokens |
| `.claude/commands/qa-cases.md` | 22,168 bytes, about 5,542 tokens | 17,573 bytes, about 4,393 tokens | 17,178 bytes, about 4,295 tokens |

What moved where (headings in the reference):

- `/qa-cases` "Tracker Intelligence", the tracker table → `test-case-writing.md`, "Tracker Link
  Formats". The rules for a URL, an ID and no tracker stay.
- `/qa-cases` "ISTQB Test Design Techniques", the worked examples → `test-case-writing.md`, "ISTQB
  Test Design Techniques in TC Format". The body keeps one line per technique with its CTFL section.
- `/qa-cases` "Runbook" → `test-case-writing.md`, "Runbook Format".
- `/qa-cases` "Reporting Results" → `test-reporting.md`, "Reporting Every Case". The body keeps the
  one-row-per-case rule, the six outcomes and the resume point.
- `qa-plan` "Check the Plan Against the Testing Quadrants", the table → `test-planning.md`, "Testing
  Quadrants". The body keeps the two axes and the four quadrants.
- `qa-plan` "Step 4", the four techniques and the worked example → `test-planning.md`, "Estimation
  Techniques". The body keeps the range rule, the technique names and the three-point formula.
- `qa-plan` "Test Execution Order" → `test-planning.md`, same heading. The body keeps the three
  orderings, the two overrides and where the order is written.
- `qa-plan` "Suite-Level Artifacts" → `test-planning.md`, same heading.
- `qa-plan` "Roles and Independence", the role detail and what independence brings and costs →
  `test-planning.md`, same heading. The body keeps the two roles, the degree table and the item 6
  instruction.
- `qa-plan` "Configuration Management for Testware", the checklist → `test-planning.md`, same
  heading. The body keeps the definition and the practical check.
- `qa-plan` "Test Monitoring, Control & Completion", all five subsections → `test-reporting.md`.
  The body keeps one line each and the instruction to read the reference first.

The `/qa-cases` automation scoring table, which sat under "Tracker Intelligence", now has its own
heading, "Automation Score (Decision Matrix)", the name its step 6 already used. Text the format
checks read (the complete example, the Accepted and Rejected Source values) did not move, so
`tests/test-tc-contracts.sh` is unchanged. The CTFL allowlist lost its `/qa-cases` runbook entry:
in the reference the citation is on the same line.

Placebo parity after the change (`node benchmark/build.js --check`): the mean file condition D
loads is 14,067 bytes (16,512 before); the placebo's 15,493 bytes are 110.1% of it (93.8% before),
inside the 75% to 125% band. Per task the placebo is now 88% of `qa-cases` (70% before) and 88% of
`qa-plan` (60% before).
