# Plan 011: Tell the package's own old files from the user's edits, with certainty

> **Executor instructions**: Write the failing test first, confirm it fails for the stated
> reason, then fix it. Do not refactor beyond this plan. Do not push or open pull requests.

## Status

- **Priority**: P1
- **Effort**: M
- **Depends on**: 010 items 1 and 2 (PRs #31, #32, merged)
- **Supersedes**: the approach taken in PR #37 for plan 010 item 3
- **Planned at**: commit `26b7f66`, 2026-09-17

## The problem this solves

When the installer meets a file that already exists at a destination and whose content differs
from what it is about to write, it must decide one of two things:

- this is the package's own file, shipped by an earlier release — overwrite it, say nothing; or
- this is the user's file — never destroy it, back it up and warn.

Today it cannot tell, because nothing records what the package used to ship. Before a manifest
exists — the state every user installed before v2.3.3 is in, exactly once — the installer has no
evidence at all.

PR #37 attempted to infer the answer: if at least 3 of the package's managed paths already exist
and they make up 60% or more of the managed set, assume a prior install and adopt every differing
file without a backup. That removes the false accusation, but it buys it with a real data-loss
path: a file the user genuinely hand-edited inside an otherwise-intact tree is overwritten with no
backup and cannot be recovered. That contradicts the guarantee in `README.md`
("Your own files are never destroyed"), which the whole of plan 009 and plan 010 exists to make
true. A guess is not good enough for a decision whose wrong answer destroys the user's work.

## The approach

Ship the evidence instead of inferring it.

Generate, at build time, a list of the SHA-256 of every file this package shipped in each tagged
release, and ship that list inside the package. The installer can then answer the question
exactly:

```text
.claude/rules/testing-guidelines.md exists and differs from what we are about to write
  ├─ its hash matches what some previous release shipped → the package's own file, adopt it
  └─ its hash matches nothing we ever shipped            → the user's file, back it up and warn
```

No threshold, no majority, no guessing, and nothing the user wrote is ever destroyed.

## Work items

1. **Generate the hash list.** A script that walks the repo's release tags (`v1.2.0` onward — the
   tags that exist; see plan 010's note on the tags that predate the repository), and for each
   tag records the SHA-256 of every file under `.claude/` as it stood at that tag. Output is a
   plain data file, one `<sha256>  <path>` per line, sorted and de-duplicated across releases —
   the path matters only for reporting, so a file moved between releases is still recognized by
   hash. Decide where it lives (`.qa-skills-known-hashes` at the package root is the obvious
   choice) and make sure it is included in the npm package (`files` in `package.json`) and in
   what `install.sh` / `install.ps1` read.
2. **Keep it current.** The list must gain the new release's hashes when a release is cut, or it
   silently rots and the installer starts misattributing again. release-please's release PR is the
   natural place; a CI check that fails when the list is stale is the safety net.
3. **Use it in both installers.** Replace the inference with a lookup, in `install_file`
   (`install.sh`) and `Install-File` (`install.ps1`). Reading the list must tolerate the same
   portable-format rules as the manifest (no BOM, LF, forward slashes) — see plan 010 item 2.
4. **Tests, in both suites.** At minimum: a file whose content matches a previous release is
   adopted with no backup and no warning; a file the user edited is backed up and reported; and
   the no-manifest upgrade path leaves no spurious backups and uninstalls to a clean tree.
5. **Correct the README** so its description matches what the installer actually guarantees, and
   say which install methods it covers (`bin/cli.js` still has no manifest — plan 010 item 2
   raised the same gap).

## Consequences to keep in mind

- The list only grows, and only by one entry per file per release, so its size is bounded and small.
- A user who edits a package file to *exactly* the bytes of an older release is indistinguishable
  from that release, and will have their file adopted. This is acceptable and worth stating in the
  PR: the content is identical to something the package shipped, so nothing of theirs is lost.
- Releases before the first tag cannot be covered. Those files fall back to being treated as the
  user's — the safe direction.

## Verification

- `./tests/test-lifecycle.sh` green locally; Windows and macOS suites green in CI.
- ShellCheck clean; `install.ps1` parses with 0 errors.
- Each fix has a test that fails before it and passes after, with the failure quoted in the PR.
