# Plan 009: Track installed files in a manifest instead of guessing by filename

> **Executor instructions**: Follow this plan step by step. Run every verification command and
> confirm the expected result before moving on. If a STOP condition occurs, stop and report.
> When done, update the status row for this plan in `plans/README.md`.

## Status

- **Priority**: P0
- **Effort**: L
- **Risk**: MED (touches both installers' install and uninstall paths)
- **Depends on**: none (builds on PR #26, merged as `ecdfde2`)
- **Category**: bug (data loss)
- **Planned at**: commit `ecdfde2`, 2026-09-15

## Why this matters

Both installers decide which files belong to the package **by filename**. PR #26 stopped them
from deleting whole folders and from removing every `rules/*.md`, but name-based ownership still
destroys user data in two directions. Both were reproduced against `ecdfde2`:

1. **Collision (data loss).** A project that already has `.claude/rules/security-qa.md` (or any
   file matching the package's own names) loses it: install overwrites it with no warning or
   backup, and uninstall then deletes it.

   ```text
   before install:  MY OWN CUSTOM SECURITY POLICY - DO NOT TOUCH
   after install:   # Security QA Rules & Guidelines ...
   after uninstall: FILE DELETED
   ```

   The package ships generic names (`security-qa.md`, `testing-guidelines.md`,
   `code-style-qa.md`), so this is plausible, not contrived. Lifecycle Test 4 uses `team-*`
   names that cannot collide, so this gap has no coverage and passes CI indefinitely.
2. **Version drift (orphans).** Uninstall derives "package files" from the *currently
   checked-out* source. A file shipped by an older version that the package later renamed is
   never targeted, so it is left behind while the installer reports complete removal.

Single-file editors have the same problem and are higher risk: uninstall unconditionally
deletes `.clinerules`, `.windsurfrules`,
`.github/copilot-instructions.md`, `.cursor/rules/qa.mdc` — which a project may own outright.

## Decision

Record what was actually installed, and act only on that.

- **Manifest**: `<BASE_DIR>/.qa-skills-manifest`, one per scope (project dir or `$HOME`).
- **Format**: one line per file, `<sha256>  <path relative to BASE_DIR>` — readable by
  `sha256sum`-style tools in bash and `Get-FileHash` in PowerShell; no JSON parser or `jq`
  dependency.
- **Install, per file**:

  | Destination state | Action |
  | --- | --- |
  | missing | write, record |
  | content equals the package's | record (no-op) |
  | listed in the manifest and unchanged since we wrote it | overwrite, record |
  | anything else (project's own file, or ours but user-modified) | back it up to `<file>.qa-skills-backup-<UTC timestamp>`, warn, then write and record |

- **Uninstall**: for each manifest entry, delete the file only if its hash still matches the
  recorded one; otherwise leave it and warn that it changed since install. Remove the manifest
  afterwards. Files not in the manifest are never touched.
- **No manifest (installed by an older version)**: fall back to deleting only files whose
  content matches the current package's copy, leaving anything else with a warning. Strictly
  safer than today's name matching, and needs no manifest to exist.

## Scope

**In scope**: `install.sh`, `install.ps1`, `tests/test-lifecycle.sh`, `tests/test-lifecycle.ps1`,
`README.md` (document the manifest and backup behavior).

**Out of scope**: `bin/cli.js` (npm CLI; it has no uninstall today — a follow-up plan should give
it the same manifest), the `qa*`/`qa-*` naming conventions themselves, and plan 008's work.

## Steps

1. **Tests first (red).** Add lifecycle tests to both suites, each failing on `ecdfde2` for the
   documented reason:
   - **Collision**: a pre-existing `.claude/rules/security-qa.md` with custom content →
     install → original content still available in a `.qa-skills-backup-*` file; uninstall →
     backup untouched.
   - **Untracked file**: a file added to `.claude/rules/` *after* install (stands in for both a
     project's own file and an older version's leftover) → uninstall leaves it.
   - **Modified package file**: edit an installed file, then uninstall → left in place, warned.
   - **Global scope**: the collision case against `$HOME`/`$env:USERPROFILE`.
2. **`install.sh`**: write the manifest on install (all editors), apply the conflict-backup
   policy, and make uninstall manifest-driven with the content-match fallback.
3. **`install.ps1`**: same behavior, `Get-FileHash -Algorithm SHA256`, reusing the
   `$PSScriptRoot`-with-fallback pattern already at lines ~744-746.
4. **README**: document the manifest file, the backup naming, and that modified files are kept.

## Verification

- `./tests/test-lifecycle.sh` → exit 0, every test passes.
- Windows CI runs `tests/test-lifecycle.ps1` (it cannot run from a WSL path locally).
- ShellCheck clean on `install.sh`; `install.ps1` parses with 0 errors.
- Manual repro from "Why this matters" no longer loses the file: the custom content survives in
  a backup, and uninstall does not delete it.

## STOP conditions

- `sha256sum` is unavailable on a supported platform (check `shasum` as the fallback before
  changing the format).
- Making uninstall manifest-driven would leave files behind for users who installed with an
  older version — the content-match fallback must cover that; if it cannot, stop and report.
- The manifest would have to live inside `.claude/` for single-file editors that never create
  that directory — keep it at `BASE_DIR`, and stop if that conflicts with an existing file.

## Maintenance notes

- Any new editor target must record its file in the manifest; uninstall then needs no per-editor
  deletion logic at all, which is what removes this whole class of bug.
- The backup suffix is deliberately timestamped so repeated installs never overwrite a backup.

## Execution note (2026-09-15)

Implemented as specified, with one deliberate difference: manifest lines carry an **editor**
column — `<sha256>  <editor>  <path relative to base>` — because uninstall runs per editor and
must not remove another editor's files from the same manifest. The install conflict policy,
uninstall matching, and the no-manifest fallback are unchanged from the plan.
