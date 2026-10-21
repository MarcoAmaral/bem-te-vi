# Plan 037: Test the paths nothing tests yet

> **Executor instructions**: Do this plan **after** plans 032 and 033 have merged and **before**
> plan 020 part B exports the tree. Each step is its own branch and pull request. A new test that
> finds a defect stays red in its own commit and the fix follows in the next one; quote the failure
> in the pull request. Run every verification command. If anything in "STOP conditions" occurs,
> stop and report. When a step lands, update this plan's row in `plans/README.md`.
>
> **Drift check (run first)**: `git diff --stat a2f08e7..HEAD -- generate-adapters.sh generate-adapters.ps1 tests/verify-adapters.sh tests/verify-adapters.ps1 tests/test-lifecycle.sh tests/test-lifecycle.ps1 bin/cli.js install.sh install.ps1 .github/workflows/ci.yml`
> Plans 032 and 033 change several of these; re-read each "Current state" item before its step.

## Status

- **Priority**: P1 (step 1 found a live divergence; the others are coverage)
- **Effort**: M overall (step 5 is a spike of unknown cost)
- **Risk**: LOW for steps 1-4 (tests and CI); MEDIUM for step 5 (paid model runs)
- **Depends on**: plan 032 (step 3 already puts `tests/test-dedupe-changelog.sh` in CI; not repeated
  here) and plan 033 (it adds the directory-symlink cases and tests its own fixes). Done in this
  private repository, before plan 020 part B.
