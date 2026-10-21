# Plan 044: `install.ps1` fixes from the pre-launch code audit

> **Executor instructions**: Read `CLAUDE.md` §5 ("Installer File-Safety Contracts") first. Every
> behaviour change starts with a failing test, committed red before its fix; quote the failure in
> the pull request. Only `install.ps1`, `tests/test-lifecycle.ps1` and conformance cases 044-049
> change here; a behaviour the other installers must share is written as a conformance case and
> left to plans 045 (`install.sh`) and 046 (`bin/cli.js`). Run `bash ~/qa-ci-all.sh <worktree>`.

## Status

- **Priority**: P0 (items 1-2), P1 (items 3-5, 7, 8), P2 (item 6)
- **Effort**: M
- **Risk**: MEDIUM (items 1 and 2 change what the installer skips, writes and records)
- **Depends on**: plan 033 (the linked-folder and manifest contracts kept here)
- **Category**: bug
- **Planned at**: commit `42d3ded` (line numbers below), 2026-10-18; done on `next` at `80ee1dd`,
  where `install.ps1` is unchanged from `42d3ded`
- **Decided by Marco, 2026-10-18**: fix every finding before the public launch; delete
  `Write-NextSteps` (item 6, left open by plan 033 item 8.5).
- **Default used (Marco asked for all remaining work on 2026-10-18)**: none needed; no item had an
  open decision.

## Why this matters

The audit before launch ran `install.ps1` on Windows PowerShell 5.1 and found seven defects. Two
lose track of the user's files: a project inside OneDrive has every folder treated as a symbolic
link, and a folder where the package puts a file (Cline documents `.clinerules/` as one) aborts
the run and leaves every file installed before it unrecorded, so uninstall can never remove them.

## The findings

1. **OneDrive folders treated as symbolic links.** `Test-IsLink` (`install.ps1:304-309`) tested
   the raw `ReparsePoint` attribute. OneDrive's Files-On-Demand sets it, with a cloud tag, on every
   folder it syncs: 400 of 400 folders sampled under a real OneDrive carry it, none has a
   `LinkType`. `Get-LinkedAncestor` (`:899-909`) then skipped real folders as links.
2. **A destination that is a directory.** `Install-File` (`:995-1011`) passed the folder to
   `Backup-Destination`, whose `Get-Sha256` (`:710`) got no hash: "You cannot call a method on a
   null-valued expression", exit 1. The manifest is buffered until `Save-ManifestBuffer` (`:1622`),
   so every file installed earlier in the run was left unrecorded. `-Uninstall` stopped the same
   way on a recorded path that is now a folder.
3. **`-Target global -Uninstall` without git on PATH** stopped with exit 1 after removing the
   files: `Purge-GitHook` (`:541`) and `Register-GitHook` (`:461`) called
   `git config --global core.hooksPath` directly, and only `Register-GitHook` is wrapped (`:1171`).
   `install.sh:1142` reads the value as empty.
4. **Scope inferred from the folder.** `$isGlobal = ($BaseDir -eq $env:USERPROFILE) -or ($BaseDir
   -eq $HOME)` (`:595`, `:1185`, `:1222`, and `:1610` for the commit offer) made `-Target project`
   run from the home folder a global install: Cline and Copilot skipped, Windsurf written to its
   global path.
5. **Hard-coded editor paths** for the commit offer (`:1608-1619`), beside the editor map.
6. **Dead `Write-NextSteps`** (`:1398`), still naming `INSTALL.md`.
7. **Commit offer paths not checked.** The audit read the offer as taking manifest paths without
   `Test-SafeManifestRel`, and running only when `.git` is a folder. That describes `install.sh`
   (`git_commit_and_push`, plan 045). In `install.ps1` the offer listed the package's own paths
   (item 5), and `Test-Path '.git'` already accepted a `.git` file. Applied here as: commit what
   the manifest records, each path checked by `Test-SafeManifestRel`, and keep accepting a `.git`
   file (a worktree).
8. **Found while writing the test for item 7: `-Editor` ignored in an interactive run.** `Main`
   asked `$PSBoundParameters.ContainsKey('Editor')` (`:1526`), which inside a function holds the
   function's own parameters, so the editor menu always showed and its default, Claude Code,
   replaced the editor asked for. `install.sh` skips the menu when `--editor` is given.

## Steps

