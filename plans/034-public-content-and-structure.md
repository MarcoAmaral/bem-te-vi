# Plan 034: What a public reader opens is English, generic, consistent and findable from every install

> **Executor instructions**: Do this plan **after** plan 032 has merged and **before** plan 020
> part B exports the tree; plans 035 and 036 add content after it (see "Maintenance notes"). Run
> every verification command. If anything in "STOP conditions" occurs, stop and report. When done,
> update this plan's row in `plans/README.md`.
>
> **Drift check (run first)**: `git diff --stat a2f08e7..HEAD -- .claude/commands .claude/skills .claude/agents .claude/rules .claude/hooks .claude-plugin generate-adapters.sh generate-adapters.ps1 tests/test-reference-links.sh tests/verify-adapters.sh tests/test-tc-contracts.sh README.md CONTRIBUTING.md`
> Every line number below was read at `a2f08e7`. Re-run each step's `grep` before editing; where a
> number has moved, trust the `grep`, not this plan.

## Status

- **Priority**: P1 (this is the content a public reader sees first; it must land before plan 020 part B)
- **Effort**: L
- **Risk**: MEDIUM (step 3 changes how every command names the files it relies on; steps 5 and 6
  change what Claude Code loads when `/qa-automate` and `/qa-defect` run)
- **Depends on**: plan 032 (merged); implemented in this private repository before the public
  cut-over (plan 020 part B)
- **Category**: shipped content, adapters, tests
- **Planned at**: commit `a2f08e7`, 2026-10-14
- **Decided by Marco, 2026-10-14**: every default in this plan (English-only runbook, the `/qa` byline keeps his name, the plugin ships no hooks), plus the `runbook` rename recorded below.
- **Decisions for Marco** (defaults below, used if he does not answer): step 1 (the notebook
  ships in English only), step 2 (the `/qa` byline keeps his name), step 7 (the plugin ships no
  hooks).
- **Decided by Marco, 2026-10-14**: the PT-BR "caderno de testes" becomes the **runbook**, the term
  his team uses for it (step 1). The full-repository English audit of the same day (scratchpad
  report `english-audit.md`, commit `a2f08e7`) is folded into step 1.

## Why this matters