- **Category**: test, ci
- **Outcome**: steps 1-4 done (#142, #144, #145, #150); ~~step 5 stopped, see Outcome below~~
  step 5 done on 2026-10-18 on branch `test/behavioural-evals`, see "Step 5 outcome" below
  (corrected 2026-10-18: the stop was lifted the same day)
- **Planned at**: commit `a2f08e7`, 2026-10-14
- **Decided by Marco, 2026-10-14**: step 5's evals run locally and manually only, never in CI.
- **Decision for Marco**: step 5 (whether paid behavioural evals run at all, and where).
- **Decided by Marco, 2026-10-18**: step 5 runs locally and by hand, not in CI (as decided on
  2026-10-14), with the Claude Code installed in a second WSL distribution on his machine (2.1.291,
  where `claude plugin eval` works), billed to that account, with a hard cap of US$5 for every eval
  run together. Nothing may be left installed in that Claude Code.

## Why this matters

Every installer defect fixed in plans 009-013 and 026 had sat in a published release on a path no
test executed. The audit after 4.0.0 listed the paths still in that state. Checking them for this
plan found the first one already broken: the PowerShell adapter generator does not produce the
same files as the bash one, so a Windows user who installs from a clone gets different bytes from
everyone else, and nothing in CI compares them.

## Boundary with other plans

- **Plan 032 step 3** runs `tests/test-dedupe-changelog.sh` in CI. Not repeated here.
- **Plan 033** tests its own fixes: directory symlinks (its item 1, cases `013`-`014`), `update`
  parity, unknown CLI options, bracketed paths, the generator's `GLOBAL` mode, and `init` after
  `link`. This plan does not test those paths again.
- **This plan** covers what no plan touches: generator parity, `link`/`unlink` beyond plan 026's
  Test 39, the interactive menus, the bash version on macOS, and the behaviour of the commands
  themselves.

## Current state

1. **Generators never compared.** `tests/verify-adapters.sh` and `tests/verify-adapters.ps1` each
   check their own generator's output for presence, size (≥ 10,000 bytes), no BOM, a non-ASCII
   probe, and content markers. Neither compares the two outputs. On a scratch copy of `a2f08e7`,
   `generate-adapters.sh` and `generate-adapters.ps1 -Clean` (Windows PowerShell 5.1, run from WSL)
   produced 7 files each, all 7 different:

   ```text
   cursor/qa.mdc        sh 250,613 bytes   ps1 250,790 bytes
   universal/CLAUDE.md  sh 251,049 bytes   ps1 251,226 bytes   (every adapter differs by 177-178 bytes)
   ```

   Stripping carriage returns and ignoring blank lines, the two are identical
   (`diff -B` → 0 lines). The ps1 output has 144 lines ending in CR in `cursor/qa.mdc` (the bash output
   none) and moves blank lines around the section joins. Cause: `generate-adapters.ps1:144`
   (`[string]::Join(...)` with a PowerShell CRLF escape), `:204` and `:208` join with CRLF while every source
   is LF.
2. **`link` / `unlink`.** `tests/test-lifecycle.sh:1063-1106` (Test 39, plan 026 item 1) covers
   `link` then `uninstall`, `unlink` keeping a foreign link, and `link` keeping a foreign link,
   project scope, bash only. Not covered: `--global`; a stale link from a removed package being
   refreshed; `link` over a real directory (`bin/cli.js:731-737` prints "run 'unlink' first", but
   `unlink` (`:750-783`) only removes symlinks, so the advice cannot work); and anything on Windows:
   `tests/test-lifecycle.ps1` never runs `link` (`grep -n link tests/test-lifecycle.ps1` → no match),
   while `cmdLink` calls `fs.symlinkSync(src, dest, "dir")` (`:741`), which on Windows needs
   Developer Mode or elevation. What happens without either is unverified.
3. **Interactive menus.** Every suite call passes `--non-interactive`/`-NonInteractive`, or
   `--target` and `--editor`. Two `install.sh` tests pipe answers (`tests/test-lifecycle.sh:472`,
   `:1359`, `printf '1\ny\nn\nn\n'`) but only reach the operation menu and the commit offer; the
   target menu (`install.sh:1047-1071`) and the editor menu (`:1073-1112`) never run. No test drives
   `install.ps1`'s menus (`Read-UserChoice`, `:71-92`) or the CLI's `@inquirer/prompts` checkbox
   (`bin/cli.js:584-597`, shown only on a TTY). The menus also disagree on invalid input:
   `install.sh` defaults to Install on a bad operation (`:1039-1041`), exits 1 on a bad target
   (`:1068-1071`), defaults to Claude Code on a bad editor (`:1107-1110`); `install.ps1` re-prompts on
   all three (`:81-91`).
4. **bash version on macOS.** `install.sh` is `#!/bin/bash`, and the suites run it directly
   (`"$REPO_DIR/install.sh"`), so on macOS it gets `/bin/bash` 3.2. Everything else is
   `#!/usr/bin/env bash`: `generate-adapters.sh`, `generate-known-hashes.sh`, the two **shipped**
   hooks `.claude/hooks/validate-tc-format.sh` and `check-test-evidence.sh`, and every test script.
   The hook tests execute the hook by path (`tests/test-validate-tc-format.sh:8`,
   `tests/test-check-test-evidence.sh:8`), so they get whatever `bash` is first in `PATH`. The
   macOS job (`.github/workflows/ci.yml`, job `test-macos`) never prints or pins the version.
   Whether `macos-latest` puts a Homebrew bash 5 ahead of `/bin/bash` was not verified from here;
   step 3 records it. A user on a stock Mac runs the hooks and the generator under 3.2.
5. **No behavioural test of any command.** The suites test installers, formats and file
   contracts; none runs a command and checks what the model produces. `claude plugin eval` exists:
   `claude plugin eval --help` on Claude Code 2.1.224 (this machine) shows "Run eval cases
   (evals/**/case.yaml or evals/**/prompt.md + graders/*.md) against a plugin and report scored
   results", with `--ablation with-without` ("Run a no-plugin baseline arm and report the score
   delta"; the default when the target is a plugin *name*, `none` for a path), `--threshold`,
   `--runs` (default 3), `--max-cost-usd`, `--json`, `--judge-model` (default haiku), and
   `eval init --bare <name>` for a blank case template. The case schema itself was not read: no
   template was generated for this plan. The repository has no `evals/` directory; the plugin is
   `.claude-plugin/plugin.json` (commands, skills, four agents; no rules) from the repository root
   (`.claude-plugin/marketplace.json`, `"source": "."`).

## Commands you will need

| Purpose | Command | Expected |
| --- | --- | --- |
| Bash generator | `./generate-adapters.sh --clean && ./tests/verify-adapters.sh` | exit 0 |
| PowerShell generator | `powershell.exe -ExecutionPolicy Bypass -File .\generate-adapters.ps1 -Clean` | exit 0 |
| Compare (Windows job, Git Bash) | `git diff --no-index --exit-code <sh-out> <ps1-out>` | exit 0 |
| Lifecycle | `./tests/test-lifecycle.sh` | ends `100% GREEN` |
| Shell lint | `npx --yes shellcheck@3.1.0 <changed .sh files>` | no output |
| Eval help | `claude plugin eval --help`; `claude plugin eval init --bare <name>` | usage; a template under `evals/` |

Run reproductions on a copy (`git archive HEAD | tar -x -C "$(mktemp -d)"`), never in this checkout.

## Scope

**In scope**: `tests/verify-adapters.*` or a new `tests/compare-adapters.sh`,
`generate-adapters.ps1`, both lifecycle suites, `bin/cli.js` (the `link` message only),
`.github/workflows/ci.yml`, a new `evals/` directory (step 5, only if the spike succeeds),
`plans/README.md`.

**Out of scope**: anything plan 033 changes (see "Boundary"); new installer behaviour; the
content of the commands (plans 034-036).

## Git workflow

Branch per step: `test/<slug>` or `ci/<slug>`. Types per CONTRIBUTING.md §2: tests `test:`, CI
`ci:`; a fix a new test forces is `fix:` when it changes what a user installs (`generate-adapters.ps1`
output, a shipped hook, `bin/cli.js`), otherwise `test:`. Red commit first, fix second. No AI
attribution lines; merge commit, never squash, never an empty body.

## Steps

### Step 1: the two generators produce the same bytes

1. Red (`test:`): in the Windows job, after "Verify Generated Adapters", add a Git Bash step:
   `./generate-adapters.sh --clean && cp -r adapters "$RUNNER_TEMP/adapters-sh"`, then
   `powershell.exe -ExecutionPolicy Bypass -File ./generate-adapters.ps1 -Clean`, then
   `git diff --no-index --exit-code "$RUNNER_TEMP/adapters-sh" adapters`. Commit it alone; CI is
   expected to fail with the 7 differing files.
2. Fix (`fix:`): join with LF instead of CRLF at `generate-adapters.ps1:144`, `:204`, `:208`, and match the
   bash generator's blank lines at each section join (compare `generate-adapters.sh:25-60` and the
   `case` starting at `:198`). The bash output is the reference: it is what `npm publish` ships
   (`package.json` `prepublishOnly`).
3. Leave both `verify-adapters.*` as they are: they catch a broken generator on each platform; the
   new step catches two working generators that disagree.

**Verify**: the Windows job's compare step passes; `verify-adapters.ps1` still passes.

### Step 2: `link` and `unlink`, everywhere they can run

1. Red (`test:`), `tests/test-lifecycle.sh`, next to Test 39, each in its own sandbox with a
   sandboxed `HOME`:
   - `link --global` then `unlink --global`: links appear under `$HOME/.claude/<sub>`, then go;
     the package's file count is unchanged.
   - Stale link: link from package copy A, delete A, link from package copy B: each
     `.claude/<sub>` now points into B.
   - Real directory: `.claude/rules/` holding a user file, then `link`: the directory and file are
     untouched and the message names a command that can actually resolve it. Red today
     ("run 'unlink' first"); fix (`fix:`) the message at `bin/cli.js:734` to
     "remove or rename it first; 'bem-te-vi uninstall' removes an install made with init".
2. `tests/test-lifecycle.ps1`: the same three cases plus Test 39's. First run it once in CI and
   record what `link` does on `windows-latest`. If it throws `EPERM`, that is a product defect, not
   a test problem: STOP and report (see STOP conditions); do not paper over it in the test.

### Step 3: macOS runs the scripts on the bash Macs ship

1. Measure (`ci:`): add a first step to `test-macos` that prints `command -v bash`,
   `bash --version | head -1` and `/bin/bash --version | head -1`. Record the result in this plan
   under an "Outcome" heading.
2. Pin (`ci:`): put `/bin/bash` first in `PATH` for the job:
   `mkdir -p "$RUNNER_TEMP/bash32" && ln -s /bin/bash "$RUNNER_TEMP/bash32/bash" && echo "$RUNNER_TEMP/bash32" >> "$GITHUB_PATH"`,
   then assert `bash -c 'echo $BASH_VERSION'` starts with `3.2`. Every `#!/usr/bin/env bash`
   script, including the hooks under test, now runs on 3.2.
3. If a suite fails on 3.2: a shipped hook or `generate-adapters.sh` failing is a user-facing defect
   (`fix:`); a test script failing is `test:`. Either way the red run is the evidence.

### Step 4: the interactive menus

1. `install.sh` (`test:`), one table-driven test in `tests/test-lifecycle.sh` piping answers with
   `printf` and no `--target`/`--editor`. Equivalence partitions per menu: each valid choice
   (target 1-3, editor 1-7, operation 1-3) maps to the right scope and editor (assert the files and
   manifest entries), empty input takes the default, and one invalid value per menu gives today's
   behaviour (listed in "Current state" item 3). Use a sandboxed `HOME` so target 2 and 3 stay in
   the sandbox.
2. `install.ps1` (`test:`): first check, in CI, whether `Read-Host` reads piped stdin under
   `powershell.exe -File`. If it does, mirror the table. If it does not, test `Read-UserChoice` by
   extracting it with the PowerShell AST parser (the technique plan 033 item 6 uses for
   `Install-File`) and feeding it through a stubbed `Read-Host`.
3. CLI (`test:`), Linux only: drive the checkbox through a pseudo-terminal with util-linux
   `script -qec "node bin/cli.js init" /dev/null`, sending `\r` (accept the default: Claude Code
   only) and, in a second case, `\e[B \r` (also Cursor). Assert the installed files. If either case
   fails intermittently in three consecutive local runs, drop it and record why here.
4. The invalid-input divergence between `install.sh` and `install.ps1` is recorded, not fixed:
   aligning it is a behaviour change for Marco to decide. Note it in the pull request.

### Step 5 (spike): behavioural evals with a no-plugin baseline

**Decision for Marco (default: local and manual only)**: evals call a model on every run (3 runs
per case by default, plus a judge), so they cost money and are not deterministic. Default: the
suite lives in `evals/`, is run by hand before a release, and its JSON report is attached to the
release pull request. Alternative: a `workflow_dispatch` job with an API key secret and
`--max-cost-usd`. Never on every pull request.

1. Generate the template: `claude plugin eval init --bare qa-cases-format` and read the case
   schema it writes. Record in this plan what a case can grade with (a script, a file check, an LLM
   judge).
2. Write two cases where the package must beat the bare model, each with a deterministic grader if
   the schema allows one:
   - `/qa-cases` on a short fixture story produces test cases that pass
     `.claude/hooks/validate-tc-format.sh` (exit 0).
   - `/qa-defect` on a fixture failure separates the observed failure from the suspected defect
     (CTFL §1.2.3), the distinction `testing-guidelines.md` requires.
3. Install the plugin by name from this repository's marketplace (`claude plugin marketplace add`
   on the checkout, then `claude plugin install bem-te-vi@bem-te-vi`), so `--ablation with-without`
   runs the baseline arm, and run `claude plugin eval bem-te-vi --runs 3 --max-cost-usd <limit
   Marco sets> --json evals/results/<date>.json`.

   > **Correction, 2026-10-18.** Installing is not needed. `claude plugin eval --help` on 2.1.291
   > says a path target resolves the plugin too and adds the no-plugin baseline arm ("default:
   > with-without whenever a plugin resolves — by name, or from the target path"), and the run
   > printed "a plugin resolved from this path, so each case also runs a no-plugin baseline arm".
   > The suite runs as `claude plugin eval .` from the checkout, which also keeps the machine's own
   > Claude Code untouched, as Marco asked.
4. Record the scores of both arms and the cost under "Outcome". A case the baseline passes as well
   as the plugin tests nothing about the package; rewrite or drop it.

## Done criteria

- [ ] The Windows job compares the two generators byte for byte and passes.
- [ ] `link`/`unlink` cases run in both lifecycle suites (or Windows is recorded as a STOP).
- [ ] The macOS job prints and asserts bash 3.2 for every `env bash` script.
- [ ] Each `install.sh` menu has a valid, default and invalid case; `install.ps1` and the CLI menu
      are covered or their exclusion is recorded here with the reason.
- [ ] Step 5: either an `evals/` suite with recorded baseline and plugin scores, or a recorded
      reason it was stopped.
- [ ] `plans/README.md` row for 037 updated; the "Tests" backlog line marked as planned here.

## STOP conditions

- `link` fails on `windows-latest` without Developer Mode: a product decision (fall back to a
  junction, or fail with a message), not a test fix. Report it.
- Pinning `/bin/bash` breaks a step for a reason unrelated to bash 3.2 (a tool missing from that
  `PATH`): report rather than unpinning.
- `claude plugin eval` is missing from the Claude Code version CI or Marco uses, its case schema
  cannot express any deterministic grader, or one run costs more than the limit Marco sets.
- The plugin cannot be targeted by name, so no baseline arm runs: a score without a baseline says
  nothing about the package; stop.

## Findings rejected

- **"No tests for `link`/`unlink`"**: no longer true as stated. Plan 026 item 1 added Test 39
  (`tests/test-lifecycle.sh:1063-1106`). What remains untested is listed in "Current state" item 2.
- **"`install.sh` itself may run on a newer bash on macOS"**: not for the installer. It is
  `#!/bin/bash` and the suites execute it directly, so on macOS it runs on `/bin/bash`. The
  concern holds for the `env bash` scripts (item 4).

## Maintenance notes

- A new generator output, or a change to either generator, must keep the step 1 comparison green;
  the bash generator is the reference.
- Eval scores drift with the model. Re-run the baseline arm whenever the cases run; never compare a
  plugin score against an old baseline.

## Outcome (2026-10-18)

Done by plan-037 under "Marco asked for all remaining work on 2026-10-18". Steps 1-4 are pull
requests into `next` (#142, #144, #145, #150). Step 5 stopped. GitHub Actions stopped running after
the first round (account billing), so the evidence below is local plus the first CI round noted
per step. No pull request has a green GitHub run: every Linux, Windows and macOS job that ran
failed only at the known lifecycle Test 19/20 ("`.claude` survived uninstall after a no-manifest
upgrade"), which #146 fixes and which was not on `next`.

- **Step 1 (#142)**: red measured locally on the unfixed `generate-adapters.ps1` (Windows PowerShell
  5.1): 7 of 7 adapters differed from the bash output. After the fix all 7 are byte-identical and
  `verify-adapters.ps1` passes. In the first CI round the new "Compare Bash and PowerShell Adapters
  (Git Bash)" step passed on windows-latest. The compare uses `diff -r`, not `git diff --no-index`,
  because Git for Windows can apply autocrlf to the latter.
- **Step 2 (#144)**: Test 39b (bash) and Test 42b (PowerShell). The real-directory case was red
  ("run 'unlink' first" cannot work) and the message is fixed. `link --global` and the stale link
  already worked. Test 42b reports "not run" on a machine that cannot create a symlink, and was not
  run active anywhere: this Windows has no symlink right, and CI stopped at Test 19 before reaching
  it. Finding for Marco (not fixed, product decision): without Developer Mode or elevation,
  `bem-te-vi link` on Windows crashes with a raw `EPERM` stack trace from `fs.symlinkSync`
  (reproduced locally, Node 22). Options: junction fallback, or catch EPERM and print one line. The
  STOP condition (link failing on windows-latest) could not be tested.
- **Step 3 (#145)**: measured on macos-latest: `command -v bash` is `/bin/bash`, version
  3.2.57(1) arm64, the same as `/bin/bash`. So the runner already ran env-bash scripts on 3.2; the
  pin and the assertion now guarantee it. With bash 3.2 pinned, the hook tests, the generator check
  and the conformance suite passed; only the lifecycle suite failed, at Test 20.
- **Step 4 (#150)**: Tests 39c (19 install.sh menu runs), 42c (19 install.ps1 runs, run locally on
  Windows PowerShell 5.1) and 39d (CLI checkbox through util-linux `script`, three consecutive
  local passes, skipped where that `script` is absent). `Read-Host` reads piped stdin, so the AST
  fallback was not needed. A stub `claude` is on PATH in the menu tests, otherwise machines without
  Claude Code get a "Continue anyway?" prompt that takes the first answer. Recorded, not fixed:
  install.sh defaults or exits on invalid menu input, install.ps1 re-prompts.
- **Combined check**: a scratch merge of #146 with #142, #144, #145 and #150 passed every local
  Linux CI step including the whole lifecycle suite (the scratch tree's markdownlint failure came
  from a node_modules symlink in the scratch tree only).
- **Step 5: STOP.** `claude plugin eval` (Claude Code 2.1.224) prints "`plugin eval` is currently
  in early access" and exits 1 on this account, including `init --bare`, so no template was written
  and the case schema could not be read. No evals directory, no scores, no cost incurred. The cost
  limit Marco was to set has no default. Re-open when the account has access.

  > **Correction, 2026-10-18 (later the same day).** Re-opened by Marco's decision recorded under
  > "Status": the Claude Code in a second distribution (2.1.291) runs `plugin eval`, and the cap is
  > US$5 in total. Step 5 is done; see "Step 5 outcome" below.
- **Defaults used (Marco asked for all remaining work on 2026-10-18)**: none applied; step 5 stopped before its decision mattered.

### Decided by Marco, 2026-10-18: the two findings above

Both are fixed on branch `fix/link-and-menu-parity`, each with its red test committed first.

- **`bem-te-vi link` without the right to create a symlink** (Windows, no Developer Mode, not
  elevated). Decided: fail with one clear line that says why and what to do, exit non-zero, leave
  nothing half-linked. Code path checked first: `cmdLink` created `.claude` (`ensureDir`) and, for a
  stale link, deleted it before calling `fs.symlinkSync`, so a refusal left an empty `.claude`
  (reproduced on Windows, Node 22.12.0) and would have lost a stale link it could not recreate.
  Now `link` first creates one throwaway link (in the target folder, or the temporary folder when
  that does not exist yet) and removes it. On `EPERM` it prints, on Windows,
  `Error: cannot create symbolic links here. Windows allows them only with Developer Mode on or in
  an elevated shell: turn one on and run link again, or run 'bem-te-vi init' to install copies
  instead. Nothing was linked.`, exits 1, and has changed nothing. Other systems get the same first
  sentence and the `init` advice. Red: on Windows the CLI printed the stack trace from
  `fs.symlinkSync` (`cli.js:889`) and left `.claude`; Test 42b failed "link printed a stack trace
  instead of a message" (Windows PowerShell 5.1, local); Test 39b-4 failed the same way. Test 39b-4
  (bash) makes `fs.symlinkSync` throw `EPERM` through a `--require` preload, so `bin/cli.js` runs
  unchanged on Linux and macOS; it covers a new project and a stale link that must survive. Test
  42b now runs on a Windows machine without the right instead of reporting "not run", and its
  linking cases still run where the right exists (GitHub's Windows runners are elevated).
  - Rejected: catching the error in the loop and undoing what `link` made. A stale link removed
    before the failing call cannot be recreated without the right, so the undo cannot be complete.
  - **Follow-up, not implemented**: a junction fallback (`fs.symlinkSync(src, dest, "junction")`
    needs no privilege on NTFS) would let `link` work without Developer Mode. Junctions change what
    `unlink`, `isBemTeViLink`, `linkedIntoPackage` and plan 033 item 1's linked-folder checks see,
    so it needs its own Windows tests.
- **Invalid input in the interactive menus.** Decided: `install.sh` re-asks like `install.ps1`.
  Checked first on Windows PowerShell 5.1: `Read-UserChoice` re-asks, and when piped input runs
  out `Read-Host` returns nothing, so the menu takes its default (`9` then end of input installs;
  `1`, `7`, end of input installs into the project). `install.sh` now sends its three menus through
  one helper, `menu_choice`: it re-asks, prints `Invalid choice '<x>'. Valid options: 1, 2, 3`, and
  takes the default on an empty answer or at the end of input. Also found and aligned: at the end
  of input every `read` stopped `install.sh` with status 1 under `set -e` (no input at all exited 1
  at the operation menu; on WSL the Windows-side question did the same after the menus); the y/n
  questions now take their default there too. CLI: its only menu is the editor checkbox, whose one
  invalid answer is an empty selection; it installed nothing and printed "Done!". It now refuses
  an empty selection and stays open (`required: true`). Without a TTY nothing changes. Tests: 39c
  (22 runs; each invalid answer is followed by a valid one that is not the default; end-of-input
  cases), 39d (empty selection, then Claude Code; three consecutive local passes), 42c unchanged
  (its expectations already described `install.ps1`; only its comment changed).
  - Not changed, recorded: `install.sh`'s y/n questions read anything but `y` as no, where
    `install.ps1`'s `Read-YesNo` re-asks. The decision covered the menus only.
- **Defaults used**: none; both items were decided by Marco.

## Step 5 outcome (2026-10-18)

Run by plan-037-evals with Claude Code 2.1.291, against the checkout as a path target
(`claude plugin eval .`), so no plugin or marketplace was installed. Every eval run of the day
together cost **US$1.63** of the US$5 cap.

**What a case can grade with** (step 5 item 1). `claude plugin eval init --bare qa-cases-format`
writes `evals/qa-cases-format/prompt.md` (frontmatter `max_turns: 10`, `allowed_tools: [Read, Glob,
Grep, Skill]`) and `graders/criteria.md` (`type: llm`). The documentation
(<https://code.claude.com/docs/en/plugin-evals>) lists six grader types: `regex` (on the final reply,
the trace, the created file names or a workspace file's contents; `contains`, `not_contains` or
`count:N`), `tool_used`, `tool_order`, `file_exists`, `llm` (a judge, Haiku by default, passing on 2 of
3 votes) and `baseline`. It says "There are no custom-code graders", so
`.claude/hooks/validate-tc-format.sh` cannot itself be a grader. Each run starts in an empty working
directory with its own temporary configuration directory: the traces show only Claude Code's
built-in plugins in the baseline arm and `bem-te-vi@inline` added in the plugin arm.

**The suite**: `evals/qa-cases-format/`, one case, two `regex` graders that restate the hook's checks:

- `frontmatter.md` (weight 1): the reply starts with `---` on its first line, holds the nine keys the
  hook checks (`runbook` or its old name `cdt`) and closes the block.
- `three-complete-cases.md` (weight 2, `count:3`): exactly three `## TC-CODE-NNN:` cases, each with all
  eleven field rows filled and a Source that names an acceptance criterion or reads "Added by QA
  (reason)", each row counted only inside its own case, as the hook does.

The graders were checked against the hook before any paid run: on the `/qa-cases` command's own
three-case example and three broken copies of it (a frontmatter key removed, a Source of "added by
me", a line of text before the frontmatter), the hook and the graders agreed on all four. After the
final run the hook was also run on each of the six replies, taken from the kept traces.

**Results, final run** (`evals/results/2026-10-18.json`, `--runs 3`, `--model sonnet` for both arms so
the cap held; the judge was the default Haiku):

| Case | Plugin arm | Baseline arm | Delta | Cost (US$) |
| --- | --- | --- | --- | --- |
| `qa-cases-format` (`/bem-te-vi:qa-cases`) | 1.0 (3 of 3 pass) | 0.0 (0 of 3) | +1.0 | 0.39 |
| `qa-defect-failure-vs-defect`, rewritten (`/bem-te-vi:qa-defect`) | 1.0 (3 of 3) | 1.0 (3 of 3) | 0 | 0.34 |

The hook on the six `qa-cases-format` replies: the three plugin replies exit 0 with three
`## TC-` cases each. The three baseline replies also exit 0, but they hold no `## TC-CODE-NNN:`
heading, and the hook skips a file without one as "not a test-case file". So "passes
`validate-tc-format.sh` (exit 0)", as item 2 states it, is necessary and not sufficient; the case
requires the three complete cases as well.

**Runs that led there** (all costs are the tool's list-price estimate, judge calls included):

| Run | What it showed | Cost (US$) |
| --- | --- | --- |
| Smoke, `--runs 1` | `frontmatter.md` failed to load: a `---` inside its pattern broke the frontmatter parser; written as `-{3}` since. `qa-defect`, first version: plugin 1.0, baseline 0.8 (only because the hedge regex looked on one line; widened to 300 characters) | 0.11 |
| Smoke, `qa-cases` only | natural-language prompt: plugin 1.0 with a Skill call, baseline 0.0 | 0.12 |
| First full run (`evals/results/2026-10-18-first-run.json`) | natural-language prompt: the plugin arm never loaded the command (0 of 3 Skill calls) and scored 0.0, like the baseline. `qa-defect`, first version: 1.0 and 1.0 | 0.56 |
| Smoke, explicit `/bem-te-vi:qa-cases` | plugin 1.0, baseline 0.0; the baseline arm receives the same text, unexpanded, and writes its own format | 0.12 |
| Final run | the table above | 0.72 |
| **Total** | | **1.63** |

### Decisions and findings

- **`qa-defect` dropped.** Its first version (the developer's explanation flagged as unverified in
  the prompt) and a rewrite (the tester's "What I saw" states the explanation as observed fact) both
  scored 1.0 in both arms over three runs each: the bare model already keeps the observed failure
  apart from the suspected defect, so the case tests nothing about the package. Its prompt and
  graders are kept verbatim in both result files. The plugin also cannot carry the distinction: the
  CTFL §1.2.3 text lives in `.claude/rules/testing-guidelines.md`, and the plugin ships no rules.
- **The command has to be named.** Asked in plain words for "formal test cases", the plugin arm
  made a Skill call in 1 of 4 runs (that run passed; the other three answered without the command
  and failed), so the case invokes `/bem-te-vi:qa-cases`. Whether
  the command's description should make it load more often is content (plans 034-036), not this
  plan; recorded here for Marco.

  > **Update, 2026-10-18.** The descriptions were changed and measured; see "Plain-language request:
  > before and after the descriptions changed" below. With the new descriptions the command loaded
  > in 3 of 3 runs.
- **Result files carry the runner's identity.** The plugin arm filled the defect report's "Reported
  By" with the account's e-mail address, and the JSON holds absolute local paths. Both committed
  files have them replaced (`<account email, redacted>`, `<repository>`, `<temp>`); scores and costs
  are unchanged. Scrub every new result file the same way before committing it.
- **Isolation.** `claude plugin list` and `claude plugin marketplace list` printed the same before
  and after, `~/.claude/settings.json` and the plugin registry files kept their SHA-256, and no trust
  entry was written. `--no-publish` kept the HTML reports local; `--keep-temp` directories were
  deleted after reading.
- **Default used (Marco asked for all remaining work on 2026-10-18)**: the documented default for
  where evals run (locally, by hand, never in CI), which Marco also decided explicitly. `--model
  sonnet` for both arms was a cost choice within his cap, not a decision of his.

**Running the suite before a release** (from the repository root, with a Claude Code that has
`plugin eval`):

```bash
claude plugin eval . --runs 3 --model sonnet --max-cost-usd 2 --trust-plugin --no-publish \
  --json evals/results/<date>.json
```

Then redact the result file as above and attach it to the release pull request. Exit 1 means a case
scored below 1.0.

### Plain-language request: before and after the descriptions changed (2026-10-18)

Added by the audit follow-up on branch `fix/command-descriptions` (Marco asked on 2026-10-18 to fix
everything before going public). A second case, `evals/qa-cases-plain-request/`, sends the first
full run's natural-language prompt verbatim ("Write formal test cases for the user story below",
no slash command) with `qa-cases-format`'s two format graders and a `skill-fired` indicator
(`tool_used: Skill`, input matching `qa-cases`; the tool reports it in the plugin arm only and
leaves it out of the score). Both runs: Claude Code 2.1.291 in the second distribution, path
target (`claude plugin eval .` from the worktree), `--runs 3 --model sonnet --no-publish
--trust-plugin -j 3`, judge unused (no `llm` grader).

| Run | Descriptions | Case | Plugin arm | Skill loaded | Baseline arm | Delta | Cost (US$) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Before (`evals/results/2026-10-18-plain-request-before.json`) | as on `next` | `qa-cases-plain-request` | 0.33 (1 of 3) | 1 of 3 | 0.0 | +0.33 | 0.35 |
| After (`evals/results/2026-10-18-plain-request-after.json`) | changed | `qa-cases-plain-request` | 1.0 (3 of 3) | 3 of 3 | 0.0 | +1.0 | 0.39 |
| After, same run | changed | `qa-cases-format` | 1.0 (3 of 3) | (named) | 0.0 | +1.0 | 0.38 |
| **Total** | | | | | | | **1.12** |

- The before run repeats the finding above on the same prompt: the plugin arm loaded the command in
  1 of 3 runs, and only that run passed. With the new descriptions it loaded it in 3 of 3 runs and
  every run passed. Three runs per arm is a small sample: the result says the description now
  triggers on this phrasing, not how often it fails on others.
- The change (one commit): `qa-cases`, `qa-defect`, `qa-bdd` and `qa-automate` gained a "Use when
  asked ..." clause naming the requests users make, as the skills already had; `qa-plan` and
  `qa-explore` gained the requests they lacked (test strategy, risk register, entry or exit
  criteria, progress or completion report; exploratory testing or an exploratory session). The
  descriptions of `qa-a11y`, `qa-api`, `qa-flaky`, `qa-migrate` and `qa-release` were reviewed and
  already named their requests; unchanged. Only `qa-cases` was measured.
- Spend: US$1.12 of the US$3.30 left of Marco's cap after the earlier runs. Isolation as before:
  `claude plugin list` and `claude plugin marketplace list` printed the same before and after,
  `~/.claude/settings.json` and the plugin registry files kept their SHA-256, `--output-dir` and
  `--report` pointed outside the repository, and no `claude-eval-*` temporary directory was left.
  Both result files are redacted as above (no account e-mail appeared in these runs; paths replaced
  with `<repository>` and `<temp>`).

### Pre-release run for 4.1.0 (2026-10-20)

Marco asked on 2026-10-20 for the suite to run before the 4.1.0 export. Run with the documented
release command, from a fresh clone of `next` at `15bd4c2` as a path target, Claude Code 2.1.291 in
the second distribution: `claude plugin eval . --runs 3 --model sonnet --max-cost-usd 1.40
--trust-plugin --no-publish -j 3`, with `--json`, `--output-dir` and `--report` outside the
repository. The cap was lowered from the documented US$2 to US$1.40 so that this run and the demo
re-recording (plan 049) stayed within the US$2.50 Marco set for both. Both cases in `evals/` ran;
together they cover `/qa-cases` named and `/qa-cases` reached from a plain request, which is the
whole suite. Judge unused (no `llm` grader). Exit 0, not partial.

| Case | Plugin arm | Skill loaded | Baseline arm | Delta | Cost (US$) |
| --- | --- | --- | --- | --- | --- |
| `qa-cases-format` (`/bem-te-vi:qa-cases`) | 1.0 (3 of 3) | (named) | 0.0 (0 of 3) | +1.0 | 0.41 |
| `qa-cases-plain-request` | 1.0 (3 of 3) | 3 of 3 | 0.0 (0 of 3) | +1.0 | 0.39 |
| **Total** | | | | | **0.79** |

- Every plugin run passed both format graders; every baseline run failed both, as on 2026-10-18.
- Result file: `evals/results/2026-10-20.json`, redacted as above (the clone's path replaced with
  `<repository>`, the runs' temporary folders with `<temp>`; no e-mail address appeared). Scores
  and costs unchanged. It goes with the release pull request.
- Isolation: from the recording machine's own project folder, `claude plugin list` and `claude
  plugin marketplace list` printed the same before the first run and after the last (this run and
  the plan 049 recording), and `~/.claude/settings.json` kept its SHA-256. No `claude-eval-*`
  temporary folder was left.
- Not done this time: the hook was not run on the replies (the traces were not kept); the graders
  restate its checks, as recorded above.
