# Plan 035: Teach the CTFL v4.0.1 topics the package names but does not explain

> **Executor instructions**: Do this plan **after plan 034 has merged**: 034 splits `qa-automate.md`
> and `/qa-defect`, removes duplicated text and fixes how commands point to references, so several
> targets below move. Follow it item by item; each item (or each group marked below) is one small PR.
> Run every verification command and confirm the expected result before moving on. If anything in
> "STOP conditions" occurs, stop and report; do not improvise. When done, update this plan's row in
> `plans/README.md`.
>
> **Drift check (run first)**: `git diff --stat a2f08e7..HEAD -- .claude/skills/qa-reference .claude/skills/qa-plan/SKILL.md .claude/commands/qa-defect.md .claude/commands/qa-cases.md .claude/commands/qa-bdd.md .claude/commands/qa-refinement.md .claude/commands/qa.md .claude/agents/qa-engineer.md .claude/agents/qa-designer.md .claude/rules/testing-guidelines.md`
> Drift is **expected** from 034. For every item, re-locate the excerpt quoted in "Current state" in
> the live tree (it may now live in a reference 034 created). If an excerpt no longer exists anywhere,
> treat that item as a STOP condition; if it only moved, apply the item at its new location.

## Status

- **Priority**: P1 (the package claims CTFL v4.0 alignment; plan 031 made the README list these
  topics as "not yet covered", and this plan is what removes them from that column)
- **Effort**: L overall (twelve items, each S or M)
- **Risk**: LOW (text only; no installer, hook or format-contract change)
- **Depends on**: plan 034 merged. Shares one new reference file with plan 036 (item 2 below); either
  plan may land first (see "Coordination with plan 036").
- **Category**: content (new CTFL content and three wording corrections)
- **Planned at**: commit `a2f08e7`, 2026-10-14 (backlog "CTFL content gaps", audit after 4.0.0)
- **Decided by Marco, 2026-10-14**: the default measure per coverage row in item 4; percentages unchanged.
- **Executed 2026-10-18**: items 1, 4, 5, 6 in #149; items 2, 3, 10 in #151 (stacked on #149);
  items 7, 8 in #153; items 9, 11, 12 in #154; the README table and this record in a docs PR. See
  "Execution record, 2026-10-18" at the end.

## Why this matters

Bem-te-vi is a set of prompts: what it does not explain, an assistant improvises. The audit after
4.0.0 measured the shipped files against the official CTFL v4.0.1 syllabus and found whole learning
objectives absent: test types, confirmation versus regression testing, maintenance testing,
white-box coverage, the coverage items that make a black-box technique measurable, checklist-based
testing, prioritisation strategies, the testing quadrants, roles and independence, DevOps and
shift-left, and the 3 Cs. Coverage targets of 70-100% are printed with no statement of *what* is
being covered. Three passages teach something the syllabus contradicts: the defect report uses
"root cause" for the defect's location, the `qa-engineer` agent calls an AI review "static
analysis", and `/qa-bdd` gives validation only to the product owner.

## Conventions you must follow

- **New content goes in on-demand files, not rules.** The always-loaded rules have a 25,000-byte
  cap (`tests/test-rules-size.sh`, 21,439 bytes at `a2f08e7`). Do not add bytes to
  `.claude/rules/*.md` in this plan. The targets are the `qa-reference` skill's references
  (`.claude/skills/qa-reference/references/`), the `qa-plan` skill, and the commands, all of which
  load only when used.
- **Every new reference file is listed** in the contents table of
  `.claude/skills/qa-reference/SKILL.md` and, if a topic is new, in its `description:` (534
  characters today; `tests/test-frontmatter.sh` caps it at 1024).
- **Cite the syllabus by section**, `CTFL v4.0 §x.y.z`, the form already used across the package.
  Use **only** the official PDF `<local copy of ISTQB_CTFL_Syllabus_v4.0.1.pdf>` for
  numbers and wording. Never use the Markdown conversion in git history: it is pre-errata and
  misnumbered.
- **Write in the package's own words.** Explain and apply; do not paste syllabus paragraphs. Short
  defined terms (e.g. "valid transitions coverage") are fine.
- **Point to references the way 034 settled.** 034 step 3 replaces `.claude/skills/...` paths
  (which plugin and skills-only installs lack) with skill-relative ones,
  `qa-reference/references/<file>.md`, and makes `tests/test-reference-links.sh` enforce it. New
  pointers use that form; new reference files sit flat in `qa-reference/references/` (the
  generators read one level) and get a `verify-adapters.sh` marker as 034 step 5 does.
- After editing anything under `.claude/`, regenerate the adapters. The references are inlined into
  every single-file adapter, so keep each addition to what an assistant needs to act.
- Branch per item or item group, e.g. `feat/ctfl-test-types`. Commit types (CONTRIBUTING.md): new
  content reaching installed users is `feat:`; a correction of wrong guidance is `fix:`. One concept
  per commit. Never add AI attribution lines to commits or PRs.

