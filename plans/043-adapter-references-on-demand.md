# Plan 043: Leave the skill references out of the merged adapters, and ship them beside each one

> **Executor instructions**: Marco decided the approach on 2026-10-18 (see "Decision"). This plan
> goes in as its own pull request first; the implementation follows on a second branch stacked on
> it, both into `next`. Order: the installers (with their conformance cases, red first), then the
> generators and the adapter checks, then the shipped wording, then the README, then the outcome
> here. One concern per commit. Run every command in "Commands" and read its output. If anything in
> "STOP conditions" occurs, stop and report. When done, update this plan's row in `plans/README.md`.
>
> **Drift check (run first)**: `git diff --stat 80ee1dd..HEAD -- generate-adapters.sh generate-adapters.ps1 install.sh install.ps1 bin/cli.js .qa-skills-editor-map tests/verify-adapters.sh tests/verify-adapters.ps1 tests/conformance README.md .claude/commands/qa.md .claude/skills/qa-reference/SKILL.md`
> Another agent is moving the CLI out of `bin/cli.js` and another is fixing the installers. A
> change to any of these files since planning means a line reference below may be stale: re-read
> it before relying on it, and keep the installer change as small as Step 1 describes.

## Status

- **Priority**: P1 (every non-Claude install carries a file far over its editor's documented size)
- **Effort**: M
- **Risk**: MEDIUM (touches all three installers; the safety layer is reused, not changed)
- **Depends on**: plan 021 (references exist), plan 033 (installer parity, file-safety contract),
  plan 034 (pointer convention), plans 035-038 (the reference files that doubled the adapters)
- **Category**: fix (adapters) and feature (installers ship new files)
- **Planned at**: commit `80ee1dd` (`github/next`), 2026-10-18
- **Decided by Marco, 2026-10-18**: leave the on-demand references out of the merged adapter
  files, and have the adapter point to the shipped reference files instead, as the Claude Code
  install already does.
- **Source**: pre-launch audit 2026-10-18; plan 021 "Approval gate" question 4, never planned.
- **Implemented**: 2026-10-18, PR #181 (stacked on the plan's PR #176), into `next`

## Why this matters

`generate-adapters.sh:81-106` and its twin `generate-adapters.ps1:127-142` merge every command,
rule, skill, agent **and every skill reference file** into one file per non-Claude editor. Plan 021
added the references to the merged file on purpose (so no content was lost), and recorded the size
problem as a follow-up it never wrote. Plans 034 to 038 then moved command detail into
`.claude/skills/qa-reference/references/`, so the merged file grew with every one of them.

Measured on `80ee1dd` (`./generate-adapters.sh --clean`, then `wc -c`, `wc -m`, `wc -l`):

| Adapter | Bytes | Characters | Lines |
| --- | --- | --- | --- |
| `windsurf/qa.md`, `copilot/copilot-instructions.md`, `cline/.clinerules` | 347,036 | 343,217 | 5,775 |
| `cursor/qa.mdc` | 347,179 | 343,358 | 5,780 |
| `antigravity/qa/SKILL.md` | 347,168 | 343,347 | 5,779 |
| `universal/AGENTS.md`, `universal/CLAUDE.md` | 347,680 | 343,859 | 5,784 |

Where the bytes come from: commands 117,113; skill `SKILL.md` files 83,933; **skill references
111,360 (15 files, all under `qa-reference`)**; rules 21,855; agents 19,588. Leaving the references
out takes each adapter to about 235,000 bytes, 232,000 characters and 3,690 lines (measured by
dropping the reference sections from the current file). `README.md:98-100` still says "about
244 KB" for the merged file.

What each editor documents, read on 2026-10-18:

| Editor | What its documentation says | Source |
| --- | --- | --- |
| Windsurf (now Devin docs) | "Workspace rule files are limited to 12,000 characters each." "The global rules file is limited to 6,000 characters." Global rules live in `~/.codeium/windsurf/memories/global_rules.md`; workspace rules in `.devin/rules/*.md`, with `.windsurf/rules/*.md` as the fallback, and "The legacy single-file `.windsurfrules` at the workspace root is also still read." Activation modes: Always On, Model Decision (only the description is in the prompt), Glob, Manual. What happens above the limit is not stated. | <https://docs.devin.ai/desktop/cascade/memories> |
| Cursor | "Keep rules under 500 lines"; "Split large rules into multiple, composable rules"; "Project rules must use the `.mdc` extension"; "A plain `.md` file in `.cursor/rules` is ignored by the rules system because it has no frontmatter". On pointing to files: "A file mention like `@migration-template.sql` tells Agent where to look, and Agent reads the file with its tools"; "The file's contents are not inlined into the prompt"; "Reference files instead of copying their contents." User rules are "defined in Customize → Rules", not files. | <https://cursor.com/docs/context/rules> |
| GitHub Copilot | No size cap on `.github/copilot-instructions.md` on the instructions page; its only length rule ("Instructions must be no longer than 2 pages") is inside the sample prompt for generating the file. The code-review tutorial: "Limit any single instruction file to a maximum of about 1,000 lines. Beyond this, the quality of responses may deteriorate." | <https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions>, <https://docs.github.com/en/copilot/tutorials/customize-code-review> |
| Cline | No numeric limit. "Rules consume context tokens"; "Keep rules concise and link to external documentation when detailed reference is needed." Workspace rules go in `.clinerules/` or `.cline/rules/`; every file there is combined, and files without frontmatter are always active. | <https://docs.cline.bot/features/cline-rules> |
| Antigravity | No numeric limit. A skill folder holds `SKILL.md` and optional `references/`; only the frontmatter is indexed at start, the body is injected when the skill activates, and "The skill instructs the agent to read this file only when needed." Workspace skills in `<project-root>/.agents/skills/`. | <https://codelabs.developers.google.com/getting-started-with-antigravity-skills?hl=en> (Google codelab; no other official page found) |

> **Correction to plan 021, 2026-10-18.** Plan 021 called Copilot's "no longer than 2 pages" a
> guideline for `copilot-instructions.md`. On the page read today that sentence is a constraint
> inside the sample prompt that generates the file, not a rule for the file. The 1,000-line figure
> above is the one Copilot documentation states. Plan 021 is not edited; this note is the record.

A search result also quoted a Copilot code-review limit of 4,000 characters per instruction file;
neither code-review page read today contains it, so it is not used here.

## Current state

**Generators.** `generate-adapters.sh:81-106` appends each `SKILL.md`, then each
`references/*.md` of that skill, under a `<!-- source: <skill>/references/<file> -->` marker
(`:31-38`). `generate-adapters.ps1:127-142` does the same; the Windows job compares the two
outputs byte for byte (`~/qa-ci-all.sh`, step "win-adapter-parity"). Adapters for Windsurf,
Copilot and Cline are the merged file unchanged (`generate-adapters.sh:248-250`); Cursor,
Antigravity and the two universal files get a header first (`:215-247`; `.ps1:213-234`).

**Adapter checks.** `tests/verify-adapters.sh:57-68` requires 13 marker strings, 12 of which are
only in reference files, and `:71-74` requires a `<!-- source: <skill>/references/<file> -->`
marker. `tests/verify-adapters.ps1:85-100` does the same with 6 markers (the two lists already
differ).

**Shipped wording that becomes false.** `.claude/skills/qa-reference/SKILL.md:41-43`: "In a single
merged file, it is the section that starts with `<!-- source: qa-reference/references/<file>.md -->`."
`.claude/commands/qa.md:70-77` names the merged-file section markers as the way to follow a pointer.
`README.md:168` says the references are "Inline" for every non-Claude install.

**What the installers write for a non-Claude editor: one file, nothing else.** The editor map
(`.qa-skills-editor-map`, one row per editor: adapter, project path, global path, label) is the
only input:

- `install.sh`: `install_to_editor` `*)` branch (`:1094-1115`) installs the one adapter;
  `package_files` (`:944-961`) lists it; `prune_unshipped` (`:1001`) maps every non-Claude
  manifest entry back to the adapter; `uninstall_from_editor` `*)` (`:1218-1239`) uninstalls it and
  removes its emptied folders.
- `install.ps1`: `Install-ForEditor` `default` (`:1179-1200`), `Get-PackageFiles` (`:1205-1229`),
  `Remove-Unshipped` (`:1264-1265`), `Uninstall-ForEditor` `default` (`:656-700`).
- `bin/cli.js`: `installNonClaudeEditor` (`:672-700`), `editorSourcePath` (`:965-973`),
  `packageFilesFor` (`:1100-1127`), `detectAndAdoptEditor` (`:1164-1180`), `cmdUninstallInit`
  (`:829-840`).
- Conformance cases 001-025 and the lifecycle suites assert only the adapter path for these
  editors (for example case 010, `tests/test-lifecycle.sh:84-94`).

So a pointer such as `qa-reference/references/testing-design.md` in a Cursor or Windsurf install
resolves today only because the text is in the merged file. Take it out and the pointer leads
nowhere unless the installers start shipping the files.

## Decision: where the reference files live

**Each non-Claude install gets the reference files in `<base>/.bem-te-vi/<editor>/`, laid out as
the pointers name them: `.bem-te-vi/<editor>/<skill>/references/<file>.md`.** `<base>` is the
project root for a project install and the home folder for a global install, exactly as for the
adapter. An editor with no global location (Copilot, Cline) gets no references on a global
install, as it gets no adapter. All three installers derive the path from the editor name; the
editor map does not change.

Why this layout:

- **It never loads as a rule.** None of the five editors reads `.bem-te-vi/`: Cursor loads `.mdc`
  files from `.cursor/rules`, Windsurf `.devin/rules`, `.windsurf/rules` and `.windsurfrules`,
  Cline `.clinerules/` and `.cline/rules/`, Copilot `.github/` instruction files, Antigravity
  `.agents/skills/`. A reference placed under any of those could become an always-on rule and undo
  the saving.
- **The pointer resolves by one prefix.** The package already names references
  `qa-reference/references/<file>.md` everywhere (plan 034 step 3); the adapter only has to say
  "prefix `.bem-te-vi/<editor>/`". Nothing in the shipped commands changes.
- **One folder per editor, so uninstall stays per editor.** The manifest records
  `<hash>  <editor>  <path>`. If two editors shared one folder, uninstalling one would remove files
  the other still points to (uninstall removes every file still as recorded for that editor).
  Separate folders keep conformance case 010 ("uninstalling one editor spares another") true. The
  cost is about 111 KB per extra editor installed.
- **The file-safety contract is inherited, not rewritten.** Every reference goes through the same
  `install_file` / `Install-File` / `installFile` as every other file, so backup, adoption by
  known hash, the symlink and read-only rules and the manifest write are unchanged. `.bem-te-vi` is
  the top-level folder, so a link there is followed and a link below it is never written through
  (plan 033 item 1), as for `.claude`.
- **The package already ships them.** `.claude/skills/` is in the npm `files` list
  (`package.json`) and in every checkout the shell installers run from.

**Rejected: point to a stable public URL instead.** The repository is private until plan 020
part B, so no such URL resolves today; a URL works only when the editor's agent can fetch the web
and is online; it pins the reader to whatever the URL serves rather than the installed version; and
Marco's decision names "shipped reference files". Kept only as the answer for the hand-copied
universal adapters, see below, and even there the first instruction is to copy the folder.

**Rejected: the editor's own folder (`.cursor/bem-te-vi/`, `.agents/skills/qa/references/`).**
Antigravity's native layout would be `.agents/skills/qa/references/`, but Windsurf's and Cline's
project adapters are single files at the project root with no folder of their own, so each editor
would need its own rule in three installers. One derived path is simpler and identical everywhere.

**The universal adapters** (`universal/AGENTS.md`, `universal/CLAUDE.md`) are never installed by
an installer; the README tells the reader to copy them by hand. Their note says the references are
the package's `qa-reference/references/` folder and asks the reader to copy it beside the file (or
attach the reference needed), so a pointer still leads somewhere.