The "Structure" bullet of the audit after 4.0.0 (`plans/README.md`, "Backlog — audit after
4.0.0") lists what a stranger notices first when they open the package: Portuguese paragraphs
inside English commands, the author's name and product codes in a template, a worked example that
stores a session token in `localStorage` while the package's own security rule forbids it, rules
stated three or six times in wording that has drifted apart, one 618-line command covering a dozen
topics, a defect command that is half an Azure DevOps and Node manual, and 87 file pointers of
the form `.claude/...` that only resolve in one of the five ways the package can be installed.

None of these breaks a test. Each one tells a public reader that the package was written for one
person's project, and the path problem means a plugin, skills-only or Cursor/Copilot user is sent
to files that do not exist on their machine.

## Current state

Measured at `a2f08e7` (`git -C <worktree> log -1 --format=%h github/main`).

### 1. Portuguese inside English commands: 37 lines in 2 files

- `.claude/commands/qa-automate.md:53-67` (15 tree comments: "Root do Framework Playwright",
  "Testes de autenticação", ...), `:73` ("Adicione ao `.gitignore` ..."), `:75` ("Propósito dos
  Diretórios"), `:77-81` (5 bullets), `:87` (the Vitest intro paragraph): **23 lines**.
- `.claude/commands/qa-cases.md:58` (`cdt: caderno-de-testes/CDT-...`), `:334` ("## Caderno de
  Testes (Execution Notebook)"), `:346-362` (the notebook template body: "Como usar este caderno",
  "Pré-condição", "Passos", "Ação", "Resultado Esperado", "Resultado Real", status values "PASSOU
  ☐ FALHOU ..."): **14 lines**.
- Found with `grep -rnP '[ãõçáéíóúâêôàÃÕÇÁÉÍÓÚÂÊÔ]'` and a Portuguese word list (`de|para|dos|das|com|
  Testes|Adicione|caderno|...`) over `.claude/{commands,rules,skills,agents,hooks}`; no other file
  matches.
- **Frontmatter is already English.** Every `description:` in `.claude/commands` and
  `.claude/skills` is English. The "QA — Automação: Playwright & Vitest" the backlog quotes comes
  from a stale global install on the author's machine (`~/.claude/commands/qa-automate.md`, dated
  2026-10-05, first line `# QA — Automação ...`, default "PT-BR"); the source changed in `33424a0`.
  Not a package defect; reinstalling fixes that machine.

### 2. Author's product and a contradicting security example

- `qa-cases.md:54` feature-code comment `AUTH, MAP, VER, EDIT, VAL, REC, SRC, etc.` and `:330`
  `**Feature codes:** AUTH, MAP, VER, EDIT, VAL, REC, SRC, SKT, REF, CPY, SET, I18N, KBD, PNL, BKM,
  ERR, NSO, TRC, A11Y, SMK`: one product's module list presented as the package's codes.
- `qa-cases.md:256`: the worked example's **Author** row is "Marco Amaral — Senior QA Analyst".
- `qa-cases.md:274,290`: `sign-in-server-picker`, "Enter portal URL in the server picker", "Click
  Apply & Reload": a specific product's sign-in. The same flow is in `qa-bdd.md:92-102,160-161,182`
  ("server URL picker", "map content is hidden", `sign-in-server-input`) and in
  `qa-automate.md:593-595`'s data-testid examples (`sign-in-server-input`, `version-list-item`).
- `qa-defect.md:394`: `"regression; p1; TC-CQG-005"`, another product code.
- `qa-cases.md:291` (TC-AUTH-002 **Expected**): "`auth-session` in localStorage has valid token".
  `.claude/rules/security-qa.md:12`: "tokens live in `HttpOnly`, `Secure`, `SameSite=Strict`
  cookies, never in `localStorage` or `sessionStorage`". The example teaches a test that passes
  only when the security rule is broken. `qa-cases.md:271` ("clear localStorage") is a harmless
  precondition and only needs to say "cookies and storage".
- `.claude/commands/qa.md:7` byline "**Bem-te-vi** | Marco Amaral | ...": an author credit, not
  template content (decision in step 2).

### 3. Duplicated text that has drifted: 4 families

| Family | Where (file:line) | Drift |
| --- | --- | --- |
| "N/A — why" | `qa-cases.md:20-24`, `qa-defect.md:16-18` and `:251`, `agents/qa-writer.md:80`, `qa.md:128-129`, `skills/qa-plan/SKILL.md:241` | Four spellings (`N/A — <why>`, `N/A — <reason>`, `"N/A — why"`, `N/A` or `N/A: <why>`). `qa-plan` allows a bare `N/A`, which every other copy forbids |
| Correct, Don't Delete | `qa-cases.md:38-42`, `qa-defect.md:23-28`, `qa-plan/SKILL.md:243-249` | Three note formats (`> **Correction, YYYY-MM-DD, <author>:**`, `Correction, YYYY-MM-DD, <author>: ...`, `<author or agent>`) and two strike-through forms (`~~old~~` plus a note, `~~old~~ (superseded YYYY-MM-DD: <why>)`) |
| TC file template | `qa-cases.md:47-95` (full) and `qa.md:95-125` (short form, "qa-cases wins on any difference") | `cdt:` value differs (`caderno-de-testes/CDT-[CODE]-[name].md` against "execution notebook path, or N/A — why"); the **Note** row allows N/A in one copy only. `tests/test-tc-contracts.sh:54-55` keeps both accepted by the hook, not identical |
| Locator choice | `.claude/rules/code-style-qa.md:16-28` (roles, then test IDs, then text and labels) and `qa-automate.md:598` | `qa-automate` says "**Never use:** CSS classes, XPath, **text content**, dynamic IDs", which contradicts the rule's third choice |

The rule-stub plus reference pairs created by plan 021 (for example `code-style-qa.md` and
`references/automation-code.md`) and the tag lists in `qa-cases.md:212-218` and
`agents/qa-designer.md:54-57` are **consistent** with `testing-guidelines.md:60-99`; they are not in
scope.

### 4. `qa-automate.md`: 618 lines, 21,178 bytes, twelve topics

`grep -nE '^#{1,3} '`: project structure (26-83), Vitest setup, config, unit pattern, SDK mocking,
`localStorage` pattern, running (85-211), Playwright config, auth fixture, Page Objects, spec
(213-416), reaching screens through the UI (418-427), behaviour profile (429-443), one shared helper
library (445-467), running Playwright (469-498), flakiness hunting (500-521), GitLab CI (523-574),
data-testid guide (576-600), how to respond (602-613), terminal logging (615-618). The whole file
loads every time `/qa-automate` runs.

### 5. `qa-defect.md`: 449 lines, 19,857 bytes

Generic: 1-258 (format, severity and priority, lifecycle, title, writing rules, example, how to
respond). Stack- or tracker-specific: Step 0's Node block (264-283, including a Python script that
reads `package.json`); the `SystemInfo` HTML block (293-304, an Azure DevOps field format); the
Azure DevOps attachment upload (337-377); "Step 2 — ADO Bug Field Mapping" and the "ADO filing
template (Python)" (381-449). The generic parts of Step 0 (285-291) and Step 1 (308-334) are
stack-neutral.

### 6. Pointers to package files: 87 `.claude/...` occurrences on 79 lines, plus 34 in other styles

`grep -rnoE '\.claude/[A-Za-z0-9_./-]+' .claude/{commands,rules,skills,agents,hooks}`, classified
by target and context:

| Target | In instructions | In a header or comment | Total |
| --- | --- | --- | --- |
| a rule (`.claude/rules/...`) | 38 | 9 "Moved from" headers in references, 1 script comment, 1 script message | 49 |
| a reference (`.claude/skills/qa-reference/references/...`) | 19 | 0 | 19 |
| a script (`.claude/hooks/*.sh`) | 11 | 2 script headers | 13 |
| a command (`.claude/commands/...`) | 5 | 1 script comment | 6 |

Other spellings of the same pointers: `rules/<name>.md` (10), `skills/<name>` (11), a bare
`<rule>.md` (13). Four styles for one idea.

What each install has (`plans/022`, table "What each install path delivers";
`install.sh:802-851`; `generate-adapters.sh:31-102`):

| Install | Rules | References | Scripts | Commands | Does `.claude/<x>` resolve? |
| --- | --- | --- | --- | --- | --- |
| Project (`bem-te-vi init`, `install.sh --target project`) | yes, in context | yes | yes | yes | **yes** |
| Global (`--target global`) | yes, in context | in `~/.claude/` | in `~/.claude/` | in `~/.claude/` | no (relative to the project) |
| Claude Code plugin | **no** | plugin cache | plugin cache, not wired | plugin cache | no |
| `npx skills add` | **no** | if the skill is installed | **no** | **no** | no |
| Cursor, Windsurf, Copilot, Cline, Antigravity, AGENTS.md | inline in one merged file | inline | **no** | inline | no (one file) |

Classes:

- **Works everywhere** (nothing to open): **13**, the 9 "Moved from" headers and 4 script comments.
  They name a path a user never needs; reworded in step 3 for consistency only.
- **Resolves only in a Claude Code project install, content still reachable elsewhere**: **62**
  (38 rule and 19 reference pointers in instructions, 5 command pointers). Global, plugin and
  merged-file users can find the content by name, but not by the path given; plugin and
  skills-only users have no rules at all.
- **Broken outside a project or global Claude Code install**: **12**, the 11 instructions to run a
  script plus `check-test-evidence.sh:158`, which tells the user to "See
  .claude/rules/test-evidence.md". The scripts are not in the merged adapters, not installed by
  `npx skills add`, and sit unwired in the plugin cache.

What the generator does today: **no rewriting**. `generate-adapters.sh` concatenates
`qa.md`, `qa-*.md`, rules, each `SKILL.md` followed by its `references/*.md` (`-maxdepth 1`: no
subfolders), and agents, stripping only YAML frontmatter. Nothing in the merged file says which
source file a section came from, so a pointer such as "`references/evidence-capture.md`" cannot be
matched to its section by a Cursor user. `tests/test-reference-links.sh` checks only
`references/<file>.md` pointers: `*skills/*` paths resolve under `.claude/skills/`, bare ones
relative to the mentioning file.

### 7. The plugin ships no hooks

- `.claude-plugin/plugin.json` declares `commands`, `skills` and `agents` only. The marketplace
  entry uses `"source": "."`, so the whole repository, `.claude/hooks/*.sh` included, is copied to
  the plugin cache (`plans/022`, "Cache copy"): the scripts are present but nothing tells Claude
  where.
- The plugin manifest reference (code.claude.com/docs/en/plugins-reference, read 2026-10-14): a
  `hooks` component is an event map (`PreToolUse`, `PostToolUse`, ...) in `hooks/hooks.json` or an
  inline object; scripts are addressed as `"${CLAUDE_PLUGIN_ROOT}"/...`. `${CLAUDE_PLUGIN_ROOT}` is
  also substituted "anywhere in the Markdown body" of a plugin's skill, command and agent content.
- `plans/022`, "Rejected approaches": "Registering `check-test-evidence.sh` and
  `validate-tc-format.sh` as plugin hooks: they are checkers the user runs, not event handlers;
  wiring them to events would change behaviour for plugin users only." In project installs
  `validate-tc-format.sh` is a **git** pre-commit hook (`install.sh:359-400`), not a Claude Code
  event.
- `tests/plugin/verify-plugin.sh` checks only `commands`, `skills` and `agents` paths and the agent
  list; it has no hooks case.

### Budgets and tests that constrain this plan

- `./tests/test-rules-size.sh`: the 9 rules total **21,439** bytes (cap 25,000).
- `./tests/test-reference-links.sh`, `./tests/verify-adapters.sh` (markers per reference file),
  `./tests/test-tc-contracts.sh` (needs the headings `## Complete Example` in `qa-cases.md` and
  `## 📋 TC Format Quick Reference` in `qa.md`), `./tests/test-frontmatter.sh`.
- `validate-tc-format.sh:131-138` requires the frontmatter keys `cdt` and `implementation_pack`. They
  are a contract with every user's existing test-case files and are **not renamed** here.

## Commands you will need

| Purpose | Command | Expected |
| --- | --- | --- |
| Portuguese left | `grep -rnP '[ãõçáéíóúâêôàÃÕÇÁÉÍÓÚÂÊÔ]' .claude/commands .claude/rules .claude/skills .claude/agents` | no output |
| Author traces | `grep -rnE 'Marco Amaral\|CQG\|NSO\|server picker\|portal URL\|Apply & Reload' .claude/commands .claude/skills .claude/agents` | only `qa.md:7` if step 2's default stands |
| Old-style pointers | `grep -rnoE '\.claude/(rules\|skills\|commands)/' .claude/commands .claude/rules .claude/skills .claude/agents \| wc -l` | 0 |
| Rules budget | `./tests/test-rules-size.sh` | ≤ 21,439 bytes |
| Links | `./tests/test-reference-links.sh` | exit 0 |
| Contracts | `./tests/test-tc-contracts.sh && ./tests/test-validate-tc-format.sh && ./tests/test-check-test-evidence.sh` | exit 0 |
| Frontmatter | `./tests/test-frontmatter.sh` | exit 0 |
| Adapters | `./generate-adapters.sh --clean && ./tests/verify-adapters.sh` (and `.ps1` on Windows CI) | exit 0 |
| Plugin | `./tests/plugin/verify-plugin.sh` | exit 0 |
| Installers | `./tests/test-lifecycle.sh && ./tests/conformance/run.sh` | exit 0 |
| Markdown lint | `npx --no-install markdownlint --dot .claude README.md plans` (plan 032 pins it) | no output |
| Sizes | `wc -lc .claude/commands/*.md .claude/skills/qa-reference/references/*.md` | numbers for README and `qa.md` |

## Scope

**In scope**: `.claude/commands/{qa,qa-automate,qa-cases,qa-defect,qa-bdd,qa-agentic,qa-static,
qa-tdd,qa-trace}.md`, `.claude/agents/*.md`, `.claude/rules/*.md` (pointer wording only),
`.claude/skills/*/SKILL.md`, `.claude/skills/qa-reference/references/*` (new files and pointer
wording), `.claude/hooks/check-test-evidence.sh:158` (one message), `generate-adapters.sh`,
`generate-adapters.ps1`, `tests/test-reference-links.sh`, `tests/verify-adapters.sh` (markers),
`README.md` (sizes and the install table), `CONTRIBUTING.md` §5 (one sentence), `plans/README.md`.

**Out of scope**: renaming the `cdt` or `implementation_pack` keys (a breaking change to users'
files: its own plan); the installers; wiring the scripts as plugin event hooks (step 7); new CTFL
or book content (plans 035 and 036); splitting the merged adapters per editor (plan 021's
follow-up); removing or renaming any shipped file (the shell `--update` keeps files the package
stops shipping, audit backlog "Installer parity").

## Git workflow

Two branches, two pull requests, so the content fixes can be reviewed apart from the moves:

- **PR A** `fix/public-content` (steps 1-3): every commit `fix:`, because each corrects shipped
  content that is wrong for its reader (wrong language, another product's data, an example that
  contradicts a shipped rule, pointers that do not resolve), and CONTRIBUTING.md §2 reserves
  `fix:` for changes that reach installed users. Step 3's generator change also reaches users (it
  changes `adapters/`), so it is `fix:` too; plan 021 typed a generator change `build:` before
  CONTRIBUTING.md's rule existed, and the rule wins. The test change is `test:`.
