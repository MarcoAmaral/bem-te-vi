# Plan 053: The installer follow-ups the audit plans recorded and left open

> **Executor instructions**: Read `CLAUDE.md` section 5 and plans 033, 044, 045, 046 and 047 first.
> Branch `fix/installer-followups` from `github/next`, one pull request into `next`. Every item is
> a red test commit followed by its fix, except items I9 and I11, which add tests only (their red is
> shown against a broken copy of the installer, never committed). The three installers change
> together and stay identical in behaviour; a guarantee they share is a conformance case
> (062-069 are reserved for this plan). New lifecycle tests are appended after the last one in each
> suite (Test 65 on in `tests/test-lifecycle.sh`, Test 51 on in `tests/test-lifecycle.ps1`).
> `install.sh` must keep running on bash 3.2, `install.ps1` on Windows PowerShell 5.1. Run
> `bash ~/qa-ci-all.sh <worktree>` before reporting. Record in each source plan, with a dated note,
> that its item is done here. Update this plan's row in `plans/README.md`.

## Status

- **Priority**: P1 (I14 and I15 tell the user something false about their files; the CLI and
  `install.ps1` stop part-way over an unreadable file; I9-I11 are guarantees nothing checks)
- **Effort**: M
- **Risk**: MEDIUM (output and skip decisions in all three installers; the conformance runners
  gain one directive and accept a manifest path with a space)
- **Depends on**: plans 033, 044, 045, 046 and 047 (the contracts and cases these items extend)
- **Category**: fix, test
- **Planned at**: commit `436faa9` (`github/next`), 2026-10-19 (line numbers below are at that
  commit)
- **Decided by Marco, 2026-10-19**: everything is developed and fixed before the 4.1.0 export
  unless it can only be done after; the installer follow-ups recorded as open in the plans are
  done now.

## Why this matters

The audit plans of 2026-10-18 fixed what they were asked to fix and recorded, honestly, what they
found on the way and did not change. Each of those records is still true on `next`, checked again
on 2026-10-19 before this plan was written. Three of them make an installer report something false
about the user's files, or stop part-way; three are guarantees the suites claim but do not check.
None of them is allowed to ship in a public release.

## The follow-ups

Each was reproduced on `436faa9` before it was written down here.

- **I13. The WSL step exits without its message** (plan 045, "Found and not changed";
  `install.sh:1663`). `WIN_HOME=$(wslpath "$(cmd.exe ...)")` is an assignment whose command
  substitution fails when `cmd.exe` or `wslpath` fails, so `set -e` ends the run there, exit 1,
  before the "could not resolve Windows home directory" branch below it can run. Reproduced: with
  both stubbed to fail and "y" to "Also install to Windows-side user profile?", the output ends at
  "WSL detected." and the exit status is 1.