## The pointer in each adapter

Both generators write a short ASCII note right after the editor's header (frontmatter or the
universal comment) and before the first section, so it is near the top of every adapter (Copilot's
guidance is to put what matters first). For an installed editor `<key>`:

```markdown
<!-- bem-te-vi: references -->
> **Reference files are separate.** This file does not contain the `qa-reference` skill's
> reference files. A pointer such as `qa-reference/references/<file>.md` names the file
> `.bem-te-vi/<key>/qa-reference/references/<file>.md`, installed with this one: in the project
> root for a project install, in your home folder for a global install. Read that file when a
> section tells you to; its text is not repeated here.
```

The universal note says the same, naming the package's `.claude/skills/qa-reference/references/`
folder and asking the reader to copy it to `.bem-te-vi/universal/` beside the file. The exact text
is fixed in the generators; this is its content.

## What else could leave the merged file (and why it does not, here)

Leaving the references out cuts each adapter by about a third. It does **not** bring any adapter
under a documented limit, and nothing short of splitting the adapter into many files would:

| Editor | Limit | After this plan | Over by |
| --- | --- | --- | --- |
| Windsurf workspace rule | 12,000 characters per file | about 232,000 characters | about 19 times |
| Windsurf global rule (`global_rules.md`) | 6,000 characters | the installer does not write this file (see "Findings outside scope") | n/a |
| Cursor | "under 500 lines" (recommendation) | about 3,700 lines | about 7 times |
| Copilot | "about 1,000 lines" (recommendation) | about 3,700 lines | about 4 times |
| Cline | none stated | about 232,000 characters | n/a |
| Antigravity | none stated; body loads on activation | about 232,000 characters | n/a |