## Commands you will need

| Purpose | Command | Expected on success |
| --- | --- | --- |
| Adapters | `./generate-adapters.sh --clean && ./tests/verify-adapters.sh` | exit 0 |
| Rules size | `./tests/test-rules-size.sh` | `✔ The 9 always-loaded rules total N bytes (cap 25000).`, N unchanged by this plan |
| Reference links | `./tests/test-reference-links.sh` | `✔ All N reference pointers resolve.` |
| Frontmatter | `./tests/test-frontmatter.sh` | exit 0 |
| TC contracts | `./tests/test-tc-contracts.sh` | exit 0 (item 1 edits TC examples) |
| Markdown lint | `npx --yes markdownlint-cli@0.49.1 --dot <changed .md files>` | no output |
| Syllabus text | see "Citation check" below | a `syl.txt` with one `=====PAGE n=====` marker per page |

### Citation check (every new section number exists in the PDF)

No PDF tool is installed system-wide on the planning machine; `pypdf` in a scratch directory works:

```bash
S="$(mktemp -d)"; python3 -m pip install --quiet --target "$S/pylib" pypdf
cat > "$S/ex.py" <<'EOF'
import sys; sys.path.insert(0, sys.argv[1])
from pypdf import PdfReader
with open(sys.argv[3], "w") as f:
    for i, p in enumerate(PdfReader(sys.argv[2]).pages, 1):
        f.write(f"\n=====PAGE {i}=====\n{p.extract_text() or ''}")
EOF
python3 -I "$S/ex.py" "$S/pylib" <local copy of ISTQB_CTFL_Syllabus_v4.0.1.pdf> "$S/syl.txt"
git diff github/main...HEAD -- .claude | grep '^+' | grep -oE 'CTFL( v4\.0)? §[0-9]+(\.[0-9]+)+' | sort -u |
  while read -r c; do s="${c##* }"; n="${s#§}"; grep -qE "^${n//./\\.}\.? " "$S/syl.txt" || echo "MISSING $s"; done
```

Expected: no `MISSING` line. The pattern only takes `CTFL §…` and `CTFL v4.0 §…` citations; book
citations (`Valente … §8.4`) are checked against the book (plan 036). Then, for each cited section, open its heading in `syl.txt` and confirm
the topic matches the sentence that cites it (a right number on the wrong topic is still wrong).

## Scope

**In scope**: `.claude/skills/qa-reference/references/testing-design.md`; one new reference
(working name `testing-in-delivery.md`, shared with plan 036); `.claude/skills/qa-reference/SKILL.md`;
`.claude/skills/qa-plan/SKILL.md`; `.claude/commands/qa-cases.md`, `qa-defect.md` (or the generic
defect-report file 034 created from it), `qa-bdd.md`, `qa-refinement.md`, `qa.md` (router row only);
`.claude/agents/qa-engineer.md` (identity lines only); `plans/README.md`.

**Out of scope**:

- Everything in plan 036 (FIRST, test smells, test doubles, testability remedies, characterization
  tests, test-code review, CI practice, delivery vs deployment, feature flags, canary, A/B, MVP, the
  UI-heavy preset). Where a topic touches both plans, the split is in "Coordination with plan 036".
- Retrospectives (§2.1.6): listed by plan 031 as absent, but not in this backlog line. Record it as a
  follow-up in `plans/README.md`; do not write it here.
- Adding `Checklist-based` to the `qa-designer` technique enum (`qa-designer.md:49`) or the
  `qa-writer` table: that changes the `/qa-agentic` contract. Follow-up only.
- `README.md`'s CTFL coverage table: update its "Not yet covered" cells only as the last step,
  listing the topics this plan actually shipped.
- The always-loaded rules (byte budget; see Conventions).
- The duplicated-text families 034 step 4 consolidates (`N/A — <why>`, "Correct, don't delete"):
  new template fields follow the form 034 settled in `qa-reference/references/written-records.md`.

## Coordination with plan 036

