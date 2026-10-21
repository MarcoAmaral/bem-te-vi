# Plan 051: Move the npm CLI out of `bin/`, so the plugin puts nothing on PATH

> **Executor instructions**: Branch `refactor/cli-out-of-bin` from `github/next`, one pull request
> into `next`. Verify the reason below against the current Claude Code plugin documentation first;
> if the documentation says otherwise, stop and report before moving anything. Move the file with
> `git mv` so its history follows it. Change every live reference; leave `tests/fixtures/**`,
> `CHANGELOG.md` and the text of past plans as they are (append a dated note only where a plan's
> instructions would now mislead). One concern per commit. Run `bash ~/qa-ci-all.sh <worktree>` on
> all three platforms before reporting.

## Status

- **Priority**: P1 (a launch blocker for the claude.ai and Cowork plugin route)
- **Effort**: S
- **Risk**: LOW (one file moves; the npm command name and its behaviour do not change)
- **Depends on**: plan 022 (the plugin and its marketplace entry, whose source is the repository
  root), plan 046 (the last change to the CLI)
- **Category**: fix, packaging
- **Planned at**: commit `5109cea` (`github/next`), 2026-10-19
- **Decided by Marco, 2026-10-18**: accept the pre-launch audit's recommendation to move
  `bin/cli.js` to `cli/bem-te-vi.js`.
- **Outcome**: done, branch `refactor/cli-out-of-bin` (into `next`), see "Outcome" below

## Why this matters

`.claude-plugin/marketplace.json` lists the plugin with `"source": "."`, so the repository root is
the plugin root, and the npm CLI at `bin/cli.js` sits in the plugin's `bin/` folder. Claude Code
gives that folder a meaning of its own.

What the documentation says, read on 2026-10-19:

- The plugin reference (<https://code.claude.com/docs/en/plugins-reference>, "Standard layout"),
  row "Executables", default location `bin/`: "Files here are on the Bash tool's `PATH` while the
  plugin is enabled, so Claude runs them as bare commands. claude.ai and Cowork don't install a
  plugin that has this directory, including one you distribute through claude.ai organization
  settings".
- The organization sync page (<https://claude.com/docs/plugins/org-sync>, "Keep executables out of
  the top-level bin directory"): "Don't include a top-level `bin/` directory in any plugin you
  distribute through organization settings. claude.ai rejects a plugin that has one, whether the
  plugin arrives by marketplace sync or by direct upload [...]. The error message starts with
  `Plugin contains a top-level bin/ directory`."

So the audit's reasoning holds on both counts:

1. A Claude Code user who installs the plugin gets `cli.js` on the Bash tool's `PATH`, a file
   that is not a command anyone should run there (it installs the package into the current
   folder).
2. The same repository cannot be installed as a plugin through claude.ai or Cowork at all.

npm's own `bin` field in `package.json` is a different thing: it names the file npm links as the
`bem-te-vi` command, and it can point anywhere in the package. Only the path changes.

## Steps

1. `git mv bin/cli.js cli/bem-te-vi.js`. The CLI finds the package as `path.resolve(__dirname,
   "..")` and reads `../package.json`; the new folder is at the same depth, so the code does not
   change.
2. `package.json`: `bin` becomes `{"bem-te-vi": "./cli/bem-te-vi.js"}` and `files` lists `cli/`
   instead of `bin/`; `package-lock.json` follows (`npm install --package-lock-only`).
   `.npmignore` does not list `bin/`. `eslint.config.js` lints `cli/**/*.js`.
3. The tests that run the CLI by path: `tests/test-lifecycle.sh`, `tests/test-lifecycle.ps1`
   (including the package copies that `link` tests build, which copied `bin`), and the two
   conformance runners. The runners also run an older package tree (`CONFORMANCE_PKG`,
   `-Package`), and every release so far has the CLI at `bin/cli.js`, so they use
   `cli/bem-te-vi.js` when the tree has it and `bin/cli.js` otherwise.
4. Every live mention: `CLAUDE.md`, `README.md`, `CONTRIBUTING.md`, `SECURITY.md`,
   `tests/conformance/README.md`, comments in `install.sh`, `install.ps1` and
   `tests/verify-adapters.*`. `ci.yml`, `llms.txt` and the generators name no CLI path (checked).
5. Plans 047 and 049 name `bin` in their drift-check commands: a dated note under each says the
   CLI is now `cli/bem-te-vi.js`.

## Done criteria

- [x] `npm pack --dry-run` lists `cli/bem-te-vi.js` and nothing under `bin/`.
- [x] `npx --no-install bem-te-vi --version`, run in a temporary folder where the packed tarball
      was installed, prints the version.
- [x] `git grep -n 'bin/cli'` shows only `tests/fixtures/**`, `CHANGELOG.md` and plans.
- [x] `bash ~/qa-ci-all.sh <worktree>` prints `linux=PASS mac=PASS windows=PASS`.

## STOP conditions

- The Claude Code documentation no longer puts a plugin's `bin/` on `PATH`, or no longer says
  claude.ai and Cowork refuse a plugin with a top-level `bin/`: stop and report, move nothing.
- Anything other than a path reference has to change for the CLI to work from its new folder.

## Outcome

## Outcome (2026-10-19)

- **The documentation check** held: both quotes in "Why this matters" were read on 2026-10-19, so
  no STOP condition fired.
- **The move.** `git mv bin/cli.js cli/bem-te-vi.js` with no change to the file (the rename has 0
  insertions and 0 deletions); `package.json` `bin` and `files`, `package-lock.json`,
  `eslint.config.js`, both lifecycle suites (including the package copies the `link` tests build)
  and both conformance runners. Every other mention is a separate `docs:` commit.
- **Older package trees.** The conformance runners use `cli/bem-te-vi.js` and fall back to
  `bin/cli.js`. Checked: `CONFORMANCE_PKG=<a git archive of 5109cea> tests/conformance/run.sh 001`
  ran the CLI from that tree's `bin/cli.js` and passed.
- **Packing.** `npm pack --dry-run` lists `cli/bem-te-vi.js` (55.9 kB) and no `bin/` entry. The
  packed tarball, installed into a temporary folder, answered `npx --no-install bem-te-vi
  --version` with `bem-te-vi 4.0.1`, and its `node_modules/.bin/` holds `bem-te-vi`.
- **What still says `bin/cli`.** `git grep -n 'bin/cli'` lists `tests/fixtures/release-v4.0.1/install.sh`
  (two lines, release bytes), `plans/pull-requests.json`, `plans/README.md` (finished rows and the
  dated audit backlog) and plan files, this one included. Plans 047 and 049 have a dated note,
  because their drift-check commands name `bin`.
- **Local CI** on `3c6a164`: `ALL LOCAL CI (cli-out-of-bin @ 3c6a164): linux=PASS mac=PASS
  windows=PASS`.
- **Commit type.** The move is `fix(plugin):`, not `refactor:`: someone who installs the plugin
  gets a different result (nothing on the Bash tool's `PATH`, and claude.ai and Cowork accept the
  plugin), which is what CONTRIBUTING.md section 2 reserves `fix:` for.
