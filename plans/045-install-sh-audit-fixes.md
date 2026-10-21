# Plan 045: install.sh fixes from the pre-launch code audit

> **Executor instructions**: Read `CLAUDE.md` §5 and plans 033 and 037 first. Every behaviour
> change starts with a failing test, committed alone; quote the failure in the pull request. Edit
> only `install.sh`, the conformance runners and cases owned here (032-037, and case 015), new
> tests at the end of `tests/test-lifecycle.sh` (plus Test 39c, which item 6 extends), and the
> files named under each item. `install.sh` must keep running on bash 3.2. Where another installer
> needs the same change, say so and leave that file to its plan (044 for `install.ps1`, 046 for
> `bin/cli.js`). Update this plan's row in `plans/README.md` when the pull request opens.

## Status

- **Priority**: P0 (items 1, 2, 5: a user's file overwritten unproven, written into, or an
  install that hangs), P1 (items 4, 6, 7, 9), P2 (items 3, 8)
- **Effort**: M
- **Risk**: MEDIUM (every fix changes what `install.sh` writes, skips or asks)
- **Depends on**: plan 033 (the contracts kept here), plan 037 (the menu decision item 6 extends),
  plan 044 (its two "destination is a directory" conformance cases, which item 2 makes
  `install.sh` pass; see the numbering note under item 2 in the Outcome)
- **Category**: bug
- **Planned at**: commit `42d3ded`, 2026-10-18 (line numbers below are at that commit)
- **Decided by Marco, 2026-10-18**: fix every audit finding before the public launch; y/n
  questions in `install.sh` ask again on an invalid answer, as `install.ps1`'s do (plan 037 had
  recorded the difference as "Not changed").

## Why this matters

The pre-launch code audit (2026-10-18) reproduced one breach of the file-safety contract in
`install.sh` (a user's file overwritten with no backup when it cannot be hashed), one write into a
user's folder, one hang, and four smaller divergences from `install.ps1`. Release 4.0.1 and the
current tree also give, for the first time, two real releases between which plan 014 A4's update
path can be checked.

## The audit findings

1. **A file that cannot be hashed is taken as matching** (`install.sh:528-534`, `:647-672`).
   `hash_file` printed nothing when `sha256sum` and `shasum` were missing or the file was
   unreadable, and the pipeline's status was awk's 0. An empty `DEST_HASH` equalled an empty
   recorded hash, so the file was overwritten with no backup, and `manifest_record` wrote an empty
   hash that uninstall could never match.
2. **A destination that is a directory** (`:789-814`): `cp` copied the adapter into the user's
   `.clinerules/` folder, an entry with no hash was recorded (`cline  .clinerules` with the hash field empty), and uninstall said
   "Nothing to uninstall".
3. **Conformance case 015 cannot fail**: it plants a link at `.qa-skills-manifest.tmp`, a name no
   installer uses any more.
4. **`grep -oP`** (`:219`, `:221`): BSD grep has no `-P`; every reinstall over an existing
   `commands/qa.md` printed `grep: invalid option -- P` and an empty installed version.
5. **`write_exclusive` and noclobber** (`:692-698`): noclobber adds `O_EXCL` only when the name does
   not exist, so a link to an existing FIFO or device at a backup name was opened through, and a
   FIFO hangs the install. The comment claimed a planted link is never followed.
6. **y/n questions**: anything but `y` was read as no, where `install.ps1`'s `Read-YesNo` asks again.
7. **Commit offer** (`:1245`): made only when `.git` is a directory (never in a worktree), and the
   paths it commits were not checked against the project.
8. **Undocumented**: with no flags and input at its end, `install.sh` installs Claude Code into
   the current project, and y/n questions take no.
9. **Plan 014 A4**: the update path between two real releases was expected, never verified.

## Steps

Each item is a red test commit followed by its fix, except items 3, 8 and 9 (no behaviour change).

1. Test 50: no SHA-256 tool on PATH, and a mode-0200 destination. Fix: a pre-flight check that a
   SHA-256 tool works (hashing empty input to the known value), before anything is written;
   `hash_file` and `hash_file_without_cr` fail, printing nothing, unless they produce 64 hex
   digits (`pipefail` inside the substitution, so a failed read never hashes as empty input); an
   unreadable destination is skipped and reported; a failed destination hash is backed up, never
   compared; `manifest_record` refuses an invalid hash; `adopt_known` never adopts an unhashable
   file.
2. Plan 044's two directory conformance cases are the red tests. Fix: a directory destination (or a link
   to one) is skipped with "it is a directory"; uninstall keeps a recorded path that is now a
   directory, says so, and drops the entry as for any kept file.

   > **Note, 2026-10-20, plan 061 B2.** "Or a link to one" held in `install.sh` only. The CLI
   > hashed a linked folder and stopped with `EISDIR`, and `install.ps1` took it for a broken link
   > and removed it; both now check for a folder, following the link, first (cases 078 and 079).
