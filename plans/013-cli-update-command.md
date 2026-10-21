# Plan 013: Make `qa-skills update` actually update

> **Executor instructions**: Write the failing test first, confirm it fails for the stated
> reason, then fix it. Do not refactor beyond this plan. Do not push or open pull requests.

## Status

- **Priority**: P2
- **Effort**: M
- **Depends on**: 009 (manifest), 011 (known-hash provenance), 012 (CLI safety), and the shared
  editor map from PR #63
- **Planned at**: commit `939ad31`, 2026-09-21

## Why this matters

`docs/specs/qa-skill-overhaul.md` §5.2 asked for:

> **Automated Update Command**: `qa-skills update` will automatically scan the target repo for
> existing IDE folders (e.g. `.cursor`, `.claude`) and overwrite them in-place with the latest
> versions.

What exists today is a stub. It prints instructions telling the user to run `npm update` and then
re-run `init` themselves:

```text
qa-skills update
To update to the latest version, run:
  npm update -g @marcoamaral/qa-skills
Then re-apply your installation:
  qa-skills init           # re-copy files
```

This is the last unbuilt item of that spec, and the only CLI command that does not do what its
name says.

## What has changed since the spec was written

The spec assumed update would have to *scan* for editor folders and guess. It no longer has to
guess about anything:

- `.qa-skills-manifest` records every file the installer wrote, with its hash and its editor.
- `.qa-skills-known-hashes` says whether a file's current content is something this package
  shipped in some release.
- `.qa-skills-editor-map` gives every editor's source and target paths in one place.

So update becomes "refresh exactly what the manifest says is installed", with scanning reserved
for the case where there is no manifest.

## Item 1 — Refresh what the manifest records

For each manifest entry, re-install that file from the current package, reusing `installFile`
so the safety contract is inherited rather than reimplemented: a file whose content matches a
previous release is adopted silently, a file the user changed is backed up first, a read-only
destination is skipped, and a symlinked destination is never written through.

The manifest must end up recording the new hashes.

## Item 2 — Remove files the package no longer ships

This is the part a re-run of `init` cannot do, and the main reason update deserves to exist.

When a release drops a rule or renames a command, `init` writes the new files and leaves the old
ones behind forever. The user's agent then reads a rule this package no longer ships. Update
must remove a file that is in the manifest but no longer in the package — subject to the same
protections: if the user has modified it, it is theirs, so keep it and say so.

## Item 3 — No manifest: detect, then adopt

An install made before v2.3.3 has no manifest. Here the spec's original instinct applies: look
for the editors' known target paths, which `.qa-skills-editor-map` now enumerates, plus the
`.claude/` tree.

A file found this way is adopted only when its hash appears in `.qa-skills-known-hashes` —
proving the package shipped it — and is otherwise left alone as the user's. Never adopt on the
strength of a path alone; that is the inference plan 011 exists to avoid.

## Item 4 — Report honestly, and decide the scope rules

Report what was updated, what was added, what was removed and what was kept, in the same shape
as the uninstall summary from plan 010 item 6. "Everything is up to date" must mean it.

Decide and state:

- whether `update` takes `--editor`, and what it does without one (the natural reading is every
  editor in the manifest, but say so);
- how `--global` interacts with a manifest in the home directory;
- what it does when nothing is installed at all — it must not silently install;
- whether it still prints the `npm update` hint, since refreshing files from an old package
  version is a real footgun. The command cannot update the package that is executing it.

### Decisions

- **`--editor`**: accepts one name from `ALL_EDITORS`, or `all` — same values as every other
  command. Without it, `update` does **not** default to `claude` the way `init`/`uninstall` do:
  when a manifest exists, it defaults to exactly the editors that manifest records (only what's
  actually installed here, not every editor this package supports); with no manifest, it falls
  back to scanning every supported editor's known target path, since there's no record yet of
  which one was installed pre-manifest.
- **`--global`**: handled by the same `resolveTarget()` every other command uses — it points
  `update` at `$HOME`, so it reads and writes `~/.qa-skills-manifest`, entirely independent of any
  project-level manifest in the current directory. The two are never merged; a project install and
  a global install are updated with two separate invocations.
- **Nothing installed at all**: no manifest and nothing adoptable from any editor's known
  pre-manifest path now reports `Nothing installed — run 'qa-skills init' first.` and performs no
  writes. `update` must never be the command that first installs something, and must not claim
  "up to date" when there is nothing to be up to date about — that combined case was audited and
  fixed (`printUpdateReport` was falling through to "Everything is up to date" when nothing existed
  at all).
- **The `npm update` hint**: still printed, but only when the run actually wrote or removed a file
  (not on "nothing installed", not on "everything is already up to date" — there's nothing stale to
  warn about in either case). Refreshing from a stale local copy of the package is a real footgun
  worth flagging every time it could matter, and `update` has no way to check or fetch a newer npm
  release of itself.
- **Unplanned fix found during this audit**: `updateManifestEditor`'s "package no longer ships
  this" branch (item 2) called `fs.rmSync(dest)` on a manifest-derived path with no path-escape
  guard — the same class of bug `f839ced` fixed for `uninstallRecorded`, left unpatched here. A
  manifest entry such as `<hash>  claude  ../../../.ssh/config` deleted a file outside the project
  tree and reported a clean update. Reproduced against the pre-fix code (file outside the tree was
  deleted, command reported "Update complete"), then fixed by applying the existing
  `isSafeManifestRel` guard at the top of the entry loop, refusing and keeping the entry rather
  than acting on it — mirroring `uninstallRecorded` exactly.

## Item 5 — Tests, in both suites

`tests/test-lifecycle.sh` and `tests/test-lifecycle.ps1`, continuing the existing numbering:

1. An unmodified installed file is refreshed to the current version.
2. A user-modified file is backed up, not silently overwritten.
3. A file the package no longer ships is removed when unmodified, and kept when modified.
4. A pre-manifest install is picked up and adopted, and the user's own files survive it.
5. Update with nothing installed does not install anything.

## Verification

- `./tests/test-lifecycle.sh` green locally; Windows and macOS suites green in CI.
- `node --check bin/cli.js`; ShellCheck clean; `install.ps1` parses with 0 errors.
- Each fix has a test that fails before it and passes after, with the failure quoted in the PR.
- The packaged tarball, not just the repo checkout, is used for at least one end-to-end check.
