# Plan 046: Fix what the code audit found in `bin/cli.js`

> **Executor instructions**: Branch `fix/cli-audit` from `github/next`, one pull request into
> `next`. Every behaviour change is red first: the failing test or conformance case is its own
> commit, quoted below, and the fix follows. Edit only `bin/cli.js`, the CLI's tests, conformance
> cases 038-043 and this plan; a change another installer needs is reported, not made. Keep the
> file-safety contract (CLAUDE.md section 5). Run `bash ~/qa-ci-all.sh <worktree>` on all three
> platforms before reporting.

## Status

- **Priority**: P1 (items 1 and 2 lose or crash on the user's files; launch blockers)
- **Effort**: M
- **Risk**: MEDIUM (installer behaviour; item 4 changes what `link` creates on Windows)
- **Depends on**: the code audit of 2026-10-18 (the auditor's probes `probe1.sh` and `probe3.sh`);
  plans 033 (linked-folder checks, refused options) and 037 (the `link` refusal and its junction
  follow-up)
- **Category**: fix, installer
- **Planned at**: commit `80ee1dd`, 2026-10-18
- **Decided by Marco, 2026-10-18**: fix every finding before the public launch, the junction
  fallback included.
- **Outcome**: done, #182 (branch `fix/cli-audit`, into `next`), see "Outcome" below

## Why this matters

The audit ran the three installers side by side and found five places where the CLI does
something the shell installers do not. Two of them touch the user's files: a folder where the
CLI expects a file crashes the run part-way, and uninstall deletes empty folders the package never
made. The other three are a missing `--version`, a `link` that cannot work on a default Windows
machine, and a different word for the same update outcome.

## The findings (line numbers at `42d3ded`)

1. **A destination that is a folder** (`bin/cli.js:447-482`). `installFile` handled a link and a
   file; for a folder `lst.isFile()` is false, so it fell through to `copyFileSync`, which threw
   `EISDIR`: an uncaught stack trace, exit 1, and with `--editor all` every editor after Cline was
   never installed. Cline also reads a `.clinerules` folder, so this is an ordinary project layout.
   Uninstall already skips such an entry (`:568`, `if (!st.isFile()) continue`): confirmed, it
   leaves the folder alone, as `install.sh`'s `[ -f "$FILE" ] || continue` does.
2. **Uninstall deletes the user's own empty folders** (`:842`).
   `removeEmptyDirsBottomUp(targetClaude)` walked the whole `.claude` tree, so `.claude/projects`
   (Claude Code's own) and a user's `.claude/my-notes/drafts` disappeared. `install.sh`
   (`:1205-1211`) and `install.ps1` (`:623-651`) prune only the five folders the package installs
   into, the emptied folders under `skills/`, and `.claude` itself.
3. **No `--version`**. `node bin/cli.js --version` printed `Error: unknown command '--version'`
   and exited 1; only `--help` showed the version.
4. **`link` on Windows without Developer Mode** (plan 037, "Follow-up, not implemented"). It stops
   with a clear message since #172, but a default Windows machine cannot link at all. A directory
   junction (`fs.symlinkSync(src, dest, "junction")`) needs no privilege on NTFS.
5. **Update over a destination that became a symlink** (probe3 J). The CLI hashed the content
   through the link, so it reported "Refreshed" (or nothing, when the linked copy matched), where
   `install.sh` and `install.ps1` report "Restored ... (was missing)".

## Steps

1. A folder destination: skip it with one line, write nothing into it, record nothing, carry on.
   In update, count such a recorded file as kept. Do not report an editor installed when its file
   was skipped.
2. Uninstall prunes only what `install.sh` and `install.ps1` prune, and only when the claude
   editor is uninstalled. Red first with conformance case 038, which runs every installer.
3. `--version` and `-v`, as the first word only, print `bem-te-vi <version>` and exit 0; after a
   command they stay unknown options (plan 033 item 4). Help and README list them.
4. `link` tries a symlink, and on Windows falls back to a junction on `EPERM`. Check, on a real
   Windows machine without the right, that every linked-folder check sees a junction as a link.
   Keep the clear message for a junction that fails too.
5. Measure the content before update only for a regular file, as the shell installers do. Red
   first with conformance case 039.

## Done criteria

- [x] Conformance cases 038 and 039 red for the CLI only, green after.
- [x] Lifecycle Tests 60-62 (bash) red before their fix, green after.
- [x] Lifecycle Test 42b (PowerShell) runs `link` with real junctions on a Windows machine without
      the right to create a symlink.
- [x] `bash ~/qa-ci-all.sh` run on all three platforms; result recorded below.

## STOP conditions

- A fix needs a change to `install.sh` or `install.ps1`: write the case, report the failure, leave
  the file to its owner.
- Junctions turn out to behave differently from symlinks for any check in `bin/cli.js`: stop and
  report rather than special-casing them.

## Outcome (2026-10-18)

- **Item 2.** Red, conformance case 038 (`tests/conformance/run.sh 038`):
  `install.sh pass`, `cli FAIL ✘ missing project:.claude/my-notes/drafts ✘ missing
  project:.claude/projects`. The case needs an empty folder, which no directive could make, so the
  runners gained `seed-dir:` (both self-tests cover it). Fixed: `removeClaudeDirsIfEmpty` removes
  the emptied folders under `skills/`, the five package folders and `.claude`, each only when empty
  and never a link, and only when the claude editor is uninstalled.
- **Item 5.** Red, conformance case 039: `install.sh pass`, `cli FAIL ✘ output lacks 'Restored
  .claude/rules/security-qa.md (was missing)'` (and the same for `test-tools.md`). Fixed:
  `installedHash` returns null for anything that is not a regular file, so a link is reported
  restored.
- **Item 1.** Red, lifecycle Test 60: `✘ 'bem-te-vi init --editor all' exited 1 over a .clinerules
  folder`, with `code: 'EISDIR', syscall: 'copyfile'`. Fixed: `installFile` skips a folder (or any
  other non-file) with `! Skipped <path> — destination is a directory, not a file (left
  untouched)` and returns false; `installNonClaudeEditor` prints its `✓` only when it wrote the
  file; update counts the skipped file as kept; a folder named like a hook keeps its mode. The
  shared behaviour is conformance cases 044-049, written by agent ps1 (renumbered from 026-027 by
  the coordinator): the CLI is to pass them when they land on `next`.

  > **Correction, 2026-10-18 (later the same day).** Agent ps1's cases arrived as 044
  > (directory-destination-skipped) and 045 (uninstall-keeps-a-recorded-path-now-a-directory), on
  > `fix/install-ps1-audit`. Run in a scratch merge of that branch with this one, 045 failed for
  > the CLI, `✘ output lacks 'is a directory'`: uninstall dropped such an entry silently. The
  > CLI now uses `install.ps1`'s wording, `Skipped <path> — it is a directory; nothing was written
  > into it` on install and `Kept <path> — it is a directory` (counted as kept) on uninstall.
  > Lifecycle Test 60 also found the pre-manifest fallback threw `EISDIR` (syscall read) on a
  > folder at a package path and stopped uninstall: red, then fixed with the same `Kept` line. In
  > the scratch merge, 044 and 045 pass for the CLI on Linux and for the CLI and `install.ps1` on
  > Windows PowerShell 5.1; `install.sh` fails both (agent sh's file).

  **2026-10-19: done in plan 053** (I14). `install.sh` and `install.ps1` now print an editor's
  line only when they wrote one of its files, as `installNonClaudeEditor` does, and the CLI's
  Claude Code folder lines follow the same rule (conformance case 062).
- **Item 3.** Red, lifecycle Test 61: `Error: unknown command '--version'`, exit 1. Fixed;
  `--versio`, `-V` and `init --version` stay refused.
- **Item 4.** Red on Windows PowerShell 5.1 without Developer Mode (local, Node 22.12.0): Test 42b
  failed `bem-te-vi link failed with exit status 1 on this machine, which can create a symlink or a
  junction`; on Linux, Test 62 (a preload reports `win32` and refuses `dir` links) failed `✘ link
  exited 1 where a junction could be made`. Checked first on that Windows machine: Node's `lstat`
  reports a junction as a symbolic link, `readlink` gives its target with a trailing backslash
  (which `path.resolve` drops), `realpath` resolves it, `readdir` types it as a link, and `rmSync`
  and `rmdirSync` remove the junction and leave its target. So `isSymlink`, `linkedAncestor`,
  `isBemTeViLink`, `linkedIntoPackage` and the empty-folder cleanup needed no change; only `link`
  did. Fixed: `dirLinkType` probes a symlink, then on Windows a junction; `link` says when it uses
  junctions; a junction that fails too gives the old message plus the error code. Test 42b now runs
  every linking case with junctions there: link, `init` and uninstall over them leave the
  package's hashes unchanged, unlink removes them, a foreign junction is kept, links to a removed
  package survive uninstall and unlink, and link refreshes them.
  - **Finding for agent ps1 (not fixed here, `install.ps1` is theirs).** With `link` now working
    on this machine, lifecycle Test 42 (install.ps1 over the folders `link` made) runs instead of
    being skipped, and fails: `install.ps1 did not suggest 'bem-te-vi unlink' for a bem-te-vi
    link`. `Write-LinkedDir` compares the link's `.Target`, and a junction Node made has a trailing
    backslash (`...\.claude\rules\`), so `EndsWith("/.claude/rules")` is false. `Test-IsLink`
    (the `ReparsePoint` attribute) does see the junction, so nothing was written or deleted
    through it: the package's 49 files were unchanged. The fix, verified locally on a copy, is one
    line after `if ($target -is [array]) ...`:
    `if ($target) { $target = $target.TrimEnd([char]92, [char]47) }`. With it, Tests 42, 42b and
    the rest of `test-lifecycle.ps1` passed on Windows PowerShell 5.1.
  - `install.sh` is not run on Windows by any supported path, so it needs no junction handling.
- **Merged with plan 043 (#181), 2026-10-18.** Plan 043 installs each non-Claude editor's skill
  references under `.bem-te-vi/<editor>/` beside its adapter. They still install when the adapter
  itself is skipped as a folder, as `install.sh` and `install.ps1` install them after their own
  `install_file` call; only the `✓` line depends on the adapter. Test 60 now checks that the
  `.clinerules` path is never recorded, rather than that no Cline entry exists. Uninstall keeps
  plan 043's removal of emptied `.bem-te-vi/<editor>/` folders, which is separate from the
  `.claude` pruning of item 2.
- **Defaults used (Marco asked for all remaining work on 2026-10-18)**: none needed a decision.
  The wording of the folder skip line is new (no shared phrase existed to reuse), so no case
  asserts it.
