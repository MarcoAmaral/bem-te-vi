# Plan 014: Production readiness, content gaps, and the road after 2.7.0

> **Executor instructions**: This is a sequencing plan, not an implementation plan. Each phase
> below becomes its own numbered plan when it is picked up. Do not implement directly from this
> document. Reproduce a defect before writing it down, and record rejected approaches with the
> reason.

## Status

- **Priority**: P1
- **Effort**: XL (spans several releases)
- **Depends on**: PRs #69, #70, #71 landing and 2.7.0 shipping
- **Planned at**: 2026-09-24

## Why this exists

Three things changed at once and together they raise the bar:

1. **It gets real use.** The package will be used at Swareco. "Works on my machine" stops being
   acceptable; the failure mode is now someone else's repository.
2. **It is monograph evidence.** The history must stay auditable and every claim traceable to a
   source.
3. **It becomes a RAG corpus.** The content will be indexed and retrieved to learn from. That
   makes *retrievability and citation* a functional requirement of the content, not a nicety.

Requirements 2 and 3 pull in the same direction — both want provenance. Requirement 1 wants
something different: fewer ways for three installers to disagree.

---

## Phase A — Stability (before Swareco use)

### A1. The recurring defect class is installer divergence

Every plan from 009 through 013 found at least one behaviour present in one installer and absent
from another. A partial list, all real and all found late:

| Found in | Divergence |
| --- | --- |
| 010 | `install.ps1` path joined a subfolder-relative path onto `.claude/`; counter never incremented |
| 012 | `bin/cli.js` crashed on a read-only file, leaving 10 of 22 files installed |
| PR #63 | `install.ps1` ignores scope for `copilot`/`cline`, writing project paths into the home directory |
| 2.6.1 | All three uninstallers accepted manifest paths that escaped the install tree |
| 013 | `update`'s removal path repeated the same traversal bug the uninstaller had just fixed |

The pattern is not carelessness. It is that **`tests/test-lifecycle.sh` and
`tests/test-lifecycle.ps1` are two independently written suites, not one contract applied to three
implementations.** A test added to one is not automatically required of the others, so parity is
maintained by memory.

**The work**: a declarative conformance suite. One list of cases — preconditions, command,
expected filesystem state and expected report — executed against all three installers by a thin
per-platform runner. A new guarantee is then written once and is automatically required of every
implementation. The existing suites stay for implementation-specific behaviour (interactive menu,
PowerShell parsing) that has no cross-platform equivalent.

This is the single highest-value stability item and should be its own plan.

### A2. Close the known divergence

`install.ps1` ignoring scope for `copilot` and `cline` is a live bug: a global install writes the
project-scope path into the user's home directory. Fix it, plus the `Cursor` / `Cursor / Trae`
message inconsistency beside it. Already in the backlog; promote it to a numbered plan and do it
inside Phase A, ideally as the first case expressed in the A1 conformance suite.

> **Status, 2026-10-02 — fixed in #78**, without a numbered plan of its own: once reproduced it
> was a four-line change. Reproduced red on real Windows (PowerShell 5.1 via WSL interop) — a
> global `copilot` install wrote `mock-home\.github\copilot-instructions.md`. Global installs now
> warn and skip, as the other two installers do; uninstall still removes the debris older
> versions left in the home directory, reporting only when it finds some. Tests: PowerShell 37-38,
> bash 38. It was not written as an A1 conformance case because A1 does not exist yet; plan 016
> takes it as its first.

### A3. Execute the WSL Windows-profile path

Plan 010 item 7 fixed the manifest path recorded when installing from WSL into the Windows user
profile, but that fix was verified by reading it against `install.ps1` and by a guard test on
`install_file`. Real `wslpath` behaviour, a real `$WIN_HOME`, and the antigravity global target on
that path have **never been executed**. A WSL distribution is now available. Run it end to end
before trusting it — this is a one-session task with a written result, not a refactor.

