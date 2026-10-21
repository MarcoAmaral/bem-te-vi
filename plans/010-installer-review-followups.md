# Plan 010: Fix the defects an independent review found in the install manifest

> **Executor instructions**: Each section below is a separate work item with its own branch.
> Work only on your assigned item. Write the failing test first, confirm it fails for the stated
> reason, then fix it. Do not refactor beyond your item. Do not push or open pull requests.

## Status

- **Priority**: P0 (two blockers are in released v2.3.3)
- **Effort**: L overall, split into independent items
- **Depends on**: PR #28 (manifest), released as v2.3.3
- **Planned at**: commit `246eba4`, 2026-09-17

## Where these came from

An independent review of `ecdfde2..dc7507e`, run with no knowledge of who wrote the change or
why, and told to treat commit messages, plans and the README as claims rather than evidence.
Both blockers below were then reproduced by hand against `main`.

## Item 1 — [BLOCKER] Installing through a symlink destroys the target file

`install.sh` `install_file` tests `[ -f "$DEST" ]`, which follows symlinks, then `cp`s over it,
writing **through** the link into a file outside the install tree. Uninstall removes the link, so
the user's file is never restored. Reproduced:

```text
.claude/rules/security-qa.md -> ~/notes/policy.md   ("MY PRECIOUS NOTES")
install  -> ~/notes/policy.md now contains the package's rule
uninstall-> ~/notes/policy.md still destroyed; only a backup under an unrelated name survives
```

`bin/cli.js` already guards this with `lstatSync().isSymbolicLink()`. `install.ps1`'s
`Copy-Item -Force` has the same shape.

**Required**: detect a symlinked destination (`[ -L ]`; `(Get-Item).LinkType` on Windows), and do
not write through it. Back up the link's target content *and* record where it pointed, then
replace the link itself. Tests in both suites.

## Item 2 — [BLOCKER] The manifest is not portable, and the README claims it is

PowerShell writes it as UTF-8 **with BOM**, **CRLF**, and **backslash** paths; bash writes
BOM-less LF with forward slashes. Feeding bash a PowerShell-format manifest (verified by
rewriting a real one byte-for-byte):

```text
uninstall -> 0 files removed, 0 "Kept" warnings, manifest deleted anyway,
             and the installer still reports complete removal
```

**Required**: one on-disk format — no BOM, LF endings, forward slashes, and paths normalized on
write and tolerant of `\r` and a leading BOM on read. Bash parsing must also survive paths
containing spaces (`awk $3` currently does not, while PowerShell's `-split '\s+', 3` does). A
test must round-trip a manifest written by one implementation and read by the other. Correct the
README, and state which install methods the guarantee covers (`bin/cli.js` has no manifest).

> **2026-10-19: done in plan 053** (I11). A recorded path with a space is now tested in all three
> installers: conformance cases 065 and 066, which fail against an installer that cuts the path at
> its first space.

## Item 3 — [SHOULD] The first upgrade from a pre-manifest install misattributes package files

With no manifest, the backup condition treats every package file whose content changed between
versions as the user's: backups pile up in `.claude/`, the warning blames the user, and because
backups are never removed they block the empty-directory cleanup so `.claude/` survives uninstall
forever. This is the path every existing user takes exactly once, and nothing tests it.

## Item 4 — [SHOULD] Divergent behavior on a read-only destination

Bash aborts mid-install with a raw `cp: Permission denied` under `set -e`, leaving a half
installed tree and no failure message. PowerShell's `Copy-Item -Force` overwrites the read-only
file instead. Pick one behavior, implement it in both, and test it.

## Item 5 — [SHOULD] PowerShell rewrites the whole manifest per file, non-atomically

`Set-ManifestEntry` re-reads and rewrites the entire file for every installed file. An
interrupted run can leave a truncated manifest that still exists, so uninstall finds nothing and
the no-manifest fallback never fires: every installed file is orphaned. Bash writes via
`> tmp && mv`. Buffer and write once, atomically.

## Item 6 — [SHOULD] Uninstall always reports success

Both installers print "uninstalled" per editor and "completely removed" at the end, even when
files were kept or nothing was removed. Report what was removed and what was kept.

## Item 7 — [SHOULD] WSL "install to the Windows profile" records an unusable path

For global antigravity, bash hardcodes `$HOME/.gemini/...` while `install_file` is passed
`BASE_DIR` = `$WIN_HOME`, so the recorded path is absolute and can never resolve; uninstall skips
it silently and then drops the entry. `install.ps1` builds the path from `$BaseDir` correctly.
`install_file` should also refuse to record a destination outside its base.

## Item 8 — [SHOULD] Test gaps

- The **no-manifest fallback** is never executed by either suite, though it is the path every
  existing user takes.
- **Per-editor isolation** (the manifest's `editor` column) is untested: install two editors,
  uninstall one, assert the other survives.
- Both suites **delete Test 2's backup** so Test 3 can assert an empty tree. Assert the true
  post-state instead of erasing the evidence.
- No coverage for symlinks, read-only destinations, or paths containing spaces or non-ASCII
  characters.

  > **2026-10-19: done in plan 053** (I11) for a space in a recorded path (conformance cases 065
  > and 066); a space in the project folder's own name has been in every conformance case since
  > plan 033 item 5.
- `tests/test-lifecycle.ps1` sets `QA_SKILLS_DEBUG` for the whole run and never clears it; there
  is no bash equivalent.

## Item 9 — [SUGGESTION] Cleanups

- `uninstall_single`'s two branches are identical apart from the fallback.
- `Split-Path -Parent $MyInvocation.MyCommand.Path` inside a function does not resolve to the
  script path; that fallback is dead code.
- The `QA_SKILLS_DEBUG` trace exists only in PowerShell and is undocumented.
- `.qa-skills-manifest` lands at the project root but is not in the installer's `git add` list,
  and consuming repos get a stray untracked file.

## Verification (applies to every item)

- `./tests/test-lifecycle.sh` green locally; Windows and macOS suites green in CI.
- ShellCheck clean; `install.ps1` parses with 0 errors.
- Each fix has a test that fails before it and passes after, with the failure quoted in the PR.