- **PR B** `refactor/on-demand-references` (steps 4-7): verbatim moves are `refactor:` (one commit
  per moved block, text unchanged, so the diff reads as a move); a commit that changes wording in
  the same step is a separate `fix:` (for example aligning `qa-plan`'s bare `N/A`, or the locator
  contradiction). PR B's title is `fix(content): ...` so its merge commit, the record Release Please
  is guaranteed to see (CONTRIBUTING.md §3 item 6), names the change; its description lists the new
  reference files users receive on `update`.

Merge with GitHub's default merge commit, never squash, never `--body ""`. No AI attribution lines
in commits or PR descriptions.

## Steps

### Step 1: English only inside English commands (PR A)

- `qa-automate.md:53-81,87`: translate the 23 lines. Keep meaning; do not add content.
- `qa-cases.md:334-363`: replace the PT-BR notebook with an English **runbook**. Heading
  "## Runbook (`runbook`)"; body "How to use this runbook", "Precondition", "Steps", "Action",
  "Expected result", "Actual result", status values `PASSED FAILED BLOCKED NOT RUN VERIFIED BY DEV
  DISCARDED`, "Notes". Add one line mapping it to CTFL terms: a runbook is a set of test procedures
  in the order of the test execution schedule (§5.1.5; listed as testware in §1.4.3).