> **Result, 2026-10-01 — executed; the file contract holds, one gap found.** The path resolves
> `%USERPROFILE%` through `cmd.exe` and `wslpath`; forwarding a sandboxed `USERPROFILE` through
> `WSLENV` ran that real code path against `C:\temp\…` instead of the real profile, with the
> Linux `HOME` sandboxed too.
>
> - Files landed at the editor map's global paths (`.cursor/rules/qa.mdc`,
>   `.windsurf/rules/qa.md`, `.gemini/antigravity/skills/qa/SKILL.md`, 23 Claude files); copilot
>   and cline were skipped.
> - The manifest: 26 entries, no BOM, LF endings, forward slashes, **no absolute paths** — the
>   antigravity entry is relative, so plan 010 item 7's fix is now confirmed by execution.
> - Every recorded hash matches its file.
> - **Cross-installer round trip:** `install.ps1 -Uninstall -Target global` on Windows read the
>   manifest `install.sh` wrote over DrvFs and removed all 26 files, exit 0. Uninstalling through
>   the WSL path itself removed 52 (26 per side).
> - **Gap:** the hook. Global hook registration uses the Linux `$HOME`, never the base directory,
>   so the Windows profile receives `validate-tc-format.sh` but Windows-side git is never told to
>   run it. Nothing is destroyed; a user just believes they are covered when they are not. Two
>   ways to close it — configure Windows git from WSL through `git.exe` (invasive), or print a note
>   after a Windows-side install pointing at `install.ps1` (minimal). Left as a decision; the README
>   documents the gap meanwhile (#79).
>
> **Decision, 2026-10-20 (Marco): the note, not `git.exe`.** `install.sh` does not configure
> Windows-side git. When it installs into the Windows user profile (the WSL step, after the
> answer "y" to "Also install to Windows-side user profile?") and that install sets up the global
> pre-commit hook (Claude Code, without `--no-hooks`), it prints once, after "Windows-side
> installation complete":
>
> ```text
>   ⚠ The pre-commit hook is not active for Windows-side git.
>       To set it up there, run install.ps1 from Windows PowerShell.
> ```
>
> Lifecycle Test 68 checks it with `cmd.exe` and `wslpath` stand-ins, as Test 65 does: the note
> once for a Windows-side install with the hook, never with `--no-hooks` or without the Windows
> side. Like Test 65, it skips outside WSL, because `install.sh` offers the Windows side only when
> `/proc/version` names Microsoft. The README's text on the gap says the same. Rejected:
> configuring Windows git from WSL through `git.exe`, as too invasive (it would change a
> `git config --global` the user never pointed this installer at).

### A4. Write down the rollback story

If a release misbehaves in a Swareco repository, the recovery path is currently undocumented.
It exists — `uninstall` removes only unmodified files, backups are timestamped and never deleted,
and `npm install @marcoamaral/qa-skills@<older>` then `qa-skills update` restores an older set —
but nobody can follow it from the README. Document it, then *test it*: install, update, roll back,
confirm the tree matches the older release byte for byte.

> **Result, 2026-10-01 — tested; the procedure above was incomplete.** Rolled a project back from
> 2.6.0 to 2.5.0, which differ by seven changed files and one added (`context-discovery.md`),
> through both `install.sh` and the npm CLI with all six editors' adapters:
>
> - **Uninstall with the current version, then install the older one** — byte-identical to a
>   fresh 2.5.0 install, 28 files including the manifest.
> - **Install the older version straight over** — *not* a rollback. The seven files revert and no
>   spurious backups appear, but `context-discovery.md` stays, still recorded in the manifest,
>   because 2.5.0 does not know it exists. Rules load automatically, so the assistant would run a
>   mix of both releases.
>
> `qa-skills update` from an older version should also work once both versions are 2.7.0 or later,
> since plan 013 made it remove unmodified files the package no longer ships; no such pair of
> releases exists yet, so that is expected, not verified. Documented in the README (#79).
>
> **Result, 2026-10-18 — the update between two real releases verified, for `install.sh` (plan 045
> item 9).** Release 4.0.1, installed by its own `install.sh` for all six editors in both scopes,
> then `install.sh --update` from the tree on its way to the next release: 84 files refreshed and
> 142 added (plan 043's reference files beside each adapter among them), none removed (4.0.1 shipped
> nothing the tree has dropped), no spurious backup, no file kept; both manifests and both trees are
> identical to a fresh install of the current tree, and uninstall afterwards leaves nothing.
> Lifecycle Test 54 now runs this on every build, from a fixture holding 4.0.1's exact files
> (`tests/fixtures/release-v4.0.1/`), so it needs no tag. Not covered: the npm CLI's `update` (Test
> 54 runs `install.sh` only) and a pair where the newer release stops shipping a file (Test 34 and
> conformance cases 016-017 cover that path with made-up files).
>
> **Result, 2026-10-19: the npm CLI's `update` over a real release's Claude Code install
> verified.** Release 4.0.1, installed for Claude Code in both scopes by its own `install.sh`, then
> `node cli/bem-te-vi.js update --editor claude` in the project and `update --global --editor
> claude` in the home, from the tree at `4c89f46`: in each scope 38 files refreshed and 14 added, no
> backup, no file kept; both manifests (sorted) and both trees are identical to a fresh install by
> the current CLI, and the CLI's `uninstall` in each scope afterwards leaves nothing. Lifecycle Test
> 67 runs this on every build from the same fixture. Plan 047's Test 63 already ran the CLI over
> 4.0.1 for the five other editors, so with Test 54 every editor's update from a real release now
> runs through both `install.sh` and the CLI.
>
> - **The test can fail.** Run alone against three broken copies of the CLI it is red: an update
>   that trusts neither the manifest's recorded hash nor the known-hash list backs up every 4.0.1
>   file ("kept or backed up files it should have replaced"); a `--global` update that writes to
>   the project leaves the home's 4.0.1 install as it was ("the home manifest after the CLI's
>   update differs"); an update that installs no file the install predates misses the 14 new files
>   ("the project manifest ... differs"). A copy whose update ignores only the known-hash list
>   stays green, which is correct: every 4.0.1 file's hash is in the 4.0.1 manifest, so the
>   recorded hash proves it; the known-hash list is for installs with no manifest (Tests 20, 35).
> - **A user's edit to a file 4.0.1 installed** is not repeated here. Every Claude Code file 4.0.1
>   shipped is still shipped, so the CLI's update backs the edit up and installs the current file,
>   as for any older release's file; Test 33 checks exactly that through the CLI, and conformance
>   case 004 that uninstall keeps the edit and its backup.
> - Still not covered: a pair of real releases where the newer one stops shipping a Claude Code
>   file, since no such pair exists yet.

---

## Phase B — Content gaps against ISTQB CTFL v4.0

The package claims CTFL v4.0 alignment in 16 places across shipped content. Two chapters are not
honestly covered.

> **Correction, 2026-10-01.** B1 and B2 below were measured by grepping for literal phrases
> ("static test", "risk-based"), which overstated both gaps; each now carries a re-measured note.
> Checking every row of the README's coverage table the same way found four topics it claimed
> but the package does not cover — QA vs QC, error → defect → failure, inspections, and tool
> categories. The README now separates covered from not yet covered (#79).

### B1. Chapter 3, Static Testing — ~~absent entirely~~ the review process is missing

> **Correction, 2026-10-01: "absent entirely" was wrong.** Code review and static analysis are
> covered (`qa-review.md`, the `qa-engineer` agent, `qa.md`), and testability and ambiguity checks
> on requirements already exist in `qa-refinement.md`, `qa-cases.md` and the `qa-groomer` agent.
> What is genuinely missing is the ISTQB **review process** — review types (informal review,
> walkthrough, technical review, inspection), roles, and the activities of a review — and any
> command dedicated to reviewing a work product as a whole. The work below stands; its
> justification is narrower than first written.

Verified: `grep -ril "static test"` across `.claude/commands`, `rules`, `skills` and `agents`
returns nothing. `qa-review.md` is code review of a branch; `qa-refinement.md` is PM advisory.
Neither is static testing in the syllabus sense — reviews and static analysis applied to work
products *before* execution, and the review process, roles and techniques that go with it.

This is the largest single gap between what the package claims and what it ships, and it is also
the highest-value addition for real use: finding an untestable acceptance criterion during
refinement is cheaper than finding it in a failing pipeline.

**The work**: a `/qa-static` (or `/qa-spec-review`) command applying ISTQB static testing to any
work product — a ticket, a specification, an ADR, an OpenAPI schema. Output: acceptance criteria
that cannot be tested as written, ambiguity, missing negative and boundary cases, states with no
defined transition, and contradictions against what the code already does. This works on a plain
Jira ticket and needs no Spec Kit, which is why it comes before anything in Phase C.

### B2. Chapter 5, Managing the Test Activities — ~~thin~~ concentrated in one skill

> **Correction, 2026-10-01: the table below is a phrase-grep artifact.** `skills/qa-plan` has a
> 5×5 likelihood × impact risk register whose score bands drive test prioritisation — risk-based
> testing in substance, never named as such — plus entry and exit criteria and metrics.
> `qa-refinement.md` touches estimation. What is genuinely absent: test estimation *techniques*,
> test monitoring and control, and configuration management. B2 is smaller than first written, and
> partly a matter of surfacing what `qa-plan` already does.

Measured coverage across shipped content:

| Topic | Files mentioning it |
| --- | --- |
| Risk-based testing / risk prioritisation | 0 |
| Test estimation | 0 |
| Test monitoring and control | 0 |
| Configuration management | 0 |
| Entry / exit criteria | 1 |
| Defect reporting | 3 |

The package is strong on Chapter 4 (test design techniques) and weak on deciding *what to test
first and when to stop*. For a QA analyst at a company, that is the daily question. Risk-based
prioritisation in particular is what turns the existing technique catalogue into a plan.

**The work**: extend `testing-guidelines.md` with risk-based prioritisation (likelihood × impact
driving depth and technique choice), and give `/qa-refinement` or a new command the estimation and
exit-criteria conversation. Scope this against the real syllabus, not from memory.

### B3. Verify before extending

Before B1 and B2 are written, confirm the chapter structure and terminology against the actual
CTFL v4.0 syllabus (document v4.0.1 — there is no v4.2; this was checked on 2026-09-22). The
package's credibility as monograph evidence depends on the citations being right.

---

## Phase C — Spec Kit

### What it is, as of 2026-09-24

<https://github.com/github/spec-kit> — a toolkit for spec-driven development. Three workflows:
SDD (`/speckit-constitution` → `specify` → `plan` → `tasks` → `implement` → `converge`), bug fixing
(`bug-assess` → `bug-fix` → `bug-test`), and idea assessment (`assess-intake` → `research` →
`define` → `shape` → `decide`). Artifacts live under `.specify/`, including `.specify/memory/`,
`.specify/bugs/{slug}/` and `.specify/assessments/{slug}/`. Installed with
`uv tool install specify-cli`, then `specify init <project> --integration <agent>`.

### The finding that should govern the integration

**Spec Kit moved between 2026-09-21 and 2026-09-24.** Three days. The commands were documented as
`/speckit.constitution` (dot-separated) and are now `/speckit-constitution` (hyphenated), and two
whole workflows — bug fixing and assessment — appeared that were not there before.

That is not a criticism of Spec Kit; it is young and moving fast, which is normal. It is a hard
constraint on how this package may depend on it: **any integration that hard-codes a command name
or a path under `.specify/` will break, and will break silently in someone else's repository.**

### What to take, in value order

1. **Nothing structural. Take the idea, not the interface.** The valuable insight is that a spec
   is a first-class artifact worth reviewing before code exists. That insight is already actioned
   by **B1**, which needs no Spec Kit at all and works for the majority of repositories that will
   never adopt it. Do B1 first and independently.

2. **Detection, not integration.** Add `.specify/` to the tier-3 "declared intent" list in
   `.claude/rules/context-discovery.md`, using the detect-and-respect idiom already established in
   `.claude/rules/linting-standards.md`: *if a spec directory exists, read it as the authoritative
   requirements source instead of re-deriving requirements from the ticket; if it does not, carry
   on*. Describe it as "a spec directory such as `.specify/`", so the rule survives a rename.
   Small, safe, degrades to nothing.

3. **A traceability command** — requirement → test case → result. This is genuinely useful and is
   the one place a spec's structure helps, because requirements already carry stable identifiers.
   But it is also the piece most coupled to a layout that has proven unstable, so it comes last
   and must degrade to reading whatever requirements source exists.

4. **The constitution concept is worth borrowing conceptually.** Spec Kit's constitution is
   project principles an agent must honour. This package already ships the QA equivalent —
   `testing-guidelines.md`, `code-style-qa.md`, `security-qa.md`. Nothing to build; worth naming
   the parallel in the monograph.

### Explicitly rejected

- **Do not migrate this repository's `plans/` to Spec Kit.** Fourteen plans are working, are
  monograph evidence, and their value is that they record what was reproduced, decided and
  rejected. Converting them would destroy exactly the audit trail the monograph depends on.
- **Do not make Spec Kit a dependency**, optional or otherwise. It requires Python and `uv`; this
  package requires Node ≥18 and nothing else.

---

## Phase D — RAG and monograph readiness

This phase exists because the content will be indexed and retrieved. Two measured problems.

### D1. Claims are not traceable to a source

"CTFL v4.0" appears 16 times across shipped content. **Section and chapter citations: zero.** A
retrieved chunk asserting "exhaustive testing is impossible" cannot be traced back to the syllabus
clause it came from, so neither a reader of the monograph nor a RAG answer can verify it.

**The work**: cite the syllabus section beside each claim that comes from it. This is also what
makes the package defensible as monograph evidence rather than assertion.

### D2. The content has no retrieval metadata

Structure as it stands: 2,032 lines of commands, 671 of rules, 244 of agents, 177 of skills.
`.claude/agents/*.md` carry YAML frontmatter (`name`, `description`, `model`). **`rules/` and
`commands/` carry none** — they open straight into an H1 and a blockquote.

For retrieval that means no stable chunk identity, no topic filter, no version, and no way to tell
a retrieved fragment of `security-qa.md` from one of `testing-guidelines.md` without reading it.

**The work**: add frontmatter to rules and commands — a stable `id`, `title`, `istqb` chapter
references, and the package `version` a chunk came from. Headings then give natural chunk
boundaries with `id` + heading as a citable anchor. This costs little, breaks nothing (frontmatter
is already the norm for `agents/`), and is what makes the corpus queryable.

**Design constraint**: whatever is added must survive `generate-adapters.sh`, which compiles these
sources into seven editor formats each with its own frontmatter rules. Verify against
`tests/verify-adapters.sh` — the Cursor `.mdc` and Antigravity `SKILL.md` formats are the
constrained ones.

### D3. Decide what the RAG corpus actually is

Worth settling before building: is the corpus the *shipped rules* (what the package teaches), the
*plans and PRs* (how it was built — the monograph's real subject), or both? They need different
chunking and different metadata. This is a decision, not an implementation, and it should be made
before D2 fixes a schema in place.

---

## Release pipeline — a finding added 2026-10-02

Not one of the original phases, but a stability finding of the same kind. 2.7.0 shipped only
after its changelog was written by hand, because `dedupe-changelog.sh` stripped every
merge-commit entry and 2.7.0's only entries were merge commits; 2.7.1 hit the same wall.

**Root cause:** release-please (`src/manifest.ts`) walks history newest-first and stops at the
previous release commit. A pull request whose commits are dated before that release was merged is
never visited — only its merge commit is. Simulating that walk over this repository reproduces
2.6.1, 2.7.0 and 2.7.1 exactly. So the PR title in the merge commit body is the one record always
seen, and the empty-body merges proposed in #75 would have hidden 2.7.0 and 2.7.1 entirely. #75
was closed unmerged; #80 keeps a merge entry unless its PR's own commits are listed beside it, and
fails CI when a PR is merged without a conventional title.

## Sequencing

| Order | Phase | Rationale |
| --- | --- | --- |
| 1 | Ship 2.7.0 (#69, #70, #71 + docs) | Clears the board; everything below builds on it |
| 2 | A2, A3 | Small, known, and A2 is the first case for A1 |
| 3 | A1 | The conformance suite — highest stability value |
| 4 | B1 | Largest content gap; independent of everything else |
| 5 | D3, then D2 | Decide the corpus before fixing a metadata schema |
| 6 | A4, B2 | Rollback story and Chapter 5 depth |
| 7 | C2, D1 | Spec detection; syllabus citations |
| 8 | C3 | Traceability, last — most coupled to an unstable layout |

Phase A gates Swareco use. Phases B and D are what make it worth using and worth citing.

### Progress, 2026-10-02

| Item | State |
| --- | --- |
| Ship 2.7.0 | Released 2026-09-30, with a hand-written changelog |
| A2 | Fixed — #78 |
| A3 | Executed — file contract confirmed, one hook gap recorded above |
| A4 | Tested and documented — #79 |
| Release pipeline | Root-caused — #80 |
| A1 | Planned in plan 016 |
| B1, B2 | Corrected scope above; not started |
| C, D | Not started; D3 needs a decision |

### Progress, 2026-10-19

Added by the coordinator from each later plan's own record; the table above is kept as it was
written. Every phase was picked up by its own plan or pull request. Two items are still open, and
neither is a phase of work for this plan: A3's hook gap, a decision for Marco, and one A4 test gap.

> **Correction, 2026-10-19.** The A4 test gap is closed by lifecycle Test 67 (the CLI's `update`
> over release 4.0.1's Claude Code install); A3's hook gap is the one item still open.
>
> **Correction, 2026-10-20.** A3's hook gap is closed too: Marco chose the note over configuring
> Windows-side git (see the 2026-10-20 decision under A3). Nothing in this plan is open.

| Item | State |
| --- | --- |
| A1 | Done by plan 016 (#82; item 6 #89, #93): one conformance suite run against all three installers |
| A2 | Fixed, #78 |
| A3 | Executed. ~~**Open:** the hook gap it found, a decision for Marco (configure Windows-side git from WSL, or print a note after a Windows-side install). Listed in `ROADMAP.md` as "The WSL hook gap"; the README documents the gap~~ Decided by Marco on 2026-10-20: the note. A Windows-side install from WSL that sets up the hook says it is not active for Windows-side git and that `install.ps1` sets it up there; lifecycle Test 68 (see the 2026-10-20 decision under A3) |
| A4 | Tested and documented, #79. The update between two real releases is verified for `install.sh` (plan 045 item 9, lifecycle Test 54); plan 047's lifecycle Test 63 updates a 4.0.1 install of each non-Claude editor with `install.sh` and with the CLI, files the current tree no longer ships included (#193). ~~**Open:** the CLI's `update` over a real release's Claude Code install has not run. Recorded here only; no plan carries it~~ Closed later on 2026-10-19: lifecycle Test 67 runs it (see the 2026-10-19 result under A4) |
| Release pipeline | Root-caused and fixed, #80 |
| B1 | `/qa-static`, #87 |
| B2 | #94, #95. Estimation techniques, monitoring and control, and configuration management are in the `qa-reference` skill's `references/test-planning.md` and `references/test-reporting.md` |
| B3 | Done by plan 038: section numbers come only from `tests/fixtures/ctfl-v4.0.1-sections.txt`, read from the official v4.0.1 PDF |
| C1 | Nothing to build, as written |
| C2, C3 | Done by plan 024 (#116): spec detection in `context-discovery.md`, and `/qa-trace` |
| C4 | Plan 024: C4a done (#116); C4b deferred, listed in `ROADMAP.md` |
| D1, D2 | Done by plan 038 (#173): every syllabus claim cites a section; every shipped file has a permanent `id`, and `generate-corpus.js` derives the title, version and sections |
| D3 | Decided by Marco on 2026-10-14 (plan 038): the corpus is both the shipped content and the build record |

## Verification

Each phase's own plan carries its verification. Two hold across all of them:

- Nothing in Phase D may change what the adapters compile to without `tests/verify-adapters.sh`
  proving the seven outputs are still correct.
- Nothing in Phase C may make this package require Spec Kit, or fail in a repository that has
  never heard of it.