- **I14. An editor is reported installed when nothing was written for it** (plan 045, "Found and
  not changed"; plan 046 item 1; `install.sh:1229`, `:1253`; `install.ps1:1271`, `:1308`).
  `install_to_editor` prints "✓ \<editor\> (\<scope\>): \<folders\>" whatever `install_file`
  decided; `install.ps1` does the same with "Installed (...)". The CLI prints an editor's line only
  when at least one file was written (`installNonClaudeEditor`), and a Claude Code folder's line
  only when the folder is not a link. Reproduced: with `.cursor/rules` and `.cursor/skills` both
  linked, `install.sh` printed both "Skipped ... it is a symbolic link" lines and then
  "✓ Cursor / Trae (project): .cursor/rules/ and .cursor/skills/"; the CLI printed no such line.
- **I15. An unreadable recorded file is reported as changed** (plan 045, "Found and not changed";
  `install.sh:963`, `:1161`). Uninstall and update keep it, which is safe, but say "changed since
  it was installed". Checking the other two installers as the item asks: the CLI does not get that
  far. `fileMatches` reads the file and throws `EACCES`, so `bem-te-vi uninstall` stops with a
  stack trace, exit 1, and the manifest is not rewritten; `bem-te-vi init` over an unreadable
  destination stops the same way in `backupDest`. `install.ps1`'s `Get-Sha256` calls
  `.Hash.ToLower()` on nothing (plan 045 item 1), so it is expected to stop too; to be confirmed on
  Windows with a file whose read is denied.
- **I9. Lifecycle Test 46b proves nothing** (plan 045, item 3 outcome;
  `tests/test-lifecycle.sh:1820-1843`; `install.sh:637`). Its `mktemp` stand-in intercepts
  `*.qa-skills-manifest.tmp.*`, but `install.sh` has named that file
  `$MF.tmp.$$.$RANDOM$RANDOM$RANDOM` since `f7cf963` and never calls `mktemp` for it, so the
  stand-in never runs and the test passes whatever `write_exclusive` does.
- **I10. Exclusive create is untested in two installers** (plan 045, item 3 outcome; plan 033,
  follow-up 2). Nothing plants a link at the CLI's manifest temp file
  (`cli/bem-te-vi.js:288-290`, random name, `"wx"`), and nothing runs `install.ps1` against a link
  planted at a backup name, a `.link-target` name or the manifest's temp name
  (`install.ps1:788-789`, `:914-925`); its guarantee rests on `FileMode.CreateNew` alone.
- **I11. A manifest path with a space is untested in all three installers** (plan 047, review
  finding 3; plan 010 item 2). The conformance runners already put every project in a folder named
  `project [1]`, so a space in the base is covered (plan 033 item 5). A space in a recorded path is
  not: the runners' manifest directives take exactly three words, so no case can record one.

## Steps

1. **I13.** Lifecycle Test 65, on WSL only (elsewhere `install.sh` never reaches the step and the
   test says it was skipped): an install with `cmd.exe` failing, and an uninstall with `wslpath`
   failing, each answering "y" to the Windows-side question. Each must print "could not resolve
   Windows home directory", write nothing outside the sandbox and exit 0, as the branch intends.
   Fix: the assignment falls back to an empty `WIN_HOME` when the substitution fails.
2. **I14.** Conformance case 062: the five Claude Code folders and both Cursor folders are links,
   except `.claude/hooks`, whose two files are seeded from the package and read-only; install
   Claude Code, then Cursor. Nothing is written, nothing recorded, and no installer prints its
   success line for either editor (`scaffolded` for Claude Code in the two shell installers,
   `✓ hooks/` in the CLI, `.cursor/rules/ and .cursor/skills/` in all three). Lifecycle Test 51
   (`install.ps1`) repeats the Cursor half with junctions, so `install.ps1` is checked on a Windows
   machine that cannot create a symlink. Fix: `install.sh` and `install.ps1` print an editor's line
   only when `install_file` wrote at least one of its files; the CLI prints a Claude Code folder's
   line only when it wrote a file in it.
3. **I15.** A new runner directive, `seed-unreadable: <path>` (Linux and macOS: `chmod a-r`;
   Windows: a deny rule for reading the file's data, for the current user), in both runners, their
   self-tests and the README. Conformance cases 063 (uninstall keeps an unreadable recorded file,
   says it cannot be read, removes the rest) and 064 (install and update skip an unreadable
   destination, and update keeps an unreadable file the package stopped shipping, each saying it
   cannot be read). Fix, the same in all three: before a file is hashed, a file that cannot be read
   is skipped on install ("Skipped \<path\> — destination cannot be read (existing file left
   untouched)", the wording `install.sh` already uses) and kept on update and uninstall
   ("Kept \<path\> — destination cannot be read", counted as kept, its entry dropped as for a
   read-only file).
4. **I9.** Test 46b plants the link at the exact name `install.sh` will use. A `BASH_ENV` file runs
   in the installer's own shell before the script: it knows `$$`, seeds `$RANDOM`, plants a link to
   a victim file at the first name `manifest_write` will draw, and seeds `$RANDOM` again, so the
   script draws the same numbers. The test fails if the victim changes or the link is gone. A
   control run of a copy of `install.sh` whose `write_exclusive` opens any name must write through
   the link; if it does not, the plant missed and the test fails rather than pass vacuously.
5. **I10.** Lifecycle Test 66 (bash) does the same for the CLI with a preload that makes the first
   six-byte `crypto.randomBytes` call return known bytes, plants the link at
   `<manifest>.tmp-<pid>-<hex>`, and records that the CLI opened that name. Lifecycle Test 52
   (`install.ps1`) loads `install.ps1`'s functions, pins `Get-Date` and the manifest's temp name,
   and plants a link at the backup name, the `.link-target` name and the temp name: a junction
   everywhere, a file symlink to a victim where the machine may create one (otherwise that part
   reports "not run", as the conformance runner does). Each name must be passed over, the link and
   its target left as they were, and the run must finish. If a taken temp name stops an installer
   where `install.sh` picks another name, that is a divergence: red, then the same retry as
   `install.sh` (up to 20 names).
6. **I11.** The four manifest directives take the path as the rest of the line after the scope and
   the editor, so it may hold a space, in both runners, with a self-test each way. Conformance cases
   065 (install of another editor rewrites the manifest and keeps entries with a space in their
   path whole; uninstall removes the unchanged one and reports the changed one by its whole path)
   and 066 (update removes an unchanged recorded file with a space in its path that the package does
   not ship, and keeps a changed one). Prove each can fail against an installer that cuts the path
   at its first space.

## Done criteria

- [x] Each fix is preceded by a committed test that fails on `436faa9`'s installers; the failure is
      quoted below and in the pull request.
- [x] Test 46b fails against a `write_exclusive` that opens any name, and passes against the real
      one.
- [x] Cases 062-066 pass for `install.sh` and the CLI on Linux and under bash 3.2.57, and for
      `install.ps1` and the CLI on Windows PowerShell 5.1 (062 is "not run" there without the
      symlink right, which Test 51 covers with junctions).
- [x] Plans 010, 033, 045, 046 and 047 carry a dated note where each item was recorded.
- [x] `bash ~/qa-ci-all.sh` passes on Linux, bash 3.2.57 and Windows PowerShell 5.1.

## STOP conditions

- A fix would change the manifest or known-hash format, or let an installer write, back up or
  delete a file it does not today.
- The runners cannot make a file unreadable on Windows without elevation: then I15's cases skip
  `install.ps1` with the reason, and Test 52's pattern is used instead.
- A planted link cannot be placed at the exact name an installer uses without changing the
  installer: record it and stop that item.

## Outcome (2026-10-19)

Branch `fix/installer-followups`, from `next` at `436faa9`, merged with `next` at `aa9c92c` (plan
for the CLI help and Node engines, #197) before the final run. Plan number 053: no plan 052 was on
`next` or in an open pull request when this plan was written; 052 was left for a parallel agent.

**Red, quoted from the runs before each fix** (Linux unless it says Windows PowerShell 5.1):

| Item | Test | Failure before the fix |
| --- | --- | --- |
| I13 | Lifecycle Test 65 | `✘ install with a failing cmd.exe did not report the Windows home it could not resolve (exit 1)`, output ending at `WSL detected.`; with the install case taken out, `✘ uninstall with a failing wslpath did not report ... (exit 1)` |
| I14 | Case 062 | `install.sh FAIL ✘ output contains 'scaffolded' ✘ output contains '.cursor/rules/ and .cursor/skills/'`; `cli FAIL ✘ output contains '✓ hooks/'` |
| I14 | Lifecycle Test 51 (Windows) | `Test 51: install.ps1 reported Claude Code installed with nothing written.` |
| I15 | Case 063 | `install.sh FAIL ✘ output lacks 'destination cannot be read' ✘ output contains 'changed since'`; `cli FAIL ✘ exit 1, expected 0 ✘ should not exist: project:.cursor/skills/qa/SKILL.md ✘ should not exist: home:.claude/rules/test-tools.md` |
| I15 | Case 063 (Windows) | `install.ps1 FAIL x exit 1, expected 0`; the run ended `[!!] Operation failed: The file '...\bem-te-vi.mdc' cannot be read: Access to the path ... is denied` (Portuguese Windows; translated) |
| I15 | Case 064 | `install.sh FAIL ✘ output contains 'changed since'`; `cli FAIL ✘ manifest should not record: project cursor .cursor/rules/retired.mdc ✘ output lacks 'Skipped .cursor/rules/bem-te-vi.mdc'`; Windows: `install.ps1 FAIL x exit 1, expected 0 x manifest lacks: home claude .claude/rules/test-tools.md` |
| I10 | Lifecycle Test 66 | `✘ the CLI exited 1 over a link at its manifest temp name, where install.sh picks another name`, `Error: EEXIST: file already exists, open '.../.qa-skills-manifest.tmp-<pid>-666666666666'` |
| I10 | Lifecycle Test 52 (Windows) | `Exception calling "Open" with "3" argument(s): "Access to the path '...\security-qa.md.qa-skills-backup-20261019T050200Z' is denied."`, `FullyQualifiedErrorId : UnauthorizedAccessException` (translated) |
| I10 | Lifecycle Test 52, CLI part (Windows) | `Test 52: the CLI exited 1 over a junction at its backup name`, `Error: EPERM: operation not permitted, copyfile` |

**Tests that change no behaviour, shown able to fail:**

- **I9.** With `write_exclusive` broken in the checkout (its existence check removed and
  `set -C` dropped), the new Test 46b fails: `✘ install.sh wrote the manifest through a link
  planted at its temp file's name`. The old Test 46b, run against the same broken installer,
  printed `✔ Test 46 passed successfully!`. The control is part of the test, not only of this
  record: a copy of `install.sh` whose `write_exclusive` is replaced by one that opens any name
  must write through the planted link, or the test fails. Checked with the installer run by bash
  3.2.57 too (the plant hits the name and the control writes through it). One finding on the way:
  in a `BASH_ENV` file bash 3.2 sets `$0` to the shell, not the script, so the plant cannot select
  the installer by name; it unsets `BASH_ENV` after planting instead.
- **I11.** Cases 065 and 066 pass for all three installers. Against copies that cut each manifest
  line after the first word of its path (as an `awk '{ print $3 }'` reader did): `install.sh`, the
  CLI and `install.ps1` all fail both, `✘ should not exist: project:.cursor/rules/my notes.mdc`,
  `✘ output lacks 'Kept .cursor/rules/old  rules.mdc'` (066 also `output lacks 'Removed
  .cursor/rules/my notes.mdc (no longer shipped)'`). A CLI that collapses repeated spaces fails 065
  (`output lacks 'Kept .cursor/rules/old  rules.mdc'`). The runner change: the new self-test check,
  run against the old `run.sh`, failed `✘ manifest-path-with-a-space: the runner rejected a
  well-formed case`.
- **`seed-unreadable`.** A mutant `run.sh` that accepted the directive without checking its path
  failed the new self-test four ways (`unreadable-climbs-out: the runner accepted a malformed
  case`, `... changed the mode of a file outside its sandbox`, and two more).

**What changed, item by item.**

- **I13.** `WIN_HOME=$(...) || WIN_HOME=""`: the message is printed and the run finishes with the
  Linux-side result, as the branch intended.
- **I14.** `install.sh` (`FILES_WRITTEN_COUNT`) and `install.ps1` (`$script:FilesWritten`) count
  what their file installer wrote; each editor's line is printed only when the count grew. The
  CLI already did this for every editor but Claude Code; its per-folder line now follows the same
  rule (`copyDirSafe` returns whether it wrote), instead of only checking that the folder is not a
  link. Case 062 is "not run" on a Windows machine without the symlink right; Test 51 covers
  `install.ps1` there with junctions.
- **I15.** The same in all three, read-only first, then unreadable: install and update skip an
  unreadable destination ("Skipped \<path\> — destination cannot be read (existing file left
  untouched)"), update and uninstall keep one ("Kept \<path\> — destination cannot be read",
  counted as kept, entry dropped), the pre-manifest uninstall keeps one the same way, and the
  pre-manifest update never adopts one. A file counts as unreadable only when opening it is
  refused (`[ -r ]`; `EACCES` or `EPERM`; `UnauthorizedAccessException`), so a missing file or a
  dangling link is not. `install.ps1` reads the file to decide; its update no longer hashes an
  unreadable destination before deciding. The runners gained `seed-unreadable` (`chmod a-r`; on
  Windows a rule denying the current user `ReadData`, removed before the sandbox is deleted).
  Plan 045 had said the runners could not make a file unreadable on every platform; on Windows
  PowerShell 5.1 the deny rule needs no elevation.
- **I9.** As above.
- **I10.** Test 66 (CLI, Linux and macOS) and Test 52 (`install.ps1`, and the CLI's backups, on
  Windows). Two divergences found and fixed, each red first: a taken manifest temp name stopped
  the CLI (`EEXIST`) and `install.ps1` (an exception from `CreateNew`), where `install.sh` draws
  another; both now draw another, up to 20. And on Windows a folder or junction at a backup name
  stopped `install.ps1` (`Write-ExclusiveFile` took only an `IOException` as "taken", and a
  folder gives access denied) and the CLI (`COPYFILE_EXCL` gives `EPERM`); both now take any
  failure on a name that exists as "taken". Case 015's comment, which listed these gaps, carries a
  dated note naming the tests that now close them.
- **I11.** The four manifest directives take the path as the rest of the line, in both runners;
  cases 065 and 066.

**Local CI**, on `afd0d3b` (the code as merged with `next`; later commits change only plans):
`ALL LOCAL CI (installer-followups @ afd0d3b): linux=PASS mac=PASS windows=PASS`, with
`LOCAL CI: 23 passed, 0 failed`, `MAC (bash 3.2) CI: 5 passed, 0 failed` and on Windows
`Conformance: 82/82 passed, 0 failed, 0 skipped, 20 not run` (the symlink cases).

**Not run here.** This Windows machine cannot create a symbolic link: the file-symlink and
`.link-target` parts of Test 52 report "not run", and case 062 is "not run" for both installers on
Windows. GitHub CI, which has that right, is not run for pull requests into `next` (local CI only,
Marco, 2026-10-18), so those parts have not run anywhere yet. The `install.ps1` red for the
manifest temp name was not run separately: the backup part failed first.

**Defaults used (Marco asked for all remaining work on 2026-10-18)**: none needed a decision. The
retry on a taken temp name and the "taken" reading of an access-denied name follow the parity rule
(`CLAUDE.md` section 5); the dropped entry of an unreadable kept file follows the read-only one.

**Found and not changed (outside this plan).**

- `install.ps1` defines `Copy-QAFile` (`:191`) and never calls it.
- With every destination skipped, `install.sh` and `install.ps1` still end with "Installation
  successful!" and the next steps, and the CLI with "Done! Open your editor and type /qa"; I14 is
  only the per-editor line.
- In update, `install.sh` counts a skipped destination (a folder, an unreadable file) as kept even
  when the manifest did not record it; `install.ps1` and the CLI count it only when recorded. Only
  the number in "N file(s) kept as-is" can differ.

> **Note, 2026-10-19 (plan 057).** All three are fixed in plan 057: `Copy-QAFile` is removed, the
> three installers say "Nothing was installed: every destination was skipped (see above)." when
> nothing was written (conformance case 067, lifecycle Test 51), and `install.sh` counts only a
> recorded destination as kept (case 068).
