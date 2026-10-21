# Plan 050: Easy to contribute to, easy for an AI agent to read

> **Executor instructions**: Marco asked on 2026-10-18 for all remaining work before the public
> launch. This plan is its own first pull request; the implementation follows on a branch stacked on
> it. One concern per commit. Run every verification command and read its output. If anything in
> "STOP conditions" occurs, stop that item and report it. When done, write the Outcome section and
> update this plan's row in `plans/README.md`.
>
> **Drift check (run first)**: `git diff --stat a32343c..HEAD -- CONTRIBUTING.md CLAUDE.md
> SECURITY.md README.md .github/ tests/test-rules-size.sh package.json`. A change to the merge or
> release text of `CONTRIBUTING.md` (sections 2 and 3) since planning is a STOP: re-read it first.

## Status

- **Priority**: P1 (public launch readiness)
- **Effort**: M
- **Risk**: LOW. Nothing under `.claude/` changes; the one shipped file touched is `README.md`
  (a heading block near the end and one sentence). One new CI step.
- **Depends on**: plan 038 (the citation and id rules the evidence bar points to), plan 021 (the
  rules size cap), plan 020 part B (the public repository every new link names)
- **Category**: docs, with one test and one CI step
- **Planned at**: commit `a32343c` (`github/next`), 2026-10-18
- **Source**: the coordinator's request of 2026-10-18, modelled on A11Y.md (see "The model")
- **Default used (Marco asked for all remaining work on 2026-10-18)**: every decision below that
  is not Marco's to make on GitHub has a stated default; the GitHub settings go to the handover.

## Why this matters

Bem-te-vi goes public with 4.1.0. Today a stranger who wants to help finds a `CONTRIBUTING.md`
written for the maintainer: commit types, the merge-commit rule Release Please depends on, plan
corrections and citation ids. Nothing tells them which contributions help most, what evidence a
claim needs, what will be refused, or how to run the checks CI will run on their pull request.
Section 1 names a Code of Conduct that does not exist. There are no issue forms, so a bug report
arrives without the editor, installer, OS and shell that decide whether it reproduces. There is no
short page saying what is planned, and `plans/README.md` is 40-odd rows of history.

An AI agent asked to use or change the package has the same problem: nothing names the files worth
reading, and the README is 500 lines written for people. Users also cannot see what the package
costs their context window: the README gives the rules' size in kilobytes, which is not the unit
their tools report.

## The model: A11Y.md

