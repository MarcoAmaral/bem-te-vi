# Plan 055: CI guards for the drift found by hand, before the 4.1.0 export

> **Executor instructions**: Branch `test/ci-guards` from `github/next`, one pull request into
> `next`, one commit per item (more where an item has a content fix and a check: the fix first, so
> every commit passes). Every new check is shown failing first, on the current tree or on a
> mutation, and the failure is quoted below and in the pull request. Content fixes do not change
> what a sample or template teaches beyond the error the check found. A lint or format fix that
> would change installer behaviour stops that item. Run `bash ~/qa-ci-all.sh <worktree>` on all
> three platforms before reporting.

## Status

- **Priority**: P1 (before the 4.1.0 export: the public repository starts with these guards)
- **Effort**: M
- **Risk**: LOW (new checks, one content correction per finding, no installer change)
- **Depends on**: plan 050 (`npm ci` on Node 24, PR #197), plan 030 (the `qa-writer` and
  `qa-designer` contract), plan 031 (the README and `/qa` router tables)
- **Category**: test, ci
- **Planned at**: commit `aa9c92c` (`github/next`), 2026-10-19
- **Decided by Marco, 2026-10-19**: do every item below before the 4.1.0 export; plan number 055.
- **Outcome**: done, branch `test/ci-guards` (into `next`), see "Outcome" below

## Why this matters

Five earlier plans ended with the same maintenance note: a drift nothing checked.

- Plans 001 (lines 179-183) and 003 (542-545): a `/qa-*` name in the router that no longer
  resolved to a command.
- Plans 031 (182-184) and 034 (491-492): the README command table and the size columns drift from
  the files. They have drifted again since: the `/qa` router says `/qa-cases` is ~19KB (it is
  21,467 bytes, ~21KB), `/qa-defect` ~13KB (16,642, ~16KB), `/qa-refinement` ~6KB (8,456, ~8KB) and
  `/qa-tdd` ~3KB (5,136, ~5KB).
- Plan 006 (258-262) and the plans README backlog: ESLint and Prettier run only through
  lint-staged, on staged `*.js`; nothing runs them over the tree and there is no `npm run lint` or
  `npm test`.
- Plans 028 (305-306) and 036 (507-510): the TypeScript samples under `.claude/` are copied into
  users' projects, and two of them could not have compiled before plan 028 corrected them; nothing
  compiles them in CI.
- Plan 030 (204-206): `tests/test-tc-contracts.sh` checks the technique names only, not that the
  `qa-writer` agent reads every field the `qa-designer` agent writes.

And one new: GitHub's `ubuntu-latest` label moves to Ubuntu 26 from 2026-10-19, while the local CI
that stands in for GitHub's (`~/qa-ci-all.sh`, plan 050) runs on Ubuntu 24.04.

## Steps

1. **I3. Pin the Linux runner.** Every `runs-on: ubuntu-latest` in `.github/workflows/` becomes
   `ubuntu-24.04`, with a one-line comment saying why, so the first public run uses the image the
   local CI mirrors. Verify: `grep -rn 'runs-on: ubuntu-latest' .github/workflows` finds
   nothing.
2. **I4. Correct the `/qa` router's sizes** from `wc -c`, KB = bytes / 1024 rounded to the nearest
   whole number (what every correct row of both tables already does: `/qa-automate` 6.68 is ~7KB,
   `/qa-review` 2.94 is ~3KB).
