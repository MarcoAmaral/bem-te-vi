# Plan 026: The installers never destroy a file they did not write

> **Executor instructions**: Follow this plan item by item. Each item is its own branch and pull
> request. Run every verification command and confirm the expected result before moving on. If
> anything in "STOP conditions" occurs, stop and report; do not improvise. When an item lands,
> update this plan's row in `plans/README.md`.
>
> **Drift check (run first)**: `git diff --stat 5b45cfa..HEAD -- bin/cli.js install.sh install.ps1 tests/conformance tests/test-lifecycle.sh tests/test-lifecycle.ps1`
> If any of these changed since this plan was written, compare the "Current state" excerpts with the
> live code before starting; on a mismatch, treat it as a STOP condition.

## Status

- **Priority**: P0 (items 1-2), P1 (items 3-7)
- **Effort**: L overall; each item S or M
- **Risk**: MED (installers write into users' projects and home directories)
- **Depends on**: none
- **Category**: bug
- **Planned at**: commit `5b45cfa`, 2026-10-13 (audit after 4.0.0)

## Why this matters

`CLAUDE.md` makes one promise above all others for `install.sh`, `install.ps1` and `bin/cli.js`:
**a user's own file must never be destroyed, and the three installers behave identically.** An audit
after 4.0.0 found paths that break it. The worst was reproduced: on a scratch copy of the package,
`bem-te-vi link` followed by `bem-te-vi uninstall` deleted **all 37 of the package's own shipped
files** and printed "✓ Removed 37 file(s)". Others overwrite a user's existing git `pre-commit`
hook, delete a read-only file the installer promised to keep, corrupt a user's global hook on
Windows, or commit and push files the user never asked to commit. Each item below closes one path
and adds the test that would have caught it.

## Required reading before you change any installer

`CLAUDE.md` §"Installer File-Safety Contracts" and plans `009`-`012` in `plans/`. The invariants
that bind every item here, quoted from `CLAUDE.md`:

- "A colliding file is backed up to `<file>.qa-skills-backup-<UTC timestamp>` unless its hash appears
  in `.qa-skills-known-hashes` ... Never guess by any other means."
- "Never write through a symlinked destination, and never overwrite a read-only one; skip it and
  carry on installing the rest."
- "Uninstall removes only files still exactly as installed, keeps and reports the rest, and never
  deletes backups."
- "`install.sh` must run on **bash 3.2** (macOS ships it): no `declare -A`, no associative arrays."

## Commands you will need

| Purpose | Command | Expected on success |
| --- | --- | --- |
| Generate adapters (needed by the suites) | `./generate-adapters.sh --clean` | exit 0 |
| Lifecycle suite (bash) | `./tests/test-lifecycle.sh` | ends with `ALL INTEGRATION TESTS PASSED SUCCESSFULLY! 100% GREEN` |
| Conformance suite (bash + CLI) | `./tests/conformance/run.sh` | `Conformance: N/N passed, 0 failed` |
| One conformance case | `./tests/conformance/run.sh 012` | that case passes for `install.sh` and `cli` |
| Shell lint | `npx --yes shellcheck@3.1.0 install.sh tests/test-lifecycle.sh tests/conformance/run.sh` | exit 0, no output |
| CLI syntax | `node --check bin/cli.js` | exit 0 |
| CLI lint | `npx eslint bin/cli.js` | exit 0 |
| Windows suites | `tests\test-lifecycle.ps1`, `tests\conformance\run.ps1` | run by CI's Windows job; you cannot run them on Linux |

## Scope

**In scope**: `bin/cli.js`, `install.sh`, `install.ps1`, `tests/conformance/run.sh`,
`tests/conformance/run.ps1`, new directories under `tests/conformance/cases/`,
`tests/test-lifecycle.sh`, `tests/test-lifecycle.ps1`, `README.md` (only the sections that describe
hooks and the commit offer), `plans/README.md` (status row).

**Out of scope**:

- `.claude/hooks/validate-tc-format.sh` and its line-ending bugs: that is plan 027.
- The manifest format and `.qa-skills-known-hashes`: shared, portable formats; do not change them.
- Renaming `.qa-skills-*` files or the "qa-skills" marker strings the installers write into hooks.
  Uninstall matches on those exact strings; existing installs depend on them.
- `--update` parity and the other installer robustness items found by the audit (plan 031 lists
  them as follow-ups).

## Git workflow

- One branch and PR per item: `fix/<slug>` from `main` (e.g. `fix/cli-link-uninstall`).
- Conventional Commits, atomic, no "and" in a message (see `CONTRIBUTING.md`). Example from
  `git log`: `fix: remove every emptied skill folder on uninstall`.
- **Never add AI attribution lines** (`Co-Authored-By: Claude …`, "Generated with Claude Code")
  to commits or PR bodies in this repository.
- PR title in Conventional Commits form; merge with a default merge commit, never squash, never an
  empty body (`CLAUDE.md` §8). Do not merge without Marco's approval.

---

## Item 1 (P0): `link` then `uninstall` must not delete the package

### Current state

`bin/cli.js:672-692`, `cmdLink`, replaces `.claude/<sub>` with a symlink to the package's own folder
and writes no manifest:

```js
    if (fs.existsSync(dest)) {
      const stat = fs.lstatSync(dest);
      if (stat.isSymbolicLink()) {
        fs.rmSync(dest); // stale link — refresh
      } else { /* warns and skips a real directory */ }
    }
    fs.symlinkSync(src, dest, "dir");
```

`bin/cli.js:612-636`, `cmdUninstall`, then sees no manifest and takes the legacy path:

```js
  const hadManifest = fs.existsSync(manifestFile(targetBase));
  ...
    if (editor === "claude" && !hadManifest) {
      for (const sub of SUBDIRS) {
        const src = path.join(PKG_CLAUDE, sub);
        ...
        for (const file of walkFiles(src)) {
          const relToSub = path.relative(src, file);
          const dest = path.join(targetClaude, sub, relToSub);
          const result2 = removeIfMatches(file, dest);
```

`dest` resolves through the symlink to `file` itself, so `removeIfMatches` (`bin/cli.js:476-489`)
finds identical content and calls `fs.rmSync(dest)`, deleting the package's own file.
`cmdUnlink` (`:701-714`) removes any symlink at `.claude/<sub>`, and `cmdLink` replaces any symlink,
without checking that it points into this package.

### Steps

1. Add a helper `linkedIntoPackage(dest)` in `bin/cli.js` that returns true when `dest` is a
   symlink whose `fs.realpathSync` lies inside `fs.realpathSync(PKG_CLAUDE)`.
2. In `cmdUninstall`, before walking a `sub`, skip it entirely when
   `linkedIntoPackage(path.join(targetClaude, sub))` is true, and print
   `i Skipped <sub>/ — it is a link to the package; run 'bem-te-vi unlink' instead`.
3. In `cmdUnlink`, remove a link only when `linkedIntoPackage` is true; otherwise print
   `! Kept <sub>/ — the link does not point to this package`.
4. In `cmdLink`, replace an existing symlink only when it already points into a `.claude/<sub>` of
   *some* bem-te-vi package (its target path ends in `/.claude/<sub>`); otherwise skip with the same
   "Kept" wording.

**Verify**: build the reproduction below in a temporary directory (never inside the repository):

```bash
T="$(mktemp -d)"; mkdir -p "$T/pkg/.claude" "$T/proj"
cp -r bin package.json .qa-skills-known-hashes .qa-skills-editor-map "$T/pkg/"
cp -r .claude/agents .claude/commands .claude/rules .claude/skills .claude/hooks "$T/pkg/.claude/"
before=$(find "$T/pkg/.claude" -type f | wc -l)
(cd "$T/proj" && git init -q . && node "$T/pkg/bin/cli.js" link && node "$T/pkg/bin/cli.js" uninstall)
after=$(find "$T/pkg/.claude" -type f | wc -l); echo "before=$before after=$after"
```

→ `before` equals `after` (37 at the time of writing). Before the fix the same script prints
`after=0`; run it once on `main` first and keep that output for the PR description (red-green proof).

### Test

Add a step to `tests/test-lifecycle.sh` (after the existing CLI tests; follow the
`printf '%b\n' "${RED}✘ …${NC}"; exit 1` pattern used throughout the file) that runs the
reproduction above against `$REPO_DIR` copied into the sandbox, and fails unless the package's file
count is unchanged and `.claude/<sub>` links are gone after `unlink`.

---

## Item 2 (P0): never overwrite an existing project `pre-commit` hook

### Current state

`install.sh:291-325` (bash) and `install.ps1:266-305` (PowerShell) write the hook unconditionally:

```bash
        if [ -d "$BASE_DIR/.git" ]; then
            local HOOK_DIR="$BASE_DIR/.git/hooks"
            local HOOK_FILE="$HOOK_DIR/pre-commit"
            mkdir -p "$HOOK_DIR"
            cat > "$HOOK_FILE" << 'PRECOMMIT'
```

```powershell
            [System.IO.File]::WriteAllText($hookFile, $hookContent, $utf8NoBom)
```

Consequences: a user's own `pre-commit` (lefthook, the pre-commit framework, a hand-written hook)
is replaced and never restored; uninstall (`install.sh:784-790`, `install.ps1:390-399`) deletes the
file by marker. When `core.hooksPath` is set (husky sets `.husky/_`), `.git/hooks` is never run, yet
the installer prints "Registered". When `.git` is a file (a worktree or submodule), bash prints
"Not a git repository" and PowerShell throws mid-install.

### Steps

1. Resolve the hooks directory with git itself, from the project directory:
   `git -C "$BASE_DIR" rev-parse --git-path hooks` (bash) and
   `git -C $BaseDir rev-parse --git-path hooks` (PowerShell). If the command fails, print the
   existing "Not a git repository" message and return.
2. If `git -C "$BASE_DIR" config core.hooksPath` is non-empty, do not write anything. Print
   `⚠ core.hooksPath is set (<value>); add the bem-te-vi check to your hook manager yourself:` and
   the one-line command `bash .claude/hooks/validate-tc-format.sh <file>`.
3. If `<hooks>/pre-commit` exists and does not contain the marker
   `Pre-commit hook to validate test cases in qa-skills`, or is a symlink, do not write. Print
   `⚠ Kept your existing pre-commit hook: <path>` and the same one-line command.
4. Otherwise write the hook as today. Keep the marker text unchanged (uninstall depends on it).
5. Make the PowerShell hook registration failure non-fatal: wrap it so an exception prints a warning
   and the install continues (today an exception aborts after the files are copied but before the
   manifest is saved, `install.ps1:905`, `:1224`, `:1258-1261`).

**Verify**: `./tests/test-lifecycle.sh` → all green, including the new tests below.

### Test

In both lifecycle suites add three cases, each in a fresh sandbox git repository:

- a pre-existing `.git/hooks/pre-commit` containing `echo mine` survives install and uninstall
  byte-for-byte;
- with `git config core.hooksPath .husky/_`, install writes no file under `.git/hooks` and prints
  `core.hooksPath is set`;
- with no hook present, install creates it and uninstall removes it (today's behaviour).

---

## Item 3 (P1): global hook append and removal touch only our own block

### Current state

- `install.sh:343-362` appends a block to any existing global hook. The appended block starts with
  `# Added by qa-skills global installer` but **never writes an end marker**; only the fresh-file
  variant (`:363-384`) ends with `# GLOBAL_PRECOMMIT_APPEND`.
- `install.sh:807-809` removes with `sed '/# Added by qa-skills global installer/,/GLOBAL_PRECOMMIT_APPEND/d'`.
  On an appended hook the range has no end, so it deletes everything to the end of the file.
- `install.ps1:347` appends with `Add-Content`, which ends the file with CRLF; bash rejects a
  `fi\r` line with a syntax error, so every later commit fails.
- `install.ps1:425` removes with `-replace '(?s)\r?\n# Added by qa-skills global installer.*', ''`
  (also to end of file), and `:435-438` deletes the whole hook file when it merely contains
  `validate-tc-format.sh`.
- `install.sh:390-393` and `install.ps1:376-379` set `init.templateDir` whenever `core.hooksPath` is
  unset, replacing any value the user already had.

### Steps

1. Wrap the global block, in both variants and both installers, between two exact lines:
   `# >>> bem-te-vi global pre-commit >>>` and `# <<< bem-te-vi global pre-commit <<<`.
   Keep the old `# Added by qa-skills global installer` line inside the block so older uninstallers
   still recognise it.
2. Append only when the existing hook's first line is a `sh` or `bash` shebang; otherwise do not
   touch it and print the one-line manual command (as in item 2).
3. Removal deletes only the lines between the two new markers, inclusive. For hooks written by an
   older release (old marker, no new markers), remove from the old marker up to and including the
   first line that is exactly `fi` at column 0 after it, which is how the old block ends; if that
   line is not found, keep the file and print a warning.
4. PowerShell: append with `[System.IO.File]::AppendAllText($hookFile, $appendContent, $utf8NoBom)`
   after normalising `$appendContent` to LF (`-replace "\r\n", "\n"`). Remove the fallback at
   `install.ps1:435-438` that deletes an unrecognised hook.
5. Set `init.templateDir` only when `git config --global init.templateDir` is empty; otherwise print
   that the existing value was kept.

**Verify**: `./tests/test-lifecycle.sh` → green with the new cases; `bash -n` on every hook file the
tests produce exits 0.

### Test

Lifecycle cases (bash and PowerShell): seed `$HOME/.git-templates/hooks/pre-commit` with
`#!/usr/bin/env bash`, `echo before`, then install globally, then append `echo after` to the hook,
then uninstall. Expect the file to contain exactly `#!/usr/bin/env bash`, `echo before`,
`echo after`, and `bash -n` on it to exit 0. Add a seeded `init.templateDir` that must survive.

---

## Item 4 (P1): the installed hooks validate every staged test-case file

### Current state

All six hook templates (`install.sh:304-317`, `:347-359`, `:370-382`; `install.ps1:282-297`,
`:327-339`, `:355-367`) loop like this:

```bash
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.md$' || true)
for FILE in $STAGED_FILES; do
```

Names with spaces split into words, names with non-ASCII characters arrive quoted in octal and do not
exist on disk, glob characters expand, and renamed files (`R`) are excluded. Each is skipped with no
message.

### Steps

Replace the loop in all six templates with:

```bash
git diff --cached --name-only -z --diff-filter=ACMR -- '*.md' |
while IFS= read -r -d '' FILE; do
    ...same body, with "$FILE" quoted everywhere...
done
```

Because the loop body runs in a subshell, make it `exit 1` on failure and follow the pipeline with
`[ "${PIPESTATUS[1]}" -eq 0 ] || exit 1`, so a failed validation still aborts the commit. Print file
names with `printf '%s'`, not `%b` or `echo -e`.

**Verify**: lifecycle cases that stage `docs/My Tests/TC-AUTH.md` and `docs/casos/TC-AÇÃO.md`, both
invalid, and expect `git commit` to fail; then fix them and expect it to succeed.

---

## Item 5 (P1): uninstall keeps a read-only adapter it promised to keep

### Current state

`install.sh:707-711`:

```bash
uninstall_single() {     # base editor dest adapter-relative-path
    uninstall_recorded "$1" "$2"
    had_manifest "$1" || remove_if_matches "$SCRIPT_DIR/adapters/$4" "$3"
}
```

`uninstall_recorded` (`:672-691`) prints "Kept … read-only" but does not write the kept entry back,
and deletes the manifest when nothing remains. `had_manifest` is then false, so `remove_if_matches`
(`:694-704`, no read-only check) deletes the read-only file it just reported as kept. `install.ps1`
(`:841-847`) and `bin/cli.js` (`:612`) read the manifest state first and are correct.

### Steps

```bash
uninstall_single() {     # base editor dest adapter-relative-path
    local HAD=0
    had_manifest "$1" && HAD=1
    uninstall_recorded "$1" "$2"
    [ "$HAD" = 1 ] || remove_if_matches "$SCRIPT_DIR/adapters/$4" "$3"
}
```

### Test

New conformance case `tests/conformance/cases/012-readonly-adapter-kept-when-last-entry/case.conf`:

```text
name: A read-only adapter is kept on uninstall even when it is the manifest's last entry
run: install project cursor
expect-exit: 0
seed-readonly: project:.cursor/rules/qa.mdc
run: uninstall project cursor
expect-exit: 0
expect-same-as-package: project:.cursor/rules/qa.mdc = adapters/cursor/qa.mdc
expect-output: read-only
```

Prove it fails first: copy the package tree from `main` (before your fix) to a temporary directory,
generate its adapters, run `CONFORMANCE_PKG=<copy> ./tests/conformance/run.sh 012`, and quote the
failure in the PR. If any installer's read-only message lacks the word `read-only`, align the wording first
(see "Output is a contract" in `tests/conformance/README.md`).

---

## Item 6 (P1): "Add to git and commit?" commits only what the installer wrote

### Current state

`install.sh:897-911`:

```bash
            git add .claude/ adapters/ CLAUDE.md .gitignore generate-adapters.sh install.sh "$(manifest_file "$(pwd)")" 2>/dev/null || true
            git commit -m "Add/update QA skill for AI-assisted editors (ISTQB CTFL v4.0)"
            ...
                for REMOTE in $(git remote); do
                    git push "$REMOTE"
```

It stages the user's own `.claude/`, `CLAUDE.md` and `.gitignore` edits, commits whatever else was
already staged, and pushes to every remote. `install.ps1:947-973` compares a forward-slash
`git rev-parse --show-toplevel` with a backslash `Resolve-Path`, and reports "Committed" without
checking `$LASTEXITCODE`.

### Steps

1. Build the path list from the project manifest entries written in this run (the manifest lines'
   third field, plus the manifest file itself). Stage with `git add -- <paths>` and commit with
   `git commit -m "<message>" -- <paths>`, which commits only those paths whatever else is staged.
2. Push only to the current branch's upstream (`git push`), never loop over every remote; print the
   result honestly from the exit code.
3. PowerShell: normalise both paths with `[IO.Path]::GetFullPath(...).Replace('\','/')` before
   comparing, use the same pathspec commit, and check `$LASTEXITCODE` before printing "Committed".

### Test

In `tests/test-lifecycle.sh`, next to "Test 14: The manifest is included in the installer's git
add" (line ~447, which already drives the commit offer): pre-stage an unrelated file and edit `CLAUDE.md`, answer `y`, and assert
the new commit's `git show --name-only` lists only manifest paths and the unrelated file is still
staged but uncommitted.

---

## Item 7 (P1): the conformance runner sandboxes HOME

### Current state

`tests/conformance/run.sh:41-55` runs `install.sh` and `bin/cli.js` without setting `HOME`, while
`home:` paths resolve to `$sb/home` (`:31-36`, `:64-65`). So case
`001-global-skips-no-global-editors` inspects a directory the installers never write to, and any
future global case would write into the developer's real home. `tests/conformance/run.ps1:74-75`
already sets `USERPROFILE` and `HOME`.

### Steps

In `run_action`, run each installer with `HOME="$sb/home" GIT_CONFIG_GLOBAL="$sb/home/.gitconfig"`
in its environment (the lifecycle suite does the same at `tests/test-lifecycle.sh:42-43`).

**Verify**: `./tests/conformance/run.sh` → all pass. Then prove case 001 can now fail: temporarily
make `install.sh` write the cline adapter to `$HOME/.clinerules` on a global install, run
`./tests/conformance/run.sh 001`, see it fail, and revert. Quote the failure in the PR.

---

## Done criteria

- [ ] Item 1 reproduction prints equal `before`/`after` counts; `cmdUnlink` keeps a foreign link.
- [ ] `./tests/test-lifecycle.sh` and `./tests/conformance/run.sh` pass on Linux; CI's Windows and
      macOS jobs pass on every item's PR.
- [ ] `npx --yes shellcheck@3.1.0 install.sh tests/test-lifecycle.sh tests/conformance/run.sh` → no output.
- [ ] `grep -n 'for FILE in \$STAGED_FILES' install.sh install.ps1` → no matches.
- [ ] `grep -n 'cat > "\$HOOK_FILE"' install.sh` appears only after an existence/marker check.
- [ ] New conformance case 012 exists and passes for every installer.
- [ ] Each PR quotes its red-before-green proof.
- [ ] `plans/README.md` row for 026 updated.

## STOP conditions

- An item seems to need a change to the manifest or known-hashes format.
- Keeping a user's hook appears to require deleting or rewriting it.
- A conformance case can only pass by giving one installer a `skip:`; report instead of skipping.
- A Windows CI failure you cannot reproduce or explain from the logs.
- `install.sh` would need a bash 4 feature.

## Maintenance notes

- The hook templates now exist in six copies across two files. A follow-up could generate them from
  one source; until then, any change must be applied to all six and covered by the lifecycle tests.
- The new markers (`# >>> bem-te-vi global pre-commit >>>`) become a contract: uninstallers of
  future releases must keep recognising both these and the old `qa-skills` marker.
- Item 2 changes visible behaviour (users with husky or their own hook no longer get an automatic
  hook). Mention it in the PR body so Release Please's changelog line is accurate.
