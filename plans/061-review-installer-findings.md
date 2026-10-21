# Plan 061: The installer findings of the final pre-launch review

> **Executor instructions**: Branch `fix/review-installer-findings` from `github/next`, one pull
> request into `next`. One commit for the runner change, one commit of red tests, then one fix
> commit per item. Conformance cases from 077. All three installers must end identical:
> conformance on Linux, under bash 3.2, and in Windows PowerShell 5.1. Run
> `bash ~/qa-ci-all.sh <worktree>` on all three platforms before reporting.

## Status

- **Priority**: P0 (Marco's rule: everything is fixed before the 4.1.0 export)
- **Effort**: S
- **Risk**: MEDIUM (installer behaviour on update, install and uninstall, in all three installers)
- **Depends on**: plan 016 (the conformance suite), plan 033 item 3 (what `update` means), plan 045
  item 2 (a destination that is a directory), plan 047 (uninstall prunes only what it emptied)
- **Category**: installers, file safety, parity
- **Planned at**: commit `8c5fd72` (`github/next`), 2026-10-20
- **Outcome**: done, branch `fix/review-installer-findings` (into `next`), see "Outcome"

## Why this matters

A final read-only review of `42d3ded..github/next` on 2026-10-20 found four installer defects.
Two break the guarantee that the three installers behave the same (B1, B2), one can delete a
user's folder (S1), and one, the same in all three, can delete a user's empty folders (L1). Marco's
rule is that every finding is fixed before the 4.1.0 export, the ones marked "later" included.

## The findings

| Item | Severity | Where | What |
| --- | --- | --- | --- |
| B1 | Blocker | `install.sh` (`EDITORS=(claude)` under `--non-interactive`), `install.ps1` (`-Editor` defaults to `claude`) | An update that names no editor refreshed Claude Code only. A project with only Cursor installed said "Nothing installed — run the installer without --update first." The CLI refreshes every editor its manifest records, and `README.md` said `install.sh --update` and `install.ps1 -Update` do the same; `install.sh --help` said "For each editor already installed". |
| B2 | Blocker | CLI `installFile`, `install.ps1` `Install-File` | A file destination that is a symlink or junction to a folder. `install.sh` (`[ -d ]` follows the link) skips it as case 044 intends. The CLI took the symlink branch and hashed the folder: `EISDIR`, uncaught, exit 1 after part of the manifest was written. `install.ps1` left linked folders out of its directory check, called the link broken and removed it with `Remove-Item -Force`, which on a junction with children asks for confirmation; with `-NonInteractive` the run aborts, and answered, the junction is replaced. |
| S1 | Should | `install.ps1` `Purge-GitHook`, global | The global uninstall removed the hooks folder (`core.hooksPath` or `~/.git-templates/hooks`) and `~/.git-templates` whenever `Get-ChildItem` (no `-Force`) listed nothing, even when this run removed no file there. `install.sh`'s `purge_git_hook` removes only the hook file. Already in `42d3ded`. |
| L1 | Later | all three, Claude Code uninstall | The Claude Code uninstall removed every empty folder under `.claude/skills/`, the five package folders and `.claude`, even when it removed nothing: `uninstall --editor all` in a project where Claude Code was never installed deleted a user's empty `.claude/skills/my-wip/` or `.claude/agents/`. |

## Decisions (defaults)

1. **B1, no menu on update.** With no editor named, `install.sh --update` and `install.ps1
   -Update` take every editor and show no editor menu, interactive or not, as the CLI's `update`
   does; their update already skips an editor the manifest does not record, and with no manifest
   adopts only known files, as the CLI does.
2. **B2, the wording.** The CLI and `install.ps1` say "Skipped `<path>` — it is a directory;
   nothing was written into it", the words they already used for a plain folder; `is a directory`
   is the phrase all three share. A link to a folder that no longer exists is still a broken link
   and is replaced, as before.
3. **S1, no folder at all.** `install.ps1` now removes only the hook file, never the folder that
   holds it, exactly as `install.sh`. The alternative, removing a folder only when this run emptied
   it by removing the hook file, would still remove a user's own `core.hooksPath` folder that held
   only the package's hook, and would differ from `install.sh`. The CLI registers no git hook.
4. **L1, the rule.** Plan 047's rule, now for Claude Code too: the folders of each file this run
   removed, up to the base and never inside a linked folder, and the package's own folders
   (`.claude/commands`, `rules`, `skills`, `agents`, `hooks`, and `.claude`) only when the run
   removed a Claude Code file. A user's empty folder under `.claude/skills/` survives even an
   uninstall that removed files.
5. **Runner, no editor.** A `run:` line may leave the editor out; the runner then passes no editor
   option (`run: <op> <scope> [<editor>]`, `tests/conformance/README.md`).
6. **Windows and links.** The Windows machine has no symlink privilege, so cases 078 and 079
   report "not run" there, as the other 22 symlink cases do. Lifecycle Test 53
   (`tests/test-lifecycle.ps1`) plants junctions instead, which need no privilege, for
   `install.ps1` and the CLI. `run.ps1` cannot link to a path under the project folder (its name
   holds wildcard characters, which `New-Item -Target` expands), so the cases link to folders in
   the home folder.

## Red, then green

Red is the second commit (`test: red cases for the four installer findings of plan 061`), run
against the installers of `8c5fd72`.

| Item | Test | Red | Green |
| --- | --- | --- | --- |
| B1 | Case 077 | `install.sh`: `✘ missing project:.cursor/skills/qa/SKILL.md`, `✘ output contains 'Nothing installed'`. `install.ps1`: the same five lines, output `[..] Nothing installed - run the installer without -Update first.` The CLI passed. | all three pass |
| B2 | Cases 078, 079 | CLI: `✘ exit 1, expected 0`, `✘ manifest lacks: project claude .claude/rules/security-qa.md`, `code: 'EISDIR'` (078); `✘ manifest lacks: project copilot .github/skills/qa/SKILL.md` (079). `install.sh` passed. On Windows both report not run (no symlink privilege). | `install.sh` and the CLI pass on Linux and bash 3.2 |
| B2 | Lifecycle Test 53 (Windows, junctions) | `install.ps1`: `.claude/commands/qa.md is a broken symlink to …\ps1-commands - replacing with the package file`, then the confirmation prompt fails under `-NonInteractive` (`Operation failed: …`), exit 1 | `install.ps1` and the CLI skip both junctions |
| S1 | Lifecycle Test 54 (Windows) | `Test 54: install.ps1 removed the user's empty core.hooksPath folder.` | passes |
| L1 | Case 080 | `install.sh`, `install.ps1` and the CLI: `✘ missing project:.claude/skills/my-wip`, `✘ missing project:.claude/agents`, `✘ missing project:.claude/hooks`, `✘ missing home:.claude/skills/my-wip` | all three pass; case 038 still passes |

## Outcome

Done on branch `fix/review-installer-findings`, into `next`. The pull request, its head and the
`ALL LOCAL CI` line are in the pull request body. `README.md`'s claim that `install.sh --update`
and `install.ps1 -Update` do the same as the CLI's `update`, and `install.sh --help`'s "for each
editor already installed", are true now; the help text also says what `--editor` changes.

Dated notes went where the behaviour was decided: plan 033 item 3 (B1), plan 045 item 2 (B2),
plan 044 (S1) and plan 047 (L1).