Every remaining section is a command, a skill body, a rule or an agent: the content the editor must
see to run `/qa-cases` at all. The next cut is **per-editor splitting**, each editor's own
on-demand mode: Cursor one `.mdc` per command with "Apply Intelligently", Windsurf one Model
Decision rule per command under 12,000 characters, Cline `paths:` rules, Copilot
`.instructions.md` files, Antigravity one skill per source skill. That turns one file per editor
into dozens in all three installers, and needs each editor's loading behaviour verified by running
it, which this environment cannot do. Marco's decision names the references only; the evidence does
not force more inside this plan. It goes to the backlog in `plans/README.md` as a candidate plan.

## Steps

### Step 1: the installers ship the references (red first)

Write the conformance cases first and run them against the unchanged installers; quote the failures
in the pull request. New cases (numbers after the highest one on `next` when implementing):

1. **A non-Claude install ships the references beside the adapter**: `install project cursor` and
   `install global antigravity` put `qa-reference/references/testing-design.md` (byte-identical to
   the package's) under `.bem-te-vi/<editor>/`, recorded under that editor; `install global
   copilot` writes no `.bem-te-vi/copilot`.
2. **Uninstalling one editor removes its references and spares another's**: install Windsurf and
   Cline, uninstall Windsurf; `.bem-te-vi/windsurf` is gone, Cline's references and entries stay.
3. **Update adds the references to an install that predates them**: install Cursor, drop one
   reference and its entry, update; it is installed and recorded ("Added").
4. **Update removes a reference the package stopped shipping**: install Cursor, seed a recorded
   `.bem-te-vi/cursor/qa-reference/references/retired-reference.md`, update; it is removed and its
   entry dropped. Red today because every non-Claude entry maps back to the adapter, which exists.

Then the same change in each installer, nothing else:

- a helper that lists `(package file, destination)` for every `.claude/skills/*/references/*.md`,
  destination `<base>/.bem-te-vi/<editor>/<skill>/references/<file>`;
- install: after the adapter is installed, install each pair through the existing install function;
- the package-file list used by update and adoption: add the pairs;
- the update prune: an entry under `.bem-te-vi/<editor>/` maps back to
  `.claude/skills/<rest>`, every other entry to the adapter as today;
- uninstall: the existing per-editor removal already removes every recorded file; then remove the
  emptied reference folders up to the base, never inside a linked folder.

Commit: `feat(installers): ship the skill references beside each non-Claude adapter`.

### Step 2: the generators leave the references out and write the pointer

`generate-adapters.sh` and `generate-adapters.ps1`: drop the references loop; write the note above
after each editor's header. Output must stay byte-identical between the two. `verify-adapters.sh`
and `.ps1` (made identical): no adapter may contain a `<!-- source: <skill>/references/... -->`
section; each must contain the note and the path it names (`.bem-te-vi/<key>/` for an installed
editor); the reference-only marker strings are removed, the markers that live in commands, rules,
skills and agents stay. Commit: `fix(adapters): point to the reference files instead of merging them`.

### Step 3: the shipped wording

`.claude/skills/qa-reference/SKILL.md:41-43` and `.claude/commands/qa.md:70-77`: a merged file
carries no reference sections; the references are installed in `.bem-te-vi/<editor>/` as its
opening note says. No `.claude/skills/` path and no concrete reference path with a prefix in the
text (`tests/test-reference-links.sh` refuses both). These are released files: older hashes stay in
`.qa-skills-known-hashes`, `--check` must pass unchanged. Commit:
`fix: say where a merged adapter's reference files are`.

### Step 4: the README

`README.md:98-100` and the install table at `:168` with the measured sizes and the new location;
the command table (`:193-203`) with every size re-measured. Commit:
`docs: update the adapter and command sizes in the README`.

### Step 5: verify and record

Run "Commands", then `bash ~/qa-ci-all.sh <worktree>`. Record the outcome here, with the new size
of each adapter against its editor's limit, and update `plans/README.md`.

## Commands

| Purpose | Command | Expected |
| --- | --- | --- |
| Adapters | `./generate-adapters.sh --clean && ./tests/verify-adapters.sh` | exit 0 |
| Conformance | `./tests/conformance/test-runner.sh && ./tests/conformance/run.sh` | pass, new cases included |
| Lifecycle | `./tests/test-lifecycle.sh` | pass (Test 20 is the known failure until `fix/update-adopts-current-files` lands) |
| Reference pointers | `./tests/test-reference-links.sh` | exit 0 |
| Citations, frontmatter | `./tests/test-ctfl-citations.sh`, `./tests/test-frontmatter.sh` | exit 0 |
| Known hashes | `./generate-known-hashes.sh --check` | exit 0, unchanged |
| All three platforms | `bash ~/qa-ci-all.sh <worktree>` | "ALL LOCAL CI": linux, mac, windows PASS |

## Done criteria

- [ ] No adapter contains a reference section; every adapter opens with the note.
- [ ] Every non-Claude install (project, and global where the editor has one) has the 15 reference
      files under `.bem-te-vi/<editor>/`, recorded under that editor; uninstall removes them.
- [ ] The four new conformance cases fail on the old installers (quoted) and pass on all three new.
- [ ] Both generators' output identical (Windows parity step).
- [ ] README sizes are measured figures.
- [ ] The outcome below lists each adapter's new size against its editor's limit.

## STOP conditions

- An installer change needs more than the five touch points in Step 1 (for example a change to the
  manifest format or the editor map): stop, the file-safety contract is shared.
- A conformance case cannot be made red against the old installers: it tests nothing; stop.
- Another agent's merged change to an installer conflicts with Step 1 in a way that is not a plain
  textual merge: stop and report.
- The pointer cannot be written without a path `tests/test-reference-links.sh` refuses: stop.

## Rejected approaches

- **A public URL for the references**: see "Decision".
- **The editor's own folder for the references**: see "Decision".
- **One shared `.bem-te-vi/references/` for every editor**: uninstalling one editor would delete
  files another editor's adapter points to.
- **Split the adapters per editor in this plan**: see "What else could leave the merged file".
- **Keep the references in the merged file for editors with no stated limit (Cline, Antigravity)**:
  two generator paths for a saving the decision already covers; every editor reads files on request.

## Findings outside scope (recorded, not fixed)

- Cursor: user rules are "defined in Customize → Rules"; the global install's
  `~/.cursor/rules/qa.mdc` is not a documented location.
- Windsurf: the documented global file is `~/.codeium/windsurf/memories/global_rules.md` (6,000
  characters); the global install writes `~/.windsurf/rules/qa.md`.
- Cline: the docs now describe `.clinerules/` and `.cline/rules/` folders only; the project install
  writes a single `.clinerules` file.
- Antigravity: the codelab names `~/.gemini/config/skills/` as the global location; the editor map
  has `.gemini/antigravity/skills/`.

Each changes an installer target path, so each needs its own plan and conformance cases.

## Outcome

Implemented 2026-10-18 on `feat/plan-043-adapter-references`, stacked on the plan's own pull
request (#176). Marco decided the approach himself; the location (`.bem-te-vi/<editor>/`) and the
rest are this plan's decisions above, so no documented default was needed.

### What was built

1. **Installers** (`3285f59`): the same five touch points in `install.sh`, `install.ps1` and
   `bin/cli.js`, nothing else. A new helper in each (`reference_files`, `Get-ReferenceFiles`,
   `referenceFilesFor`) lists every `.claude/skills/*/references/*.md` with its destination
   `<base>/.bem-te-vi/<editor>/<skill>/references/<file>`. Install calls the existing install
   function for each after the adapter; the package-file list (update, adoption) adds them; the
   update prune maps an entry under `.bem-te-vi/<editor>/` back to `.claude/skills/<rest>`;
   uninstall removes the emptied folders, never inside a linked one. The editor map, the manifest
   format and the safety functions are unchanged. Conformance cases 026-030.
2. **Generators and checks** (`b88a84f`): both generators drop the references loop and write the
   note after each editor's header; `verify-adapters.sh` and `.ps1` now run the same checks (no
   reference section, the note in the first 15 lines, the folder it must name, one marker per
   remaining source kind). The six reference-only marker strings in the `.ps1` and twelve in the
   `.sh` are gone with the sections they tested.
3. **Shipped wording** (`396b737`): `qa-reference/SKILL.md` and `/qa` say the references are
   installed beside a merged file under `.bem-te-vi/<editor>/`.
4. **README** (`c4d43a3`): adapter size, the install table (a separate row for the hand-copied
   `AGENTS.md` and `CLAUDE.md`), every command size (KB = 1,024 bytes, rounded).

### Red evidence

- Cases 026-029 against the installers at `80ee1dd`: every installer fails, on Linux (`install.sh`,
  CLI) and on Windows PowerShell 5.1 (`install.ps1`, CLI), each on the missing files, the missing
  manifest entries and, for 028 and 029, the missing "Added" and "no longer shipped". Case 029 also
  showed a real defect in the old CLI: it "Refreshed" the recorded reference by copying the Cursor
  adapter over it, because every non-Claude entry mapped back to the adapter.
- Cases 027 and 030 cover folder cleanup, which an old installer passes vacuously (it never created
  the folders). They were run against an intermediate build that installs the references but does
  not clean up, and failed there on `install.sh` and the CLI: "should not exist:
  project:.bem-te-vi/windsurf" and "should not exist: project:.bem-te-vi".
- The new `verify-adapters.sh` against the adapters built at `80ee1dd`: "cursor/qa.mdc contains a
  skill reference section", "does not open with the note", "does not name
  .bem-te-vi/cursor/qa-reference/references/<file>.md".

### Sizes after the change, against each editor's documented figure

Measured at `c4d43a3` (`wc -c`, `wc -m`, `wc -l`):

| Adapter | Bytes | Characters | Lines | Documented figure | Status |
| --- | --- | --- | --- | --- | --- |
| `windsurf/qa.md` | 235,840 | 232,484 | 3,700 | 12,000 characters per workspace rule file | over, about 19 times |
| `cursor/qa.mdc` | 235,981 | 232,623 | 3,705 | "under 500 lines" | over, about 7 times |
| `copilot/copilot-instructions.md` | 235,839 | 232,483 | 3,700 | "about 1,000 lines" | over, about 4 times |
| `cline/.clinerules` | 235,837 | 232,481 | 3,700 | none stated | n/a |
| `antigravity/qa/SKILL.md` | 235,975 | 232,617 | 3,704 | none stated | n/a |
| `universal/AGENTS.md`, `universal/CLAUDE.md` | 236,559 | 233,201 | 3,711 | n/a (copied by hand) | n/a |

Down from 347,036 bytes (32 percent). Each install of a non-Claude editor now also writes the 15
reference files (111,360 bytes) under `.bem-te-vi/<editor>/`. Per-editor splitting stays in the
backlog.

### Verification

`bash ~/qa-ci-all.sh` at `c4d43a3`: "ALL LOCAL CI (plan-043 @ c4d43a3): linux=PASS mac=PASS
windows=PASS". Linux 20 of 20 steps (lifecycle included, so the known Test 20 failure no longer
occurs on `next`); macOS under bash 3.2.57 5 of 5; Windows PowerShell 5.1 lint, adapters,
conformance (46 passed, 14 symlink cases not run: no Developer Mode) and lifecycle, plus
byte-for-byte parity of the two generators' output. `./generate-known-hashes.sh --check` passes
unchanged. Not run: any of the five editors themselves, so that each one follows the note to the
installed file is documented behaviour (quoted above), not observed.