- **One shared reference, two owners.** The new reference `testing-in-delivery.md` holds testing
  across the delivery lifecycle. **This plan owns** the CTFL sections: DevOps and testing (§2.1.4),
  shift-left (§2.1.5), confirmation and regression testing (§2.2.3), maintenance testing (§2.3).
  **Plan 036 owns** the practice sections from the book's chapter 10: CI preconditions, the
  broken-build rule, delivery vs deployment, feature flags, canary releases and A/B validity.
  Whichever plan lands first creates the file with its title, a one-paragraph purpose and its own
  sections; the second appends and adds the cross-links (e.g. this plan's DevOps section links to
  036's CI section once it exists, never before: a link to a missing heading is a defect).
- **Coverage belongs here.** Statement and branch coverage, and what the coverage targets measure,
  are item 4 of this plan, including the book's chapter 8 caveat on coverage targets. Plan 036 does
  not touch the coverage table.
- **`testing-design.md` is edited by both plans in different sections**: this plan adds test types,
  coverage items, white-box and checklist-based testing; 036 extends the mocking section and the
  pyramid preset. Rebase rather than resolve conflicts by hand.
- **`qa-engineer.md` line 10** (`SOLID & FIRST Principles | Static Analysis & Code Review
  Specialist`): this plan changes only "Static Analysis"; 036 makes "FIRST" resolve to a definition.

---

## Item 1: test levels and test types (§2.2.1, §2.2.2)

**Syllabus.** FL-2.2.1 (K2) *Distinguish the different test levels*; FL-2.2.2 (K2) *Distinguish the
different test types*. §2.2.1 describes five levels and the attributes that tell them apart (test
object, objectives, basis, defects and failures, approach and responsibilities), and the forms of
acceptance testing. §2.2.2 describes four test types (functional, non-functional with the ISO/IEC
25010 characteristics, black-box, white-box), each applicable at every level.

**Current state.**

- `testing-design.md:60-71` "Level Tags and CTFL Test Levels" maps `@unit`/`@integration`/`@api`/`@e2e`
  to levels. It names levels but not what distinguishes them, nor the acceptance-testing forms.
- No file explains test types: `grep -rniE 'test type' .claude` → no match. Non-functional appears
  only as a tool category (`test-tools.md:19`) and as checklist lines (`qa-refinement.md:73`,
  `qa-static.md:88`).
- **A test type is used as a technique**: `qa-cases.md:269` `| **ISTQB Technique** | Functional — entry point |`
  and `qa-cases.md:287` `| **ISTQB Technique** | Functional — happy path |`. "Functional" is a test
  type (§2.2.2); the field asks for a technique (§4).
- `qa-plan/SKILL.md:234` item 6 asks the plan for "levels, types, techniques" with nothing to read.

**Target.** `testing-design.md`, extending the existing level section; the two `qa-cases.md` rows.

**What to write** (outline):

1. Under the level section: one line per level with its focus and typical owner; the five
   distinguishing attributes as a short list; acceptance-testing forms (user, operational,
   contractual, regulatory, alpha, beta) in one sentence; note that levels can overlap in time.
2. New subsection "Test types (CTFL v4.0 §2.2.2)": the four types, one or two lines each in the
   package's words; the eight ISO/IEC 25010 characteristics as a list, each with the command or
   reference that covers it in this package (security → `security-checks.md`, usability /
   accessibility → `accessibility-checks.md`, performance → none yet, say so); "every type applies at
   every level, with a different focus"; "a type is not a technique and not a level".
3. `qa-cases.md:269,287`: replace "Functional — …" with the technique actually applied (likely State
   Transition for a dialog that appears in the unauthenticated state, EP for a valid-input happy path;
   choose from the technique table). If the test type is worth recording, it goes in **Note**.

**Commits**: `feat: explain CTFL test types beside the test levels`;
`fix: name a technique, not a test type, in the qa-cases examples`.

**Verify**: `grep -n 'Functional —' .claude -r` → no match; `./tests/test-tc-contracts.sh` exit 0.

## Item 2: confirmation, regression and maintenance testing (§2.2.3, §2.3)

**Syllabus.** FL-2.2.3 (K2) *Distinguish confirmation testing from regression testing*; FL-2.3.1 (K2)
*Summarize maintenance testing and its triggers*.

**Current state.**

- `qa-migrate/SKILL.md:24` is the only citation of §2.2.3 and §2.3.
- `qa-plan/SKILL.md:110` defines the release gate by the two questions "do the fixes work?" and "did
  the change break anything that already worked?", which are confirmation and regression testing,
  unnamed.
- `qa-defect.md:256` "**Recommend retest criteria**" and the Status value `Retest` (`qa-defect.md:47`)
  describe confirmation testing without the term.
- `@regression` is a suite tag (`testing-guidelines.md`, rule) with no definition of what makes a
  test a regression test. "Impact analysis" and "maintenance testing": no match in `.claude`.

**Target.** New reference `testing-in-delivery.md` (create it if plan 036 has not), sections
"Confirmation and regression testing" and "Maintenance testing"; one-line pointers from
`qa-plan/SKILL.md:110` and from the defect-report step that today reads "Recommend retest criteria"
(in the file 034 left for the generic defect report).

**What to write** (outline):

- Confirmation testing: proves the reported defect is fixed; options by risk (rerun the failing
  tests; add tests for the code changed by the fix; at minimum, repeat the reproduction steps).
- Regression testing: proves the change, including a confirmed fix, broke nothing else (same
  component, other components, connected systems, environment). Scope it by **impact analysis**
  first. Regression suites grow every release: prime automation candidates, run in CI, at every
  level where something changed.
- Map to the package: the release gate's two questions; `@regression` and `@smoke` as suite tags
  (not test types); the defect report's "retest criteria" become the confirmation test.
- Maintenance testing: corrective, adaptive and perfective changes, planned and hot fixes; scope
  depends on the risk of the change, the size of the system and the size of the change; triggers:
  modification, upgrade or migration of the environment (including data conversion; point to the
  `qa-migrate` skill as an instance), retirement (archiving, restore and retrieval).

**Commit**: `feat: add confirmation, regression and maintenance testing to the references`.

**Verify**: `grep -rn 'impact analysis' .claude` → at least one match in the new reference.

## Item 3: DevOps and shift-left (§2.1.4, §2.1.5)

**Syllabus.** FL-2.1.4 (K2) *Summarize how DevOps might have an impact on testing*; FL-2.1.5 (K2)
*Explain shift left*.

**Current state.** `testing-guidelines.md:15` (rule, principle 3) mentions "Shift-left testing
(reviews, static analysis, unit tests)" in one clause; `test-tools.md:20` lists DevOps as a tool
category. Nothing explains either.

**Target.** `testing-in-delivery.md`, section "DevOps, shift-left and testing" (placed before 036's CI
sections).

**What to write** (outline):

- DevOps from the tester's side: benefits (fast feedback, CI encourages component tests and static
  analysis with each commit, stable automated environments, visible non-functional quality, less
  repetitive manual testing, lower regression risk) and costs (a pipeline to define and keep,
  tools to maintain, automation effort). Manual testing from the user's perspective is still needed.
