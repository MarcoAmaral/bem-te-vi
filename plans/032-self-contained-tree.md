# Plan 032: The tree builds, tests and releases without this repository's history

> **Executor instructions**: Do this plan **before** plan 020 part B exports the tree. It can land
> at any time before then: the frozen hash list stays open while releases ship from this
> repository, and is sealed only at export. Run every verification command,
> including the tagless dry run. If anything in "STOP conditions" occurs, stop and report. When
> done, update this plan's row in `plans/README.md`.
>
> **Drift check (run first)**: `git diff --stat 7d33cbf..HEAD -- generate-known-hashes.sh .qa-skills-known-hashes tests/test-lifecycle.sh tests/test-lifecycle.ps1 tests/test-dedupe-changelog.sh .github/workflows .gitignore`

## Status

- **Priority**: P0 (blocks plan 020 part B: the public repository's first CI run would fail)
- **Effort**: M
- **Risk**: MEDIUM (touches the installers' provenance list, a file-safety contract)
- **Depends on**: plan 011 (the known-hash list it changes); sealed by plan 020 part B
- **Category**: build, test
- **Planned at**: commit `7d33cbf`, 2026-10-14

## Why this matters

Plan 020 part B starts the public repository from the current tree with **one commit and no
tags**. A dry run did exactly that on 2026-10-14: `git archive` of `7d33cbf`, minus
`.claude/settings.local.json`, then `git init` and one commit. The local CI mirror failed 2 of its
15 steps:

- **known-hashes**: `generate-known-hashes.sh --check` → "no tag contains a .claude/ tree; refusing
  to write an empty hash list".
- **lifecycle**: Test 20 ("a full no-manifest upgrade leaves no spurious backups") reported three
  spurious backups. It seeds older files with `git show "v2.2.0:$f" … || true`; without the tag
  each file is silently written empty, and an empty file is rightly treated as the user's.

The first failure hides a worse one. The release workflow regenerates `.qa-skills-known-hashes`
from tags after every release. In the public repository that would rebuild the list from its own
tags only and **drop the hashes of every release shipped from this repository** (v2.x up to the last release before the cut-over).
An installer would then back up a user's untouched copy of an older package file instead of
adopting it: the exact misattribution plan 011 exists to prevent, for every user who installed
before the cut-over.

## Current state

- `generate-known-hashes.sh:29-50`: the list is built only from `git tag`; zero tags is an error.
- `.github/workflows/release-please.yml` (step "Refresh the known-hash list after a release"):
  regenerates and commits the list after a tag.
- `tests/test-lifecycle.sh:593,858,894,962` and `tests/test-lifecycle.ps1` (8 lines): read
  `v2.2.0:<file>` from git.
- `tests/test-dedupe-changelog.sh:16,24`: builds its fixture with `git show 6a204fe:CHANGELOG.md`.
  The script is not run in CI today (audit backlog, "Tests").
- Conformance cases already use committed fixture files (`qa-v2.3.0.md`), not git objects.
- Repository hygiene listed in the audit backlog for the cut-over: `.claude/settings.local.json` is
  tracked (privacy scan finding 8); `ci.yml` has no `permissions:` block; `release-please.yml` runs
  `npx --yes markdownlint-cli@0.49.1` while holding a write token.

## Commands you will need

| Purpose | Command | Expected |
| --- | --- | --- |
| Hash list current | `./generate-known-hashes.sh --check` | exit 0 |
| Lifecycle | `./tests/test-lifecycle.sh` | exit 0 |
| Dedupe test | `./tests/test-dedupe-changelog.sh` | exit 0 |
| Tagless dry run | `git archive HEAD \| tar -x -C <empty dir>`, `git init`, one commit, then the full CI list | every step passes |

## Scope

**In scope**: `generate-known-hashes.sh`, a new frozen hash file, `.qa-skills-known-hashes`
(regenerated, content unchanged), the two lifecycle suites and their fixtures, the dedupe test and
its fixture, `ci.yml`, `release-please.yml`, `.gitignore`, `.claude/settings.local.json` (untracked
only), `CLAUDE.md` (its `generate-known-hashes.sh` line), `plans/README.md`.

**Out of scope**: the installers (they keep reading `.qa-skills-known-hashes` exactly as today);
the export itself and the public changelog (plan 020 part B); any other audit backlog item.

## Git workflow

Branch `fix/self-contained-tree`. Conventional Commits, one concept per commit: `build:` for the
hash generator, `test:` for fixtures, `ci:` for workflows, `chore:` for the untracked settings
file. None of these reaches an installed user, so none is `feat:` or `fix:` (CONTRIBUTING.md).

## Steps

### Step 1: a hash list of this repository's releases that seals at export

Add `known-hashes-before-public.txt` (same portable format as `.qa-skills-known-hashes`: no BOM, LF,
`<sha256>  <path>`, sorted), holding the hashes of every tag in this repository, with a header
comment naming its source. Its first line is a state marker:

- `# state: open` in this repository. `generate-known-hashes.sh` rewrites the file from the tags
  every time it runs, and `--check` fails when it is stale, so every private release still on the
  way to the cut-over (Marco decided on 2026-10-14 to finish all planned work first) is added by
  the release workflow's existing refresh step.
- `# state: sealed at <final private main SHA>` in the public repository. Plan 020 part B's export
  writes this line; the generator then never rewrites the file, and `--check` fails if the file
  changed after sealing.

`generate-known-hashes.sh` writes `.qa-skills-known-hashes` as the sorted union of that file and
every tag's files. Zero tags is no longer an error when the file is present and non-empty.

The installers are untouched: `.qa-skills-known-hashes` stays the only file they read, and its
content must be byte-identical before and after this step (`git diff --exit-code`).

### Step 2: lifecycle tests read fixture files, not tags

Commit the three v2.2.0 files the suites use (`security-qa.md`, `accessibility-qa.md`, `qa.md`) under
`tests/fixtures/release-v2.2.0/`, and read them from there in `test-lifecycle.sh` and
`test-lifecycle.ps1`. Drop the `|| true` on the seed: a missing fixture must fail the test setup,
not write an empty file.

### Step 3: the dedupe test owns its fixture, and CI runs it

Commit `6a204fe`'s `CHANGELOG.md` as `tests/fixtures/dedupe-changelog/CHANGELOG.before.md`, read it
from there, and add `./tests/test-dedupe-changelog.sh` to the Linux job. If the test also needs the
commits the changelog links to, build them in a temporary repository inside the test.

### Step 4: repository hygiene before the cut-over

- Untrack `.claude/settings.local.json` (`git rm --cached`) and add it to `.gitignore`.
- `ci.yml`: `permissions: contents: read` at the top level.
- `markdownlint-cli` becomes a pinned devDependency; `release-please.yml` runs it with
  `npx --no-install` after `npm ci`.

### Step 5: prove it on a tagless tree

Repeat the 2026-10-14 dry run on the branch head: export, `git init`, one commit, run the full CI
list. Record the result in this plan's Outcome section.

## Done criteria

- [ ] Tagless dry run: every CI step passes, including known-hashes, lifecycle and dedupe.
- [ ] `.qa-skills-known-hashes` is byte-identical to `main`'s.
- [ ] `grep -n 'v2\.2\.0:' tests/test-lifecycle.sh tests/test-lifecycle.ps1` → no matches.
- [ ] `git ls-files .claude/settings.local.json` → empty.
- [ ] CI green on Linux, Windows and macOS.
- [ ] `plans/README.md` row for 032 updated; plan 020 part B's steps reference this plan.

## STOP conditions

- `.qa-skills-known-hashes` would change content: the union is wrong; do not ship it.
- A lifecycle test needs a git object other than a v2.2.0 file: list it and ask.
- The file is sealed while releases still ship from this repository: they would be missed.

## Maintenance notes

- `known-hashes-before-public.txt` is never regenerated in the public repository; it is the only
  record of what the private releases shipped. A change to it is a defect.
- After the cut-over, the public repository's tags add to the list; the frozen file only ever
  contributes the past.

## Outcome (2026-10-15)

Implemented on `fix/self-contained-tree` in eight commits (steps 1-4), then proved by step 5.

**Before (red).** The 2026-10-14 dry run, repeated on `github/main` (`d3746c4`): `git archive`, minus
`.claude/settings.local.json`, `git init`, one commit, zero tags. The local CI mirror failed 2 of 15
steps (known-hashes, lifecycle), and `tests/test-dedupe-changelog.sh` exited 128 (`git show 6a204fe`).

**After (green).** The same export of the branch head (`b70327a`), with line 1 of
`known-hashes-before-public.txt` set to `# state: sealed at b70327a…`, as plan 020 part B's export
will write it: one commit, zero tags, `settings.local.json` not in the tree. All 15 CI-mirror steps
pass, and the dedupe test passes with all of its cases run (none skipped). `.qa-skills-known-hashes`
is regenerated from the sealed file alone (152 entries, zero tags) byte-identical to `main`'s.

**Decided during implementation.**

- The open file refuses to drop an entry no tag still provides, so the same export **without** the
  seal fails `generate-known-hashes.sh --check` on purpose ("must be sealed"); every other step
  passes there too. This stops a repository without the tags from silently rewriting the list.
- The seal check compares the file with the first commit that has it sealed. A later edit, or
  reopening it, fails `--check` and the write.
- The release workflow's refresh step commits both hash files, since the open file changes with
  every release.
- The dedupe test's six changelogs are fixtures, not only `6a204fe`'s: the other five cases used
  to skip without history. The test rebuilds the commit shape they link to in a scratch repository.
- Fixtures are exact bytes (`-text` in `.gitattributes`) and listed in a new `.markdownlintignore`,
  since v2.2.0's files and release-please's raw `*` bullets fail today's markdownlint rules.
- `release-please.yml` runs `npm ci --ignore-scripts`: markdownlint needs no install scripts, and
  the job holds a write token. Pinning markdownlint-cli surfaces its own moderate and low
  dev-only advisories in `npm audit`; they were already run through `npx --yes`.

Not run locally: `tests/test-lifecycle.ps1` (no PowerShell here); CI's Windows job runs it.