- **The `cdt` key becomes `runbook`, without breaking anyone.** The template (`qa-cases.md:58`, now
  `runbook: runbooks/RB-[CODE]-[name].md`), `qa-writer` and the README write `runbook:`.
  `validate-tc-format.sh` accepts either key and reports the old one as "`cdt` is the old name of
  `runbook`", without failing. Existing fixtures keep `cdt` (they now test the old name); add
  `tests/fixtures/tc-format/runbook-key.md` for the new one, and a conformance or contracts check
  that the template, `qa-writer` and the hook name the same key.
- **One name for one thing**: `qa-explore/SKILL.md` calls the same artefact a "run sheet"; it
  becomes "runbook" there too.
- **Repository text** found by the English audit, outside the commands:
  - `README.md:101` and `:212-213` claim "full Portuguese (PT-BR) support" and a Portuguese
    template. Drop the claim; keep "answers in the language of your prompt" only if a test or a
    command line shows it is true.
  - `CLAUDE.md:11` "Source Language: Standard English & Portuguese Markdown" → "English".
  - `examples/serverest/**`: ServeRest's own Portuguese messages and field names stay verbatim
    (the tests assert what the real server returns); add a short English gloss beside each in the
    example READMEs.
  - `tests/conformance/cases/003-*/qa-v2.3.0.md` and `006-*/qa-v2.3.0-crlf.md` stay byte-exact
    copies of the released v2.3.0 file (their hashes are what the "older release adopted" cases
    test); add one line to `tests/conformance/README.md` saying why they are not translated.
