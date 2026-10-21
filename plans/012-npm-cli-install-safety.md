# Plan 012: Give the npm CLI the same file-safety guarantees as the shell installers

> **Executor instructions**: Each item below is a work item. Write the failing test first,
> confirm it fails for the stated reason, then fix it. Do not refactor beyond your item.

## Status

- **Priority**: P0 (data loss, in the currently published package)
- **Effort**: M
- **Depends on**: 009 (manifest), 010 (symlinks, portable format), 011 (known-hash provenance)
- **Planned at**: commit `48e634e`, 2026-09-18

## Where these came from

Plans 009, 010 and 011 hardened `install.sh` and `install.ps1` until neither can destroy a
user's file. `bin/cli.js` — the `npx @marcoamaral/qa-skills` / `qa-skills init` path — was never
touched, and is now the only way to install this package that has none of those protections.
`README.md` says so honestly, which is not the same as it being acceptable.

Both blockers below were reproduced against `bin/cli.js` at `48e634e`, in a scratch project.

## Item 1 — [BLOCKER] `init` silently overwrites the user's own files

`cmdInit` calls `copyDir`, which calls `fs.copyFileSync` for every file with no check of any
kind: no comparison against what the package ships, no backup, no manifest. A user with their
own `.claude/rules/security-qa.md` loses it, with nothing written to disk to recover it from and
no message saying anything happened. Reproduced:

```text
.claude/rules/security-qa.md  = "MY OWN SECURITY POLICY - IRREPLACEABLE"
qa-skills init
  -> file silently overwritten, 0 backups, no manifest
```

This is the defect plan 009 fixed for `install.sh` and `install.ps1`, still live in the npm path.

**Required**: back up a colliding file the same way the shell installers do
(`<file>.qa-skills-backup-<UTC timestamp>`), report it, and record every written file in
`.qa-skills-manifest`.

## Item 2 — [BLOCKER] `init` writes through a symlinked file, outside the install tree

`cmdInit` checks `lstatSync(dest).isSymbolicLink()` for each of the five **subdirectories**, but
never for the files inside them. `fs.copyFileSync` follows a symlinked destination file and
writes to whatever it points at. Reproduced:

```text
.claude/commands/qa.md -> /tmp/outside/outside.md   ("NOTES OUTSIDE THE INSTALL TREE")
qa-skills init
  -> /tmp/outside/outside.md overwritten with the package's file
  -> .claude/commands/qa.md is still a symlink
```

**Correction to the record**: plan 010 item 1 states "`bin/cli.js` already guards this with
`lstatSync().isSymbolicLink()`". That is wrong, and the reproduction above disproves it. The
guard exists only at directory level. Plan 010 is left as written — it is the historical record
of what was believed at the time — and this is the correction.

**Required**: detect a symlinked destination *file*, never write through it, back up the link's
content and record where it pointed, then replace the link itself, exactly as `install.sh` and
`install.ps1` now do.

## Item 3 — There is no uninstall for anything `init` copies

`cmdUnlink` removes symlinks created by `link` and nothing else. Files placed by `init` can only
be deleted by hand, and with no manifest there is no record of which files those were.

**Required**: an uninstall that removes only files still exactly as installed, keeps and reports
anything the user changed, and leaves the user's backups alone — the behaviour the shell
installers already have.

## Item 4 — No provenance check on upgrade

`.qa-skills-known-hashes` ships in the npm package (it is in `package.json`'s `files`), so the
CLI has the evidence available and does not consult it. Once item 1 adds backups, every changed
package file would be backed up as if it were the user's, which is the misattribution plan 011
exists to prevent.

**Required**: the same lookup — a destination whose hash the package once shipped is adopted
silently; anything else is the user's and is backed up.

## Item 5 — `bin/cli.js` has no test coverage at all

Neither suite executes it. Every defect above has been sitting in a published package
undetected because nothing runs this code path.

**Required**: cover the CLI from `tests/test-lifecycle.sh` and `tests/test-lifecycle.ps1`, so it
is exercised on Linux, Windows and macOS like everything else. Node is available on all three
runners.

## Design note

All three installers must agree on the on-disk contracts, or they will corrupt each other's
state when a user switches between them:

- `.qa-skills-manifest` — no BOM, LF endings, forward-slash paths, `<sha256>  <editor>  <path>`.
- `.qa-skills-known-hashes` — read with the same tolerance (leading BOM, trailing `\r`).
- Backups — `<file>.qa-skills-backup-<UTC timestamp>`, never removed by uninstall.

A test should install with one implementation and uninstall with another, the way plan 010
item 2's round-trip test does for the two shell installers.

## Verification (applies to every item)

- `./tests/test-lifecycle.sh` green locally; Windows and macOS suites green in CI.
- ShellCheck clean; `install.ps1` parses with 0 errors.
- Each fix has a test that fails before it and passes after, with the failure quoted in the PR.
