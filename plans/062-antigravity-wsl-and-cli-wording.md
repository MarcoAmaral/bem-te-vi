# Plan 062: Antigravity on WSL, and the CLI's install wording for every editor

> **Executor instructions**: Branch `fix/antigravity-wsl-note` from `github/next`, one pull request
> into `next`. One commit for this plan, one commit of red tests per change, then one commit per
> item. Only printed text and documentation change; no file is written, kept or removed
> differently, so the conformance suite is unchanged. Run `bash ~/qa-ci-all.sh <worktree>` on all
> three platforms before reporting.

## Status

- **Priority**: P1 (found by the pre-launch editor check; fixed before the 4.1.0 export)
- **Effort**: S
- **Risk**: LOW (printed text and documentation)
- **Depends on**: plan 008 (the CLI's editor support), plan 047 (each editor's own folders),
  plan 058 (the Antigravity CLI's skills folder)
- **Category**: installer output, documentation
- **Planned at**: commit `c83f0f9` (`github/next`), 2026-10-21
- **Outcome**: done, branch `fix/antigravity-wsl-note` (into `next`), see "Outcome"

## Why this matters

Before the 4.1.0 export, the maintainer installed the packed release into a scratch project with
`init --editor antigravity` and opened it in the Antigravity IDE (2.5.5, Gemini 3.8 Flash), then
sent the two prompts of `evals/qa-cases-format` and `evals/qa-cases-plain-request`, reading the
conversation logs Antigravity keeps. Three setups were tried.

1. **`antigravity-ide .` typed in a plain WSL terminal: nothing loads.** The agent ran on the
   Windows side: its context held no rule and no project skill, and every read of a
   `\\wsl.localhost\...` path was refused by Antigravity's default permission policy. All three
   replies were generic, with no frontmatter and no `## TC-` case. The cause is Antigravity's
   launcher: it looks for VS Code's WSL extension (`ms-vscode-remote.remote-wsl`), finds none,
   since Antigravity ships its own (`google.antigravity-remote-wsl`), and opens the folder as a
   Windows window on `file://wsl.localhost/<distro>/...`. Its title has no `[WSL: <distro>]`.
2. **The same files in a Windows folder: they work.** The agent had the rule text in context,
   read `.agents/skills/qa-cases/SKILL.md` and the `qa-reference` files it points to, for the
   named and the plain request alike, and both replies passed the evals' graders and
   `validate-tc-format.sh`, as Claude Code does in `evals/results/2026-10-20.json`.
3. **A WSL window, in a clean distro: they work.** A fresh distro with Node 24 from nvm, the
   packed tarball installed for the project and `--global`, opened with `antigravity-ide --remote
   wsl+<distro> /home/<user>/btv-try` (title `btv-try [WSL: <distro>]`). The agent ran inside the
   distro (its logs are in the distro's `~/.gemini/antigravity-ide/`), had the rule text in
   context, read the skill and its references on its own for both prompts, with no refusal and
   no web search, and both replies passed the graders and `validate-tc-format.sh`.

> **Corrected 2026-10-21, coordinator:** the first version of this plan read setup 1 as
> "a project opened through WSL ('Connect to WSL') gets nothing" and told WSL users to keep the
> project in a Windows folder. Setup 1 was never a WSL window (the launcher fell back to a
> Windows one), and setup 3 shows a WSL window works. Item 1 and the decisions below replace it.

The layout is right on Windows and in WSL; a WSL user needs to know how to open a WSL window.
The same runs showed two lines of the CLI's output that are written for Claude Code only:

- the header, `installing to project (./.claude/)` or `global (~/.claude/)`, for every editor,
  while an Antigravity install writes `.agents/` or `~/.gemini/`;
- `Done! Open your editor and type /qa to get started.`, while the next line tells an Antigravity
  user to ask for `qa-cases` by name.

## Items

1. **README: Antigravity on WSL.** A third note under "Two notes on the editor layout" (which
   becomes "Three notes"): open the project in a WSL window (title `[WSL: <distro>]`) and install
   from inside the distro; `antigravity-ide .` in a plain WSL terminal currently opens a Windows
   window whose agent cannot read the project; how to open a WSL window; the version and date it
   was checked.
2. **The installers print the WSL window command.** Under WSL (`WSL_DISTRO_NAME` set), `install.sh`,
   `install.ps1` and the CLI print, under the Antigravity line, `in WSL, open the folder in a WSL
   window: antigravity-ide --remote wsl+<distro> <folder>`, with the project's folder, or
   `<folder>` for a global install. Same words in all three.
3. **CLI header names the right folder.** `label()` takes the editors of the run: Claude Code
   alone keeps `./.claude/` and `~/.claude/`; any other editor, alone or with Claude Code, says
   `project (this folder)` or `global (your home folder)`, since each editor's own `✓` line
   already names its folders. `init`, `uninstall` and `update` pass their editors; `link` and
   `unlink` are Claude Code only and keep the old text.
4. **CLI "Done!" line.** `Done! Next steps:`, the words `install.sh` and `install.ps1` print,
   followed by the per-editor lines, which already say how to start in each editor (Claude Code:
   "type /qa to start").

## Decisions (defaults)

1. **The tip is keyed on `WSL_DISTRO_NAME`**, which WSL sets in every session, in all three
   installers, rather than on `install.sh`'s `/proc/version` check, so the three agree and the
   tests can set it. It is printed for Antigravity only: the launcher fault is Antigravity's.
2. **No check for installing from Windows into `\\wsl.localhost\...`.** That is rare (the trap is
   how the folder is opened, not where the installer runs) and cannot be reproduced on CI; the
   README covers it.
3. **The lifecycle suites test the tip, not the conformance suite**, which cannot set an
   environment variable per case. Bash Test 70 runs `install.sh` and the CLI, PowerShell Test 55
   runs `install.ps1`, with the same expected line.
4. **Not checked:** macOS (no Mac; the layout is the Linux one, and CI's macOS job covers the
   installers), and Cursor, Windsurf, Copilot and Cline under WSL (their launchers find their own
   WSL extension; not observed). Antigravity's launcher fault is reported to Antigravity by the
   maintainer, if at all.

## Verification

- Red first: lifecycle Test 69 runs `init --editor antigravity` and `init --editor antigravity
  --global` (with `HOME` in the sandbox) and fails on the old header and "Done!" line; it also
  checks that `init` with no editor still prints `./.claude/` and "type /qa to start". Bash Test
  70 and PowerShell Test 55 fail until the tip is printed under WSL, and check that it is not
  printed without `WSL_DISTRO_NAME`.
- Local CI on Linux, macOS (bash 3.2) and Windows PowerShell 5.1.

## Outcome

Done on branch `fix/antigravity-wsl-note`, into `next`. The pull request, its head and the
`ALL LOCAL CI` line are in the pull request body.
