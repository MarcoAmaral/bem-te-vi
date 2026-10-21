# Plan 024: A second look at Spec Kit, and what Bem-te-vi should take from it

> **Executor instructions**: This is a decision plan, not an implementation plan. Nothing here is
> built until Marco picks candidates (see the STOP at the end). Each chosen candidate becomes its
> own change on its own branch. Reproduce a defect before writing it down, and record rejected
> approaches with the reason rather than deleting them. Nothing in this repository may depend on
> Spec Kit, hard-code its command names, or hard-code its paths; it is always described as "a spec
> directory such as `.specify/`".

## Status

- **Priority**: P2
- **Effort**: XS to M per candidate (see each); nothing is mandatory
- **Depends on**: plan 014 Phase C (this refreshes it); plan 021 (rule size budget)
- **Planned at**: 2026-10-12
- **Spec Kit commit read**: `03de661789b74405ae93b8b532d52d2cf8af422e`, committed 2026-10-12
  07:25 -0500, `pyproject.toml` version `1.1.4.dev0` (latest release in `CHANGELOG.md`: 1.1.3,
  2026-10-09). Cloned with `--depth 50` into `.tmp_repos/spec-kit` (gitignored); its installer was
  never run.

## Why this matters

Plan 014 Phase C was written on 2026-09-24 and warned that Spec Kit moves fast enough to break any
integration that hard-codes it. Eighteen days later that warning is still the governing fact, and
the picture has also grown: Spec Kit now has extensions, presets, bundles and workflow overlays,
and it ships steps that overlap with ISTQB static testing and traceability. This plan re-reads it
as it is today, re-judges the four Phase C candidates against what Bem-te-vi already ships, and
looks for new ideas worth taking. Two of the four candidates turned out to be partly or wholly
shipped already, which Phase C could not know.

---

## Findings: Spec Kit as of 2026-10-12

Source: <https://github.com/github/spec-kit>, commit above. Paths below are relative to that
repository.

### What changed since the 2026-09-24 description

The shallow clone reaches back only to 2026-10-06 (50 commits), so **changes between 09-24 and
10-06 cannot be listed from history**; the comparison below is the 09-24 description in plan 014
against the tree as it stands.