- **Decision for Marco (default)**: English only. The command already says "Respond in the language
  of the user's prompt", which covers a Portuguese runbook; a second, Portuguese template is a
  translation the package would have to keep in step.

**Verify**: the "Portuguese left" command prints nothing; `./tests/test-tc-contracts.sh` passes.

### Step 2: no author product, and an example that obeys the security rule (PR A)

- **Also in this step** (found by plan 041): `qa-defect.md:117-118` defines priority P1 as "Fix
  immediately, block release" and P2 as "Fix before release", a second release gate that
  contradicts plan 029's single, severity-based gate (`qa-plan/SKILL.md`). Reword both as
  scheduling guidance and point to the one gate; `fix:` commit.

- `qa-cases.md:54,330`: replace the product's code list with generic examples and the rule that
  produces them: "`[CODE]`: 2-5 capitals naming the feature area, for example `AUTH`, `CART`,
  `SRCH`, `A11Y`; use the project's own list when it has one". `qa-groomer.md:49` already says
  "2-5 capitals"; match it.
- `qa-cases.md:256`: **Author** → `[Name] — QA Analyst`.
- The sign-in example, one wording across `qa-cases.md:265-310`, `qa-bdd.md:92-102,140-182,200-226`
  and `qa-automate.md:576-600`: an email and password sign-in, test IDs `sign-in-overlay`,
  `sign-in-email-input`, `sign-in-submit`, `topbar-user-profile-btn`; no "portal URL", "server
  picker", "Apply & Reload" or "map". Keep the step count and techniques so the example still
  shows EP, state transition and error guessing.
- `qa-cases.md:291` **Expected** → "Overlay disappears. App loads. User info visible. The session
  cookie is set with `HttpOnly`, `Secure` and `SameSite`; no token is readable from `localStorage`
  or `sessionStorage`." `qa-cases.md:271` → "No session (cookies and storage cleared), app loads
  fresh".
- `qa-defect.md:394`: `TC-CQG-005` → `TC-AUTH-005`.
- `qa-cases.md:319` "Linear issue IDs (or tracker used)" → "tracker issue IDs".
- **Decision for Marco (default)**: keep `qa.md:7`'s byline. It credits the author of the package,
  as the README does; it is not a value a user copies into their documents.

**Verify**: the "Author traces" command; `grep -n 'localStorage has' .claude/commands/qa-cases.md`
→ nothing; `./tests/test-tc-contracts.sh` passes (the example is one of its fixtures).

### Step 3: one way to name a package file, valid in every install (PR A)

> **Note, 2026-10-19 (plan 057).** The reference form below, `qa-reference/references/<file>.md`,
> did not open in a Claude Code project install: the spot check of 2026-10-19 read it as a path
> from the project root, in 3 of 3 runs. Shipped text now names a reference as "the `qa-reference`
> skill's `references/<file>.md`", and the reader loads the skill to find its folder. The rest of
> this step (rules by name, commands by slash name, scripts by file name) stands.

The fix is a **naming convention, plus a source marker in the merged adapters**. Rejected
alternatives are in "Maintenance notes".

