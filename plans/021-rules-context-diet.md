# Plan 021: A context diet for the always-loaded rules

> **Executor instructions**: This is a plan only. **STOP: needs Marco's approval before
> implementation.** It changes what every installed project loads into every conversation, so it
> ships as its own reviewed plan (plan 019 phase 9). Do not edit any shipped file until Marco
> approves; then follow the Items in order, one pull request per item.

## Status

- **Priority**: P1
- **Effort**: M
- **Depends on**: plan 020 (the Bem-te-vi rename merged first, so the moved text is not renamed twice);
  plan 019 phase 3 (skill frontmatter)
- **Planned at**: 2026-10-08, against `main` at v2.9.0

## Why this matters

Claude Code loads every file in `.claude/rules/` that has no `paths:` frontmatter **at launch, in
every conversation**, "with the same priority as `.claude/CLAUDE.md`" (see "How rules load today").
Bem-te-vi installs nine such files. A developer who asks an unrelated question in an installed
project still pays for all of them, and cost-aware teams notice this first. Competitors advertise
the opposite: a lean `SKILL.md` with heavy references read on demand.

Plan 019 estimated "8 files, ~38 KB". That figure is stale: `test-evidence.md` and `test-tools.md`
have been added since. Measured on 2026-10-08:

### Measurements

Method: `wc -c` (bytes), `wc -m` (characters), `wc -w` (words). No offline tokenizer is available
(`tiktoken` is not installed and the sandbox has no network install), so tokens are an
**estimate with a range**: the upper figure is bytes / 4, the lower is words x 1.3. Markdown
with code fences, tables and emoji headings sits closer to the upper figure. Treat the numbers as
accurate to roughly 15 percent; the plan's targets are expressed in bytes so they can be checked
exactly. If a real tokenizer is wanted, Item 0 measures with the same one before and after.

| File | Bytes | Words | Tokens (words x 1.3) | Tokens (bytes / 4) |
| --- | --- | --- | --- | --- |
| `testing-guidelines.md` | 11,383 | 1,678 | 2,181 | 2,845 |
| `test-tools.md` | 5,921 | 820 | 1,066 | 1,480 |
| `code-style-qa.md` | 5,787 | 833 | 1,082 | 1,446 |
| `security-qa.md` | 5,579 | 722 | 938 | 1,394 |
| `test-evidence.md` | 5,400 | 834 | 1,084 | 1,350 |
| `context-discovery.md` | 5,101 | 787 | 1,023 | 1,275 |
| `accessibility-qa.md` | 5,040 | 697 | 906 | 1,260 |
| `conventional-commits.md` | 2,482 | 371 | 482 | 620 |
| `linting-standards.md` | 1,833 | 275 | 357 | 458 |
| **All nine rules** | **48,526** | **7,017** | **~9,100** | **~12,100** |

The merged adapters for the other editors (after `./generate-adapters.sh`):

| Adapter | Bytes | Words | Tokens (words x 1.3) | Tokens (bytes / 4) |
| --- | --- | --- | --- | --- |
| `windsurf/qa.md`, `copilot/copilot-instructions.md`, `cline/.clinerules` | 180,188 | 24,188 | ~31,400 | ~45,000 |
| `cursor/qa.mdc` | 180,372 | 24,215 | ~31,500 | ~45,100 |
| `antigravity/qa/SKILL.md` | 180,361 | 24,215 | ~31,500 | ~45,100 |
| `universal/AGENTS.md`, `universal/CLAUDE.md` | 180,767 | 24,251 | ~31,500 | ~45,200 |

The rules are 48.5 KB of that 180 KB (27 percent); the rest is commands, skills and agents.

Where the bytes sit, by section (the movable part is the largest):

| Section | Bytes |
| --- | --- |
| `testing-guidelines`: principles 1,155; defect chain 1,688; strategic alignment 659; pyramid 1,706; techniques 1,143; field heuristics 891; tagging 1,851; CI/CD syntax 573; flaky protocol 629; DoD 734 | 11,383 |
| `accessibility-qa`: WCAG criteria 2,433; Playwright/axe template 1,172; manual checklist 1,005 | 5,040 |
| `security-qa`: OWASP verification 1,984; scanning plus XSS payload spec 1,986; manual checklist 1,180 | 5,579 |
| `code-style-qa`: patterns 961; locators 682; anti-patterns 677; assertion examples 870; git standards 2,286 | 5,787 |
| `test-evidence`: screenshots 1,255; visible actions 628; recordings 1,391; ASCII names 443; checker 680 | 5,400 |
| `test-tools`: categories 2,298; benefits 852; risks 922; applying 1,437 | 5,921 |