| Area | 2026-09-24 (plan 014) | 2026-10-12 (read now) |
| --- | --- | --- |
| Command spelling | `/speckit-constitution`, hyphenated | Still hyphenated (`README.md` lines 82-87, `/speckit-bug-assess`). Stable for 18 days. Command files use placeholders such as `__SPECKIT_COMMAND_TASKS__` that are rendered per agent, so the literal name is not even fixed inside Spec Kit |
| Core SDD sequence | constitution, specify, plan, tasks, implement, converge | Unchanged in `workflows/speckit/workflow.yml`, which adds `review-spec` and `review-plan` gate steps. Plus the optional commands `clarify`, `checklist`, `analyze`; `taskstoissues` is now **deprecated** (CHANGELOG 1.1.3, #4879) |
| Bug workflow | `bug-assess`, `bug-fix`, `bug-test` | Same three, now shipped as an extension (`extensions/bug`) and a bundle (`bundles/bugfix`); lifecycle hooks added in 1.1.3 (#4878) |
| Assessment workflow | `assess-intake` to `decide` | Same, now an extension (`extensions/assess`) and a bundle |
| New structure | none | **Extensions** (`extensions/`), **presets** (`presets/`: `constitution-sync`, `lean`, `scaffold`), **bundles**, a workflow engine with overlays and a step catalog, an MCP adapter (`docs/reference/mcp.md`), community catalogs |
| Hook mechanism | not described | Every command reads `.specify/extensions.yml` for `before_*` / `after_*` hooks |
| Release cadence | not recorded | 1.1.1 (10-06), 1.1.2 (10-07), 1.1.3 (10-09): a release every one to two days |

Net: the command names held still, but the surface around them (extensions, presets, bundles,
workflows, MCP) grew substantially. The 09-24 conclusion stands, strengthened: depend on none of it.

### The commands that matter to a QA package

All under `templates/commands/`; templates under `templates/`.

- **`checklist.md`**: its stated concept is "Unit Tests for English": a checklist validates the
  quality, clarity and completeness of the *requirements*, explicitly not the implementation.
  Items are written as questions ("Is 'prominent display' quantified?"), grouped by quality
  dimension (completeness, clarity, consistency, coverage, edge cases), numbered `CHK001...`, and
  the reviewer, not the agent, owns the `[x]`. The agent asks up to five clarifying questions
  first, derived from the input rather than from a fixed list. This is checklist-based reviewing
  (CTFL v4.0 §3.2.2) under another name.
- **`clarify.md`**: asks up to five targeted questions against a fixed ambiguity taxonomy
  (functional scope including out-of-scope, domain and data model including lifecycle and state
  transitions, UX flow, non-functional attributes, integration and failure modes, edge cases,
  constraints, terminology, completion signals) and writes the answers back into the spec. It
  mutates the spec; `/qa-static` deliberately does not.
- **`analyze.md`**: strictly read-only cross-artifact consistency check across `spec.md`,
  `plan.md`, `tasks.md` and the constitution. Detection passes: duplication, ambiguity,
  underspecification, constitution alignment, coverage gaps, inconsistency. Output: a findings
  table with stable IDs and severities (CRITICAL/HIGH/MEDIUM/LOW), a **coverage table (requirement
  key, has task, task IDs)**, unmapped tasks, and metrics (coverage %). Requirements are keyed by
  explicit `FR-###` / `SC-###` identifiers. Capped at 50 findings; deterministic IDs on re-run.
- **`converge.md`**: assesses the code against spec, plan and tasks, then appends unmet work as new
  tasks. Append-only. This is Spec Kit's requirement-to-implementation loop; it traces
  requirement to *code*, not to *tests or results*.
- **`constitution.md`** and `constitution-template.md`: project principles an agent must honour,
  stored in a memory file under the spec directory. `analyze` treats a constitution violation as
  automatically CRITICAL. The template's own examples include "Test-First (NON-NEGOTIABLE)" and
  "Integration Testing", so the concept is partly about testing discipline.
- **`spec-template.md`**: every user story carries an "Independent Test" and Given/When/Then
  acceptance scenarios; requirements carry `FR-###` IDs; unclear ones are marked
  `[NEEDS CLARIFICATION: ...]`; success criteria are `SC-###` and must be measurable.
- **`tasks-template.md`**: tests are explicitly **optional** ("only if tests requested"), and when
  present must be written first and fail. There is no core QA or test-design step.
- **`extensions/bug/commands/speckit.bug.test.md`**: validates a fix and writes a verification
  report to a per-bug directory. It is a re-test of one bug, not a test-design workflow.

### What does not exist

No core command designs test cases, applies a test design technique, or records a result against a
requirement. Quality in core Spec Kit is requirement-side (`checklist`, `clarify`, `analyze`) and
code-side (`converge`). The gap between "requirement has a task" and "requirement has a passing
test" is open in core. The community catalogs list quality-oriented extensions by name
(CHANGELOG mentions "Quality Gates", "SpecAssay"); their contents were **not read**, so no claim
is made about whether they fill the gap.

---

## Candidates (plan 014 Phase C, re-judged)

### C1. Review the spec first · already shipped as `/qa-static`

- **Still valuable?** Yes, and it is now corroborated: Spec Kit's `checklist` and `analyze` are the
  same idea. Nothing to build for the idea itself.
- **Where Bem-te-vi stands**: `.claude/commands/qa-static.md` applies CTFL v4.0 chapter 3 (review
  type, the generic review process, six finding categories, severities, testable rewrites). It is
  read-only and takes any work product.
- **Residual gap, small**: see N1 below (duplication and terminology drift are named in
  CTFL §3.1.3 but are not one of `qa-static`'s six categories).

### C2. Detect a spec directory · half shipped

- **Still valuable?** Yes, and it is cheap.
- **What exists**: `qa-static.md` Step 0 already says "if the repository has a spec directory (for
  example one created by GitHub Spec Kit, `.specify/`), read it as one more requirements source.
  Never depend on its layout". **`.claude/rules/context-discovery.md` does not**: its tier 3
  lists `plan.md`, `architecture.md`, `docs/`, ADRs, README and CONTRIBUTING and says nothing about
  a spec directory (verified with grep, 2026-10-12). Plan 014 asked for the rule edit; only the
  command edit landed. Because `context-discovery.md` governs `/qa-cases`, `/qa-bdd`,
  `/qa-automate`, `/qa-tdd`, `/qa-static` and Stage 1 of `/qa-agentic`, the other five entry points
  currently ignore a spec directory.
- **Design sketch**
  - Edit `.claude/rules/context-discovery.md` tier 3 to add one bullet: *if the repository has a
    spec directory such as `.specify/`, read its specification and any project-principles file as
    the authoritative requirements source before re-deriving requirements from the ticket; if it
    is absent or unfamiliar, carry on.* Detect by looking for a hidden spec directory at the repo
    root and reading what is in it; do not name files inside it.
  - Add the matching contradiction rule to the existing "contradicts the ticket" section: spec
    directory vs ticket disagreement is reported, not silently resolved.
  - Regenerate adapters; `tests/verify-adapters.sh` and `tests/test-rules-size.sh` must pass (this
    rule is size-budgeted by plan 021; the addition is two or three lines).
- **Reads / writes**: reads a spec directory; writes nothing.
- **Effort**: XS. One rule edit, adapters regenerated, no new test (behaviour is prompt text); add
  a line to `QA_SKILL_TESTS.md` if that file lists rule behaviours.
- **Recommendation**: **Build.** It closes a gap that plan 014 already approved.

### C3. A requirement to test case to result traceability command · not built

- **Still valuable?** Yes, and the Spec Kit re-read sharpens why. Core Spec Kit stops at
  requirement to task (`analyze`) and requirement to code (`converge`). Nothing connects a
  requirement to a *test case* or to a *result*. That link is the heart of the CTFL test-basis
  coverage idea (§1.4.4 traceability, and §3.1.3 "gaps in test-basis coverage"), and Bem-te-vi is
  the package that owns test cases. It already half-writes the data: `qa-writer` carries
  "Traces to REQ-3" into each TC's Note, TCs have an `Issue` field, and `/qa-agentic` keeps one
  folder per ticket with `requirements.md`, `checklist.md` and the TC files.
- **Design sketch: `/qa-trace`** (new command, `.claude/commands/qa-trace.md`)
  - **Reads**, in this order, stopping at whatever exists (degrade, never require):
    1. A requirements source: the `/qa-agentic` ticket folder's `requirements.md`; else a spec
       directory per C2 (the specification's identified requirements and acceptance scenarios);
       else a pasted ticket. Use any stable identifier found (`REQ-3`, `FR-001`, `AC-2`); if none,
       assign `R-001...` and say so, because an invented ID must be marked as invented.
    2. Test cases: `TC-*.md` files (parsed by the existing field layout) and automated specs,
       linked by the Note's "Traces to" value, the tracker `Issue` field, or a requirement ID in
       the test title or tag. A link inferred by keyword is reported as *inferred*, never as
       *traced*.
    3. Results, if any: test runner output the user points at (a report file or pasted output).
       No results means the column reads "not run", not "pass".
  - **Writes**: by default nothing, matching `analyze`'s read-only stance (a report in chat). With
    an explicit argument, `traceability.md` inside the ticket folder.
  - **Output**: a matrix (requirement, test cases, technique, automation status, last result,
    link basis: traced/inferred), plus three lists: requirements with no test, tests with no
    requirement, requirements whose only tests failed or never ran; and a coverage figure stated
    as "requirements with at least one test", never as proof of adequacy (ISTQB principle 1).
  - **Maps to**: CTFL §1.4.4 (traceability supports coverage and impact analysis), §3.1.3 (test
    basis coverage gaps), and the package's own Expected Gain rule (a covered requirement whose
    test passes but does not deliver the outcome is still a finding).
  - **Does not**: score test quality, invent links, or modify test cases.
- **Tests required** (it changes behaviour): a fixture ticket folder under `tests/fixtures/`
  with one covered, one uncovered and one orphan test, and an assertion script in the style of
  `tests/test-validate-tc-format.sh`. Adapters regenerated and `verify-adapters` passing; a new
  command also needs its name registered wherever the command list lives (README, plugin
  manifest, `tests/plugin`).
- **Risk**: the matrix is only as good as the Note/Issue discipline; if TCs carry no links, the
  command reports that honestly and the value drops. That is a finding about the suite, not a bug.
- **Effort**: M. One command, one fixture, one test script, docs. No dependency on Spec Kit.
- **Recommendation**: **Build, after C2.** It is the one new capability with clear user value and
  no overlap with `/qa-static`.

### C4. Borrow the constitution concept · not built

- **Still valuable?** The 09-24 verdict ("nothing to build, name the parallel") mostly stands,
  with one correction found in this read. Spec Kit's constitution is not only principles; it is
  something its other commands *enforce* (`analyze` treats a violation as CRITICAL). Bem-te-vi's
  rules are shipped *to* a target repo but nothing lets that repo say "for us, these rules are
  non-negotiable, and these are overridden". Today overrides happen only by editing installed
  files, which the installer's file-safety contract then treats as a user edit.
- **Two possible shapes**
  - **C4a. Documentation only (recommended if built at all)**: a short section in `README.md` or
    the monograph notes naming the parallel (shipped rules are the QA constitution; per-project
    overrides go in the target repo's own project guide, which agents already read). Effort: XS.
  - **C4b. A project QA-principles file** the commands read (for example a repo-level QA
    principles document that `/qa-static`, `/qa-review` and `/qa-cases` check their output
    against, reporting violations as findings). It would be a new convention, a new thing to
    document and test, and it overlaps with the target repo's own project guide, which already
    carries this role. Effort: M. Not recommended without evidence a user needs it.
- **Recommendation**: **C4a only**; defer C4b until a real ticket shows the need. Decide with
  plan 015 item 6 (templates and contracts), which already covers "write the field contract down
  once".

---

## New ideas from the current Spec Kit

### N1. Name duplication and terminology drift in `/qa-static` · worth taking

`analyze` runs duplication and inconsistency passes (same concept named two ways, near-duplicate
requirements). CTFL §3.1.3 lists duplications among the defects cheaper to find statically, and
`qa-static`'s step 3 quotes that sentence but has no category for it: its six categories cover
untestable criteria, ambiguity, missing negative cases, undefined states, contradictions and
missing non-functional requirements. Add duplication and terminology drift to category 5
(contradictions) rather than a seventh category, to keep the checklist short. Add the
out-of-scope check from `clarify`'s taxonomy to category 3 ("no stated out-of-scope").
**Effort**: XS (one command edit, adapters regenerated). **Recommendation**: build with C2.

### N2. Requirements-quality questions phrased as checklist items · worth taking, narrowly

The "unit tests for English" framing is a clear teaching device and matches checklist-based review.
`qa-static` produces findings, not a reusable checklist. A small addition: an optional `--checklist`
style output that turns the findings into reviewer-owned questions with the same ownership rule
(the reviewer, not the agent, closes an item). This is nice-to-have; findings with testable
rewrites already do the job. **Effort**: S. **Recommendation**: defer; revisit only if a user asks
for a reusable review checklist.

### N3. Coverage table and deterministic IDs · take as a requirement on C3

`analyze`'s coverage table (key, covered, IDs) plus metrics and "re-running produces the same IDs"
is exactly the shape C3 needs. Fold it into C3's design (done above) rather than building it
separately.

### N4. Reviewer-owned status for review artifacts · take as a convention

`checklist` forbids the agent from marking its own items done. `qa-static` already says the human
author or their manager owns status decisions (§3.2.3 roles). Confirm the same wording is present
in `/qa-trace` if C3 is built. No separate work.

---

## Rejected approaches

| Idea | Reason rejected |
| --- | --- |
| Depend on Spec Kit, optionally or otherwise | Requires Python and `uv`; this package requires Node 18 and nothing else. Releases land every one to two days. Plan 014 rejected it and nothing here changes that |
| Hard-code `/speckit-*` command names or `.specify/` file names | Command files themselves use `__SPECKIT_COMMAND_*__` placeholders rendered per agent, so even Spec Kit does not fix a literal name. Detect a spec directory generically |
| Build a Spec Kit extension or preset from Bem-te-vi | Couples distribution to its extension API (`extensions/EXTENSION-API-REFERENCE.md`), which is itself moving; and the package targets seven editors, not one. Revisit only if Spec Kit users ask, and then as a separate artifact |
| Mirror `clarify` (write answers back into the spec) | Mutating the work product contradicts the review model: authors own their documents (CTFL §3.2.3). `/qa-static` reports; the author fixes |
| Mirror `converge` (assess code against spec, append tasks) | That is requirement-to-code, which is `/qa-review` territory and Spec Kit's own domain; Bem-te-vi's value is requirement-to-test |
| Adopt Spec Kit's hook mechanism (`before_*` / `after_*`) | Needs a registry file and a hook executor; this package has hooks of a different kind under `.claude/hooks/` and no need for a second system |
| Migrate this repository's `plans/` to Spec Kit | Unchanged from plan 014: the plans are monograph evidence of what was reproduced, decided and rejected |
| Add a core test-design step to Spec Kit | Out of scope: contributing upstream is a separate decision and not something this package should assume |

---

## Recommendation summary

| Candidate | Verdict | Effort | Order |
| --- | --- | --- | --- |
| C1 review spec first | Already shipped; nothing to build | none | n/a |
| C2 spec directory in `context-discovery.md` | Build; closes a half-shipped item | XS | 1 |
| N1 duplication and out-of-scope in `/qa-static` | Build with C2 | XS | 1 |
| C3 `/qa-trace` | Build after C2 | M | 2 |
| C4a name the constitution parallel | Build as a doc line, optional | XS | 3 |
| C4b project QA-principles file | Defer until a ticket shows the need | M | none |
| N2 checklist output | Defer | S | none |

> **Decided by Marco, 2026-10-20.** C4b and N2 stay deferred until a user asks for them.

## Not verified

- Behaviour of any Spec Kit command was **read, not run**. The installer was not executed, so what
  `specify init` actually writes into a project (and where) was not observed; paths come from
  command text and `README.md`.
- History before 2026-10-06 was not available in the shallow clone, so the interval 09-24 to
  10-06 is compared by state only, not by commit.
- Community extensions and presets (for example the quality-oriented ones named in CHANGELOG) were
  not read; whether any already provides test-case traceability is unknown.
- Whether `/qa-trace`'s inference of links from test titles is reliable enough to ship, rather than
  traced-only, needs a prototype against real test suites.

## Verification

- `npx --yes markdownlint-cli@0.49.1 --dot plans/024-spec-kit-second-look.md` reports no errors.
- Each file path in this plan resolves in this repository; each Spec Kit path resolves at commit
  `03de661789b74405ae93b8b532d52d2cf8af422e`.
- No employer, client or ticket identifiers appear; Spec Kit is described generically wherever it
  would otherwise enter a command or rule.
- For any candidate that is later built: regenerate adapters, `tests/verify-adapters.sh` passes,
  `tests/test-rules-size.sh` passes for rule edits, and nothing may make this package require Spec
  Kit or fail in a repository that has never heard of it.

---

## STOP: Marco decides which candidates to build

Do not start C2, N1, C3 or C4a until Marco names them. Suggested default if he wants one answer:
C2 plus N1 as one small change, then C3 as its own plan (the next free number; 025 is taken by the daily-practice second pass, whose item 7 is real-world evidence for C3), skipping C4b and N2.