3. Rename case 015 to what it still proves, and say in its comment which tests do cover exclusive
   create.
4. Test 51: a `grep` stand-in that refuses `-P` as BSD grep does. Fix: `grep -oE
   '[0-9]+\.[0-9]+\.[0-9]+'`; an empty result prints "unknown" (the old `|| echo unknown` never
   ran, the pipeline's status being head's).
5. Test 52: a link to a FIFO at the exact backup name, clock pinned as in Test 49, run under a
   60-second limit (`timeout`, or `perl -e alarm` where there is none). Fix: `write_exclusive`
   treats any existing name, a link included, as taken; `manifest_write` uses it too; the comments
   say what noclobber does.
6. Test 39c: "maybe" then "y", "Y", and "maybe" then the end of input, to "Overwrite?". Fix:
   `yes_no`, used by every y/n question, with `install.ps1`'s message "Please enter 'y' or 'n'.".
7. Test 53: a worktree whose manifest holds a `../` entry. Fix: the offer runs when `.git` is a
   file too; the paths come from `manifest_lines` and pass `safe_manifest_rel`.
8. README, in the Editor Support note on the shell installers.
9. Fixture `tests/fixtures/release-v4.0.1/` (exact bytes of the tag's installer, generator, editor
   map, known-hash list and five shipped folders; plan 032's rule is fixtures, not tags) and Test
   54: release 4.0.1 installs every editor in both scopes with its own installer, the current
   `install.sh --update` runs, and the result must equal a fresh install of the current tree.

## Done criteria

- [x] Tests 50-54 and the extended 39c fail on `install.sh` before each fix and pass after it.
- [x] Plan 044's directory cases pass for `install.sh` (run from plan 044's branch; they reach
  `next` with it).
- [x] Case 015 renamed; its comment names the tests that cover exclusive create.
- [x] README documents the no-flags, end-of-input behaviour.
- [x] Plan 014 A4 records the 4.0.1-to-current result.
- [x] `bash ~/qa-ci-all.sh` passes on Linux, bash 3.2.57 and Windows PowerShell 5.1.

## STOP conditions

- A fix needs a change to `install.ps1` or `bin/cli.js`: record it here, leave the file to its plan.
- The 4.0.1 fixture would need a git object at test time (plan 032).

## Outcome (2026-10-18)

Branch `fix/install-sh-audit`, from `next` at `80ee1dd`.

**Red, quoted from the runs before each fix:**

| Item | Test | Failure on `install.sh` before the fix |
| --- | --- | --- |
| 1 | Test 50a | `✘ install.sh ran with no SHA-256 tool (exit 0)` |
| 1 | Test 50b (probe) | `sha256sum: …/security-qa.md: Permission denied`, file overwritten, 0 backups, manifest entry for `.claude/rules/security-qa.md` with no hash |
| 2 | Plan 044's directory cases | `✘ should not exist: project:.clinerules/.clinerules`, `✘ output lacks 'is a directory'` (both cases) |
| 4 | Test 51 | `✘ install.sh called grep with an option BSD grep does not have:` / `grep: invalid option -- P` |
| 5 | Test 52 | `✘ install.sh hung or failed (124) on a link to a FIFO at the backup name` |
| 6 | Test 39c | `✘ Test 39c: an invalid y/n answer failed (1)` (see the WSL note below) |
| 7 | Test 53 | `✘ install.sh failed in a worktree` (no offer, so the "y" reached the Windows-side question) |

On WSL, items 6 and 7 fail by exit status rather than by their message: the answer meant for the
missing or misread question reaches "Also install to Windows-side user profile?", where the tests
stub `cmd.exe` and `wslpath` to fail so nothing is written outside the sandbox. Off WSL they fail on
"an invalid y/n answer was not reported" and "install.sh did not commit in a worktree".