1. **Convention** (write it once in `qa.md`, after the rule list, and once in
   `qa-reference/SKILL.md` "How to use"):
   - A rule by name: "the `context-discovery` rule". In every install that has rules, the rule is
     already in context; nothing needs opening.
   - A reference by skill-relative path: `qa-reference/references/evidence-capture.md`, "a file in
     the `qa-reference` skill's folder". Inside `qa-reference/SKILL.md` keep `references/<file>`.
     Claude Code gives a loaded skill its own directory, so this resolves in project, global,
     plugin and skills-only installs.
   - A command by its slash name: "the `/qa-cases` template", "'The Ticket Folder' in
     `/qa-agentic`".
   - A script by name with its install-specific location and a fallback: "run the package's
     `check-test-evidence.sh` (a Claude Code install puts it in `.claude/hooks/`); when it is not
     installed, apply its checks by reading the specs and say that the checker was not run". This
     generalises the pattern `qa-agentic.md:32` already uses for `validate-tc-format.sh`.
2. **Apply it** to all 87 `.claude/...` occurrences and the 34 other-style pointers (`rules/x.md`,
   `skills/x`, bare `x.md`). The 9 "Moved from `.claude/rules/x.md`" headers become "Detail behind
   the `x` rule". `check-test-evidence.sh:158` → "See the test-evidence rule". The 2 script header
   comments keep their own file name without a directory.
3. **Generators**: in `generate-adapters.sh` and `generate-adapters.ps1`, write one line before
   each merged section: `<!-- source: rules/context-discovery.md -->`,
   `<!-- source: qa-reference/references/evidence-capture.md -->`,
   `<!-- source: commands/qa-cases.md -->`. A merged-file reader can then find the section a pointer
   names. Both generators must emit byte-identical output (`tests/verify-adapters.*`).
4. **Tests**: `tests/test-reference-links.sh` resolves `<skill>/references/<file>.md` under
   `.claude/skills/` (keep the bare `references/` case for `SKILL.md`), and fails on any
   `.claude/(rules|skills|commands)/` path in instructions. `tests/verify-adapters.sh` asserts at
   least one `<!-- source:` marker per source kind.
5. **README**: the install table states, per install, that scripts and rules are absent where they
   are, and what the commands do instead.

Before committing, do the behavioural spot check by hand: in a scratch project with
`bem-te-vi init`, and again with the plugin installed (`claude plugin marketplace add <clone>`),
run `/qa-automate` on a small spec request and confirm in the transcript that the evidence
reference is opened. Record both results in the PR.

**Verify**: "Old-style pointers" → 0; links, adapters, contracts and rules-size pass; rules total
not above 21,439 bytes (names are shorter than paths).

### Step 4: one canonical home per duplicated family (PR B)

- **New reference** `qa-reference/references/written-records.md`: "Every field, every record"
  (`N/A — <why>`, one spelling, with the examples now in `qa-cases.md:21-22` and
  `qa-defect.md:17-18`) and "Correct, don't delete" (one note format,
  `Correction, YYYY-MM-DD, <author or agent>: <what was wrong and what is right>`, and one
  strike-through form, `~~old~~ (superseded YYYY-MM-DD: <why>)`).
- `qa-cases.md`, `qa-defect.md`, `qa-plan/SKILL.md`, `agents/qa-writer.md`, `qa.md`: keep **one
  line** each with the exact `N/A — <why>` form (the TC hook depends on it, and a command loads
  alone) plus a pointer to `written-records.md`; delete the longer restatements.
- `qa-plan/SKILL.md:241`: drop the bare `N/A` and `N/A: <why>` forms (separate `fix:` commit; it
  contradicted the other five).
- TC template: `qa.md`'s short form keeps its heading and block (`test-tc-contracts.sh` needs both)
  but takes `qa-cases.md`'s values for `cdt` and **Note** as fixed in step 1, so the two are
  identical where they overlap.
- Locators: `qa-automate.md:598` → "Locator choice follows the `code-style-qa` rule: roles first,
  then test IDs, then labels and text; never structural CSS or XPath." (`fix:` commit.)
- `CONTRIBUTING.md` §5's last sentence names `written-records.md` (`docs:`).

**Verify**: `grep -rn "Correct, Don't Delete" .claude` → only `written-records.md`;
`grep -rnE 'N/A: |`N/A`' .claude/skills/qa-plan` → nothing; contracts and links pass.

### Step 5: `/qa-automate` becomes an entry point (PR B)

Move text verbatim into three new references (flat in `qa-reference/references/`: the generators
read only one level):

| New file | Moves from `qa-automate.md` (lines at `a2f08e7`) |
| --- | --- |
| `vitest-patterns.md` | Vitest project tree (30-46); Vitest setup, config, `tests/setup.ts`, unit pattern, SDK mocking, `localStorage` pattern, running Vitest (85-211) |
| `playwright-patterns.md` | Playwright project tree and directory purposes (47-83); config, auth fixture, Page Objects, spec (213-416); running Playwright (469-498); data-testid guide (576-600) |
| `automation-ci.md` | Flakiness hunting (500-521); GitLab CI pipeline (523-574); terminal logging and reporters (615-618) |

