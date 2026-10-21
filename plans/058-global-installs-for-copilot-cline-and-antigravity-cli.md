# Plan 058: Global installs for GitHub Copilot and Cline, and the Antigravity CLI's skills folder

> **Executor instructions**: Branch `feat/global-copilot-cline` from `github/next`, one pull request
> into `next`. Re-read the editors' documentation first and quote it here with URL and date; install
> only to locations the documentation names for the user level. Then the conformance cases, red
> first (numbers 069-079 are reserved for this plan; quote the failures), then the editor map and
> the three installers (identical behaviour, CLAUDE.md item 5), then the lifecycle tests that named
> the old behaviour, then the README, ROADMAP and plan 047 notes. One concern per commit. Run
> `bash ~/qa-ci-all.sh <worktree>` before the pull request. If anything in "STOP conditions" occurs,
> stop that item and report.

## Status

- **Priority**: P2 (two editors could be installed per project only although both document a
  global folder; the Antigravity CLI did not see a global install at all)
- **Effort**: S
- **Risk**: MEDIUM (changes what a global install writes for three editors in all three
  installers; the file-safety layer is reused, not changed)
- **Depends on**: plan 047 (the editor-native layout and the editor map's five columns), plan 053
  (cases 065-068)
- **Category**: feature (installers)
- **Planned at**: commit `8761bf4` (`github/next`), 2026-10-20
- **Source**: Marco's decision of 2026-10-20 on two items plan 047 left open: D4 (global installs
  for Copilot and Cline) and "Findings outside scope" (the Antigravity CLI's global skills folder),
  both for 4.1.0
- **Outcome**: done, see "Outcome (2026-10-20)"

## Why this matters

Plan 047 put every non-Claude editor's rules and skills where the editor documents them, but left
two decisions open. D4: "Add global installs for Copilot (`~/.copilot/skills/`) and Cline
(`~/.cline/skills/`, `~/.cline/rules/`), now documented?" was "No, not in this plan", so `install
global copilot` and `install global cline` printed "only supports project-level install" and wrote
nothing (conformance case 001). And "Antigravity's CLI reads global skills from
`~/.gemini/antigravity-cli/skills/`, a third location this plan does not install to": a global
Antigravity install reached the App and the IDE, not the CLI. Marco decided both on 2026-10-20:
install them, for 4.1.0.

## What the documentation says (read 2026-10-20)

Read with WebFetch on 2026-10-20. Quotes are the pages' words.

### GitHub Copilot

| Source | What it says |
| --- | --- |
| [About agent skills](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills) | "Project skills, stored in your repository (`.github/skills`, `.claude/skills`, or `.agents/skills`)"; "Personal skills, stored in your home directory and shared across projects (`~/.copilot/skills` or `~/.agents/skills`)" |
| [Creating agent skills](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent/create-skills) | "create a `~/.copilot/skills` or `~/.agents/skills` directory in your local home directory"; "Agent skills work with Copilot cloud agent, Copilot code review, the GitHub Copilot CLI", "the GitHub Copilot app, and agent mode in Visual Studio Code" |
| [VS Code: agent skills](https://code.visualstudio.com/docs/copilot/customization/agent-skills) | "Personal skills, stored in your home directory": `~/.copilot/skills/`, `~/.claude/skills/`, `~/.agents/skills/` |
| [Copilot CLI: custom instructions](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions) | "GitHub Copilot CLI supports instructions from the following locations." `$HOME/.copilot/copilot-instructions.md`: "User-level instructions that apply across repositories." |
| [VS Code: custom instructions](https://code.visualstudio.com/docs/copilot/customization/custom-instructions) | "For personal, always-on instructions in Copilot sessions, use `~/.copilot/copilot-instructions.md`." "Instruction support depends on the agent harness selected for your session." "For Local harness sessions, user instructions use VS Code profile storage." |

**Global rules for Copilot: none written.** The only always-on user-level instructions file the
documentation names, `~/.copilot/copilot-instructions.md`, is documented for the Copilot CLI and for
VS Code sessions on the Copilot harness. VS Code's Local harness keeps user instructions in profile
storage, and Copilot cloud agent and Copilot code review run on GitHub.com, where no page says a
file in the user's home folder is read. So no user-level instructions file is read by every Copilot
surface, and a global Copilot install is the skills tree alone, as Marco's decision asked. The file
is also one the user owns, like Windsurf's `global_rules.md` (plan 047, "Rejected approaches").

### Cline

| Source | What it says |
| --- | --- |
| [Skills](https://docs.cline.bot/customization/skills) | "Place skill directories in `.cline/skills/` (workspace) or `~/.cline/skills/` (global)"; global on macOS and Linux "`~/.cline/skills/`", on Windows "`C:\Users\USERNAME\.cline\skills\`" |
| [Rules](https://docs.cline.bot/customization/cline-rules) | "Global rules go in your system's Cline Rules directory." (the default table: `~/Documents/Cline/Rules`, Windows `Documents\Cline\Rules`); "Cline also searches `~/.cline/rules` and `~/Cline/Rules` for global rules."; "Rules without frontmatter are always active." |

The rules go to `~/.cline/rules/`, not the default `~/Documents/Cline/Rules`: both are documented
global rules locations, and `~/.cline/rules/` is a fixed path under the home folder on every
system, the global twin of the project's `.cline/rules/`, while the Documents folder moves with
OneDrive on Windows ("it checks `Documents\Cline\Rules` under the OneDrive directories").

### Antigravity

| Source | What it says |
| --- | --- |
| [Skills](https://antigravity.google/docs/skills) | Antigravity CLI: "`~/.gemini/antigravity-cli/skills/<skill-folder>/`", scope "Global (all workspaces)"; "`~/.gemini/antigravity-cli/plugins/<name>/skills/`", "Plugin-provided skills". Antigravity App: "`~/.gemini/config/skills/<skill-folder>/`", "Global (all workspaces)". Antigravity IDE: "`~/.gemini/config/skills/<skill-folder>/`", "Global (all workspaces; legacy `~/.gemini/antigravity/skills/` is also supported)". |

The CLI's global folder is confirmed, so the STOP condition for it did not fire.

## What changes

`.qa-skills-editor-map`, read by all three installers:

| Editor | Global rules | Global skills |
| --- | --- | --- |
| `copilot` | `-` (unchanged) | `.copilot/skills` (was `-`) |
| `cline` | `.cline/rules` (was `-`) | `.cline/skills` (was `-`) |
| `antigravity` | `-` (unchanged) | `.gemini/config/skills,.gemini/antigravity-cli/skills` (was the first only) |

A skills column may now name several folders separated by `,`; the skills tree goes into each, in
that order, recorded under the same editor. `install.sh` (`editor_files`), `install.ps1`
(`Get-EditorFiles`) and the CLI (`loadEditorMap`, `editorFilesFor`) split it the same way; every
other step (install, update's "no longer shipped" prune, uninstall, the emptied-folder cleanup)
already works from that one list of pairs, so it covers the new folders under the same manifest
rules: only recorded files are removed, only while their hash is unchanged, and only folders this
run emptied. The first folder stands for the install in the shell installers' "Existing file found"
question; the install line names every folder ("Antigravity (global): .gemini/config/skills/ and
.gemini/antigravity-cli/skills/").

Per editor and scope after this plan (project unchanged):

| Editor | Project rules | Project skills | Global rules | Global skills |
| --- | --- | --- | --- | --- |
| Cursor | `.cursor/rules/` | `.cursor/skills/` | none | `~/.cursor/skills/` |
| Windsurf | `.windsurf/rules/` | `.windsurf/skills/` | none | `~/.codeium/windsurf/skills/` |
| GitHub Copilot | `.github/copilot-instructions.md` | `.github/skills/` | none (see above) | `~/.copilot/skills/` (new) |
| Cline | `.cline/rules/` | `.cline/skills/` | `~/.cline/rules/` (new) | `~/.cline/skills/` (new) |
| Antigravity | `.agents/rules/` | `.agents/skills/` | none | `~/.gemini/config/skills/` and `~/.gemini/antigravity-cli/skills/` (new) |

Conformance case 001 ("A global install skips editors that have no global target") is retired:
after this plan no editor has `-` as its global skills folder, so it has no editor to run against.
The skip itself stays in all three installers for a future row with no global folder. Lifecycle
Test 38 (both suites) asserted that a clean global uninstall of Cline says nothing, because Cline
had no global target; it now says "nothing to remove", as every editor with one does.

The rules budgets are unchanged: a global Cline install writes the same ten generated files as a
project one, measured by `tests/verify-adapters.*`.

## Conformance cases

| Case | Asserts |
| --- | --- |
| 069 | `install global copilot` writes `adapters/skills` at `~/.copilot/skills`, recorded under copilot, and no `~/.copilot/copilot-instructions.md`, `~/.copilot/instructions`, `~/.github` or `~/.agents`. |
| 070 | `install global cline` writes `adapters/cline/rules` at `~/.cline/rules` and `adapters/skills` at `~/.cline/skills`, recorded, and nothing at `~/.clinerules`, `~/Documents/Cline`, `~/Cline/Rules` or `~/.agents`. |
| 071 | `install global antigravity` writes `adapters/skills` at both `~/.gemini/config/skills` and `~/.gemini/antigravity-cli/skills`, recorded, and no `~/.gemini/GEMINI.md`, `AGENTS.md` or `~/.gemini/antigravity`. |
| 072 | After global installs of the three, global uninstalls remove every file and the folders they emptied (`~/.cline`, `~/.gemini`, `~/.copilot/skills`), keep `~/.copilot/config.json` of Copilot's own, and leave no manifest. |
| 073 | Update of a global Antigravity install that recorded only `~/.gemini/config/skills` adds the CLI folder and reports it "Added". |
| 074 | Update of a home manifest recording the `.clinerules` an older `install.ps1` left in the home folder installs Cline globally and removes the old file as "no longer shipped". |

## STOP conditions

- A documentation page no longer names a location this plan installs to for the user level: stop
  that editor's item and report.
- No documented user-level instructions file read by every Copilot surface: install Copilot skills
  only and say so (this is what happened; not a stop).
- Antigravity's documentation does not confirm `~/.gemini/antigravity-cli/skills/`: stop that item.
- `tests/verify-adapters.*` budgets fail: stop and report.

## Rejected approaches

- **`~/.agents/skills/` for Copilot.** Documented, but Cursor, Windsurf and Cline read it too, so a
  copy there would be listed by every one of them and uninstalling Copilot would remove another
  editor's skills (plan 047, D7). `~/.copilot/skills/` is Copilot's own, as `.github/skills/` is per
  project.
- **`~/.copilot/copilot-instructions.md` for Copilot's global rules.** Not read by every Copilot
  surface (see above), and a single file the user owns.
- **`~/Documents/Cline/Rules` for Cline's global rules.** Documented as the default, but its place
  depends on the system and on OneDrive; `~/.cline/rules` is also documented and fixed.
- **A sixth column in the editor map for the Antigravity CLI.** It would move the label column that
  every reader and two lifecycle tests index, for one editor's second folder; a list in the skills
  column changes only the three places that build the pairs.
- **A separate `antigravity-cli` editor.** It would need its own menu entry and `--editor` value for
  what Antigravity documents as one product's three surfaces, and `--editor antigravity --global`
  would still miss the CLI.

## Findings outside scope (recorded, not fixed)

- The "Next steps" lines of `install.sh` and `install.ps1` are the same for both scopes: after a
  global install they still say "bem-te-vi rules always on" for Cursor, Windsurf and Antigravity,
  and "rules in .github/copilot-instructions.md" for Copilot, though a global install of those
  writes skills only. True before this plan for the first three; now also for Copilot.

  > **Fixed, 2026-10-20 (branch `fix/final-tidy`).** After a global-only install the line of
  > Cursor, Windsurf, Copilot and Antigravity now reads "skills only (a global install writes no
  > rules)"; Cline keeps "bem-te-vi rules always on", true of `~/.cline/rules/`. A project install,
  > or `both`, keeps the old lines, which name rules the project part wrote. The CLI printed no
  > line for these editors at all; it now prints the same ones. Conformance cases 075 (global) and
  > 076 (project), red first on `next` at `15bd4c2`: 075 failed for `install.sh` ("output contains
  > 'Cursor/Trae : bem-te-vi rules always on'", "... 'copilot-instructions.md'") and for the CLI
  > ("output lacks 'Cursor/Trae : skills only (a global install writes no rules)'"); 076 failed
  > for the CLI only ("output lacks 'Cursor/Trae : bem-te-vi rules always on'").
- Not run: any of the editors. The locations are the documented ones, quoted above; none is
  observed.

## Outcome (2026-10-20)

Implemented on branch `feat/global-copilot-cline`. No STOP condition fired: every location written
is named for the user level in the pages quoted above.

**Red first.** Cases 069-074 were committed before any installer change and run against the
installers of `next` (`8761bf4`). Every one failed for `install.sh` and the CLI on Linux, and for
`install.ps1` and the CLI on Windows PowerShell 5.1. First failure per case, the same for every
installer:

| Case | First failure |
| --- | --- |
| 069 | `home:.copilot/skills/qa-a11y/SKILL.md differs from the package's adapters/skills/qa-a11y/SKILL.md` (the file is missing) |
| 070 | `home:.cline/rules/bem-te-vi-accessibility-qa.md differs from the package's adapters/cline/rules/bem-te-vi-accessibility-qa.md` |
| 071 | `home:.gemini/antigravity-cli/skills/qa-a11y/SKILL.md differs from the package's adapters/skills/qa-a11y/SKILL.md` |
| 072 | `output lacks '.copilot/skills/'` |
| 073 | `home:.gemini/antigravity-cli/skills/qa-a11y/SKILL.md differs from the package's adapters/skills/qa-a11y/SKILL.md` |
| 074 | `home:.cline/rules/bem-te-vi-accessibility-qa.md differs from the package's adapters/cline/rules/bem-te-vi-accessibility-qa.md` |

(On Windows the first line listed for 069, 071 and 073 is the `qa/SKILL.md` of the same folder.)
Case 072 first asserted the manifest between the installs and the uninstalls; the runner reads
every expectation after the last run, so that version passed on `next` for the wrong reason. It
was rewritten to check what the installs printed, then failed on `next` as above.

**Green.** With the editor map and the three installers changed, all 58 cases pass: Linux 116/116
(`install.sh` and the CLI), Windows PowerShell 5.1 94/94 with 22 not run (the symlink and
unreadable-file cases, which need privileges that machine does not have).

**Tests that named the old behaviour.** Case 001 retired (see "What changes"). Lifecycle Test 38,
both suites: a clean global uninstall of Cline now says "nothing to remove". Lifecycle Test 54
(`install.sh`): it compared an update of a 4.0.1 `--target both --editor all` install with a fresh
`--target both --editor all` install of the current tree; the fresh one now also installs Copilot
and Cline in the home folder, which 4.0.1 never did and update never adds, so the home manifests
differed (`> ... cline  .cline/rules/bem-te-vi-accessibility-qa.md`, ...). The fresh home install
is now of the four editors 4.0.1 installed there; the comparison is otherwise unchanged.