3. **I5. `tests/test-docs-drift.sh`**: every `/qa-<name>` in shipped content and `README.md` is a
   command file or a skill invoked by its name; README's command table lists exactly
   `.claude/commands/*.md` and the router lists every command but itself; every `~NKB` in either
   table matches `wc -c`. README has no size column for skills, so there is none to check. Red on
   the current tree (step 2's four sizes) and on mutations of the other two checks.
4. **I8. Extend `tests/test-tc-contracts.sh`**: the field names of a `qa-designer` checklist entry
   (the `- <Field>:` lines of its output contract) equal the fields the `qa-writer` agent says it
   reads from `checklist.md`, written as `` `<Field>:` `` in its "Where each value comes from"
   list. Fix the writer's list if the check finds a field it never reads.
5. **I6. `npm run lint` and `npm test`.** `lint` runs `eslint .` and `prettier --check .` over what
   their configurations cover; `test` runs the fast local checks (no installer suites, no
   generator, no ShellCheck, which is a system package). A Linux CI step runs `npm run lint`.
   Whatever `prettier --check .` reveals is fixed in its own commit without changing behaviour.
6. **I7. `tests/test-ts-samples.sh`**: extract every ```` ```ts ````, ```` ```typescript ```` and
   ```` ```tsx ```` block under `.claude/`, write each to its own file (at the path its first-line
   comment names, if any, so the blocks of one document can import each other), and run
   `tsc --noEmit --strict --skipLibCheck` over them with a generated `tsconfig.json`. A block that
   is intentionally partial is skipped only after a `<!-- ts-check: skip (<reason>) -->` line; every
   marker is listed below with its reason. Fix the real type errors (content commits). Types come
   from the smallest set of devDependencies: `typescript`, `@playwright/test`, `vitest`,
   `@types/node`; any other package a sample imports is declared as an untyped module in the
   check, and listed there.
7. Add each new check to `ci.yml` (Linux job, beside the others, with its own ShellCheck line as
   the newer steps do) and to the table in CONTRIBUTING.md section 4.

`examples/` is not checked by step 6: it is not in `package.json` `files`, so it does not ship, and
its outputs are committed unedited on purpose (plan 028).

## Done criteria

- [x] `grep -rn 'runs-on: ubuntu-latest' .github/workflows` finds nothing.
- [x] `tests/test-docs-drift.sh`, `tests/test-ts-samples.sh` and the extended
      `tests/test-tc-contracts.sh` pass, are ShellCheck-clean, and each was seen failing first.
- [x] `npm run lint` and `npm test` exit 0.
- [x] `bash ~/qa-ci-all.sh <worktree>` prints `linux=PASS mac=PASS windows=PASS`.

## STOP conditions

- A lint or format fix would change what an installer does: stop that item and report.
- A TypeScript sample fails in a way whose fix would change what it teaches (not only make it
  compile): stop that sample, mark nothing, and report.
- `typescript`, `@playwright/test` or `vitest` cannot be added without a high-severity advisory in
  the shipped (non-dev) dependency tree.

## Outcome (2026-10-19)

Branch `test/ci-guards`, one pull request into `next`. No STOP condition fired. Every item had a
documented direction from Marco (2026-10-19), so no default had to be chosen.

**I3, runners.** The five `runs-on: ubuntu-latest` (three in `ci.yml`, one each in `pr-title.yml`
and `release-please.yml`) are `ubuntu-24.04`, each with a one-line comment.
`grep -rn 'runs-on: ubuntu-latest' .github/workflows` now finds nothing. The Windows and macOS jobs
keep `windows-latest` and `macos-latest`: the local CI does not mirror an image for them.

**I4, router sizes.** `/qa-cases` ~21KB, `/qa-defect` ~16KB, `/qa-refinement` ~8KB, `/qa-tdd` ~5KB.
Each number has the same width as the old one, so `qa.md` stays 14,161 bytes and its own README
size does not move. The parallel work on the 5,000-token limit will change `/qa-cases` (and
`qa-plan`, which has no size column) again; `tests/test-docs-drift.sh` will then name the row to
update.

**I5, `tests/test-docs-drift.sh`.** Three checks:

- all 141 `/qa-*` references in `.claude/{agents,commands,rules,skills,hooks}` and `README.md`
  resolve to a command or a skill (a name inside a path or URL, such as `.claude/qa-x` or
  `github.com/a/qa-x`, is not a reference);
- README's command table lists exactly `.claude/commands/*.md`, and the `/qa` router's table lists
  every command but `/qa`;
- every `~NKB` in both tables is `round(bytes / 1024)`.

Red on the tree before I4: the four router rows above, for example
`✘ the /qa router's command table: /qa-cases says ~19KB, but .claude/commands/qa-cases.md is 21467
bytes (~21KB)`. Red on mutations: `/qa-trace` renamed `/qa-tracer` in `qa.md` (unresolved reference
at `qa.md:38`, and a router row for a command that does not ship); README's `/qa-review` row renamed
(missing and extra command); a new `qa-new.md` with no row (missing from both tables); 2,000 bytes
added to `qa-review.md` (both tables: `says ~3KB, but ... is 5014 bytes (~5KB)`). README has no size
column for skills, so there is none to check.

**I8, the designer-to-writer hand-off.** `tests/test-tc-contracts.sh` now compares the `- <Field>:`
lines of the `qa-designer` output contract with the `` `<Field>:` `` names in the `qa-writer`
"Where each value comes from in `checklist.md`" list. Red on the tree:
`✘ qa-designer writes fields qa-writer never says it reads: Checks, Feature tag, Level, Priority,
Status, Suite, Technique`. Five of the seven were named in prose and never marked as fields; two
were not named at all: nothing said the **ISTQB Technique** row comes from `Technique:` or that each
item of `Checks:` becomes one test case. The writer's list now names all eight (content commit
`fix(agents):`). Red on mutations: the writer reading a `Severity:` the designer never writes, and
the designer gaining a `Risk:` field the writer never reads. The header block (Feature, Code,
Tracker, Risk) is a placeholder line in the designer's contract, not `- <Field>:` lines, so it is not
compared; both agents copy it unchanged from `requirements.md`.

**I6, `npm run lint` and `npm test`.** `eslint .` already passed. `prettier --check .` failed on 55
files, all records or fixtures: `examples/` (committed unedited, plan 028), `benchmark/results/`,
`evals/results/`, the benchmark's `fixtures/` (their text is inside `benchmark/cases.sha256`) and its
two plugins (what conditions A to C load), `tests/fixtures/`, and `plans/pull-requests.json` (written
by `gh pr list --json`). They are in `.prettierignore`, each group with its reason; none was
reformatted. The 55th, `.claude-plugin/plugin.json`, is checked with Prettier's `json-stringify`
parser: Release Please rewrites it with `JSON.stringify` on every release, which puts each array
item on its own line, and Prettier's default `json` parser would fold them, so formatting it would
have been undone, and `npm run lint` failed, by the next release. No tracked file changed format,
so no installer behaviour could change. `npm run lint` is `eslint . && prettier --check .`; red
with the old configuration (55 files) and on a mutation (extra spaces in one line of
`cli/bem-te-vi.js`), green after. A Linux CI step runs it right after `npm ci`. `npm test` runs
fifteen checks that need only Node and bash, plus the benchmark integrity check, in about 13
seconds; CONTRIBUTING.md section 4 says what it leaves out.

**I7, `tests/test-ts-samples.sh`.** 21 TypeScript blocks under `.claude/`: 11 type-check with
`tsc --strict --skipLibCheck` (TypeScript 7.0.2), 10 are skipped by a marker. Red on the tree before
the markers: three parse errors in the JSX block (`playwright-patterns.md:294`), which stop `tsc`
before it checks types; with only that block marked, 46 errors in the other 9 blocks the markers now skip (`TS2304` cannot find
`page`, `applyDiscount`, `calculateTotal`, `saveCartTotal`, `vi`; `TS2593` `it`/`describe` without
an import; `TS2307` `./fileName`, `./validationUtils`, `../../pages/SignInPage`). Red on mutations:
`waitFor({ state: "shown" })` in `BasePage` (`TS2322`, not one of the four states), a string
coverage threshold in the Vitest config (`TS2769`), a marker with no reason, a marker followed by
text. The playwright-patterns page objects and spec are written at the paths their first comment
names, so `CheckoutPage` imports `BasePage` and the spec imports `CheckoutPage` as in a project.

Every opt-out marker, `<!-- ts-check: skip (<reason>) -->` on the line before the block's fence
(one blank line between, for markdownlint):

| Block (fence line) | Reason in the marker |
| --- | --- |
| `.claude/commands/qa-bdd.md:192` | uses the project's SignInPage page object, which the sample does not define |
| `references/automation-ci.md:22` | fragment: page is the test's fixture |
| `references/automation-code.md:74` | shows test structure: applyDiscount is the code under test, not shown |
| `references/automation-code.md:110` | fragment: page and expect come from the surrounding test |
| `references/automation-code.md:124` | shows Arrange-Act-Assert: calculateTotal is the code under test, not shown |
| `references/evidence-capture.md:26` | fragment: page is the test's fixture |
| `references/playwright-patterns.md:294` | a JSX attribute beside two Playwright expressions, not one file |
| `references/vitest-patterns.md:78` | template: ./fileName stands for the module under test |
| `references/vitest-patterns.md:112` | fragment: the top of a test file, with vi as a Vitest global and the module under test not shown |
| `references/vitest-patterns.md:131` | fragment: Vitest globals, and saveCartTotal and loadCartTotal are the code under test, not shown |

(`references/` is `.claude/skills/qa-reference/references/`.) The marker commit is `docs:`: an HTML
comment changes nothing a reader or an assistant is told to do, so it is not a `fix:`.

Types: devDependencies `typescript` (already in the tree through commitlint's TypeScript loader,
now named), `@playwright/test`, `vitest` and `@types/node@24`; `node_modules` grows from 101 MB to
158 MB; `npm audit --omit=dev` still finds nothing, and the dev audit lists the same seven advisories
as before. Five packages the samples import have no types installed and are declared as untyped
modules in the check: `@axe-core/playwright`, `@cucumber/cucumber`, `@testing-library/jest-dom`,
`@vitejs/plugin-react` and `dotenv`, plus the fictional `@my-company/payment-sdk/*` of a skipped
block. Code around them is checked; their own API is not.

**Rejected approaches** (kept, with the reason):

- *Fixing the `/qa-bdd` step definitions.* Under the `@cucumber/cucumber` stub every step function's
  `this.page` failed with `TS2683` (`this` implicitly `any`), and a typed `PlaywrightWorld` was
  written for all eleven steps. Checked against the real `@cucumber/cucumber` 13.3.0 types in a
  temporary folder, the original block compiles with no error: `IWorld` has an index signature, so
  `this.page` is `any` there. The failure was the stub's, not the sample's, so the sample was
  restored and the check sets `noImplicitThis: false`, which makes a stubbed callback behave as the
  real types do.
- *Installing real types for all five packages* (+95 packages, +36 MB): rejected for the smallest
  addition Marco asked for. Worth revisiting if a sample's use of one of those APIs is ever wrong.
- *A prelude that declares `page` for the fragments*, so they are checked too: not done. It would
  check five more blocks, but every fragment would need its own declarations, which is the
  hand-written typing the stubs avoid.
- *Checking `examples/`*: not shipped (`package.json` `files`), committed unedited on purpose, and
  `prettier --check` already shows they are kept byte for byte.

**Local CI** on `57c6334` (the last code commit; only this plan and its README row change after it):
`ALL LOCAL CI (ci-guards @ 57c6334): linux=PASS mac=PASS windows=PASS` (Linux 23 steps, bash 3.2 five
steps, Windows four steps with conformance 74/74 and 18 cases not run for want of symlink privilege,
and adapter parity).

**Merge with `next`, 2026-10-19.** `next` gained #198 (fixes to `/qa-cases` and `/qa-defect` from the
benchmark pilot) while this branch was open. The merge had one conflict, in
`tests/test-tc-contracts.sh`, where #198 added its Source and `/qa-defect` checks beside this plan's
hand-off check; both are kept. On the merged tree `tests/test-docs-drift.sh` failed at once:
`✘ README.md's command table: /qa-cases says ~21KB, but .claude/commands/qa-cases.md is 22168 bytes
(~22KB)`, and the same for `/qa-defect` (18,206 bytes, ~18KB) in both tables. #198 had changed the
two files without their size rows; the next commit gives both tables ~22KB and ~18KB. This is the
drift the check exists for, found on its first merge.

**For `~/qa-ci-local.sh`** (Marco maintains it):

```bash
add lint 'if grep -q "\"lint\":" package.json; then npm run lint; else npx eslint .; fi'
add docs-drift '[ ! -f tests/test-docs-drift.sh ] || { shellcheck tests/test-docs-drift.sh && ./tests/test-docs-drift.sh; }'
add ts-samples '[ ! -f tests/test-ts-samples.sh ] || { [ -d node_modules/@playwright/test ] || npm ci --no-audit --no-fund >/dev/null 2>&1; shellcheck tests/test-ts-samples.sh && ./tests/test-ts-samples.sh; }'
```

The existing `eslint` line (`npx eslint .`) is covered by `lint` and can go. `ts-samples` runs
`npm ci` first when `node_modules` predates the new devDependencies (the script installs only when
`node_modules` is missing). `tc-contracts` already runs the extended test.
