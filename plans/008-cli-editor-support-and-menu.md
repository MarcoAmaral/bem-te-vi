# Plan 008: Port --editor support into bin/cli.js and add interactive menu

> **Executor instructions**: Follow this plan step by step. Run every verification command
> and confirm the expected result before moving to the next step. If anything in "STOP
> conditions" occurs, stop and report. When done, update the status row for this plan in
> `plans/README.md` — unless a reviewer dispatched you and told you they maintain the index.
>
> **Drift check (run first)**: `git diff --stat 0dc3af8..HEAD -- bin/cli.js package.json .npmignore install.sh`.
> If `package.json` changed since this plan was written (e.g. plan 006 landed first and added
> devDependencies/scripts/lint-staged config), merge your additions alongside what's there —
> add your `dependencies` and `engines` changes without removing plan 006's `devDependencies`/
> `scripts`/`lint-staged` keys.

## Status

- **Priority**: P2
- **Effort**: L
- **Risk**: MED
- **Depends on**: none (but touches `package.json`, shared with plan 006 — see drift check)
- **Category**: direction (feature) / dx
- **Planned at**: commit `0dc3af8`, 2026-07-30

## Why this matters

`docs/specs/qa-skill-overhaul.md` §5 asks for an interactive colored multi-select installer
menu in `bin/cli.js`. Today `bin/cli.js` only copies/symlinks `.claude/{commands,rules,skills,
agents,hooks}` — it has no concept of "editor" at all, while `install.sh` already supports
`--editor <claude|cursor|windsurf|copilot|cline|antigravity|all>` and knows exactly where each
editor's adapter file belongs (`README.md`'s own "Editor Support" table documents this gap
today: "The full multi-editor installer (`install.sh`) is available ... for editors beyond
Claude Code"). The repo owner has explicitly chosen to close this gap by porting `install.sh`'s
editor-targeting logic into `bin/cli.js` **before** adding the interactive menu, so the menu
has real multi-editor options to offer instead of just "Claude Code."

**Root blocker this plan must solve first**: `bin/cli.js` is distributed via npm, and the npm
package currently does **not** include the `adapters/` directory —
`.npmignore` explicitly excludes it, and `package.json`'s `"files"` allowlist doesn't list it
either. `install.sh` only works for non-Claude editors because it assumes it's run from inside
a full git clone where `adapters/` sits alongside the script (see `install.sh` line 145:
`ADAPTERS_DIR="$SCRIPT_DIR/adapters"`). A globally-`npm install -g`'d `bin/cli.js` has no such
clone to read from. This plan's core decision: **ship the compiled `adapters/` directory as
part of the published npm package**, with a `prepublishOnly` script guaranteeing it's freshly
regenerated before every publish (so it can never go stale relative to `.claude/` source).

## Current state