`qa-automate.md` keeps: the intro and pointers (5-22), a "Where the detail lives" table (file,
holds, read it when) for the three new files plus `automation-code.md`, `evidence-capture.md`,
`accessibility-checks.md` and `security-checks.md`; "Reach Every Screen Through the Interface",
"Capture a Behaviour Profile First" and "One Shared Helper Library" (418-467, the judgement this
command exists for); "How to Respond" (602-613). Target: about 130 lines.

Add each new file to the `qa-reference/SKILL.md` contents table and to its `description` (it
decides when the skill loads); add one `verify-adapters.sh` marker per new file (for example
`defineConfig`, `storageState`, `repeat-each`). Update the size column in `README.md` and
`qa.md`.

**Verify**: `wc -l .claude/commands/qa-automate.md` ≤ 150; every moved heading appears exactly once
under `.claude/` (`grep -rn '^### Auth Setup Fixture' .claude` → one line); adapters, links and
frontmatter pass; the behavioural spot check from step 3, on `/qa-automate`, still opens the
right file.

### Step 6: `/qa-defect` is generic; stack and tracker specifics are references (PR B)

| New file | Moves from `qa-defect.md` |
| --- | --- |
| `defect-system-info.md` | The Node block of Step 0 (264-283), under a "Node" heading, so other stacks can be added beside it |
| `tracker-azure-devops.md` | The `SystemInfo` HTML block (293-304); the attachment upload (337-377); "ADO Bug Field Mapping" and the filing template (381-449) |

`qa-defect.md` keeps the generic report (1-258), Step 0's stack-neutral part (what to record, the
`git` and `uname` commands, 285-291), Step 1's capture procedure (308-334), and one paragraph:
"When the team's tracker has its own bug schema, map the report's fields to it; for Azure DevOps
the mapping and an upload script are in `qa-reference/references/tracker-azure-devops.md`." Add
both files to the `qa-reference` contents table and markers to `verify-adapters.sh`.

**Verify**: `grep -nE 'ADO|Azure|dev\.azure|node --version' .claude/commands/qa-defect.md` → only the
pointer paragraph; links, adapters and lint pass.

### Step 7: the plugin and the two scripts (PR B, documentation only by default)

**Decision for Marco (default): the plugin ships no hooks.** `plans/022` already rejected wiring the
two checkers to Claude Code events, for a reason that still holds (behaviour would change for
plugin users only), and `validate-tc-format.sh` is a git pre-commit hook elsewhere, not a session
event. A plugin `hooks` entry would also need the script to read the tool event's JSON on stdin
instead of file arguments: a new feature with its own tests, not structure work.