1. Conformance cases 044 (a destination that is a directory is skipped with one line saying "is a
   directory", nothing written into it or recorded for it, the rest installed and recorded) and 045
   (uninstall keeps a recorded path that is now a directory, says so, drops its entry, removes the
   rest). Then `Install-File` skips a folder that is not a link, `Uninstall-Recorded` and
   `Remove-IfMatches` keep one, and `Test-VersionConflict` no longer prompts about one.
2. `Test-IsLink` keeps the attribute check, then reads the tag through
   `[Microsoft.PowerShell.Commands.InternalSymbolicLinkLinkCodeMethods]::GetLinkType`, the method
   behind PowerShell's own `LinkType` property, given the path rather than an item, so a dangling
   link is still recognised. A link is `SymbolicLink` or `Junction`; a tag it cannot read is
   treated as a link, the cautious answer it gave before.
3. `Install-ToDirectory` saves the manifest in a `finally` block around the deployment.
4. Both `core.hooksPath` reads go through `Invoke-GitQuiet`.

   > **Note, 2026-10-20, plan 061 S1.** This audit did not record that the same global
   > `Purge-GitHook` removed the hooks folder and `~/.git-templates` whenever `Get-ChildItem`
   > listed nothing in them, a user's own `core.hooksPath` folder included. It now removes only the
   > hook file, as `install.sh` does (lifecycle Test 54).
5. The scope comes from `-Target`: `Install-ToDirectory` passes its `$Scope` to
   `Install-ForEditor`, `Update-ForEditor`, `Add-KnownFiles`, `Get-PackageFiles` and
   `Uninstall-ForEditor`.
6. The commit offer (`Invoke-GitIntegration -BaseDir`) commits each manifest path that passes
   `Test-SafeManifestRel` and is still a file, plus the manifest: what `install.sh` commits. The
   hard-coded list is gone.
7. `$Script:EditorGiven` is read at script level; `Main` uses it.
8. Delete `Write-NextSteps`.

## Done criteria

- Cases 044 and 045 pass for `install.ps1`; lifecycle Tests 44-49 pass; every earlier test and
  case still passes.
- `grep -n 'USERPROFILE) -or' install.ps1` and `grep -n Write-NextSteps install.ps1` find nothing.

## Rejected approaches

- **Reading the reparse tag with `Add-Type` and `FindFirstFile`** (its `dwReserved0` is the tag).
  Documented Win32, but it compiles C# on every run, which costs about a second and is blocked
  where policy stops `csc.exe` in the temporary folder. `GetLinkType` ships with every PowerShell
  and already answers for `Get-Item`'s `LinkType`.
- **Asking `Get-Item` for `LinkType`.** The comment at `:302` records that Windows PowerShell 5.1's
  `Get-Item` may not find a dangling link; calling `GetLinkType` on the path avoids the lookup.
- **Commit-offer paths from the editor map** (item 5 as worded). The map gives every path the
  package might write, including one the run skipped: a `.clinerules` folder went to `git add`
  with the user's rules in it (Test 49 red). The manifest records only what was installed.
- **Keeping the manifest entry of a recorded path that is now a folder.** A folder there is no
  longer the package's file; the entry is dropped as it is for a file kept because it changed,
  which is what `install.sh` already did (silently).

## Outcome (2026-10-18)

The two conformance cases were written as 026 and 027 and renumbered 044 and 045 the same day:
plan 043 had already taken 026-030, and the coordinator gave this plan 044-049.

Red, each committed before its fix (Windows PowerShell 5.1):

| Item | Test | Red |
| --- | --- | --- |
| 2 | Case 044 | `install.ps1 FAIL`: exit 1, manifest lacks claude, cursor, antigravity, "Operation failed: You cannot call a method on a null-valued expression" |
| 2 | Case 045 | `install.ps1 FAIL`: exit 1, manifest still records cursor, output lacks "is a directory" |
| 1 | Test 44 | "Test-IsLink says True for the tagged folder, expected False" |
| 2 | Test 45 | "the failed run saved no manifest, orphaning every file it installed" |
| 3 | Test 46 | exit 1, "Operation failed: The term 'git' is not recognized" |
| 4 | Test 47 | "a project install from the home folder did not write .clinerules" |
| 8 | Test 48 | "the editor menu was shown although -Editor was given" |
| 5, 7 | Test 49 | "the commit took the user's .clinerules/01-mine.md" |

What Test 44 covers: OneDrive cannot be used (its folders sync to the cloud), so the test sets a
third-party reparse tag (`0x123`, with a GUID buffer) on a folder, which an unelevated user may
do, and checks `Test-IsLink` and `Get-LinkedAncestor` on it, a plain folder, a junction and a
dangling junction. Nothing can be opened inside the tagged folder (no filter driver handles the
tag), so no install runs into it. Separately, read-only on 400 real OneDrive folders: the old
`Test-IsLink` called 400 links, the new one 0.

Test 49 also carries a tampered manifest entry, `.cursor/../notes.md`, that climbs back into the
project to a file of the user's: with the `Test-SafeManifestRel` check removed, it fails ("the
commit took the user's notes.md").

Conformance status of the other installers on the same cases, left to their plans:

| Case | `install.sh` (plan 045) | `bin/cli.js` (plan 046) |
| --- | --- | --- |
| 044 | FAIL: writes `.clinerules/.clinerules` into the folder, no "is a directory" | FAIL: exit 1 (EISDIR), antigravity never installed, no "is a directory" |
| 045 | FAIL: drops the entry without a word | FAIL: drops the entry without a word |