- Shift-left: test earlier without neglecting later testing. Map each syllabus practice to what the
  package ships: reviewing the specification (`/qa-static`), test-first (`/qa-tdd`, `/qa-bdd`), CI
  with automated component tests (036's CI section), static analysis tools before dynamic testing
  (`test-tools.md`), non-functional testing from component level where possible. It costs effort
  early and needs stakeholder buy-in.

**Commit**: `feat: explain DevOps and shift-left for testing`.

## Item 4: white-box testing, and the measure behind the coverage targets (§4.1, §4.3)

**Syllabus.** FL-4.1.1 (K2) *Distinguish black-box, white-box and experience-based test techniques*;
FL-4.3.1 (K2) *Explain statement testing*; FL-4.3.2 (K2) *Explain branch testing*; FL-4.3.3 (K2)
*Explain the value of white-box testing*.

**Current state.**

- `testing-design.md:20-29` "Coverage Strategy Targets": "Critical Paths 100% / Business Logic 80%+ /
  Utilities 70%+ / UI as needed", under the sentence "Coverage is a guide, not a goal, but baseline
  standards must be enforced" (`:22`). No row says what is counted: statements, branches,
  requirements or journeys.
- "white-box", "statement coverage", "branch coverage": no match in `.claude`. `qa-plan/SKILL.md:150`
  lists "code coverage where available" as a metric.
- The book *Engenharia de Software Moderna* §8.4 ("Cobertura de Testes") makes the same point from
  practice: there is no universal target, track the trend, inspect what is uncovered. Cite it here
  (in the package's own words; plan 036 does not repeat it).

**Target.** `testing-design.md`: rewrite the coverage table's header and rows to name the measure;
new section "White-box techniques and code coverage".

**What to write** (outline):

- The three technique families in two lines each (§4.1), and that experience-based techniques
  complement the other two.
- Statement coverage: what it counts, what 100% guarantees, what it misses (data-dependent defects,
  untaken branches). Branch coverage: conditional and unconditional branches; it subsumes statement
  coverage. Value: covers the implementation even when the specification is vague; blind to
  requirements that were never implemented (omissions); black-box testing alone gives no code
  coverage measure.
- Coverage table: each row states its measure. Proposed default (see Decision below): Critical
  paths → 100% of the journey's acceptance criteria and risk items (requirements coverage, not code);
  Business logic → 80% **branch** coverage; Utilities → 70% statement coverage; UI → visual
  regression, no code figure. Replace "baseline standards must be enforced" with: a figure is a
  floor to investigate below, not a target to game; track the trend; read the uncovered lines.
- One line on tooling: Vitest's coverage report (`vitest run --coverage`) gives statements and
  branches separately; read the branch column.

**Decision for Marco**: the measure per row. Default above; keep the percentages unchanged.

**Commit**: `feat: name the coverage measure and explain statement and branch coverage`.

**Verify**: `grep -n -i 'branch coverage' .claude/skills/qa-reference/references/testing-design.md` → match.

## Item 5: coverage items for EP, decision tables and state transition (§4.2.1, §4.2.3, §4.2.4)

**Syllabus.** FL-4.2.1, FL-4.2.3, FL-4.2.4 (all K3) *Use … to derive test cases*. Each section defines
the technique's coverage items and how coverage is measured: partitions (and Each Choice for several
sets) for EP; feasible columns for decision tables, with the T/F/–/N/A notation, infeasible columns
removed, minimisation allowed; for state transition, all-states, valid-transitions (0-switch) and
all-transitions coverage, one invalid transition per test case to avoid defect masking.

**Current state.** BVA already carries its coverage items (plan 028, `testing-design.md:52`). The
other three rows do not: `testing-design.md:51` "Divide inputs into valid/invalid groups", `:53` "Map
combinations of inputs to outputs", `:54` "Verify state changes based on triggers/events". The
`qa-cases.md` technique section repeats them (`:149-207`): its decision table (`:175-187`) uses `Y/N`
for actions and says nothing about infeasible columns; its state-transition text (`:189-196`) is "Map
all states and valid transitions" with no coverage criterion.

**Target.** `testing-design.md` (add a "Coverage items" column, or a subsection per technique if the
table becomes unreadable). In `qa-cases.md`, adjust only what remains after 034: if 034 replaced
that section with a pointer to `testing-design.md`, edit nothing there.

**What to write** (outline): per technique, the coverage item, the 100% condition and the
percentage formula in one line; for state transition, which criterion to choose by risk (valid
transitions as the usual minimum; all transitions for safety- or mission-critical behaviour, which the
syllabus names as a minimum there); in `qa-cases.md`, the `X`/blank action notation and one invalid
transition per case.

**Commit**: `feat: give every black-box technique its coverage items`.

## Item 6: checklist-based testing (§4.4.3)

**Syllabus.** FL-4.4.3 (K2) *Explain checklist-based testing*.

**Current state.** `qa-static.md:79` applies checklist-based **reviewing** (§3.2.2), a static
technique. The technique table (`testing-design.md:49-56`) lists error guessing and exploratory
testing but not checklist-based testing. `qa-explore/SKILL.md:108` has "Risk-area prompts (package
checklist)", a checklist with no guidance on how to use or maintain one.