**Green**: every test above passes after its fix; see the pull request for the full local CI run.

**Numbering of plan 044's cases.** They were written as 026
(`directory-destination-skipped`) and 027 (`uninstall-keeps-a-recorded-path-now-a-directory`),
and the red and green runs above used those copies. Plan 043 (#176, #181) then took 026-030, so
plan 044 renumbers them into its new range, 044-049; the item 2 fix commit's message still says
026 and 027.

**Item 3.** Case 015 is now `015-link-at-the-old-manifest-temp-name-not-written-through`. It proves
only that the fixed name stays unused. The task as given said exclusive create is covered by
lifecycle Tests 46b and 49 for `install.sh` and the CLI; checking that showed it is narrower:

- `install.sh`: Tests 49 and 52 cover `write_exclusive`, which now writes backups, link-target
  files and the manifest's temp file.
- CLI: Test 49 covers its backups (`"wx"`); nothing plants a link at its manifest temp file
  (`bin/cli.js:281-282`, also `"wx"`), whose name is random.
- `install.ps1`: nothing (plan 033).
- **Test 46b proves nothing any more**: its `mktemp` stand-in intercepts
  `*.qa-skills-manifest.tmp.*`, but `install.sh` has named that file with `$RANDOM` since `f7cf963`
  (2026-10-15) and never calls `mktemp` for it. Recorded, not changed: 46b is outside this plan's
  scope (tests are only appended here); Test 52 covers the same function.

> **2026-10-19: done in plan 053** (I9, I10). Test 46b now plants its link at the exact temp name
> `install.sh` draws, with a control that must write through it. Lifecycle Test 66 plants one at
> the CLI's manifest temp name, and `tests/test-lifecycle.ps1` Test 52 at `install.ps1`'s backup,
> `.link-target` and manifest temp names and at the CLI's backup name on Windows.

**Item 9 (also recorded in plan 014 A4).** Release 4.0.1, installed with its own `install.sh` for
all editors in both scopes, then `install.sh --update` from this branch (merged with `next` at
`44b269a`, plan 043 included): 84 files refreshed and 142 added across the two scopes (the 11
skill and reference files added since 4.0.1, in each scope, and the skill references plan 043
installs beside each non-Claude adapter), none removed (4.0.1 shipped nothing the tree has dropped), no backup, no file
kept; both manifests and both trees identical to a fresh install of the current tree (`diff -r`);
uninstall then left nothing in either folder. Test 54 was green on its first run, as a verification
test should be; it fails when the update step runs release 4.0.1's installer instead (the manifests
differ).

**Other installers.**

- Item 1: by reading the code, the CLI hashes with Node's `crypto` and `fs.readFileSync`, which
  throws on an unreadable file instead of returning nothing, and `install.ps1`'s `Get-Sha256` calls
  `.Hash.ToLower()` on `Get-FileHash`'s result, which throws when there is none. Neither takes a
  failed hash for a match. No conformance case: the runners cannot remove a hashing tool or make a
  file unreadable on every platform, so 032-037 stay unused.
- Item 2: the CLI fails both directory cases: `directory-destination-skipped` (`EISDIR` from
  `copyfile`, exit 1, Antigravity never installed) and
  `uninstall-keeps-a-recorded-path-now-a-directory` (no "is a directory" line). Left to plan 046.
- Items 4-7 are `install.sh`'s own.

**Found and not changed (recorded for a later plan).**

- After a skipped destination (read-only, unreadable or a directory) `install_to_editor` still
  prints "✓ \<editor\> (project): \<path\>".
- On WSL, when `cmd.exe` or `wslpath` fails, the Windows-side step exits under `set -e` instead of
  printing "could not resolve Windows home directory".
- Uninstall reports an unreadable recorded file as "changed since it was installed"; it is kept,
  which is safe, but the reason is wrong.

> **2026-10-19: done in plan 053**, all three: the "✓" line only when a file was written (I14,
> conformance case 062), the Windows-home message on WSL (I13, lifecycle Test 65), and an
> unreadable file kept and reported as one that "cannot be read" (I15, conformance cases 063 and
> 064). The CLI and `install.ps1` had stopped on such a file rather than keep it.
