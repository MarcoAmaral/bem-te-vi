# Plan 063: `install.sh --update` on macOS leaves a tail of one editor's skills wrong

> **Executor instructions**: Branch `fix/macos-update-tail` from `main`, one pull request into
> `main`. One commit for this plan, then the diagnosis on a separate branch `diag/issue-3` that is
> never merged, then one commit of red tests and one commit for the fix. Do not write the fix before
> item 1 has named the cause: a fix for the wrong loop would pass every local run and leave the
> defect in place. Release as a normal Release Please 4.1.1.

## Status

- **Priority**: P1 (a user's update can leave part of an editor's skills deleted)
- **Effort**: M
- **Risk**: MEDIUM (installer file-safety code, plans 009-012 and 047)
- **Depends on**: plan 016 (conformance suite), plan 033 item 3 (update), plan 047 (each editor's
  own folders)
- **Category**: installer, macOS
- **Planned at**: commit `b03e9ed` (`main`), 2026-10-22
- **Issue**: [#3](https://github.com/MarcoAmaral/bem-te-vi/issues/3)
- **Outcome**: done, PR #5 (branch `fix/macos-update-tail`); see "Progress, 2026-10-23" and
  "Outcome"

## Why this matters

On GitHub's macOS runners, conformance case `052-update-moves-an-old-project-install-to-the-native-layout`
failed for `install.sh` in 2 of 5 runs of the same installer code. After `update project all`, a
contiguous tail of one editor's skill files, in `LC_ALL=C` sort order, did not match the package:

| Run | Editor | Files that differ |
| --- | --- | --- |
| 39798216738 (PR #1, `e40641a`) | Windsurf | `.windsurf/skills/qa-api/SKILL.md` to the end, 49 of 51 |
| 39850441474 (`main`, `e12b9b5`) | Cline | `.cline/skills/qa-reference/references/playwright-patterns.md` to the end, 30 of 51 |

The CLI passed the case in every run, and so did `install.sh` on Linux and Windows. 25 local runs
under bash 3.2.57 on Linux passed. The npm package does not ship `install.sh`, so only users who run
it from a clone on macOS (`/bin/bash` 3.2) are affected.

The runner's message does not tell a missing file from a changed one: `expect-tree-as-package` runs
`cmp -s`, which fails the same way for both. It prints only the last 6 lines of installer output,
so the failed runs do not show what the installer did to those files.

## Two candidate causes (neither confirmed)

Both loops read `editor_files`, which reads `find | LC_ALL=C sort` through a process substitution
nested inside the process substitution of its caller. A list cut short there gives a contiguous
tail in sort order, in whichever editor it happens to.

- **A, prune** (issue #3's hypothesis). `prune_unshipped` builds `SHIPPED` from
  `editor_files`. If the list is cut, every recorded file after the cut is "no longer shipped" and,
  since it still matches its recorded hash, is removed. The log would show
  `- Removed .<editor>/skills/... (no longer shipped)` for the tail.
- **B, install**. `install_to_editor` reads `package_files` (which calls `editor_files`). If that
  list is cut, the tail is never written. Case 052 seeds no skill file, so the tail would be
  missing, with no `Removed` line for it.

The two need different fixes, and so does a third cause neither of these covers, so item 1 decides.

## Items

1. **Diagnose on macOS** (branch `diag/issue-3`, never merged). A workflow that runs only on push to
   that branch and only on `macos-latest`, with bash 3.2 first in PATH as `ci.yml` does. A small
   matrix of jobs, each running `tests/conformance/run.sh 052` repeatedly. On that branch only:
   - `run.sh` copies each sandbox's whole `output.log` to `$CONFORMANCE_KEEP_LOGS` before it
     deletes the sandbox, and the workflow uploads that folder as an artifact;
   - `prune_unshipped` and `install_to_editor` print how many lines they read from
     `editor_files`/`package_files` for each editor (a diagnostic line, so the log shows a cut
     list directly rather than only its effect).

   **Done when** at least one failing run's log names the cause (A, B or something else), or, after
   at least 60 runs of the case with none failing, the plan records that and stops, and the
   diagnosis goes back to Marco.

2. **A test that fails without the fix.** The truncation is timing-dependent and has not been
   reproduced on Linux, so a conformance case cannot reproduce it on demand. Decide from item 1's
   finding; the likely shape is that the installer must never act on a list it has not read to the
   end (for example, `editor_files` ends with a terminator line, and a reader that does not see it
   stops without removing anything). Its red test makes the list cut short on purpose and checks
   that nothing is removed. Item 1 tells us whether a test seam like that is needed or whether a
   direct test exists.

3. **The fix**, in `install.sh` and in every other installer the same cause applies to. Read how
   `cli/bem-te-vi.js` and `install.ps1` build the same lists before deciding they need no change,
   and say in the PR which installers changed and why. Must still run on bash 3.2.

4. **Verify**: the full conformance and lifecycle suites on Linux, macOS and Windows, and the
   diagnostic workflow of item 1 run again against the fix with no failure across the same number
   of runs.

## Progress, 2026-10-23: item 1 names cause A

Run [39954501142](https://github.com/MarcoAmaral/bem-te-vi/actions/runs/39954501142) on
`diag/issue-3` (`58c8352`), 6 jobs of 10 runs of case 052 for `install.sh` on `macos-latest` under
bash 3.2. 1 of 60 runs failed (job 5). Its log:

- `DIAG prune windsurf: read 13, expected 61`: `prune_unshipped` read 13 lines of `editor_files`
  (Windsurf's 10 rule files and 3 skill files), and a separate read of the same function right
  after it returned all 61.
- 48 lines `- Removed .windsurf/skills/... (no longer shipped)`, from `qa-automate/SKILL.md` to
  `qa/SKILL.md`: the rest of the list, deleted because each still matched its recorded hash.
- Every `DIAG install` line of all 60 runs read the expected count. One failure is too few to
  call the install loop safe: it reads the same function through the same construct.

The list is cut while it is being read, not when it is produced, and the update then acts on
the cut list. Which of the two nested process substitutions loses the lines is not known.

## Outcome

- **Item 2**: lifecycle Test 71. `BEM_TE_VI_TEST_CUT_LIST=<n>`, a test-only setting, keeps the
  first n lines of the list; with 13, an update must leave every Windsurf skill file as installed,
  keep the manifest, exit non-zero and say why. Red at `5f2aa3e` (the setting in the old reading
  loop: the update removed skill files), green at `e9bb31d`.
- **Item 3**: `install.sh` only. `editor_files` no longer uses process substitution;
  `read_editor_files` reads the whole list by command substitution and accepts it only when its
  last line is an end marker; `prune_unshipped` and the non-Claude install loop act on nothing
  else. A cut list leaves that editor as it was, prints an error, and the run ends with
  "Update incomplete" and exit status 1. `cli/bem-te-vi.js` (`editorFilesFor`) and `install.ps1`
  (`Get-EditorFiles`) build the list in memory before acting on it, so they are unchanged. The
  other `< <(...)` readers (the Claude Code install loop, `adopt_known`, uninstall's folder
  cleanup) can only skip work on a short list, never remove a file, and were left as they are.
- **Item 4**: lifecycle suite and conformance (128/128) on Linux; conformance cases 050-059 and
  Test 71 under bash 3.2.57; PR #5's CI on Linux, macOS and Windows. Run
  [39966085295](https://github.com/MarcoAmaral/bem-te-vi/actions/runs/39966085295) on
  `diag/issue-3-fix` (`04e9cdc`): 300 runs of case 052 on `macos-latest`, 0 failed, no list
  refused as cut and no skill file removed. At the rate item 1 saw (1 in 60), 300 clean runs
  would occur by chance about 0.7% of the time.

## STOP conditions

- Item 1 shows a cause other than A or B: stop, record it here, and re-plan before writing a fix.
- Any change would make one installer behave differently from the others on a case the
  conformance suite runs: stop and ask.

## Rejected approaches

- **Retry the update when a file is missing afterwards.** It hides the defect: a user's
  file deleted by the first pass is not restored, only the package's own.
- **Fix both loops without diagnosing.** Both fixes would pass
  every local run, since the defect has never reproduced off macOS, so the PR could not show which
  one was needed or that either was enough.