What changes instead: step 3's script wording tells every install what to do when the script is
absent; `README.md`'s install table says plugin users get the scripts only through `bem-te-vi
init`. Writing `${CLAUDE_PLUGIN_ROOT}` into the shared Markdown was considered and rejected: the
plugin substitutes it, but every other install would show the literal text, and it is the kind of
single-platform reference CLAUDE.md rule 1 forbids.

If Marco chooses to ship a hook anyway, stop after step 6 and write that as its own plan, starting
from `plans/022`'s rejected approach and adding a hooks case to `tests/plugin/verify-plugin.sh`.

> **Step 7 evidence, 2026-10-16.** Default kept: the plugin ships no hooks. `grep -c hooks
> .claude-plugin/plugin.json` gives 0 and `tests/plugin/verify-plugin.sh` has no hooks case;
> `grep -rn CLAUDE_PLUGIN_ROOT .claude` finds nothing, so no shared Markdown carries a
> single-platform variable. The install table in `README.md` (added in PR A) says plugin users get
> the references but not the scripts, and each command says what to do when a script is absent.
> No file changed for this step beyond this note.

### Step 8: close

Regenerate adapters, run every command in the table, update the `plans/README.md` row for 034 and
strike "Structure" in the backlog with a dated note pointing to the two PRs (never delete it).

## Done criteria

- [ ] `grep -rn 'cdt' .claude` → only the hook's old-name message; template, `qa-writer` and hook
  agree on `runbook`; the `cdt` fixtures still pass.
- [ ] `grep -n 'PT-BR' README.md CLAUDE.md` → no match.
- [ ] "Portuguese left" → no output; "Author traces" → only `qa.md:7` (or nothing, if Marco chose so).
- [ ] No test-case example in `.claude/` expects a token in `localStorage` or `sessionStorage`.
- [ ] "Old-style pointers" → 0; `tests/test-reference-links.sh` checks the new form and passes.
- [ ] Every merged adapter carries `<!-- source:` markers; sh and ps1 output identical.
- [ ] One canonical home per family in the table of "Current state" §3; one `N/A — <why>` spelling.
- [ ] `qa-automate.md` ≤ 150 lines; `qa-defect.md` has no Azure DevOps or Node specifics.
- [ ] Rules total ≤ 21,439 bytes; adapters, contracts, frontmatter, plugin, lifecycle and
  conformance suites pass; CI green on Linux, Windows and macOS.
- [ ] Behavioural spot check recorded for a project install and a plugin install.
- [ ] README and `qa.md` size columns match `wc -c`; `plans/README.md` row updated.

## STOP conditions

- A step would rename or delete a shipped file, or rename a key `validate-tc-format.sh` requires.
- The rules total would rise above 21,439 bytes.
- The behavioural spot check shows Claude no longer opens a reference it opened before step 3:
  report the transcript; do not add `.claude/` paths back as a quick fix.
- `generate-adapters.sh` and `generate-adapters.ps1` cannot be made to emit identical markers.
- A moved block needs wording changes to make sense in its new file: make the move verbatim, then
  the wording a separate `fix:` commit; if the meaning changes, ask.
- Marco chooses plugin hooks (step 7) or a Portuguese notebook (step 1): those become their own work.

## Maintenance notes

- **Where new reference content goes.** Plans 035 (CTFL content gaps) and 036 (book gaps) add
  content after this plan, and the backlog says "put new content in on-demand references, not
  rules". The home is `.claude/skills/qa-reference/references/<topic>.md`: flat (the generators
  read one level), one topic per file, named for what the reader is doing (`test-levels-and-types.md`,
  `white-box-coverage.md`, `test-doubles.md`), each with a row in the `qa-reference/SKILL.md`
  contents table, a "read it when" clause, a `verify-adapters.sh` marker, and pointers written in
  step 3's convention. A rule gains at most one line that points to it. A command keeps judgement
  and the response procedure; templates, long examples and tool specifics go to a reference. 035
  and 036 must land after this plan, or they will add pointers in the old style and content to
  files this plan is splitting.
- **Rejected for step 3**: rewriting `.claude/` paths at adapter time (fixes only the merged
  adapters; plugin, global and skills-only installs read the source files unchanged); generating a
  separate plugin tree with rewritten paths (rejected in `plans/022` as duplicated content with a
  drift check); `${CLAUDE_PLUGIN_ROOT}` in shared Markdown (step 7).
- **Noticed, not in scope**: the plugin root is the repository root, so its `bin/` (holding
  `cli.js`) is a plugin `bin/` directory. The manifest reference says such files go on the Bash
  `PATH` and that claude.ai and Cowork do not install plugins that have one. Not verified against
  this plugin; worth a check before the public listing.
- A small CI check that every command's and reference's size in `README.md` matches `wc -c` would
  stop the size columns drifting again (plan 031's maintenance note says the same).

## Outcome

Recorded 2026-10-19 by plan 054 item 4. The work landed in PR A #138 and PR B #140 (see the row in
`plans/README.md`); the done criteria above were not re-verified here, and none is ticked by this
note.

**Behavioural spot check: not done, stopped by the usage limit.** Set-up, all in throwaway folders
in the MarcoWork distro: a fresh clone of `github/next` at `436faa9`; a project installed with
`./install.sh --target project --editor claude --non-interactive` (it put the reference at
`.claude/skills/qa-reference/references/evidence-capture.md`); then `claude -p` (Claude Code
2.1.224, `--model haiku`, `--setting-sources project,local --strict-mcp-config`, `--allowedTools
Read Glob Grep Skill`, `--output-format stream-json --verbose`) asked which punctuation character
the evidence-capture reference gives as an example of one that makes platforms drop uploads (the
answer, "middle dot", is in that file only).

- Run 1, project install: the session's init event lists the package's 8 skills and 11 commands
  among its slash commands (`qa-a11y` ... `qa-release`, `qa`, `qa-agentic`, ... `qa-trace`), so the
  install was found. The model never ran: `"api_error_status":429`, `"result":"You've hit your
  weekly limit · resets Oct 21, 2pm (America/Sao_Paulo)"`, `"total_cost_usd":0`. No Read, no answer.
- The plugin variant (`claude -p --plugin-dir <clone>`) was not run: the same account, the same
  limit.
- Nothing was installed into a Claude Code configuration: `claude plugin list` before and after
  the run is identical, and `~/.claude/settings.json` has the same SHA-256.

The criterion "Behavioural spot check recorded for a project install and a plugin install" stays
open. To finish it after the limit resets: the same two runs, then check the transcript for a Read
of `qa-reference/references/evidence-capture.md` and the answer for "middle dot".

> **Note, 2026-10-19, coordinator.** The spot check was done later the same day by plan 057 (#203),
> after it replaced this plan's pointer form, which a project install had read as a path from the
> project root: on plan 057's branch, a project install (runs A1-A3) and a plugin load with
> `--plugin-dir` (runs P1c and P2) each opened the reference on demand and answered from it. See
> plan 057, "Evidence after the change". The criterion "Behavioural spot check recorded for a
> project install and a plugin install" is met by those runs, for the pointer form plan 057 ships;
> it is not ticked above, since the other criteria there were never re-verified.
