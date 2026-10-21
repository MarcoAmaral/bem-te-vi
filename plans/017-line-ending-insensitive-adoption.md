# Plan 017: Recognise the package's own files whatever their line endings

> **Executor instructions**: Write conformance case 006 first and quote its failure against all
> three installers before changing any of them. Change the three installers in one pull request,
> so they never disagree on `main`. Do not change the manifest or known-hash formats.

## Status

- **Priority**: P2
- **Effort**: M
- **Depends on**: #84 (LF checkouts), plan 016's conformance suite (#82)
- **Planned at**: 2026-10-05

## Why this matters

The installers recognise the package's own files by SHA-256 — against the package's current copy,
against the install manifest, and against `.qa-skills-known-hashes`, the hashes of every file any
release ever shipped. A hash is of exact bytes, so **the same file with CRLF line endings is a
different file to all three installers.** A CRLF copy of a file a release actually shipped is not
adopted; it is backed up as if the user had written it.

Found on 2026-10-05 by the conformance suite's first Windows CI run (#82): case 003 failed for
`install.ps1` and `bin/cli.js`, because Git for Windows' default `core.autocrlf=true` had checked
the fixture out as CRLF. Reproduced on Linux for `install.sh` and `bin/cli.js` by converting the
fixture to CRLF:

```text
install.sh  FAIL
  ✘ unexpected backup of project:.claude/commands/qa.md
cli         FAIL
  ✘ unexpected backup of project:.claude/commands/qa.md
```

PR #84 fixes the cause going forward: with `* text=auto eol=lf`, a Windows clone now checks the
package out as LF, so new installs carry hashes the package knows. Confirmed with a real Windows
git clone — `qa.md` from `main` had 116 CRLF lines and an unrecognised hash; from #84 it has none.

**What #84 cannot fix** is a CRLF copy already on someone's disk.

## Exposure, stated precisely

The manifest already protects most installs. A file whose bytes match its manifest entry is
recognised whatever its line endings, because the entry records the bytes that were installed —
so every install made from 2.3.3 onward, including one from a CRLF Windows clone, is fine.

The gap is a CRLF file with **no matching manifest entry**, where only the known-hash list can
vouch for it:

- installs made before 2.3.3, when there was no manifest;
- installs whose manifest was deleted;
- installs copied by hand from a Windows checkout — the working repository in plan 015 was
  installed by hand-copying, from an LF source in that case.

In each, an upgrade backs up every package file instead of adopting it. Nothing is destroyed —
backups are taken — but the user is told that their own files collided with the package, which
is false, and plan 011's promise of telling the package's files from the user's with certainty
does not hold.

## Item 1 — One comparison rule, in all three installers

> A file on disk **matches** a hash if the SHA-256 of its bytes equals it, **or** the SHA-256 of
> its bytes with every carriage return (`0x0D`) removed equals it.

The second hash is computed only when the first does not match, so the common case costs nothing.

Removing every CR byte, rather than only CR before LF, is chosen because it is trivially identical
in all three implementations — `tr -d '\r'` in bash, a byte filter in PowerShell and in Node — and
the shipped files are Markdown and shell, which never contain a lone CR. It cannot make two files
with different text match: only CR bytes are ignored.

Apply it at every point where a file on disk is compared with a hash:

| Comparison | `install.sh` | `install.ps1` | `bin/cli.js` |
| --- | --- | --- | --- |
| destination vs the package's current copy | `backup_dest` | its equivalent | `installFile` |
| destination vs its manifest entry | `backup_dest` | its equivalent | `installFile` |
| destination vs `.qa-skills-known-hashes` | `known_hash` | `Test-KnownHash` | `knownHashes.has` |
| uninstall: file vs its manifest entry | `uninstall_recorded` | `Uninstall-Recorded` | `uninstallRecorded` |
| uninstall without a manifest: file vs current copy | `remove_if_matches` | `Remove-IfMatches` | `removeIfMatches` |
| `update`: file vs its manifest entry | — | — | `updateManifestEditor` |

Hashes are still **recorded** as the raw bytes installed. The manifest and known-hash formats do
not change, and a file written by one installer stays readable by the other two.

## Item 2 — Decide whether uninstall applies the rule too

Uninstall removes only files "still exactly as installed". If an editor rewrites an installed
file's line endings — a Windows editor set to CRLF, say — today it is kept and reported as
changed, and left behind after uninstall.

**Recommendation: apply the rule to uninstall as well.** A file that differs from what was
installed only in carriage returns carries none of the user's content, so removing it cannot
destroy any; and recognising a file on install but not on uninstall would be its own
inconsistency. The alternative — install-only — is safe too, and errs towards keeping files.
This is a behaviour decision for the maintainer, so it is recorded here rather than assumed.

**Decision, 2026-10-08: apply the rule to uninstall.** #88 shipped it that way in 2.8.0, stating it
as an assumption. The maintainer then delegated the decision ("do 1 to 6"), and the
recommendation above stands: uninstall treats a file that differs only in carriage returns as
unmodified. Conformance case 007 pins it.

One limit either way: the comparison runs against the *recorded* hash. A file installed as CRLF
and later converted to LF does not match a CRLF record. After #84, installs from clones record LF
hashes, so this concerns only installs made from a CRLF checkout before it.

## Item 3 — Conformance cases

1. **006 — A CRLF copy of an earlier release's file is adopted.** The fixture is 2.3.0's
   `commands/qa.md` with CRLF line endings, kept byte-exact by #84's `-text` attribute. Must fail
   against all three installers today, and pass after item 1.
2. **007 — Uninstall removes an installed file whose only change is its line endings**, or keeps
   it, according to item 2's decision.

## Rejected approaches

- **Add CRLF variants of every hash to `.qa-skills-known-hashes`.** Doubles the list, still misses
  a file with mixed line endings, and moves an installer-behaviour question into the generator.
- **Normalise files to LF on install.** Changes the bytes a user's file ends up with, and does
  nothing for recognising the files already on disk.
- **Rely on #84 alone.** It fixes new checkouts, not files that are already installed.

## Verification

- Case 006 quoted failing against all three installers, then passing.
- `tests/conformance/run.sh` green on Linux and macOS, `run.ps1` green on Windows, in CI.
- Lifecycle suites still pass; ShellCheck clean; both `.ps1` files parse; bash 3.2 compatible.