## How rules load today

Findings from the vendors' documentation, checked 2026-10-08.

**Claude Code** (<https://code.claude.com/docs/en/memory>, section "Organize rules with
`.claude/rules/`"):

- "Rules without `paths` frontmatter are loaded at launch with the same priority as
  `.claude/CLAUDE.md`." Rules without a `paths` field "are loaded unconditionally and apply to all
  files."
- **Path-scoped rules exist.** A rule with `paths:` frontmatter (a YAML list or comma-separated
  string of globs, with brace expansion) "loads when Claude uses the Read, Write, or Edit tool on a
  matching file", and also when Claude views one matching file with a Bash command that counts as a
  read, such as `cat` or `head`. They load again on demand after `/compact`.
- The same page recommends keeping instructions that "only matter for one part of the codebase" in
  path-scoped rules or a skill, and warns that files over 200 lines "consume more context and may
  reduce adherence" (that guidance is written for `CLAUDE.md`, but rules carry the same priority).
- The `InstructionsLoaded` hook can log which rules load, when and why. That is the tool for
  verifying this plan.

**Skills** (<https://code.claude.com/docs/en/skills>): a skill's description is always in context
(capped at 1,536 characters); the body "loads only when it's used, so long reference material costs
almost nothing until you need it". Supporting files in the skill directory "load on-demand when
Claude follows your references" from `SKILL.md`. `SKILL.md` should stay under 500 lines. Skills
accept the same `paths:` field to load only for matching files.

**The other editors** (the adapters are one merged file each; see `generate-adapters.sh`, which
strips frontmatter, concatenates commands, rules, skills and agents, and prepends a per-editor
header):

| Editor | Activation modes and limits | Source |
| --- | --- | --- |
| Cursor | Always Apply, Apply Intelligently (by description), Apply to Specific Files (`globs`), Apply Manually. Recommends rules under 500 lines. Our `qa.mdc` already sets `alwaysApply: false`. | <https://cursor.com/docs/context/rules> |
| Windsurf (now under Devin docs) | Always On, Model Decision, Glob, Manual. Workspace rules "limited to 12,000 characters per file". | <https://docs.devin.ai/desktop/cascade/memories> |
| GitHub Copilot | One repository-wide `copilot-instructions.md`, plus `.instructions.md` files with path frontmatter. Repository-wide instructions "must be no longer than 2 pages". | <https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions> |
| Cline | `.clinerules/` folder; conditional rules with `paths:` frontmatter. "Rules consume context tokens... keep rules concise." | <https://docs.cline.bot/features/cline-rules> |

Two consequences. First, only Claude Code has the split we need (always-on rules versus on-demand
skill references) in a form the installers already deliver. Second, **the merged adapters already
break two documented limits**: `windsurf/qa.md` is 180 KB against a 12,000-character per-file
limit, and `copilot-instructions.md` is 180 KB against a two-page guideline. That is a separate
defect, recorded here because the diet interacts with it (see "Other editors"); this plan does not
fix it.

## The proposal

Split each heavy rule into a short **core** that stays in `.claude/rules/` (the must-lists, the
things that apply even to a conversation that is not about writing tests) and a **reference** that
moves out of auto-loading and is read only when the work needs it.

### Where the references live

A new skill, `.claude/skills/qa-reference/`, with a `SKILL.md` that is a table of contents (what
each reference holds and when to read it) and a `references/` folder:

```text
.claude/skills/qa-reference/
├── SKILL.md                        # contents and "read when" lines, under 60 lines
└── references/
    ├── testing-design.md           # pyramid, techniques table, field heuristics, CI/CD syntax
    ├── automation-code.md          # POM detail, assertion examples, git/pre-push detail
    ├── accessibility-checks.md     # axe template, manual a11y checklist
    ├── security-checks.md          # XSS payload spec, scanning, manual security checklist
    ├── evidence-capture.md         # screenshot, recording and pacing detail, checker usage
    └── test-tools.md               # categories, benefits, risks, how to recommend a tool
```

Why a skill and not a new top-level directory: skills are already an installed subdirectory
(`SUBDIRS` in `bin/cli.js`, the scaffold loop in `install.sh`, and `install.ps1`), so, if they copy nested folders (to be confirmed in Verification), no installer
change is needed to deliver, record in the manifest, back up and uninstall the files. The commands
and agents that need a reference already name rules by path (`/qa-automate` names
`test-evidence.md` and `code-style-qa.md`; `qa-designer` pulls the technique definitions); those
pointers are repointed to the reference file. The skill's description lets Claude pull a
reference on its own when a conversation turns to writing a Playwright spec, an axe check or a
tool recommendation.

> **Checked 2026-10-08, after this plan was written:** `install.sh` and `bin/cli.js` both copy a
> nested `.claude/skills/<skill>/references/` folder and record its files in `.qa-skills-manifest`
> (a `references/x.md` added to `qa-plan` in a scratch install showed up in the project and in the
> manifest for both). `install.ps1` was not run; its verification step still applies.

### What stays always-on, file by file

Targets are bytes, so they can be checked with `wc -c`; tokens are bytes / 4.

| File | Today | Keep in `rules/` | Moves to `references/` | After |
| --- | --- | --- | --- | --- |
| `testing-guidelines.md` | 11,383 | the 7 principles; the defect-chain summary; strategic alignment; the tagging taxonomy; the failure and quarantine protocol; the Definition of Done | pyramid, ISTQB techniques table, field heuristics, CI/CD filter syntax (`testing-design.md`) | ~7,000 |
| `context-discovery.md` | 5,101 | everything (it governs every entry point that produces tests) | nothing | 5,101 |
| `code-style-qa.md` | 5,787 | AAA; POM rules as one-line bullets; the locator order; the anti-patterns list; a four-line atomic-commit reminder | assertion code examples; the full Git standards, pre-push table, red-green proof (`automation-code.md`) | ~2,400 |
| `accessibility-qa.md` | 5,040 | the WCAG 2.2 AA criteria as a condensed must-list | the axe template; the manual checklist (`accessibility-checks.md`) | ~2,000 |
| `security-qa.md` | 5,579 | the OWASP verification must-list | the payload spec; scanning commands; the manual checklist (`security-checks.md`) | ~1,800 |
| `test-evidence.md` | 5,400 | the six hard rules: viewport not full page, no element crops, visible pointer and label, open the recording, ASCII names, the checker command | code examples, the skipped-test recording trap, pacing detail (`evidence-capture.md`) | ~1,300 |
| `test-tools.md` | 5,921 | a ~400-byte stub: name the activity and category before naming a product; never present a tool as a guarantee | all four sections (`test-tools.md`) | ~400 |
| `conventional-commits.md` | 2,482 | everything (applies to every commit in the target repo) | nothing | 2,482 |
| `linting-standards.md` | 1,833 | everything (applies to every edit in the target repo) | nothing | 1,833 |
| **Total** | **48,526** | | | **~24,300** |

The two commit and lint rules and `context-discovery.md` stay whole on purpose: they govern work
that is not "writing a test" (committing, editing code, grounding any test design). The
principles and tagging taxonomy stay because every skill, command and agent assumes them, and the
tag list is what a reviewer checks first.

### Before and after target

| Measure | Before | After | Change |
| --- | --- | --- | --- |
| Always-loaded rules, bytes | 48,526 | at most 25,000 | about -48 percent |
| Always-loaded rules, tokens (bytes / 4) | ~12,100 | at most ~6,250 | about -5,900 |
| Always-loaded rules, tokens (words x 1.3) | ~9,100 | at most ~4,700 | about -4,400 |
| Loaded only on demand | 0 | ~24,000 bytes (~6,000 tokens) | new |

The saving is on every conversation in an installed project, including unrelated ones. A
conversation that does write tests pays roughly what it pays today, plus one `Read` per reference
it needs.

### Other editors

The merged adapter is one file per editor, and `generate-adapters.sh` merges only `SKILL.md`
files (`find ... -name "SKILL.md"`), so `references/` would silently vanish from every non-Claude
adapter and `tests/verify-adapters.sh` would fail (it asserts the merged file contains `ISTQB`,
`Arrange-Act-Assert` and `OWASP`). Item 3 therefore makes the generator append each
`references/*.md` after its `SKILL.md`, in a fixed order, for both `generate-adapters.sh` and
`generate-adapters.ps1`. Result: **non-Claude adapters keep their full content and gain no savings
in this plan.** That is deliberate. Their size is a different problem (180 KB against Windsurf's
12,000-character file limit and Copilot's two-page guideline) and needs a different fix: per-editor
splitting using each editor's own on-demand mode (Cursor `globs` or Apply Intelligently, Windsurf
Model Decision, Copilot `.instructions.md`, Cline `paths:`). Recommend a follow-up plan once this
one proves the split on Claude Code.

## Items

0. **Baseline.** Re-measure with a real tokenizer if one can be installed, record the table above in
   the pull request, and log which rules load with the `InstructionsLoaded` hook in a scratch
   project, so "before" is observed rather than assumed.
1. **Create the skill and move the text.** Add `qa-reference/SKILL.md` (with the frontmatter
   `tests/test-frontmatter.sh` requires) and the six references, moving text verbatim first and
   condensing the cores second, as two commits so the move is reviewable as a move.
2. **Repoint the callers.** Every command, skill and agent that names a moved section by rule path
   (`grep -rn "rules/" .claude/commands .claude/skills .claude/agents`) names the reference file
   instead, with a "read it when" clause. `commands/qa.md`'s rule table (lines 48-52, 77) gains the
   new skill.
3. **Generators.** Merge `references/*.md` into the adapters (both generators), then regenerate.
4. **Release.** This is a behaviour change for installed projects: a `refactor:` commit, but visible in
   the changelog. Existing installs receive the new layout through `update`, which relies on
   plan 009-013's manifest, so the old `rules/*.md` files are replaced only if still unmodified
   and a user's edited copy is kept and reported, as the file-safety contract requires.

## Verification

- **Skills still find the moved content.** For each moved section, a test greps the installed
  tree and asserts the reference exists and that its caller points to a path that exists
  (extend `tests/test-frontmatter.sh` or add a sibling check: every `references/` path mentioned in
  a command, skill or agent resolves).
- **Behavioural check, done by hand before merging.** In a scratch project with the new install,
  ask for "a Playwright spec with an axe check", "an XSS payload test", and "recommend a test
  tool". Confirm with `InstructionsLoaded` and the transcript that the matching reference was read
  and that the answer carries content that now lives only there (the axe `withTags` call, the
  payload list, the tool categories). Record the transcripts in the pull request.
- **Always-on size is enforced.** A test fails if the sum of `.claude/rules/*.md` exceeds 25,000
  bytes, so the diet cannot quietly regrow.
- **Adapters unchanged in content.** `tests/verify-adapters.sh` and `.ps1` pass; the merged
  adapter still contains every moved section (grep for one marker phrase per reference).
- **Lifecycle and conformance unaffected.** `tests/test-lifecycle.sh`, `tests/conformance/run.sh`
  and their PowerShell twins pass without edits to the suites: installers copy skill
  subdirectories already, so no installer logic changes. Confirm that claim by running install,
  uninstall and `update` and checking `references/` files appear in `.qa-skills-manifest` and are
  removed on uninstall; if the installers flatten or skip nested skill folders, stop and add a
  conformance case before going further. `./generate-known-hashes.sh --check` passes.
- Markdownlint and prettier clean on every touched file.

## Rejected approaches

- **Path-scope the rules in place with `paths:` frontmatter** (`**/*.spec.*`, `tests/**`, ...).
  The mechanism is real and costs no installer change, and the adapters strip frontmatter so other
  editors would be unaffected. Rejected as the main approach because the trigger is a *file read
  or write*, not the task: test layouts differ by repository (`e2e/`, `cypress/`,
  `__tests__/`, `*.test.ts`, `src/**/*.spec.ts`), so a glob list is a guess that silently fails to
  load in a repo it does not fit, and the rules mostly matter in conversations that **write
  test cases or plans as markdown or tickets** and never touch a matching file. A rule that loads
  "sometimes" is harder to reason about than one that is read on request. Kept as a possible
  refinement for `code-style-qa.md`'s core only, after real feedback.
- **Delete the detail instead of moving it.** Loses the axe template, the payload spec and the
  evidence procedure, which are content users value and the monograph cites.
- **Rewrite every rule shorter but keep it in `rules/`.** Saves less (roughly a quarter), and
  removes the examples that make the rules checkable.
- **Make rules opt-in at install time (`--rules minimal|full`).** Adds a choice and a second
  tested configuration to all three installers for a saving the split gives for free.
- **A new top-level `.claude/references/` directory.** Needs a new entry in `SUBDIRS`, the editor
  map, the scaffold loops and the conformance suite for no benefit over a skill folder.
- **Also shrink the other editors' adapters now.** Each editor needs its own mechanism; bundled
  here it widens a plan about Claude Code's loading model into five. Follow-up plan instead.

## STOP: needs Marco's approval before implementation

Decisions to confirm:

1. Is a roughly 50 percent cut of the always-loaded rules (48.5 KB to about 24 KB) the right
   target, or should `testing-guidelines.md`'s defect-chain section also move?
2. Is `qa-reference` the right home, and is "read on request through the skill description" an
   acceptable loading model, given it is less certain than an auto-loaded rule?
3. Ship after launch week with real feedback (plan 019 suggests this), or before?
4. Open a follow-up plan for the non-Claude adapters' size, including the Windsurf 12,000-character
   limit?