The model is A11Y.md (<https://github.com/fecarrico/A11Y.md>, MIT), a Markdown accessibility
standard written for AI coding agents. Its files were read on 2026-10-18 with
`gh api repos/fecarrico/A11Y.md/contents/<path> -H "Accept: application/vnd.github.raw"`. Structure
and ideas are borrowed; every sentence here and in the files this plan adds is written for
Bem-te-vi.

| A11Y.md file | What it does there | What this plan takes |
| --- | --- | --- |
| `CONTRIBUTING.md`, "The three contributions worth the most" | Field report, erratum, gap, each with its issue form | The ranking idea, with this package's four: a wrong CTFL claim, a field report, a worked example, an editor's install path |
| same, "The evidence bar" | Every normative claim cites a WCAG criterion or is labelled house rule; primary sources only | The same shape, pointing at the rules this repository already enforces (plan 038 citations, plan 021 cap, conformance-first installer changes) instead of restating them |
| same, "Mechanics" | Both languages, run the linter, changelog, tools stdlib-only | Fork-and-PR steps and the CI steps by name; no changelog step, because Release Please writes it |
| same, "What will not be merged" | Accessibility theatre, overlays, unverified AI output | A list for this package: untested installer behaviour, broken parity, uncited claims, vendor-specific instructions, unverified AI output |
| same, "Conduct" | Points to the code, adds one project line | Section 1 points to the code and to the private reporting channel |
| `CODE_OF_CONDUCT.md` | Contributor Covenant 2.1 with a project paragraph and an e-mail address | The 2.1 text unchanged, contact through GitHub's private reporting, no e-mail address |
| `.github/ISSUE_TEMPLATE/erratum.yml` | Quote the standard, state reality, give the primary source | The CTFL claim form: file, quoted claim, the section that contradicts it |
| `field-report.yml` | Real project, what happened, artifacts | Same purpose, with this package's install method and editor |
| `proposal.yml` | The gap, why existing guides miss it, evidence it matters | The skill or command proposal: the QA task, why existing skills miss it, evidence |
| `standard-integrity.yml` | Named in the request; **does not exist** (HTTP 404 on 2026-10-18; the folder holds `config.yml`, `erratum.yml`, `field-report.yml`, `gallery.yml`, `proposal.yml`) | Its likely role, the integrity of what is taught, is the CTFL claim form |
| `gallery.yml` | Projects built with the standard | Not taken (see "Rejected approaches") |
| `config.yml` | Contact links: wiki, private security report | Blank issues off; Discussions and the security policy |
| `llms.txt` | H1, summary, sections of raw links, a "Not context" note | Same format, raw links to this repository's `main` |
| `tools/context-cost.py` | Python, exact characters, tokens labelled as an estimate from a fixed divisor | The labelled estimate only, added to the existing bash size test; no Python |

## Current state (at `a32343c`)

- **`CONTRIBUTING.md`** has sections 1 to 6. Other files point into that numbering:
  `CLAUDE.md` ("CONTRIBUTING.md §3 item 6"), `.github/pull_request_template.md`
  (`#2-conventional-commits`), `tests/test-plan-format.sh` ("CONTRIBUTING.md section 5"), and
  `ci.yml`'s merge-commit job ("See CONTRIBUTING.md"). Sections 2 and 3 are load-bearing for
  `verify-merge-commits.sh` and Release Please. **So sections 1 to 6 keep their numbers and text;
  new material goes after them, with a pointer at the top.**
- **Section 1** asks contributors to uphold "our Code of Conduct"; no such file exists.
- **`SECURITY.md`** sends private reports to
  `https://github.com/MarcoAmaral/bem-te-vi/security/advisories/new` and names no e-mail address.
  The handover turns private vulnerability reporting on for the new repository (step 3).
- **`.github/`** holds `pull_request_template.md` and `workflows/`. No issue forms.
- **The PR template** asks that "the resulting `adapters/` diff (if any) is committed", but
  `adapters/` is in `.gitignore` (`# Generated adapters`): there is never a diff to commit. It
  names two checks of the twenty in the Linux job.
- **`README.md`** ends with a five-step "Contributing" section and links no roadmap. Line 98 says
  "about 21 KB of rules load into every conversation".
- **`tests/test-rules-size.sh`** prints bytes per rule and the total (21,855 bytes at planning,
  21,770 characters; cap 25,000 bytes).
- **`package.json` `files`** lists `.claude/` content, `bin/`, `adapters/`, `README.md`,
  `CHANGELOG.md` and two metadata files. `npm pack --dry-run` at planning: 56 files, of which the
  root ones are `.qa-skills-editor-map`, `.qa-skills-known-hashes`, `CHANGELOG.md`, `LICENSE`,
  `README.md`, `package.json`. None of the files this plan adds is in that list, so none ships.

## Steps

### 1. `CODE_OF_CONDUCT.md`

The Contributor Covenant 2.1, from its source
(`EthicalSource/contributor_covenant`, `content/version/2/1/code_of_conduct.md`), without the
site's TOML front matter. The one placeholder, `[INSERT CONTACT METHOD]`, becomes the maintainer's
GitHub profile and the repository's private reporting form, the channel `SECURITY.md` already uses.
The source uses `*` list markers and this repository's markdownlint requires `-` (MD004); the text
stays byte-for-byte and a `markdownlint-disable MD004` comment goes above it.

Verify: `diff` against the source shows only the front matter, the comment and the contact line.

### 2. `CONTRIBUTING.md`

Keep sections 1 to 6 where they are. Changes:

- A short "Start here" paragraph under the title pointing outside contributors to the new sections
  and to `ROADMAP.md`, and saying that sections 2 to 6 govern commits, merges and the release.
- Section 1 links `CODE_OF_CONDUCT.md` and says how to report.
- Section 4 gains "Running the checks locally": every step of the CI Linux job by its name in
  `ci.yml`, with the command, plus the Windows and macOS jobs in one line each.
- New section 7, "The contributions that help most": a wrong or missing CTFL claim with its section;
  a field report from real QA work; a worked example in `examples/`; an editor's install path.
- New section 8, "The evidence bar": syllabus claims cite a CTFL v4.0.1 section with `§` (pointing to
  section 6, not restating it); book citations "section N.N" in words; package practice says it is
  not syllabus content; installer changes start with a failing conformance case and change all three
  installers; content changes keep the rules under the size cap; a field report needs the version,
  editor and the output.
- New section 9, "What will not be merged".
- New section 10, "From fork to pull request": fork, clone, `npm ci`, branch, change, run the checks,
  push, open the PR against `main` with the template; the merge itself follows section 3.

Verify: `grep -n '^## ' CONTRIBUTING.md` shows 1 to 6 unchanged in order, then 7 to 10;
`git diff` shows no line removed from sections 2, 3, 5 and 6.

### 3. Issue forms

`.github/ISSUE_TEMPLATE/`:

- `installer-bug.yml`: editor, installer (`bem-te-vi` CLI, `install.sh`, `install.ps1`, plugin,
  `npx skills`), package version, OS, shell, the exact command, the output, expected result.
- `ctfl-claim.yml`: file, the claim quoted, the CTFL v4.0.1 section that contradicts or supports a
  missing claim, what it should say.
- `field-report.yml`: the project and stack (no confidential detail), editor and install method,
  what worked, what did not, the output if it can be shared.
- `proposal.yml`: the QA task, why the existing skills and commands do not cover it (name the closest
  one), evidence it is needed, CTFL section if any.
- `config.yml`: `blank_issues_enabled: false`; links to Discussions and to the security policy.

Labels the forms apply: `bug`, `documentation`, `enhancement` (GitHub creates these on every new
repository) and `installer`, `ctfl`, `field-report`, `proposal` (created by the handover step).

The PR template: replace the stale `adapters/` item with "`./generate-adapters.sh --clean` and
`./tests/verify-adapters.sh` pass", link section 4's list of checks, and add the evidence-bar items
(citations, failing test first for installer changes). Keep its headings.

Verify: each form parses as YAML (`python3` with PyYAML, which MarcoWork has) and its field ids are
unique. This is a one-off check, not a CI step: GitHub itself reports a form that does not parse.

### 4. `ROADMAP.md`

One page, written by hand from `plans/README.md`: what 4.1.0 ships (from the release notes in the
handover), the work finishing before launch (plans 043 to 046, 049), what is planned next (plan 047,
plan 048, the audit backlog: plugin installs without rules, the git hook's text kept in one source,
the WSL hook gap, the editor paths plan 043 found undocumented, and the deferred plan 024 items), what
is out of scope, and how to propose something. It says `plans/` holds the detailed record. Linked
from the README and from CONTRIBUTING.

### 5. `llms.txt` and its check

At the root, in the llmstxt.org format (H1, blockquote summary, H2 sections of links with a note
each). Links are raw GitHub URLs on `MarcoAmaral/bem-te-vi` `main`: README, the `/qa` router, each
skill's `SKILL.md`, the commands, agents, rules and references, then CONTRIBUTING, CLAUDE.md, the
roadmap and the plans index.

`tests/test-llms-txt.sh` checks that every repository link in `llms.txt` names a path git tracks
(a gitignored file such as `docs/` would 404 on GitHub), that no link points at another branch or
repository, and that every shipped `.md` file under `.claude/` is listed, so a new skill or
reference cannot be missed. A CI step "llms.txt Links Resolve" runs it in the Linux job, shellcheck
first, as the citation step does.

Red first: run the test against an `llms.txt` with one misspelt path and one missing skill, quote
both failures.

### 6. Context cost

`tests/test-rules-size.sh` adds to its total line "about N tokens (estimate: bytes / 4)". Bytes, not
characters, because `wc -c` behaves the same on every platform and `wc -m` depends on the locale;
the rules are almost all ASCII (21,855 bytes, 21,770 characters at planning), so the difference is
under 1%. Four is the usual rule of thumb for English text; a real tokenizer would make the test
depend on one vendor's model. The README sentence on line 98 gains the same figure, labelled as an
estimate.

### 7. The handover and the README

the maintainer's launch checklist (kept outside the repository) gets a step after step 3: turn on
Discussions and create the labels the forms use and `good first issue`'s description, with the exact
`gh` commands, and a pointer to this plan's issue candidates for after step 7.

The README gets one small block under a "Contributing and roadmap" heading, replacing the five-step
"Contributing" section near the end (whose steps CONTRIBUTING now covers), and nothing else besides
the token figure. Plans 048 and 049 edit the README in parallel, near the top.

## "Good first issue" candidates

For Marco to file after launch (handover step 7 is done); this plan files nothing. Each is small,
needs no installer change, and comes with the check that proves it.

> **Decided by Marco, 2026-10-20.** Candidates 1, 3 and 4 stay for newcomers: they are filed as
> good first issues, not done by the maintainer. Candidate 2 is already done (note under Issue 2).

### Issue 1: put the CTFL citation on the line that names CTFL

Source: plan 038's rule that `tests/fixtures/ctfl-uncited-allow.txt` "should only shrink".

```bash
gh issue create -R MarcoAmaral/bem-te-vi --label "good first issue" --label ctfl \
  --title "Put the CTFL citation on the same line for four allow-listed lines" --body-file - <<'EOF'
`tests/fixtures/ctfl-uncited-allow.txt` lists lines that name CTFL without citing a section. Four
of them are there only because the citation sits on the next line or the heading above
(the block "The citation is on the next line of the same sentence"):

- `.claude/commands/qa-cases.md`: "use this format. In CTFL terms a"
- `.claude/skills/qa-reference/references/testing-design.md`: "## Level Tags and CTFL Test Levels",
  "| Level tag | CTFL test level |", "A test type groups test activities by what they evaluate.
  CTFL names four:"

Rewrap or reword each so the `§` citation is on the line that names CTFL, then delete its entry from
the allow-list. Take section numbers only from `tests/fixtures/ctfl-v4.0.1-sections.txt`.

Done when `./tests/test-ctfl-citations.sh` passes with those entries removed and
`./tests/test-rules-size.sh` still passes. See CONTRIBUTING.md sections 6 and 8.
EOF
```

### Issue 2: confirm each editor's documented global rules path

> **Note, 2026-10-19, coordinator.** Done by plan 047 (#193); not to be filed. Plan 047 read each
> editor's current documentation and moved the install paths to what it gives; the candidate is
> kept below as it was written.

Source: plan 043, "Findings outside scope" (installer target paths the editors no longer document).

```bash
gh issue create -R MarcoAmaral/bem-te-vi --label "good first issue" --label installer \
  --title "Confirm the documented global paths for Cursor, Windsurf, Cline and Antigravity" \
  --body-file - <<'EOF'
`bem-te-vi init --global` writes to a fixed path per editor (`.qa-skills-editor-map` at the
repository root). Plan 043 found that some of these paths are no longer in the editors' own
documentation: Cursor global rules, Windsurf global rules, Cline's single `.clinerules` file and
the Antigravity global skill folder.

For each editor, find the current official documentation of where global (user-level) rules or
skills live, and comment here with a table: editor, path the package uses, path the documentation
gives, link, date read. No code change in this issue: the installer change, if one is needed, is a
separate pull request that starts with a failing conformance case (CONTRIBUTING.md section 8).
EOF
```

### Issue 3: a worked example for `/qa-defect`

Source: `examples/README.md` lists no example for `/qa-defect`; the `/qa-automate` example already
holds a real failure to report.

```bash
gh issue create -R MarcoAmaral/bem-te-vi --label "good first issue" --label documentation \
  --title "Add a worked example of /qa-defect for TC-CART-030" --body-file - <<'EOF'
`examples/serverest/qa-automate/` records a real failing test, TC-CART-030, against the public
ServeRest API. There is no example of `/qa-defect` yet.

Run `/qa-defect` on that failure against https://serverest.dev, and commit the output unedited in
`examples/serverest/qa-defect/` with a `README.md` like the other examples: the exact prompt, the
date, the package version, the editor and model, and honest limits (what was wrong, assumed or
only partly done). Add a row to `examples/README.md`.

Done when the report carries the defect's severity and location kept apart from its root cause, as
`/qa-defect` asks, and the README lists anything it got wrong.
EOF
```

### Issue 4: a worked example for `/qa-bdd`

Source: `examples/README.md` lists no example for `/qa-bdd`.

```bash
gh issue create -R MarcoAmaral/bem-te-vi --label "good first issue" --label documentation \
  --title "Add a worked example of /qa-bdd on the ServeRest cart story" --body-file - <<'EOF'
`examples/serverest/qa-agentic/` starts from the story "As a customer, I can't add the same product
to my cart twice". There is no example of `/qa-bdd` yet.

Run `/qa-bdd` on the same story and commit the scenarios unedited in `examples/serverest/qa-bdd/`,
with a `README.md` like the other examples (prompt, date, package version, editor and model, honest
limits). Add a row to `examples/README.md`.

Done when the README compares the scenarios with the agentic example's requirements and says which
requirements no scenario covers.
EOF
```

## Done criteria

- [ ] `CODE_OF_CONDUCT.md` is Contributor Covenant 2.1, verbatim apart from the contact line.
- [ ] `CONTRIBUTING.md` sections 1 to 6 keep their numbers; sections 7 to 10 and the CI step list exist.
- [ ] Four issue forms and `config.yml` parse; blank issues are off.
- [ ] `ROADMAP.md` and `llms.txt` exist, linked from the README block and CONTRIBUTING.
- [ ] `tests/test-llms-txt.sh` was red on a broken `llms.txt` (quoted in the PR), is green, and
      runs in CI.
- [ ] `tests/test-rules-size.sh` prints the token estimate; the README states it.
- [ ] `npm pack --dry-run` lists the same files as at planning.
- [ ] The handover has the GitHub settings step; the issue candidates are in this plan.
- [ ] Local CI (Linux) green.

## STOP conditions

- A change would renumber `CONTRIBUTING.md` sections 1 to 6 or alter the text of sections 2 and 3.
- `npm pack --dry-run` lists a file this plan added.
- The Contributor Covenant text cannot pass markdownlint without editing its words.
- A README edit by plan 048 or 049 conflicts with the block here in a way that is not a plain
  merge: keep theirs, re-add this block, report.

## Rejected approaches

- **Renumbering CONTRIBUTING so the newcomer sections come first.** Four files point at the current
  numbers, two of them at the release rules; a pointer at the top gives the same reading order.
- **A Python context-cost tool like A11Y.md's.** It answers a question this package does not have
  (cost per task type of lazily loaded guides; here only the rules are always loaded) and adds a
  runtime contributors do not otherwise need.
- **A real tokenizer for the estimate.** A dependency, and tied to one vendor's model; the package is
  model-agnostic (`CLAUDE.md`, development convention 1).
- **A gallery form.** There are no outside projects to list yet; a field report already captures use
  on a real project. Revisit when there are some.
- **Shipping `llms.txt` in the npm package.** Its links point at GitHub, and the installed files are
  already on the user's disk; it is for agents reading the repository.
- **Checking only that `llms.txt` links resolve.** A stale index fails silently when a skill is
  added; the reverse check costs a few lines and fails with the line to add.

## Outcome

Implemented 2026-10-18 on `docs/contributing-and-agent-entry-points`, stacked on the plan branch
`docs/plan-050-contributing` (plan PR #185, implementation PR #188).

**Default used (Marco asked for all remaining work on 2026-10-18):** the conduct contact is the
private reporting form `SECURITY.md` already uses, with the maintainer's GitHub profile and no
e-mail address; the token estimate is bytes divided by 4; the GitHub settings and the issue filing
are Marco's (handover step 3a). No STOP condition fired.

- **Drift check**: nothing in the listed files changed between `a32343c` and the branch point.
- **Step 1, `CODE_OF_CONDUCT.md`**: the Contributor Covenant 2.1 source, front matter removed, a
  `markdownlint-disable MD004` comment on the first line. `diff` against the source shows only those
  and the contact sentence: "reported to the community leaders responsible for enforcement at the
  repository's private reporting form, <...security/advisories/new>, which SECURITY.md also uses and
  only you and the maintainer (@MarcoAmaral) can see".
- **Step 2, `CONTRIBUTING.md`**: sections 1 to 6 keep their numbers and text, apart from section 1,
  which now links the code and the reporting form, and section 4, which gains "Running the Checks
  Locally" (all 21 CI Linux steps by name, including the new one, then the macOS and Windows jobs).
  New: a "Start here" paragraph under the title and sections 7 to 10. Headings are in Title Case
  like sections 4 to 6.
- **Step 3, issue forms**: `installer-bug.yml`, `ctfl-claim.yml`, `field-report.yml`,
  `proposal.yml` and `config.yml` (blank issues off; Discussions; the security policy). All five
  parse with PyYAML and have unique field ids. The PR template's stale `adapters/` item now asks
  for `generate-adapters.sh --clean` and `verify-adapters.sh`; two items added (citations, the
  failing test for an installer change), one item links section 4's list.
- **Step 4, `ROADMAP.md`**: as planned. Plans 045, 047, 048 and 049 had no plan file on any branch
  when it was written; their lines use the names the coordinator gave them, and the page says
  `plans/README.md` is right where the two disagree.
- **Step 5, `llms.txt`**: 55 links (README, router, 8 skills, 10 commands, 4 agents, 9 rules, 15
  references, CONTRIBUTING, CLAUDE.md, ROADMAP, plans index, examples, changelog, security policy).
  `tests/test-llms-txt.sh` and the CI step "llms.txt Links Resolve". Red first, on the committed
  test before `llms.txt` existed, then on a copy with a misspelt path, a deleted skill line and a
  link to an untracked path:

  ```text
    ✘ no llms.txt at <repository>/.claude/worktrees/plan-050-impl
    ✘ no tracked file at .claude/skills/qa-flakey/SKILL.md (https://raw.githubusercontent.com/MarcoAmaral/bem-te-vi/main/.claude/skills/qa-flakey/SKILL.md)
    ✘ no tracked file at docs/notes.md (https://raw.githubusercontent.com/MarcoAmaral/bem-te-vi/main/docs/notes.md)
    ✘ .claude/skills/qa-flaky/SKILL.md ships but llms.txt does not link it; add: - [name](https://raw.githubusercontent.com/MarcoAmaral/bem-te-vi/main/.claude/skills/qa-flaky/SKILL.md): what it is for
    ✘ .claude/skills/qa-release/SKILL.md ships but llms.txt does not link it; add: - [name](https://raw.githubusercontent.com/MarcoAmaral/bem-te-vi/main/.claude/skills/qa-release/SKILL.md): what it is for
    ✘ not a link to this repository on main: https://example.com/SECURITY.md
  ```

  Green: "All 55 llms.txt links name tracked files, and all 47 shipped .md files are linked", also
  under bash 3.2.57 and on a `git archive` copy outside git (the on-disk fallback).
  **For later plans**: a new shipped `.md` file under `.claude/` now needs a line in `llms.txt`;
  the check names the line to add.
- **Step 6, context cost**: `tests/test-rules-size.sh` now ends "about 5464 tokens of context in
  every conversation (an estimate: bytes / 4)"; README line 98 says "roughly 5,500 tokens (an
  estimate: bytes divided by 4 ...)".
- **Step 7**: handover step 3a written (Discussions, four labels, the `good first issue`
  description, and filing this plan's four issues after step 7). The README's five-step
  "Contributing" section became "Contributing and Roadmap", five links; nothing else in the README
  changed besides the token sentence.
- **`npm pack --dry-run`**: 56 files, the same root files as at planning; nothing added here ships.
- **Not run**: the Windows and macOS jobs (nothing here runs on them; the CI change adds a Linux
  step only). `~/qa-ci-local.sh` in MarcoWork does not know the new step, so it was run by hand.