**Target.** `testing-design.md`: a row in the technique table and a short section; one pointer line
under `qa-explore/SKILL.md:108`.

**What to write** (outline): items phrased as questions, each checkable on its own; leave out what a
tool can check, what belongs in entry or exit criteria, and what is too general; keep the list short;
add items from high-severity defects and retire items that stop finding anything (defect analysis);
high-level checklists trade repeatability for coverage; useful for functional and non-functional
testing where no detailed cases exist.

**Commit**: `feat: add checklist-based testing to the technique reference`.

## Item 7: test case prioritisation and the testing quadrants (§5.1.5, §5.1.7)

**Syllabus.** FL-5.1.5 (K3) *Apply test case prioritization*; FL-5.1.7 (K2) *Summarize the testing
quadrants and their relationships with test levels and test types*.

**Current state.** `qa-plan/SKILL.md:76` orders tests by risk only ("test the highest levels
first"). Coverage-based and requirements-based prioritisation, dependencies between cases and
resource windows: absent. "quadrant": no match in `.claude`. The pyramid presets sit at
`qa-plan/SKILL.md:39-51` (duplicated in `testing-design.md:9-18`; 034 may keep only one).

**Target.** `qa-plan/SKILL.md` (an on-demand skill, the package's home for CTFL chapter 5): a "Test
execution order" subsection after the risk-based bullets; a "Testing quadrants" subsection after the
pyramid presets (wherever 034 left them).

**What to write** (outline):

- Prioritisation: risk-based, coverage-based (including additional-coverage ordering) and
  requirements-based, one line each with when to choose it; a higher-priority case that depends on
  a lower-priority one forces the lower one first; tools, environments and people available only in
  windows constrain the order. Show the order as a column in the release-gate table only if that
  table already has room; otherwise as a numbered list.
- Quadrants: the two axes (business- vs technology-facing; supporting the team vs critiquing the
  product), Q1-Q4 with their typical content, and a mapping to this package (Q1: `@unit`,
  `@integration` in CI; Q2: `/qa-bdd`, `@api`, functional cases; Q3: `qa-explore`, usability,
  acceptance; Q4: `@smoke`, security, accessibility, performance). Use: check a plan covers all four.

**Commit**: `feat: add prioritisation strategies and the testing quadrants to qa-plan`.

## Item 8: roles in testing and independence of testing (§1.4.5, §1.5.3)

**Syllabus.** FL-1.4.5 (K2) *Compare the different roles in testing*; FL-1.5.3 (K2) *Distinguish the
benefits and drawbacks of independence of testing*.

**Current state.** `qa-plan/SKILL.md:234` asks the plan's test approach for "independence of testing"
with no definition anywhere; "independence": that line is the only match in `.claude`.
`qa-bdd.md:24` and `qa-refinement.md:129` (Three Amigos) touch the whole-team idea only.

**Target.** `qa-plan/SKILL.md`, a short "Roles and independence" subsection referenced from plan item 6.

**What to write** (outline): the test management role and the testing role, and that one person can
hold both; the four degrees of independence (author, peer, separate team in the organisation,
outside the organisation); mixing degrees across levels is usual; benefits (different biases,
challenging assumptions) and drawbacks (isolation, developers losing ownership of quality, testers
seen as a bottleneck); what to write in the plan's item 6 (who tests what, at which degree, why).

**Commit**: `feat: explain roles and independence of testing in qa-plan`.

## Item 9: the 3 Cs of a user story (§4.5.1)

**Syllabus.** FL-4.5.1 (K2) *Explain how to write user stories in collaboration with developers and
business representatives*. §4.5.1: Card, Conversation, Confirmation; INVEST; a stakeholder unable to
say how to test a story is a signal.

**Current state.** INVEST is at `qa-refinement.md:80-87`; acceptance-criteria formats (§4.5.2) at
`qa-refinement.md:96,128,146`. "3 C" / "Card, Conversation": no match in `.claude`.

**Target.** `qa-refinement.md`, "User Story Review Checklist" (`:91-101`).

**What to write**: one checklist line for the 3 Cs (the confirmation is the acceptance criteria,
produced in the conversation), and one line: if nobody can say how a story will be tested, it is
unclear, of doubtful value, or the team needs help testing it. Cite §4.5.1.

**Commit**: `feat: add the 3 Cs to the user story review`.

## Item 10: the defect report carries the §5.5 context, and "root cause" means a cause (§5.5, §1.2.3)

**Syllabus.** FL-5.5.1 (K3) *Prepare a defect report*; FL-1.2.3 (K2) *Distinguish between root
cause, error, defect, and failure*. §5.5 lists the report's typical content, including the author's
role, the context of the defect (test case, test activity, SDLC phase, technique, checklist or test
data used) and status values such as deferred, duplicate and awaiting confirmation testing. §1.2.3:
a root cause is the fundamental reason for the problem (the situation that led to the error).

**Current state** (in `qa-defect.md`; 034 step 6 keeps the generic report, lines 1-258, in the
command and moves only the Node and Azure DevOps parts to references):

- `qa-defect.md:40` `Reported By    : [Name]`: no role or organisation. The Environment block
  (`:50-57`) has Test Data and Test Case but no test activity, SDLC phase, technique or checklist.
- `qa-defect.md:47` Status: `New Assigned Open Fixed Retest Closed Rejected Reopened`: no
  `Deferred`, `Duplicate`; `Retest` is not named as confirmation testing.
- `qa-defect.md:81-82` "Root Cause (filled after analysis)" is followed by Fix Applied, Fixed In
  Build: it is used as the fix record.
- `qa-defect.md:255`: `7. **Suggest root cause** if obvious (e.g., "Missing null check at line X")`.
  A missing null check at a line is the **defect** and its location, not the root cause.
- The always-loaded rule already states the distinction (`testing-guidelines.md:31-38`); the
  command contradicts it.

**Target.** `qa-defect.md`: the template, its "How to respond" steps and the filled example
(`:231-232`). If a new field needs a tracker slot, add it to the field mapping in
`qa-reference/references/tracker-azure-devops.md` (created by 034 step 6).

**What to write**:

1. (fix) Split the section into **Defect location (if known)** (file, function, line: the defect) and
   **Root cause (after root-cause analysis)** (the error and the situation behind it: ambiguous
   requirement, missing review, time pressure). Step 7 becomes "Suggest the likely defect location
   if obvious; leave Root cause `N/A — not yet analysed` until analysis is done." Fix the example.
2. (feat) Add `Reporter role`, and a **Context** block: test activity, SDLC phase, technique or
   checklist used, test data. Add `Deferred` and `Duplicate` to Status; describe `Retest` as
   "awaiting confirmation testing" and link item 2's section.
3. Every new field appears in the example (Template Completeness, `qa-defect.md:14-21`).

**Commits**: `fix: keep the defect location apart from the root cause`;
`feat: add the CTFL defect context fields to the defect report`.

**Verify**: `grep -n 'Suggest root cause' .claude -r` → no match.

## Item 11: the `qa-engineer` agent is a review, not static analysis (§3.1, §3.2)

**Syllabus.** §3.1: static testing is either manual examination (reviews) or tool-based (static
analysis); FL-3.1.3 (K2) *Compare and contrast static testing and dynamic testing*.

**Current state.** `qa-engineer.md:10` "Static Analysis & Code Review Specialist"; `:12` "execute deep
static code analysis"; `:18` "Static Analysis Expert"; `qa.md:86` routes the trigger "static analysis"
to this agent. The agent is a model reading code: a review (§3.2). It runs no analyser.

**Target.** `qa-engineer.md:10,12,18` and the `qa.md:86` row.

**What to write**: call it an AI-assisted code review (a form of static testing by examination,
CTFL v4.0 §3.1); one sentence that it complements, never replaces, static analysis tools (linters,
type checkers, security scanners; `test-tools.md`), and that a finding a tool can check belongs in
the tool. In `qa.md:86` keep "code review" and "testability"; route "static analysis" to the
tool-selection reference instead. Leave the word "FIRST" on line 10 for plan 036.

**Commit**: `fix: describe the qa-engineer agent as a code review, not static analysis`.

**Verify**: `grep -rn -i 'static analysis expert\|deep static code analysis' .claude` → no match.

## Item 12: validation is part of testing, not only the product owner's (§1.1, §2.2.1, §1.5.2)

**Syllabus.** §1.1: testing involves verification (meets specified requirements) **and** validation
(meets users' and stakeholders' needs in the operational environment). §2.2.1: acceptance testing
focuses on validation, ideally by the intended users. §1.5.2: in the whole-team approach everyone is
responsible for quality.

**Current state.** `qa-bdd.md:26-29`:

```markdown
**Verification vs Validation:**

- **Verification**: "Built it right?" — matches spec (dev/QA)
- **Validation**: "Built the right thing?" — meets user needs (PO/customer)
```

It contradicts the always-loaded rule's "Expected Gain Validation" (`testing-guidelines.md:45`),
which makes QA test whether the feature delivers its value.

**Target.** `qa-bdd.md:26-29`.

**What to write**: both are testing activities shared by the team; validation is done by QA through
scenarios built from user goals and expected gain, by the product owner in review, and by intended
users in acceptance testing; neither belongs to one role. Cite §1.1 and point to the rule's
Expected Gain Validation.

**Commit**: `fix: share validation across the team in /qa-bdd`.

---

## Last step: the README coverage table

After the items merge, update `README.md`'s "ISTQB CTFL v4.0 — Coverage" table: move each topic this
plan shipped out of "Not yet covered". Commit `docs: list the CTFL topics the package now covers`.

## Done criteria

- [ ] Every item's verify command gives the expected result.
- [ ] Citation check: no `MISSING` section; each cited heading matches its topic.
- [ ] `./generate-adapters.sh --clean && ./tests/verify-adapters.sh` exits 0.
- [ ] `./tests/test-rules-size.sh`: total unchanged from before this plan (no rule edited).
- [ ] `./tests/test-reference-links.sh`, `./tests/test-frontmatter.sh`, `./tests/test-tc-contracts.sh` pass.
- [ ] Every new reference is in the `qa-reference` contents table.
- [ ] Book text check (item 4 cites the book): run the 4-gram comparison in plan 036's Done
      criteria on the changed files → no hit that is book text.
- [ ] Markdown lint clean on every changed file.
- [ ] `plans/README.md`: row for 035 updated; retrospectives (§2.1.6) and the `qa-designer`
      checklist technique recorded as follow-ups.

## STOP conditions

- Plan 034 has not merged.
- An excerpt quoted above exists nowhere in the live tree (moved is fine; gone is not).
- A section number or learning objective quoted here does not match the PDF.
- An item would need bytes in `.claude/rules/`.
- An edit changes a format the hooks or `tests/test-tc-contracts.sh` enforce (TC fields, technique
  enum): report it instead of changing the contract.

## Maintenance notes

- Item 4's per-row measures are a judgment; Marco may prefer others. The percentages are unchanged.
- The ISO/IEC 25010 list in item 1 follows the syllabus (which already uses the 2023 names
  "interaction capability" and "flexibility" as aliases). If the package later adds performance
  testing guidance, link it from that list.
- Two cross-links depend on plan 036 (DevOps → CI section). Whichever plan lands second adds them.

## Execution record, 2026-10-18

**Default used (Marco asked for all remaining work on 2026-10-18).** Item 4's measure per row is
the documented default: critical paths, requirements coverage (acceptance criteria and risk items);
business logic, branch coverage; utilities, statement coverage; UI, visual regression with no code
figure. The percentages are unchanged. No other item had an open decision.

**Pull requests.** The plan allows a PR per item or per item group; no group was marked, so the
items were grouped by the file they change, to keep pushes few and avoid PRs that conflict with
each other:

| PR | Items | Why grouped |
| --- | --- | --- |
| #149 | 1, 4, 5, 6 | All extend `testing-design.md`; items 5 and 6 change the same technique table |
| #151 | 2, 3, 10 | The new `testing-in-delivery.md`; item 10's `Retest` status links item 2's section |
| #153 | 7, 8 | Both add to `qa-plan/SKILL.md` |
| #154 | 9, 11, 12 | Small edits to files no other group touches |

PR #151 is stacked on #149: both edit the single-line `description:` of `qa-reference/SKILL.md`, so a
branch off `next` would have conflicted on that line. Merge #149 first. The README table and this
record are a separate docs PR, to merge after the four.

**Drift check.** Drift from 034 was as expected; no excerpt was gone. Moved lines: `qa-cases.md`
technique rows 269 and 287 were at 265 and 283; the `qa-defect.md` status line at 45, the root-cause
block at 79-84 and steps 7-8 at 256-257; the `qa.md` router row at 95. `qa-cases.md`'s technique
section was not replaced by a pointer in 034, so item 5 edited it. 034's maintenance note suggested
one file per topic (`test-levels-and-types.md`, `white-box-coverage.md`); this plan, written after
it, names `testing-design.md` as the target for items 1, 4, 5 and 6, and that was followed.

**STOP check.** Every section number quoted in this plan exists in the v4.0.1 PDF with the topic
the plan gives it. One learning objective is quoted in its v4.0 wording: FL-4.1.1 reads
"Distinguish black-box test techniques, white-box test techniques and experience-based test
techniques" in v4.0.1 (Appendix C, Release Notes, records the change from "Distinguish
black-box, white-box and experience-based test techniques"). The meaning is the same, and no shipped file
quotes the objective, so it was not treated as a STOP.

**Syllabus ambiguities resolved.**

- Item 2 outline: "corrective, adaptive and perfective". §2.3 says "corrective, adaptive to changes
  in the environment or improve performance or maintainability" and never uses "perfective"; the
  reference follows the syllabus.
- Item 2 outline: `qa-migrate` "as an instance" of an environment migration. `qa-migrate` moves a
  test suite (testware), not the operational environment, so the reference says it applies the same
  regression logic and is not one of the §2.3 triggers.
- Item 7 outline put accessibility in Q4. §5.1.7 puts "non-functional tests (except usability
  tests)" in Q4 and usability testing in Q3, and item 1 files accessibility under usability, so
  accessibility went to Q3.
- Item 7: the execution order is a numbered list under the release-gate table, not a column; the
  gate table keeps its three columns.
- Item 1: the "Usually done by" column of the level table uses §1.5.3's example split (developers,
  test team, business representatives) together with §2.2.1's notes. Maintainability is mapped to
  the `qa-engineer` testability review; that mapping is the package's, since the syllabus does not
  list sub-characteristics. Cross-browser Playwright projects were not claimed as compatibility
  testing, so compatibility reads "Not covered yet".