- `bin/cli.js` (full current content, 186 lines):

  ```js
  #!/usr/bin/env node
  'use strict';

  const fs   = require('fs');
  const path = require('path');
  const os   = require('os');

  const PKG_DIR    = path.resolve(__dirname, '..');
  const PKG_CLAUDE = path.join(PKG_DIR, '.claude');

  const SUBDIRS = ['commands', 'rules', 'skills', 'agents', 'hooks'];

  const NO_COLOR = process.env.NO_COLOR || !process.stdout.isTTY;
  const c = {
    green:  s => NO_COLOR ? s : `\x1b[32m${s}\x1b[0m`,
    yellow: s => NO_COLOR ? s : `\x1b[33m${s}\x1b[0m`,
    cyan:   s => NO_COLOR ? s : `\x1b[36m${s}\x1b[0m`,
    red:    s => NO_COLOR ? s : `\x1b[31m${s}\x1b[0m`,
    bold:   s => NO_COLOR ? s : `\x1b[1m${s}\x1b[0m`,
  };

  function ensureDir(dir) { if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true }); }
  function copyDir(src, dest) { /* recursive copy, see file */ }
  function chmodHooks(targetClaude) { /* chmod +x hooks/*.sh, see file */ }
  function resolveTarget(args) { return args.includes('--global') ? os.homedir() : process.cwd(); }
  function label(args) { /* "global (~/.claude/)" or "project (./.claude/)" */ }

  function cmdInit(args) { /* copies each SUBDIRS entry from PKG_CLAUDE into <target>/.claude/ */ }
  function cmdLink(args) { /* symlinks each SUBDIRS entry */ }
  function cmdUnlink(args) { /* removes symlinks */ }
  function cmdUpdate(args) { /* prints npm update instructions */ }
  function cmdHelp() { /* prints usage */ }

  const [,, command, ...args] = process.argv;
  switch (command) {
    case 'init':    cmdInit(args);   break;
    case 'link':    cmdLink(args);   break;
    case 'unlink':  cmdUnlink(args); break;
    case 'update':  cmdUpdate(args); break;
    default:        cmdHelp();       break;
  }
  ```

  Read the full file yourself before editing — this excerpt omits some function bodies for
  brevity, but the shape above (module-level `const`s, five `cmd*` functions, a `switch` at
  the bottom) is exact and complete for structural purposes.
- `install.sh`'s editor → target-path mapping (the exact mapping this plan ports), confirmed
  by reading `install.sh` lines 380–460:

  | Editor | Source (within `adapters/`) | Target path (project scope) | Target path (global scope) |
  | --- | --- | --- | --- |
  | `claude` | `.claude/{commands,rules,skills,agents,hooks}/*` (raw source, not compiled) | `<base>/.claude/{...}` | same, `<base>=$HOME` |
  | `cursor` | `adapters/cursor/qa.mdc` | `<base>/.cursor/rules/qa.mdc` | same |
  | `windsurf` | `adapters/windsurf/qa.md` | `<base>/.windsurfrules` | `<base>/.windsurf/rules/qa.md` |
  | `copilot` | `adapters/copilot/copilot-instructions.md` | `<base>/.github/copilot-instructions.md` | same |
  | `cline` | `adapters/cline/.clinerules` | `<base>/.clinerules` | same |
  | `antigravity` | `adapters/antigravity/qa/SKILL.md` | `<base>/.agents/skills/qa/SKILL.md` | `$HOME/.gemini/antigravity/skills/qa/SKILL.md` |

  Note the asymmetry: `claude` copies raw `.claude/` source (multiple files/dirs), every other
  editor copies one single compiled adapter file to one single target path. Model your data
  structure around this asymmetry rather than forcing both shapes into one generic copy
  function.
- `package.json` current full content — see plan 006's "Current state" section for the exact
  text (both plans may run against the same base file; don't assume plan 006 hasn't already
  changed it — re-read `package.json` live before editing).
- `.npmignore` current full content:

  ```gitignore
  adapters/
  tests/
  prompt-history/
  generate-adapters.sh
  generate-adapters.ps1
  install.sh
  install.ps1
  CLAUDE.md
  DISTRIBUTION_GUIDE.md
  QA_SKILL_TESTS.md
  USAGE_EXAMPLES.md
  .claude/settings.local.json
  ```

  The `adapters/` line is what this plan must remove.
- `README.md` lines 180–192 "Editor Support" table currently documents `install.sh --editor
  <name>` as the only way to install non-Claude editors, with the note: "The full multi-editor
  installer (`install.sh`) is available in the GitHub repository ... for editors beyond Claude
  Code." This table and note must be updated once `qa-skills init --editor <name>` works too —
  do not leave stale docs claiming a gap that no longer exists.
- `.claude/hooks/*.sh` need `chmod +x` after copy for the `claude` editor target — `cli.js`'s
  existing `chmodHooks` function already does this; keep reusing it for the `claude` case only
  (other editors don't have hooks).
- Node version available in this environment for testing: check with `node --version` — must
  be ≥18 for `@inquirer/prompts` (verify at execution time; do not assume).

## Scope

**In scope** (create/modify):

- `bin/cli.js` (major rewrite of `cmdInit`/`cmdLink`/`cmdUnlink`, add `--editor` parsing, add
  interactive menu)
- `package.json` (add `@inquirer/prompts` as a **regular** `dependency`, not devDependency —
  it's needed at runtime when the CLI runs; bump `engines.node` to `>=18`; add `"adapters/"` to
  the `"files"` array; add `"prepublishOnly": "./generate-adapters.sh --clean"` script)
- `.npmignore` (remove the `adapters/` line)
- `README.md` (update "Editor Support" table + CLI Reference section to reflect the new
  `--editor` flag and interactive menu; remove the now-inaccurate "full multi-editor installer
  is only in the GitHub repo" note, replacing it with accurate current capability)

**Out of scope** (do NOT touch):

- `install.sh` / `install.ps1` — they remain the reference implementation this plan ports
  from; do not modify their editor-mapping logic. (They were already fixed for the unrelated
  uninstall-glob bug in plan 004 — don't touch that either.)
- `generate-adapters.sh` — no changes; it already produces the 7 adapter files this plan
  consumes.
- Any actual editor-specific compiled *content* (i.e. don't edit what's inside
  `adapters/cursor/qa.mdc` etc. — only how `cli.js` copies those already-correct files).

## Git workflow

- Branch: `feat/cli-editor-support`.
- Commits:
  1. `feat: ship compiled adapters/ in the published npm package`
  2. `feat: add --editor targeting to qa-skills init/link/unlink`
  3. `feat: add interactive multi-select editor menu to qa-skills init`
  4. `docs: update README for CLI multi-editor support`
- Do NOT push or open a PR unless instructed.

## Steps

### Step 1: Ship `adapters/` in the published package

In `.npmignore`, remove the line `adapters/`.

In `package.json`, add `"adapters/"` to the `"files"` array (keep every existing entry) and
add a `prepublishOnly` script:

```json
"scripts": {
  "prepublishOnly": "./generate-adapters.sh --clean"
}
```

(If plan 006 already added a `"scripts"` object with other entries, add `prepublishOnly`
alongside them — do not replace the object.)

**Verify**: `./generate-adapters.sh --clean` (regenerate first, so the pack test below reflects
current source) then `npm pack --dry-run 2>&1 | grep "adapters/"` → shows adapter files listed
for inclusion. `npm pack --dry-run 2>&1 | grep -c "adapters/"` → a positive count (roughly 7,
one per compiled file, though exact count depends on nested paths — don't hardcode an exact
number in an assertion, just confirm it's non-zero).

### Step 2: Add editor → path mapping data and `--editor` flag parsing

In `bin/cli.js`, add a data structure describing every non-`claude` editor's source (within
the now-shipped `adapters/` dir) and its two target paths (project, global), matching the table
in "Current state" exactly:

```js
const ADAPTERS_DIR = path.join(PKG_DIR, 'adapters');

const EDITOR_TARGETS = {
  cursor:      { source: 'cursor/qa.mdc',                    project: '.cursor/rules/qa.mdc',                  global: '.cursor/rules/qa.mdc' },
  windsurf:    { source: 'windsurf/qa.md',                   project: '.windsurfrules',                       global: '.windsurf/rules/qa.md' },
  copilot:     { source: 'copilot/copilot-instructions.md',  project: '.github/copilot-instructions.md',      global: '.github/copilot-instructions.md' },
  cline:       { source: 'cline/.clinerules',                project: '.clinerules',                          global: '.clinerules' },
  antigravity: { source: 'antigravity/qa/SKILL.md',          project: '.agents/skills/qa/SKILL.md',           global: '.gemini/antigravity/skills/qa/SKILL.md' },
};

const ALL_EDITORS = ['claude', ...Object.keys(EDITOR_TARGETS)];
```

Add a helper to parse `--editor <name>` (or `--editor all`) out of `args`, validating against
`ALL_EDITORS` and printing an error + exit code 1 for an invalid value (mirror `install.sh`'s
own validation message style: `"Error: invalid --editor value '<value>'. Use: claude, cursor,
windsurf, copilot, cline, antigravity, or all."`).

**Verify**: temporarily add a `console.log` or write a quick standalone check that
`parseEditor(['--editor', 'bogus'])` exits 1 with the expected message, then remove the
temporary check — this is a structural check, not a permanent test file (no test framework
exists in this repo for JS; don't introduce one for this alone).

### Step 3: Rewrite `cmdInit` to support `--editor`

Extend `cmdInit(args)` so that:

- With no `--editor` flag and a TTY (`process.stdout.isTTY`): trigger the interactive menu
  (Step 4) instead of defaulting silently.
- With no `--editor` flag and **not** a TTY (CI, piped, non-interactive): preserve **today's
  exact behavior** — copy only the `claude` target (`.claude/{commands,rules,skills,agents,
  hooks}`) with no prompt, so existing scripts/CI using `qa-skills init` without flags do not
  break. This is a hard backward-compatibility requirement, not a suggestion.
- With `--editor claude`: same as today's `cmdInit` (the existing `SUBDIRS` copy logic —
  reuse it unchanged, don't rewrite what already works).
- With `--editor <name>` for any key in `EDITOR_TARGETS`: copy the one adapter file from
  `ADAPTERS_DIR/<source>` to `<targetBase>/<project|global path>`, creating parent directories
  as needed (`ensureDir(path.dirname(dest))`), matching `install.sh`'s per-editor target paths
  exactly (see the table in "Current state" — windsurf and antigravity have *different* paths
  for project vs. global scope; get this right, it's the most error-prone part).
- With `--editor all`: run `claude` plus every key in `EDITOR_TARGETS` in sequence, printing a
  `✓`/`~`/`⚠` line per editor exactly like the existing `cmdInit` does for `.claude/` subdirs.

**Verify**: create a scratch temp directory (e.g. under the scratchpad, NOT inside the repo),
`cd` into it, and run the built `bin/cli.js` (via `node <repo>/bin/cli.js init --editor cursor`)
— confirm `.cursor/rules/qa.mdc` is created with content matching
`<repo>/adapters/cursor/qa.mdc` byte-for-byte (`diff` the two files, expect no output). Repeat
for at least one more editor (e.g. `copilot`) to confirm the mapping table is read correctly,
not hardcoded to one case. Clean up the scratch directory afterward.

### Step 4: Add the interactive multi-select menu

Run `npm install @inquirer/prompts` (regular dependency, not dev — see Scope). Import
`checkbox` from `@inquirer/prompts` in `bin/cli.js`. When `cmdInit` is invoked with no
`--editor` flag and `process.stdout.isTTY` is true, prompt:

```js
const { checkbox } = require('@inquirer/prompts');
const chosen = await checkbox({
  message: 'Which editors do you want to install QA Skills for?',
  choices: [
    { name: 'Claude Code', value: 'claude', checked: true },
    { name: 'Cursor / Trae', value: 'cursor' },
    { name: 'Windsurf', value: 'windsurf' },
    { name: 'GitHub Copilot', value: 'copilot' },
    { name: 'Cline', value: 'cline' },
    { name: 'Gemini / Antigravity', value: 'antigravity' },
  ],
});
```

`cmdInit` becomes `async` to support this (top-level `switch` at the bottom of the file must
`await` it — wrap the dispatch in an async IIFE or top-level `await` if Node's CommonJS/module
type supports it in this repo's config; verify `package.json` has no `"type": "module"` — if
absent, CommonJS top-level await is unavailable in older Node, so wrap in an async function
call instead: `(async () => { switch(...) { case 'init': await cmdInit(args); break; ... } })();`).
Then install/copy for each editor in `chosen`, reusing Step 3's per-editor logic.

**Verify**: this cannot be fully automated (it's an interactive TTY prompt) — verify
structurally: `node -e "require('@inquirer/prompts')"` exits 0 (package resolves). Run
`node bin/cli.js init --editor claude` (non-interactive, explicit flag) end-to-end in a scratch
dir and confirm it still works exactly as before this plan (regression check on the one path
that must never change behavior).

### Step 5: Update `cmdHelp` and README

Update `cmdHelp()`'s printed usage to document `--editor <name>` and mention the interactive
menu triggers when no flag is given in a TTY.

In `README.md`:

- "Editor Support" table (lines ~182–190): change each non-Claude row's "Install" column from
  `install.sh --editor <name>` to `qa-skills init --editor <name>` (or list both, if you want
  to keep documenting the shell-installer path as an alternative — repo owner has not asked to
  remove `install.sh`, only to give `cli.js` parity).
- Remove or rewrite the note "The full multi-editor installer (`install.sh`) is available ...
  for editors beyond Claude Code" since it's no longer true — `qa-skills` (npm) now also
  supports them.
- "CLI Reference" table (lines ~202–209): add a row for `init --editor <name>` and
  `init --editor all`.

**Verify**: `grep -n "editor" README.md` shows the updated rows; `npx markdownlint-cli README.md`
→ exit 0.

## Test plan

No existing test framework covers `bin/cli.js` behavior (only shell-level install/uninstall
lifecycle via `./tests/test-lifecycle.sh`, which tests `install.sh`, not `bin/cli.js`). This
plan's manual scratch-directory verifications in Steps 3–4 are the test. Do not introduce a JS
test framework (Jest/Vitest/node:test) as a side effect of this plan — that would be an
unrequested new dependency; if the repo owner wants `bin/cli.js` test coverage, that's a
separate, explicit ask.

Run `./tests/test-lifecycle.sh` at the end regardless — it exercises `install.sh`, which this
plan does not touch, so it must still pass unchanged; a failure here means something in Step 1
(e.g. the `.npmignore`/`package.json` changes) unexpectedly affected `install.sh`'s behavior,
which would be a STOP condition (see below).

## Done criteria

- [ ] `npm pack --dry-run` includes `adapters/**`
- [ ] `node bin/cli.js init --editor cursor` in a scratch dir produces
      `.cursor/rules/qa.mdc` identical to `adapters/cursor/qa.mdc`
- [ ] `node bin/cli.js init --editor copilot` in a scratch dir produces
      `.github/copilot-instructions.md` identical to `adapters/copilot/copilot-instructions.md`
- [ ] `node bin/cli.js init --editor claude` (no other flags) in a scratch dir produces
      exactly the same `.claude/` tree as `bin/cli.js` did before this plan (regression check)
- [ ] `node bin/cli.js init` with stdout piped (non-TTY, e.g. `node bin/cli.js init | cat`) in a
      scratch dir behaves exactly like `--editor claude` — no hang, no crash, no prompt
- [ ] `package.json` has `@inquirer/prompts` under `dependencies` (not `devDependencies`),
      `engines.node` is `>=18`, `"adapters/"` is in `"files"`, `"prepublishOnly"` script exists
- [ ] `README.md`'s Editor Support table and CLI Reference table are updated; no remaining
      claim that non-Claude editors require the GitHub-only `install.sh`
- [ ] `./tests/test-lifecycle.sh` exits 0 (must be unaffected — it tests `install.sh`, not this
      plan's files)
- [ ] `git status --porcelain` shows only in-scope files changed
- [ ] `plans/README.md` row for 008 updated

## STOP conditions

- The current Node version available for testing is <18 — `@inquirer/prompts` requires it;
  you can still write the code but cannot execute-verify Steps 3–4's interactive parts. Report
  this plainly rather than claiming verification that didn't happen.
- Any of the `EDITOR_TARGETS` project-vs-global path pairs you derive from `install.sh` don't
  match what's read directly from the live `install.sh` file at execution time (it may have
  changed since this plan was written) — re-derive from the live file, don't trust this plan's
  table blindly if drift is detected.
- Making `cmdInit` async breaks the non-TTY/CI default path (`qa-skills init` with no flags in
  a script) — this must never change behavior; if you can't preserve it, stop and report rather
  than shipping a behavior change silently.
- `npm install @inquirer/prompts` pulls in a dependency tree that conflicts with anything plan
  006 installed — reconcile `package.json`/`package-lock.json` by hand; if unclear how, stop
  and report the conflict.

## Maintenance notes

- Any future new editor `install.sh` adds should also be added to `bin/cli.js`'s
  `EDITOR_TARGETS` map — the two are now parallel implementations of the same mapping and will
  drift if only one is updated. Consider, as a future follow-up (not this plan), extracting the
  mapping into a single JSON/JS data file both `install.sh` (via `jq` or similar) and
  `bin/cli.js` read from, to eliminate the duplication entirely.
- `install.sh` itself is unchanged and remains fully functional as an alternative multi-editor
  path (e.g. for users who don't have Node/npm) — this plan adds a second way to do the same
  thing, it does not deprecate `install.sh`.
