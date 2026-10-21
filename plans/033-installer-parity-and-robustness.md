# Plan 033: The three installers agree, and none of them writes where it should not

> **Executor instructions**: Do this plan **after** plan 032 has merged and **before** plan 020
> part B exports the tree to the public repository. Each item is its own branch and pull request.
> Read `CLAUDE.md` §5 ("Installer File-Safety Contracts") and plans `009`-`012` and `026` first.
> Every item starts with a failing test; quote that failure in the pull request. Run every
> verification command. If anything in "STOP conditions" occurs, stop and report; do not improvise.
> When an item lands, update this plan's row in `plans/README.md`.
>
> **Drift check (run first)**: `git diff --stat a2f08e7..HEAD -- install.sh install.ps1 bin/cli.js generate-adapters.sh generate-adapters.ps1 tests/conformance tests/test-lifecycle.sh tests/test-lifecycle.ps1 CLAUDE.md README.md`
> Plan 032 touches the lifecycle suites; re-read each "Current state" excerpt against the live code
> before starting an item. A mismatch in an installer is a STOP condition.

## Status

- **Priority**: P0 (items 1-2), P1 (items 3-5, 7), P2 (items 6, 8, 9)
- **Effort**: L overall; each item S or M
- **Risk**: MEDIUM (every item changes what an installer writes or deletes in a user's tree)
- **Depends on**: plan 032 (lifecycle fixtures it rewrites); plans 009-013 and 026 (the contracts
  kept here). All of it is done in this private repository, before plan 020 part B.
- **Category**: bug
- **Planned at**: commit `a2f08e7`, 2026-10-14
- **Decided by Marco, 2026-10-14**: item 1 refuses linked folders *below* the editor's top-level folder only (the top-level folder itself may be a link, for dotfile setups); item 3: `update` also installs files a release starts shipping.
- **Decisions for Marco**: item 1 (which symlinked directories are refused) and item 3 (what
  `update` does with files the package added since the install); defaults below.

## Why this matters

`CLAUDE.md` promises that `install.sh`, `install.ps1` and `bin/cli.js` behave identically and never
destroy a file they did not write. The audit after 4.0.0 listed eight places where that is not
quite true. Re-checking them for this plan, on a scratch copy of `a2f08e7`, turned two of them into
data-loss reproductions:

```text
# Item 1: `bem-te-vi link` from the npm package, then install.sh from a clone, same project
link exit=0
install.sh install exit=0     package files: 39 before, 39 after
install.sh uninstall exit=0   package files: 39 before, 1 after
  "Bem-te-vi has been completely removed. Removed 38 file(s)."

# Item 2: a symlink planted at .qa-skills-manifest.tmp, pointing at victim.txt ("VICTIM CONTENT")
sh  install exit=0  victim.txt now: "d94b5d14…  claude  .claude/commands/qa-trace.md" (1 line)
cli init    exit=0  victim.txt now: "691d65af…  claude  .claude/commands/qa-agentic.md" (1 line)
```

The first deletes the npm package's own files through the links `bem-te-vi link` created. The
second lets a repository a user clones overwrite any file the user can write, because
`.qa-skills-manifest` sits at the project root and is meant to be committed. The rest are parity
gaps (the CLI and the shell installers disagree on what `update` does), silent acceptance of typos,
a generator that overwrites `~/.claude/CLAUDE.md`, and documentation that describes contracts the
code does not implement.

## Current state

Every claim below was read at `a2f08e7` or reproduced on a scratch copy of it (scripts in "Commands
you will need"). Windows behaviour was read, not run, except where a `powershell.exe` result is
quoted.

1. **Symlinked parent directories.**
   - `install.sh:667` checks `[ -L "$DEST" ]` for the file only; `:709-710` then
     `mkdir -p "$(dirname "$DEST")"` and `cp "$SRC" "$DEST"` follow a symlinked directory anywhere on
     the path. `uninstall_recorded` (`:730-766`) deletes `$BASE/$REL` through the same links.
   - `install.ps1:848-849` checks `$existingItem.LinkType` for the file only; `:892-893`
     (`New-Item -ItemType Directory -Path (Split-Path -Parent …)`, `Copy-Item`) follow linked
     directories, and `Uninstall-Recorded` (`:913-947`) deletes through them.
   - `bin/cli.js:538-541` (`installClaudeEditor`) removes a symlink at `.claude/<sub>` and copies a
     real directory in its place (`~ replaced symlink → copy`); deeper links are followed.
     `cmdUninstallInit` skips a `.claude/<sub>` that `linkedIntoPackage` (`:486-497`) recognises
     (plan 026 item 1); the shell installers have no such check.
   - Reproduced, case A (`.claude/rules` → an outside directory holding the user's
     `security-qa.md`): `install.sh` wrote 9 package files and a backup into the outside directory
     and replaced the user's file there; `cli init` replaced the link with a real directory and left
     the outside directory untouched. Case B is the reproduction quoted above.
2. **Manifest temp file.** `install.sh:571` (`TMP="$MF.tmp"`, then `: > "$TMP"`) and `:735`;
   `bin/cli.js:228` (`${mf}.tmp`, `writeFileSync`). Both follow a symlink at that name (reproduced
   above). `install.ps1:783` uses `$mf.tmp-$PID`: predictable, not exclusive. Three manifest writes
   are not atomic at all and also follow a symlinked manifest: `bin/cli.js:468` (uninstall),
   `bin/cli.js:819` (`removeManifestEntries`), `install.ps1:945` (`Uninstall-Recorded`).
3. **`update` parity.** Reproduced with a manifest entry for a file the package no longer ships
   (`retired-rule.md`, unchanged since install) and, separately, a file the package ships that the
   install predates (`test-tools.md` removed with its entry):

   ```text
   install.sh --update : retired file present, entry kept;  new file installed
   cli update          : retired file absent,  entry gone;  new file NOT installed
   ```

   `install.sh` has no update path of its own: `--update` only skips the overwrite prompt
   (`check_version_conflict`, `:203-229`, the skip at `:206-208`). `install.ps1` is the same
   (`Test-VersionConflict`, `:142-150`). `bin/cli.js:832-895` (`updateManifestEditor`) walks only
   manifest entries, so it prunes, but never adds. Plan 013 item 4 asked update to report "what was
   added"; `README.md:354` says update "Installs nothing that was not already installed". With
   nothing installed, the CLI does nothing (`:1030-1042`, the no-manifest branch); `install.sh --update` installs everything.
4. **CLI accepts anything.** `bin/cli.js:1095-1117`: an unknown command falls to `default:` and
   prints help with exit 0. `resolveTarget` (`:79-81`) and `parseEditorFlag` (`:91-106`) look for
   known flags and ignore the rest. Reproduced: `bem-te-vi instal` → exit 0;
   `bem-te-vi init --globl --editor claude` → exit 0, installed into the **project** (`.claude/`
   and `.qa-skills-manifest` created in the working directory). `install.sh --bogus` → exit 1
   (`:62-66`). `install.ps1` rejects unknown parameters through `param()` binding (`:36-50`).
5. **`install.ps1` wildcard paths.** `Test-Path` without `-LiteralPath` on computed paths at
   `:592`, `:720`, `:801`, `:839`, `:916`, `:929`, `:951-952`, `:963`, plus `:600-630`. Checked on
   Windows PowerShell 5.1.26100 with a manifest that exists under `%TEMP%\btv[1]\`:
   `Test-Path` → `False`, `Test-Path -LiteralPath` → `True`; `New-Item -Path` created the directory
   correctly. So in a project whose path contains `[` or `]`: `Get-ManifestLines` (`:720`) reads
   nothing and the next install rewrites the manifest with only this run's entries, dropping other
   editors'; `Uninstall-Recorded` (`:916`) returns early, `$hadManifest` (`:963`) is false, and
   `Remove-IfMatches` (`:951`) never finds a file, so uninstall removes nothing and reports
   "Nothing to uninstall".
6. **`install.ps1` out-of-base guard.** `Install-File` (`:844-846`) computes
   `$rel = $DestinationPath.Substring($BaseDir.Length)` with no check that the destination is
   inside the base. The comment at `:897-901` says "Install-File refuses to *record* such a path";
   it does not. `install.sh:660-666` and `bin/cli.js:290-295` both refuse, and
   `tests/test-lifecycle.sh` (around `:400-430`) tests the bash guard by extracting the function.
7. **`GLOBAL=true ./generate-adapters.sh`** (`:243-255`) runs `cp` over `~/.claude/CLAUDE.md` and
   `~/AGENTS.md`. Reproduced with both seeded: exit 0, both replaced, no backup. The `[TIP]` lines
   (`:257-260`) and the header written into both universal adapters (`generate-adapters.sh:218-227`,
   `generate-adapters.ps1:164-172`, shipped in `adapters/`) tell users to run the same `cp`.
8. **Installer completion text.** `install.sh:1252` and `install.ps1:1408` list 7 of the 10
   `/qa-*` commands (missing `/qa-agentic`, `/qa-static`, `/qa-trace`); `:1254`/`:1410` 4 of the 9
   rules; `:1255`/`:1411` 2 of the 4 skills. `install.sh:1277` and `install.ps1:1423` print
   "Quick start: …/INSTALL.md"; no such file exists (`ls INSTALL.md` fails). `install.ps1:1134` is
   the same line inside `Write-NextSteps` (`:1118-1139`), which nothing calls. `install.ps1:8` and
   `:61` still say "ISTQB CTFL v4.0 + Postman + JUnit + Playwright"; `:15-16` lists five editors
   (no `antigravity`). `bin/cli.js:626-628` prints no list at all ("Open your editor and type /qa
   to get started."), so the three installers' hints already differ.
9. **`CLAUDE.md` §5.** `:113` gives both shared files the format `<sha256>  <editor>  <path>`;
   `.qa-skills-known-hashes` has two fields (`awk '{print NF}'` → 128 lines of 2). `:115` says a
   symlinked destination is skipped; every installer backs up its content, writes
   `<backup>.link-target`, and replaces the link (conformance case `008`).

## Commands you will need

| Purpose | Command | Expected on success |
| --- | --- | --- |
| Adapters (the suites need them) | `./generate-adapters.sh --clean` | exit 0 |
| Lifecycle (bash + CLI) | `./tests/test-lifecycle.sh` | ends `100% GREEN` |
| Conformance (bash + CLI) | `./tests/conformance/run.sh` | `Conformance: N/N passed, 0 failed` |
| One case against an old tree | `CONFORMANCE_PKG=<copy of main> ./tests/conformance/run.sh <NNN>` | fails before the fix |
| Shell lint | `npx --yes shellcheck@3.1.0 install.sh generate-adapters.sh tests/test-lifecycle.sh tests/conformance/run.sh` | no output |
| CLI | `node --check bin/cli.js && npx eslint bin/cli.js` | exit 0 |
| Windows suites | `tests\test-lifecycle.ps1`, `tests\conformance\run.ps1` | CI Windows job |

Build every reproduction outside the repository: `git archive HEAD | tar -x -C "$(mktemp -d)"`,
then `./generate-adapters.sh` inside that copy. Never point a reproduction at this checkout: the
case B reproduction deletes the package tree it links to.

## Scope

**In scope**: `install.sh`, `install.ps1`, `bin/cli.js`, `generate-adapters.sh`,
`generate-adapters.ps1` (the universal header only), `tests/conformance/run.sh`,
`tests/conformance/run.ps1`, `tests/conformance/README.md` (new directives), new cases under
`tests/conformance/cases/`, both lifecycle suites, `README.md` (the install, `update` and
symlink paragraphs only), `CLAUDE.md` §5, `plans/README.md` (status row).

**Out of scope**: the manifest and known-hash formats (unchanged); the git hook code (plan 026);
generator parity beyond the header (plan 037 step 1); tests of paths no fix here touches (plan 037).

**Boundary with plan 037**: this plan tests its own fixes, red first. Plan 037 covers paths no plan
touches. The directory-symlink cases added here satisfy 037's "directory symlinks" line.

## Git workflow

- One branch and pull request per item: `fix/<slug>` from `main`.
- Commit types (CONTRIBUTING.md §2): a change to an installer, `bin/`, `.claude/` or `adapters/`
  output is `fix:`; a test or conformance runner change is `test:`; `CLAUDE.md` is `docs:`.
  Commit the failing test first (`test:`), then the fix (`fix:`), so the red state is in history.
- No AI attribution lines in commits or pull request bodies. Merge with a default merge commit,
  never squash, never an empty body (`CLAUDE.md` §8). Do not merge without Marco's approval.
- Keep `install.sh` on bash 3.2: no `declare -A`, no `${var,,}`, no `mapfile`.

---

## Item 1 (P0): never write or delete through a symlinked directory

**Decision (default)**: a symlinked directory **below** the editor's top-level directory (any
directory under `.claude/`, `.cursor/`, `.windsurf/`, `.agents/`, `.gemini/`, `.github/`) is never
written or deleted through. The top-level directory itself (`.claude` → a dotfiles repository is a
common setup, and the editor reads through it) is followed as today. *Alternative for Marco*: refuse
every symlinked directory between the base and the file, top level included; safer, but a global
install into a symlinked `~/.claude` would then install nothing.

Behaviour, identical in all three installers:

- **Install / update**: for each file, walk the directories from the top-level directory
  (exclusive) to the file (exclusive). If one is a symlink, skip the file and print, once per link,
  `! Skipped <dir>/ — it is a symbolic link; nothing was written through it`. When the link is a
  `bem-te-vi link` (`isBemTeViLink` logic: its target ends in `.claude/<sub>`), add
  `run 'bem-te-vi unlink' first`. Carry on with the rest.
- **Uninstall / update removal**: a manifest entry whose path crosses such a link is kept, keeps
  its manifest entry, is reported with the same phrase, and counts as kept.
- **CLI**: remove the replace-link-with-copy branch at `bin/cli.js:538-541`, so `init` after `link`
  skips those folders with the message above instead of silently converting them. Keep plan 026's
  `linkedIntoPackage` check in `cmdUninstallInit`; the new rule covers it, but it costs nothing.

Steps:

1. Red: add conformance cases (they need no runner change; `seed-symlink` already creates directory
   links and `run.ps1` reports "not run" without Developer Mode):
   - `013-symlinked-directory-not-written-through`: `seed: home:outside/security-qa.md = MY OWN
     OUTSIDE RULE`, `seed-symlink: project:.claude/rules -> home:outside`, `run: install project
     claude`; expect exit 0, `expect-content: home:outside/security-qa.md = MY OWN OUTSIDE RULE`,
     `expect-absent: home:outside/testing-guidelines.md`, `expect-file:
     project:.claude/commands/qa.md` (the rest installed), `expect-output: symbolic link`.
   - `014-uninstall-never-deletes-through-a-symlinked-directory`: `seed-package:
     home:outside/security-qa.md = .claude/rules/security-qa.md`, `seed-symlink:
     project:.claude/rules -> home:outside`, `seed-manifest: project claude
     .claude/rules/security-qa.md`, `run: uninstall project claude`; expect
     `expect-same-as-package: home:outside/security-qa.md = .claude/rules/security-qa.md`,
     `expect-manifest: project claude .claude/rules/security-qa.md`, `expect-output: symbolic link`.
   Before any installer change, align the phrase: all three must print `symbolic link` (see
   "Output is a contract" in `tests/conformance/README.md`). Run both cases against a copy of
   `main`: `013` fails for `install.sh` and `install.ps1` (the CLI passes today), `014` fails for
   all three.
2. Red: lifecycle Test 44 in `tests/test-lifecycle.sh`: the case B script (CLI `link` from one
   package copy, `install.sh` install and uninstall from another, both under `$SANDBOX_DIR`); fail
   unless the linked package's file count is unchanged. Mirror it in `tests/test-lifecycle.ps1`
   (`install.ps1` instead of `install.sh`); if `node bin/cli.js link` cannot create links on the
   runner, the PowerShell copy creates them with `New-Item -ItemType SymbolicLink` and skips with a
   message when that fails too.
3. Fix `install.sh`: a helper `linked_ancestor BASE REL` printing the first symlinked directory
   between `$BASE/<first segment of REL>` (exclusive) and the file, using `[ -L ]` on each prefix.
   Call it in `install_file` before the `[ -L "$DEST" ]` check, and in `uninstall_recorded` and
   `remove_if_matches` before deleting.
4. Fix `install.ps1`: the same helper with `Test-IsLink` (`:290-294`) on each prefix; call it in
   `Install-File`, `Uninstall-Recorded` and `Remove-IfMatches`.
5. Fix `bin/cli.js`: the same helper with `isSymlink`; call it in `installFile`,
   `uninstallRecorded`, `removeIfMatches`, `updateManifestEditor`'s removal branch and
   `detectAdoptOne`; delete `:538-541`.
6. `README.md:292`: add one sentence for the directory rule.

**Verify**: cases `013`, `014` pass for every installer; lifecycle green in both suites; the case B
script prints `before=39 after=39` (or whatever the current count is, unchanged).

## Item 2 (P0): manifest writes are exclusive and atomic

Behaviour: every manifest write goes to a new, uniquely named temporary file in the same directory,
created exclusively (fails if anything, including a symlink, already has that name), then renamed
over `.qa-skills-manifest`. A rename replaces a symlinked manifest rather than writing through it.

1. Red: conformance case `015-planted-temp-file-link-not-written-through`: `seed: home:victim.txt
   = VICTIM CONTENT`, `seed-symlink: project:.qa-skills-manifest.tmp -> home:victim.txt`,
   `run: install project claude`, `run: uninstall project claude`; expect
   `expect-content: home:victim.txt = VICTIM CONTENT`. Fails today for `install.sh` and the CLI;
   `install.ps1` uses another name and passes (record that in the pull request; its fix is
   hardening, not a reproduced defect).
2. `install.sh`: one helper `manifest_write MF` that reads the new body on stdin, writes it to
   `TMP="$(mktemp "$MF.tmp.XXXXXX")"` (mktemp is exclusive on GNU and BSD), `chmod 644 "$TMP"`
   (mktemp creates 0600), then `mv -f "$TMP" "$MF"`. Use it in `manifest_record` (`:568-582`) and
   `uninstall_recorded` (`:730-766`).
3. `bin/cli.js`: one helper `writeManifest(mf, entries)` using
   `fs.openSync(tmp, "wx")`, where `tmp` is `.qa-skills-manifest.tmp-<pid>-<12 random hex
   characters>` (`process.pid`, `crypto.randomBytes(6)`), then `fs.renameSync`; when `entries` is empty, `fs.rmSync(mf, { force: true })`. Use it at
   `:222-234`, `:468` and `:819`.
4. `install.ps1`: `Save-ManifestBuffer` (`:779-787`) and `Uninstall-Recorded` (`:945`) both go
   through one function that opens `"$mf.tmp-$([guid]::NewGuid().ToString('N'))"` with
   `[System.IO.File]::Open($tmp, [System.IO.FileMode]::CreateNew)`, writes the bytes
   `Set-ManifestLines` writes today (no BOM, LF), closes it, then `Move-Item -LiteralPath $tmp
   -Destination $mf -Force`.

**Verify**: case `015` green everywhere; `grep -n '\.tmp"' install.sh` and
``grep -n '\.tmp`' bin/cli.js`` → no fixed names left; the round-trip tests still pass.

## Item 3 (P1): `update` means the same thing in all three installers

**Decision (default)**: the CLI's `update` is the contract, plus one addition. For every editor the
manifest records: refresh each recorded file the package still ships; **install each file the
package now ships that the manifest does not record yet** (through the normal install path, so a
colliding user file is backed up); remove each recorded file the package no longer ships if it is
unchanged, keep and report it if changed, and drop its entry either way. With no manifest: adopt
only files whose hash is known (plan 013 item 3); with nothing installed, write nothing and say
`Nothing installed`. *Alternative for Marco*: keep "installs nothing that was not already
installed" (`README.md:354`) and make the shell installers stop adding new files instead; users then
need `init` after every release that adds a file.

> **Note, 2026-10-20, plan 061 B1.** With no editor named, `install.sh --update` and `install.ps1
> -Update` still refreshed Claude Code only (their non-interactive default), so this contract held
> only with an editor named; both now take every editor the manifest records, as the CLI does
> (case 077).

1. Red: add `update` to the conformance runners: `run: update <scope> <editor>` maps to
   `--update` (`install.sh`), `-Update` (`install.ps1`), `update` (CLI). Document it in
   `tests/conformance/README.md`. New cases:
   - `016-update-removes-what-the-package-stopped-shipping`: `run: install project claude`,
     `seed: project:.claude/rules/retired-rule.md = RETIRED RULE`, `seed-manifest: project claude
     .claude/rules/retired-rule.md`, `run: update project claude`; expect
     `expect-absent: project:.claude/rules/retired-rule.md`,
     `expect-no-manifest: project claude .claude/rules/retired-rule.md`.
   - `017-update-keeps-a-changed-file-it-stopped-shipping`: same, then edit the file before
     `update`; expect the edit survives and the entry is gone.
   - `018-update-installs-what-the-package-started-shipping`: `run: install project claude`, then
     delete one file and its manifest entry (add a `drop-manifest: <scope> <editor> <path>` setup
     directive that removes the file and its line), `run: update project claude`; expect the file is
     back and recorded.
   - `019-update-with-nothing-installed-writes-nothing`: `run: update project claude`; expect
     `expect-absent: project:.claude`, `expect-absent: project:.qa-skills-manifest`.
   Against `main`: `016`, `017`, `019` fail for the shell installers, `018` for the CLI.
2. `install.sh`: `OPERATION=update` gets its own branch in `run_lifecycle_action` (`:1118`): for
   each editor, if the base has a manifest, run the install path for that editor (which refreshes
   and adds), then prune the manifest's entries for that editor whose source file
   (`$SCRIPT_DIR/.claude/<rel without .claude/>` or the editor's adapter) no longer exists, using
   `file_matches` and the read-only rule from `uninstall_recorded`. No manifest: adopt known-hash
   files only, as `detectAndAdoptEditor` does; nothing found → `Nothing installed`.
3. `install.ps1`: the same in `Install-ToDirectory` (`:1293`) when `$global:OPERATION -eq
   'update'`.
4. `bin/cli.js`: after `updateManifestEditor` refreshes recorded entries, walk the package's files
   for that editor (`installClaudeEditor`'s walk, or the single adapter) and `installFile` each one
   the manifest lacks; report them as `✓ Added <rel>`.
5. Align the summary lines: all three print `Refreshed`, `Added`, `Removed … (no longer shipped)`,
   `Kept … changed since it was installed`, `Nothing installed`.
6. `README.md:354` and the `--update` help text (`install.sh:129-130`) describe the decided
   behaviour.

**Verify**: cases `016`-`019` pass for all three; lifecycle Test 2 (`tests/test-lifecycle.sh:101`)
still passes.

## Item 4 (P1): the CLI rejects what it does not understand

Behaviour: `help`, `--help`, `-h` and no command print help, exit 0. An unknown command prints
`Error: unknown command '<x>'` and the help to stderr, exit 1. Each command accepts only its own
options (`init`, `uninstall`, `update`: `--global`, `--editor <name>`; `link`, `unlink`:
`--global`); anything else prints `Error: unknown option '<x>'. Run 'bem-te-vi help' for usage.`
and exits 1 **before writing anything**.

1. Red: conformance directive `run-unknown-option: <install|uninstall|update> <scope> <editor>`
   that appends one unknown option in the installer's own syntax (`--bogus-option` for `install.sh`
   and the CLI, `-BogusOption` for `install.ps1`). Case `020-unknown-option-rejected`: that run,
   then `expect-exit: 1`, `expect-absent: project:.claude`,
   `expect-absent: project:.qa-skills-manifest`. Red for the CLI only. If `powershell.exe -File`
   reports a non-1 status on a binding error, accept "non-zero" by adding `expect-exit-nonzero`
   rather than special-casing an installer.
2. Red: lifecycle test in `tests/test-lifecycle.sh`: `node bin/cli.js instal` exits 1 and
   `node bin/cli.js init --globl` exits 1 and creates nothing.
3. Fix: a `parseArgs(command, args)` in `bin/cli.js` that validates against a per-command table
   and returns `{ global, editor }`; `resolveTarget`, `label` and `parseEditorFlag` read from it.
   The dispatch `default:` branch becomes the unknown-command error.

## Item 5 (P1): `install.ps1` treats every computed path literally

1. Red: make the conformance sandbox path hostile, so every existing case exercises it: in
   `tests/conformance/run.ps1` and `run.sh`, name the project directory `project [1]` instead of
   `project` (the `project:` prefix still resolves to it). Expected red: cases that uninstall or
   reinstall fail for `install.ps1`; `install.sh` and the CLI should already pass (if they do not,
   that is a finding for this item, not a reason to revert the rename).
2. Fix: `-LiteralPath` on every `Test-Path`, `Get-ChildItem` and `Remove-Item` that takes a
   computed path, at the lines listed in "Current state" item 5 and any others
   `grep -nE 'Test-Path [^-]|Test-Path \(|Get-ChildItem \$|Remove-Item -Path' install.ps1` finds.
   `New-Item -Path` is literal on 5.1 (checked) and can stay.
3. Rename the `$input` variables in `Read-UserChoice` and `Read-YesNo` (`:83`, `:105`): `$input` is
   an automatic variable in PowerShell.

**Verify**: the grep above returns only literal, uncomputed paths; Windows conformance green.

## Item 6 (P2): `install.ps1` refuses to record a path outside its base

1. Red: in `tests/test-lifecycle.ps1`, extract `Install-File` and its helpers with
   `[System.Management.Automation.Language.Parser]::ParseFile` (the script cannot be dot-sourced:
   it ends by calling `Main`), call it with a destination outside the base, and expect a
   terminating error and no manifest entry. Same shape as the bash guard test around
   `tests/test-lifecycle.sh:400-430`.
2. Fix: at the top of `Install-File`, resolve both paths with `[IO.Path]::GetFullPath`, and throw
   `refusing to install <dest> — it is not inside base <base>, so it can never be recorded in the
   manifest.` (the wording `install.sh:663` and `bin/cli.js:293` use) unless the destination starts
   with the base plus a separator.

## Item 7 (P1): the adapter generator never overwrites a user's global files

1. Red: lifecycle test (bash only; the PowerShell generator has no `GLOBAL` mode): seed
   `$SANDBOX_HOME/.claude/CLAUDE.md` and `$SANDBOX_HOME/AGENTS.md`, run
   `HOME=$SANDBOX_HOME GLOBAL=true ./generate-adapters.sh`, expect both unchanged.
2. Fix `generate-adapters.sh:243-255`: write each global file only when nothing exists at that
   path (`[ -e ] || [ -L ]`); otherwise print `! Kept <path> — it already exists; merge
   adapters/universal/<file> into it by hand` and continue. Exit 0.
3. Change the `[TIP]` lines (`:257-260`) and the universal header in **both** generators to say
   "copy only if you have no such file; otherwise merge it by hand". Keep the two headers
   byte-identical (plan 037 step 1 will compare them).

**Commit types**: the header change reaches `adapters/` (`fix:`); the `GLOBAL` guard runs on a
clone user's machine and writes into their home (`fix:`).

## Item 8 (P2): the post-install hint lists what ships, derived from the tree

The hint is hand-written in two installers and has drifted (`install.sh:1250-1256`,
`install.ps1:1406-1412`: 7 of 10 commands, 4 of 9 rules, 2 of 4 skills, the four agents), and
both point at a missing `INSTALL.md` (`install.sh:1277`, `install.ps1:1423`; the 2026-10-14 dry
run printed it). `bin/cli.js` prints no list at all: `init` ends with "Open your editor and type
/qa to get started." (`:626-628`). So the three installers already disagree.

Behaviour, identical in all three, printed after a Claude Code install (the other editors keep
their one-line hints):

```text
  Claude Code : type /qa to start
              : commands : /qa-agentic /qa-automate /qa-bdd … (every .claude/commands/qa-*.md, sorted)
              : skills   : qa-explore qa-migrate qa-plan qa-reference (every .claude/skills/*/)
              : agents   : qa-designer qa-engineer qa-groomer qa-writer (every .claude/agents/*.md)
              : rules    : 9 files in .claude/rules/ (always loaded)
```

Each list is **computed at run time from the package's own `.claude/`** (`find`/`ls` sorted with
`LC_ALL=C` in bash, `Get-ChildItem … | Sort-Object Name` with ordinal sort in PowerShell,
`fs.readdirSync(...).sort()` in Node), so adding a command or skill updates the hint with no edit.
Rules are counted, not named: nine file names do not help a user.

1. Red (`test:`): conformance case `021-post-install-hint-lists-what-ships`. It cannot hard-code the
   names (they would drift), so add a directive `expect-output-lists-package: <dir> <pattern>` that
   each runner expands from the package under test: for every match of `<pattern>` in `<dir>`
   (e.g. `.claude/skills` `*/`, `.claude/commands` `qa-*.md`), the output must contain its name
   (without `.md`, with a leading `/` for commands). Case: `run: install project claude`,
   `expect-output-lists-package: .claude/commands qa-*.md`,
   `expect-output-lists-package: .claude/skills */`,
   `expect-output-lists-package: .claude/agents *.md`, `expect-no-output: INSTALL.md`. Red for all
   three installers today (the CLI prints no list; the shell installers miss names and print
   `INSTALL.md`).
2. Fix `install.sh` and `install.ps1`: replace the hard-coded block with the derived one; drop the
   "Quick start" line; keep "Full guide" and "Examples" (both files exist in a clone:
   `README.md`, `examples/README.md`).
3. Fix `bin/cli.js` (`cmdInit`, `:626-628`): print the same derived block after a `claude` install.
   It prints no documentation paths (the npm package ships `README.md` but not `examples/`).
4. `install.ps1`: correct the comment help (`:7-17`: no Postman or JUnit, add `antigravity`) and
   the banner (`:61`).
5. `Write-NextSteps` (`:1118-1139`) is dead code holding the same broken line. Mention it in the
   pull request; delete it only if Marco agrees (CLAUDE.md: no unrequested cleanup).

## Item 9 (P2): `CLAUDE.md` §5 says what the code does

Last, after items 1-8, so it describes the final behaviour (`docs:`):

- `:113`: `.qa-skills-manifest` is `<sha256>  <editor>  <path>`; `.qa-skills-known-hashes` is
  `<sha256>  <path>`.
- `:115`: "Never write through a symlinked destination: back up the content it points at, record
  the target in `<backup>.link-target`, and replace the link. Never write or delete through a
  symlinked directory below the editor's top-level folder (plan 033 item 1). Never overwrite a
  read-only file; skip it and carry on installing the rest."
- Add: "Every manifest write goes to an exclusively created temporary file renamed into place."

---

## Done criteria

Ticked 2026-10-18 on branch `fix/plan-033-followups`, each with the evidence it was ticked on.

- [x] Conformance cases `013`-`021` exist, each shown red against `main` in its pull request, and
      pass for `install.sh`, `install.ps1` and the CLI (a `skip:` needs Marco's approval).
      Re-checked here: against a tree built from `a2f08e7` (the plan's base), `013` to `021` each
      fail for the installer they target (`013 install.sh FAIL`, `014`, `015`, `018` and `021` both
      `FAIL`, `016`, `017`, `019` `install.sh FAIL` with the CLI already passing because its `update`
      is the contract, `020` `cli FAIL` with `install.sh` already refusing). On this branch:
      `Conformance: 48/48 passed, 0 failed, 0 skipped` (`install.sh` and the CLI, Linux) and, on
      Windows PowerShell 5.1, `Conformance: 34/34 passed, 0 failed, 0 skipped, 14 not run` (the
      symlink cases need Developer Mode here; `install.ps1` on those is shown by GitHub CI only).
      No case carries a `skip:`.
- [x] The case B reproduction leaves the linked package's file count unchanged. Lifecycle Test 44:
      `install.sh left the linked package's 44 files untouched` (compared with `diff -r`), and
      Test 39 now compares bytes too (`9088b6d`).
- [x] `bem-te-vi init --globl` exits 1 and writes nothing. Lifecycle Test 47 passed: exit 1,
      `Error: unknown`, project folder left empty.
- [x] `GLOBAL=true ./generate-adapters.sh` leaves an existing `~/.claude/CLAUDE.md` byte-identical.
      Lifecycle Test 48: `The generator kept the user's global files and installed into an empty home`.
- [x] `grep -rn 'INSTALL.md' install.sh install.ps1` returns only the dead function: the one hit is
      `install.ps1:1409`, inside `Write-NextSteps`, which nothing calls (`grep -n Write-NextSteps
      install.ps1` finds only its definition). The hint of all three installers is derived from
      `.claude/` (case `021` passes for both installers run locally).
- [ ] CI green on Linux, Windows and macOS; ShellCheck and ESLint clean. Local Linux CI on this
      branch: 15 of 17 steps green; ShellCheck, ESLint and markdownlint clean after the follow-up
      commits; the only failure is lifecycle Test 20 (the known failure, owned by
      `fix/update-adopts-current-files`). Lifecycle with only Test 20 removed from a scratch copy:
      `ALL INTEGRATION TESTS PASSED SUCCESSFULLY! 100% GREEN`, 39 tests. GitHub CI on the pull
      request is the remaining evidence.
- [x] `plans/README.md` row for 033 updated; the "Installer parity and robustness" backlog line
      marked as planned here.

## STOP conditions

- A fix needs a change to the manifest or known-hash **format**: stop; that breaks every older
  install.
- The directory-link rule (item 1) would skip files in a layout Marco relies on (a dotfiles
  `~/.claude`, a monorepo with linked `.claude/skills`): report the layout before choosing.
- A conformance case cannot be made red against `main` for the installer it targets: the defect
  may be gone; record it under "Findings rejected" with the output.
- Windows CI cannot create symlinks and every new link case reports "not run": do not merge item 1
  on Linux evidence alone; ask.
- `install.sh` needs a bash 4 feature.

## Findings rejected

- **"`install.ps1` lacks the out-of-base manifest guard"**, as far as *uninstall* goes: it has one
  (`Test-SafeManifestRel`, `:903-911`, used at `:922`), and conformance case `005` covers it. Only
  the install-side guard is missing (item 6).
- **"`install.ps1`'s manifest temp file has a fixed name"**: it does not (`$mf.tmp-$PID`,
  `:783`). It is predictable and not exclusive, so item 2 still changes it, as hardening.

## Maintenance notes

- A symlinked top-level directory that points into a package's own `.claude/` (made by hand, not
  by `link`) is still followed under the default decision; uninstall would then delete the
  package's files. Accepted residual risk unless Marco picks the stricter alternative.
- Every new shared message an installer prints is a conformance contract once a case quotes it.
  Change all three together.
- **Accepted residual risk: `install.sh` hook `chmod` through a path** (decided 2026-10-18, see
  "Follow-up findings resolved"). Bash has no `fchmod`, so a path-based `chmod +x` cannot be tied
  to the file that was checked a moment earlier. The window is a few instructions between
  `[ -L ... ]` and `chmod`, the installer runs as the same user who owns the folder, and the worst
  outcome is an executable bit on one file that user already controls. No safe replacement exists
  that runs on bash 3.2, so none is invented.

## Found while implementing items 1-2 (2026-10-15)

Not fixed by items 1-2; each needs its own red test before a fix:

- `install.sh` aborts in `mkdir -p .claude/<sub>` when `<sub>` is a dangling symbolic link.
- The backup file (`<file>.qa-skills-backup-<UTC timestamp>`) and the `.link-target` write follow a
  dangling link planted at that exact name. The timestamped name makes this hard to arrange, but
  the writes should be exclusive like the manifest's (item 2).
- `install.sh` cannot change a hook's mode without a path-based `chmod` (bash has no `fchmod`); it
  now skips a hook that is a symbolic link, but a swap inside that window is still possible.

## Security-review findings to batch into one follow-up PR (2026-10-16)

A background review of the item 3-9 commits reported these; only one-line summaries were given.
Each needs verifying (red first) before a fix:

- `tests/conformance/run.sh`: an unescaped regular-expression metacharacter (case text used in a
  pattern).
- `tests/conformance/test-runner.sh`: a security assertion weaker than the guarantee it checks.
- `tests/test-lifecycle.sh`: a file-safety control verified only in part (e.g. the message or exit
  code, not that the protected file or link is unchanged).
- `tests/conformance/run.sh`: a coverage gap (possibly closed by the runner self-test added here).

## Item 5 on Windows: what the `project [1]` red actually was (2026-10-18)

Reproduced on Windows PowerShell 5.1.26100 before any fix: cases `002`, `003`, `005` and `006`
failed for `install.ps1` exactly as in CI, then `007` aborted the run.

- **Cause.** `powershell.exe` started in a folder whose name holds `[` or `]` cannot enter it and
  starts in `$PSHOME`. In the child, `Get-Location` and `$PWD` both read
  `C:\WINDOWS\System32\WindowsPowerShell\v1.0` while `[System.IO.Directory]::GetCurrentDirectory()`
  is `...\project [1]`, so `-Target project` installed into `$PSHOME` (access denied, or files in the
  wrong place). A user whose project folder has brackets in its name hits the same thing.
  Fix: `install.ps1` returns to the process directory with `Set-Location -LiteralPath`, only when
  `$PWD` is `$PSHOME`, the process directory differs and holds a bracket. Not unconditionally: in an
  open session the process directory lags behind a `cd` on purpose.
- **Rejected: `[WildcardPattern]::Escape` on `-Destination`** (commits `2e53532`, `c847560`).
  On 5.1, `Copy-Item` and `Move-Item` already take `-Destination` literally (checked: a plain
  `...\project [1]\a.txt` copies and moves), so the escape put backticks into the real path and
  every copy failed with "Could not find a part of the path", breaking the runner self-test too.
  Both are reverted.
- **Case `020` aborted the run on 5.1.** `run.ps1` runs under `$ErrorActionPreference = 'Stop'`,
  which turns the installer's stderr, merged by `2>&1`, into a terminating error, so the refusal the
  case expects stopped the runner. `Invoke-Action` now runs the installer under `'Continue'`.
- After both fixes, locally: runner self-test 27 checks passed; conformance 34/34 passed, 14 not
  run (the symlink cases need Developer Mode on that machine; CI runs them). `test-lifecycle.ps1`
  was not run locally (no Windows `git` there); CI runs it.
- **Case `024` never ran on Windows CI**, reported as "needs Developer Mode" on a runner that can
  create links. 5.1's `New-Item -ItemType SymbolicLink` refuses a missing target with
  `PathNotFound` before it checks the privilege (checked locally: missing target `PathNotFound`,
  existing target `NewItemSymbolicLinkElevationRequired`), and `run.ps1` read every failure as the
  privilege. `seed-symlink` now makes a missing target as a folder only while the link is created,
  reports "not run" only for the privilege error, and stops the run on any other failure.

## Update adopts a file identical to the package's current one (2026-10-18)

- **Defect.** On `next`, lifecycle Test 20 failed ("`.claude` survived uninstall after a no-manifest
  upgrade"); it passed on `main`.
- **Cause.** An `--update` with no manifest adopts a file only when its hash (raw or CR-stripped) is
  in `.qa-skills-known-hashes`, a list of tagged releases only. A file byte-identical to the
  package's current source file was never adopted, never recorded in the manifest, and uninstall
  left it. `main` hid this because every shipped file still equalled the last release; plan 034
  changed shipped content. `backup_destination` and its twins already treat such a file as the
  package's own on the install path.
- **Red.** Conformance case `025-update-adopts-a-file-identical-to-the-package` (two package files
  seeded with no manifest, then `update`) failed on `next` for `install.sh` and the CLI
  with `manifest lacks: project claude .claude/commands/qa.md`, `manifest lacks: project claude
  .claude/rules/test-tools.md` and `output lacks 'Adopted'`.
- **Fix.** `adopt_known` (`install.sh`), `Add-KnownFiles` (`install.ps1`) and `detectAdoptOne`
  (`bin/cli.js`) adopt a file when its raw or CR-stripped hash equals the package source file's hash,
  or is a known hash, with the same message and counters as before. `CLAUDE.md` section 5 now says so.
  This is the installer's own existing rule, not a new heuristic: identical bytes are certainty.

## Follow-up findings resolved (2026-10-18)

Marco asked for all remaining work on 2026-10-18. Branch `fix/plan-033-followups`, one commit per
fix, test first. Reproduced on a built copy of the branch, never in this checkout.

Found while implementing items 1-2:

1. **`install.sh` aborting in `mkdir -p .claude/<sub>` on a dangling link: already fixed, commit
   `608f959`** (`fix(install): skip a dangling linked folder instead of aborting in install.sh`,
   test commit `ae6fbc1`, conformance case `024`). Checked again with a dangling link planted at
   every folder each installer creates (`.claude/{rules,commands,skills,agents,hooks}`,
   `.cursor/rules`, `.windsurf/{rules,workflows}`, `.github/instructions`): `install.sh` and
   `bin/cli.js` both exited 0, nothing was created at the link's target. `.clinerules` is a single
   file, not a folder, so it has no such case. `install.ps1` is covered by case `024` on CI only
   (the local Windows machine has no symlink privilege).
2. **Backup and `.link-target` writes following a link planted at their name: already fixed.**
   Backups: `9c60000` (`install.sh`), `0d86fae` (`install.ps1`), `958a8ee` (`bin/cli.js`); the
   `.link-target` write is exclusive in all three (`write_exclusive`, `Write-ExclusiveFile`,
   `flag: "wx"`). Red test `16f17b4` (lifecycle Test 49) pins the clock and plants the link at the
   exact backup and `.link-target` names for `install.sh` and the CLI. `install.ps1` cannot have
   its clock pinned from the suite, so its guarantee rests on `FileMode.CreateNew` (an existing
   name, a link included, is never opened); no run of it against a planted link exists.

   > **2026-10-19: done in plan 053** (I10). `tests/test-lifecycle.ps1` Test 52 loads
   > `install.ps1`'s functions, pins `Get-Date` and plants links at the backup, `.link-target` and
   > manifest temp names. A junction at the backup name stopped `install.ps1` with access denied,
   > and the CLI on Windows with `EPERM`; both now pass over the name.
3. **`chmod` through a path in `install.sh`: not fixable in bash 3.2.** Recorded as accepted
   residual risk in "Maintenance notes", with the reasoning. The skip of a hook that is a symbolic
   link stays, and lifecycle Test 45 still covers it.

Security-review findings. All four were real, found by naming a concrete instance and showing
that a mutant of the runner or the installer passed the old suite.

- **`tests/conformance/run.sh`, unescaped metacharacter.** `expect-manifest`, `expect-no-manifest`
  and `drop-manifest` put the case's path into a regular expression (`grep -E "...$a3\$"`), so a
  dot matched any character: `drop-manifest` of `a.md` also removed the entry for `aXmd`.
  `run.ps1` already used `[regex]::Escape`. Red (`f4c8b5a`, case `manifest-lookup-is-literal` in
  `test-runner.sh`): `001-manifest-lookup-is-literal ... install.sh FAIL ✘ manifest lacks:
  project claude aXmd`, `Conformance runner self-test: 1 problem(s)`. Fix `5a462ee`: the line is
  compared as text by `awk` with the value read from the environment.
- **`tests/conformance/test-runner.sh`, assertion weaker than the guarantee.** The canary check
  compared content only, so a refused case that still ran `chmod` on the outside file passed.
  It now also checks the mode (`8a82081`; `test-runner.ps1` checks the read-only attribute).
  Not red on its own: it adds a second failure to the mutant that skips the path check for
  `seed-readonly`, so it is defence in depth, said plainly.
- **`tests/test-lifecycle.sh`, a control verified in part.** Test 39 compared the *number* of files
  in the linked package after `uninstall`, so a file edited in place passed. With a `cli.js`
  mutant that appended a byte to `.claude/rules/security-qa.md` during uninstall, the old Test 39
  printed `MINI-PASS`; the new one (`diff -r` against a snapshot, as Test 44 already did) does not
  (`9088b6d`).
- **`tests/conformance/run.sh`, coverage gap.** The runner self-test refused a climbing path for
  only seven directives. Mutants of `check_directive` that stopped checking `seed-readonly`,
  `seed-crlf`, `expect-content`, `expect-backup-link-target`, `expect-output-lists-package`,
  `skip` (no reason) and `expect-exit-nonzero` (with a value) all passed the old suite
  (`27 checks passed` for each). Seven new `rejected` checks kill every one (`23aa3ee`); the same
  checks are in `test-runner.ps1` (`6920c84`), run on Windows PowerShell 5.1: 35 checks passed.

**Findings rejected:** none. Default used (Marco asked for all remaining work on 2026-10-18): no
decision without a documented default was needed.

## The runner self-test failed now and then (2026-10-20)

The local macOS job (bash 3.2.57) once failed `test-runner.sh` with `unspaced-equals: the runner did
not report a malformed case`, then passed on reruns. The runner was never wrong: the check
`printf '%s\n' "$out" | grep -q 'malformed case'` raced under `set -o pipefail`. bash writes the
printf output a line at a time, `grep -q` exits at its first match, the printf still writing the
lines after it gets SIGPIPE, and pipefail turns its exit status 141 into a failed check. Any
`rejected` check could hit it, more often when the machine is busy.

Red, on `next` at `3227405`: three loops at once (two under bash 3.2.57, one under the system bash),
about 770 self-test runs in all, failed five times on five different checks (`drop-climbs-out`,
`skip-without-reason`, `exit-not-a-number`, `expect-path-climbs-out`, `package-path-climbs-out`).
A copy of the self-test that printed `PIPESTATUS` and `$out` on failure showed
`PIPESTATUS printf=141 grep=0` each time, with both `malformed case` lines in the output.

Fix: the check reads `$out` from a here-string, so there is no pipe and no writer to signal.
Green: the same three loops, 900 runs, no failure. `test-runner.ps1` checks `$out.Contains(...)`, a string method, so
it never had the race.

Rejected: rerunning the check on failure, which would hide the race instead of removing it.

> **Same pattern elsewhere, 2026-10-20, coordinator.** A sweep for `| grep -q` under `set -o pipefail`
> found the same race in `dedupe-changelog.sh` (a multi-line list piped into `grep -qx`; it runs in
> the release workflow), `verify-merge-commits.sh` (`git log` piped into `grep -qE`) and
> `tests/verify-adapters.sh` (frontmatter from `awk` piped into `grep -qx`, safe today because the
> input is small). All three now read a here-string. `install.sh` sets only `set -e`, so its
> `known_hash` pipe takes `grep`'s status and was never affected; the other `head -1 | grep -q`
> checks pass one line and cannot race.