- Item 9: the Confirmation line cites §4.5.2 too, because "usually an outcome of the conversation"
  is §4.5.2's wording of the link.

**Verification.**

- Every item's verify command gives the expected result: no `Functional —`, `impact analysis` in
  the new reference, `branch coverage` in `testing-design.md`, no `Suggest root cause`, no `static
  analysis expert` or `deep static code analysis`.
- Citation check on each branch: no `MISSING` line; each cited heading read in the PDF text and
  matched to its sentence.
- Book 4-gram check (plan 036's script) on every changed file: the only hit is the book's title in
  the §8.4 citation.
- `./tests/test-rules-size.sh`: 21,415 bytes on `next` and on every branch; no rule was edited.
- Local Linux CI on every branch: all steps pass except lifecycle Test 20 (".claude survived
  uninstall after a no-manifest upgrade"), the known failure on `next` until
  `fix/update-adopts-current-files` lands.
- GitHub CI: #149 ran on Linux, Windows and macOS; every step passed except the same Test 20 on
  each platform. #151, #153 and #154 did not run: GitHub refused to start the jobs ("recent account
  payments have failed or your spending limit needs to be increased").

**README.** The coverage table moves every topic shipped here to "Covered". The chapter 4 cell
also held "acceptance-criteria formats", which `/qa-refinement` already taught before this plan
(its CTFL §4.5.2 lines); it moved with the 3 Cs. Retrospectives and tool-based static analysis stay
in "Not yet covered".

**Left open.**

- Retrospectives (§2.1.6) and `Checklist-based` in the `qa-designer` technique enum and the
  `qa-writer` table: recorded as follow-ups in `plans/README.md`.
- The `/qa-cases` complete example's header lists "Error Guessing" among its techniques, and none of
  its three cases uses it. Noticed while fixing item 1; not changed.
- Plan 036 adds the cross-link from the shift-left row (today `automation-ci.md`) to its CI section,
  and owns the rest of `testing-in-delivery.md`.

> **Update, 2026-10-18 (later the same day).** Marco asked for everything to be fixed before going
> public, and the first two bullets above were done as three follow-ups. Retrospectives (§2.1.6, with
> §5.3.2) went into the `qa-plan` skill beside the completion report, not into
> `testing-in-delivery.md`: the syllabus records a retrospective's results in the test completion
> report, which `qa-plan` teaches (#175); the README table moves them to "Covered".
> `Checklist-Based` is in the `qa-designer` enum and in the technique rows of `qa-writer` and the
> `/qa` quick reference, and `tests/test-tc-contracts.sh` now fails when the enum lacks a technique
> the reference's table teaches (#177). The `/qa-cases` example header now reads "EP, State
> Transition", the techniques its cases use (#178).
