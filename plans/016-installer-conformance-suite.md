# Plan 016: One conformance suite for three installers

> **Executor instructions**: Build in the order of the items. Write each case so that it fails
> against at least one historical installer before it passes against the current ones, and quote
> that failure in the pull request. Do not delete a lifecycle test until the case replacing it is
> green on all three platforms.

## Status

- **Priority**: P0 — gates use of the package in a colleague's repository (plan 014 A1)
- **Effort**: L
- **Depends on**: plans 009-013; #78 for its first case
- **Planned at**: 2026-10-02

## Why this matters

`install.sh`, `install.ps1` and `bin/cli.js` must behave identically (CLAUDE.md, "Installer
File-Safety Contracts"). They have not. Every plan from 009 to 013 found a behaviour present in one
installer and absent from another — including the same path-traversal bug twice, and an
`install.ps1` that wrote copilot and cline into the home directory for months while the other two
skipped them (#78).

The cause is structural. The guarantees are tested by two independently written lifecycle
suites, and within the bash suite the same contract is written once per installer:

| Contract | `install.sh` | `bin/cli.js` | PowerShell suite |
| --- | --- | --- | --- |
| A colliding user file is backed up | test 5 | test 21 | separately again |
| A symlinked destination is never written through | test 8 | test 22 | separately again |
| A read-only destination is skipped | test 11 | test 26 | separately again |
| An older release's file is adopted, not backed up | test 18 | test 24 | separately again |
| Uninstalling one editor spares the others | test 17 | test 29 | separately again |

A guarantee added for one installer is not required of the others, so parity is kept by memory.
It fails in the way daily QA work at Swareco found for its own automation rules: written down,
not enforced, broken in a new way each time (plan 015 item 2).

**The fix:** each guarantee is written **once**, as data, and a thin runner per platform executes
every case against every installer available there. A new guarantee is then automatically required
of all three.

---

## Item 1 — The case format

A case is a directory, `tests/conformance/cases/NNN-slug/`, holding a `case.conf` and optional
fixture files. `case.conf` is line-based (`key: value`, `#` comments, keys may repeat) so it can be
parsed by bash 3.2 and Windows PowerShell 5.1 without a dependency.

Paths are written with a scope prefix — `project:` or `home:` — and forward slashes. The runner
resolves them inside its sandbox.

### Setup directives

| Directive | Meaning |
| --- | --- |
| `seed: <scope>:<path> = <text>` | Write a literal file |
| `seed-fixture: <scope>:<path> = <file>` | Copy a file from the case directory, for example an older release's content |
| `seed-package: <scope>:<path> = <package path>` | Copy a file from the current package, for example `adapters/cline/.clinerules` |
| `seed-manifest: <scope> <editor> <path>` | Append a manifest entry with that seeded file's actual hash |
| `seed-readonly: <scope>:<path>` | Mark a seeded file read-only |
| `seed-symlink: <scope>:<path> -> <scope>:<path>` | Create a symlink (skipped, and reported, where the platform cannot) |

**Actions**, run in order: `run: <install|uninstall> <project|global> <editor>`.

### Expectations

| Directive | Meaning |
| --- | --- |
| `expect-exit: <n>` | Exit status of the last action |
| `expect-file:` / `expect-absent: <scope>:<path>` | Presence |
| `expect-same-as-package: <scope>:<path> = <package path>` | Byte-identical to the package's copy |
| `expect-content: <scope>:<path> = <text>` | Exact content |
| `expect-backup: <scope>:<path>` | A `<path>.qa-skills-backup-*` exists |
| `expect-no-backup: <scope>:<path>` | None exists |
| `expect-manifest:` / `expect-no-manifest: <scope> <editor> <path>` | Manifest entry present or absent |
| `expect-output:` / `expect-no-output: <phrase>` | Plain substring in combined output |

`skip: <installer> — <reason>` exempts one installer from a case. A skip is a recorded divergence,
reviewed like a bug; the runners print every skip in their summary.

**Output is a contract too.** The installers word most messages differently, so `expect-output`
may only use phrases all three already share, such as `only supports project-level install`
and `Refusing`. Where a case needs a phrase they do not share, the case's pull request aligns the
wording first.

## Item 2 — The bash runner

`tests/conformance/run.sh` runs every case against `install.sh` and `bin/cli.js`, each in a fresh
sandbox with `HOME` redirected, as the lifecycle suite does. It maps actions to each installer's
flags, prints a case × installer matrix, and exits non-zero on any failure. It must run on bash
3.2: no associative arrays.

## Item 3 — The PowerShell runner

`tests/conformance/run.ps1` runs every case against `install.ps1` and `bin/cli.js` on Windows,
with `USERPROFILE` and `HOME` redirected. That redirect also keeps `git config --global` inside
the sandbox — verified on 2026-09-30 by writing a probe key with `HOME` redirected, and confirming
the real global configuration did not receive it.

Symlink cases need Developer Mode or an elevated shell on Windows. CI runners have it; a
developer's machine may not. The runner reports such a case as **not run**, never as passed, and
says why.

## Item 4 — The first cases

Each must fail against at least one historical installer:

1. **Global install skips editors with no global target** — copilot and cline. Fails against
   `install.ps1` before #78.
2. **A colliding user file is backed up** — a user's own `.claude/rules/security-qa.md`.
3. **An older release's file is adopted silently** — fixture taken from a tagged release's
   `.claude/` and listed in `.qa-skills-known-hashes`. Fails against `install.sh` and
   `install.ps1` before 2.4.1, and `bin/cli.js` before 2.5.0 — when each began consulting the list
   (2.4.0 shipped the list itself, unused).
4. **Uninstall keeps a modified file and every backup.**
5. **A tampered manifest cannot reach outside the install tree** — an entry climbing out with
   `../`, with the victim's real hash. Fails against every installer before 2.6.1.

## Item 5 — CI

A `conformance` step in each platform job, after adapter generation: `run.sh` on Linux and macOS,
`run.ps1` on Windows. It is platform-relevant code, so it runs whenever the OS matrix does.

## Item 6 — Retire the duplicates

Once a case is green on all three platforms, delete the lifecycle tests it replaces, in the same
pull request, listing each one. What stays in the lifecycle suites is behaviour with no
cross-installer equivalent: the CLI's interactive menu and non-TTY default, `link` and `unlink`,
`update` (whose meaning differs: `install.sh --update` reinstalls, `qa-skills update` only
refreshes), git integration and hook registration, and the WSL path.

## Follow-ups (recorded 2026-10-05)

1. **The symlink backup cannot be asserted yet.** `expect-backup-content` globs
   `<path>.qa-skills-backup-*`, which also matches the `<backup>.link-target` file written beside
   a symlinked destination's backup, and takes the last match. So case 008 cannot check the backup's
   content or the recorded link target, and the symlink lifecycle tests (bash 8/22, PowerShell
   8/21) stay until both runners exclude `*.link-target` from that glob. Found while retiring the
   duplicates (#89).
2. **`verify-merge-commits` can miss a merge.** The CI job checks `before..sha` of the push that
   triggered it. When two pushes to `main` land close together, the newer pending run cancels the
   older one, and the older push's range is never checked. #79's merge (`ac253e9`) was skipped that
   way. ~~Proposed fix: check `<last release tag>..HEAD` instead of the push range, so every run covers
   everything since the last release whatever happened to earlier runs.~~
   **Correction, 2026-10-07:** the cancellation is the cause, and it also hid a second gap. Merging
   #86-#90 in a row left only the last, docs-only push verified, so the Windows and macOS jobs never
   ran on the merged code at all. The tag range would have fixed only the merge-title check, while
   re-checking already-verified commits on every run. **Fixed instead at the cause:** on `main`, each
   commit gets its own concurrency group, so every push's run completes and each checks its own
   range on every platform it touches. The cost is one full run per code-bearing merge on `main`,
   which is what the workflow's comment always intended.

---

## Rejected approaches

- **One test driver in Node for all three installers.** It would need Node on every machine that
  runs `install.sh` or `install.ps1`, and those exist precisely for users without Node.
- **Comparing installer output wholesale.** The installers word messages differently on purpose
  (PowerShell console colours, labels), so a byte comparison would fail for reasons that do not
  matter. Expectations are about the filesystem and the manifest; output is checked only through
  shared phrases.
- **Extending the existing suites with a loop over installers.** That keeps the bash and PowerShell
  suites as two independent copies of every case, which is the problem.

## Verification

- Each case quoted failing against a named historical installer, then passing.
- `run.sh` green on Linux and macOS, `run.ps1` green on Windows, in CI.
- The lifecycle suites shrink by the tests each case replaced, and their remaining tests still pass.
- ShellCheck clean; both `.ps1` files parse with 0 errors; bash 3.2 compatible.
