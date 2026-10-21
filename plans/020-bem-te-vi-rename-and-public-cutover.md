# Plan 020: Rename to Bem-te-vi and move to a fresh public repository

> **Executor instructions**: Two parts, in order. Part A is ordinary work in this private
> repository, one pull request. Part B prepares the public repository; every outward-facing step in
> it (creating the repository, pushing, making it public, `npm publish`, archiving this one) is
> **Marco's**. Prepare those steps and hand them over; never perform them.

## Status

- **Priority**: P0. Gates plan 019 phases 7-8 (README and launch).
- **Effort**: M (part A), M (part B)
- **Depends on**: plan 019 phases 2-4 merged (license, frontmatter, English default); the name
  decision in `decisions/name.md` (#104)
- **Planned at**: 2026-10-08

## Why this matters

Two decisions Marco made on 2026-10-08:

1. **The name.** "qa-skills" is shared with three other projects, including the unscoped npm
   package that a bare `npx qa-skills` installs. The package becomes **Bem-te-vi**: option B in
   `decisions/name.md`, which renames the package, command, repository and product name but keeps
   the internal file names, so existing installs need no migration.
2. **A fresh public repository.** The privacy scan (plan 019 phase 6) found copyrighted PDFs, a
   personal author email, an employer email and intranet host, and AI attribution trailers in this
   repository's history. Rewriting history would break every SHA this repository's audit trail and
   the monograph cite. Instead, this repository stays private and unaltered as the record of
   everything before launch, and a new public repository starts from the cleaned current tree.

## Part A: the rename (this repository, one PR)

Identifiers, from `decisions/name.md`:

| What | From | To |
| --- | --- | --- |
| Display name | QA Skills | Bem-te-vi |
| npm package | `@marcoamaral/qa-skills` | `@marcoamaral/bem-te-vi` |
| CLI command (`bin`) | `qa-skills` | `bem-te-vi` |
| GitHub repository | `MarcoAmaral/qa-skills` | `MarcoAmaral/bem-te-vi` (the new public one) |

**Do not rename** `.qa-skills-manifest`, `.qa-skills-known-hashes`, `.qa-skills-editor-map`, the
`.qa-skills-backup-<UTC>` suffix or `QA_SKILLS_DEBUG`. Changing them is option C, which needs a
migration in all three installers.

> **Added 2026-10-08, during part A:** the git hook marker comments
> (`# Added by qa-skills global installer`, `Pre-commit hook to validate test cases in qa-skills`)
> are kept too. Uninstall finds the hooks earlier versions wrote by those exact strings, so
> renaming them would strand those hooks.

Steps:

1. Inventory every user-visible occurrence: `grep -rn -i "qa skills\|qa-skills" --exclude-dir=node_modules
   --exclude-dir=.git --exclude-dir=adapters .`, then classify each hit as product name (rename),
   internal file name (keep), historical record (keep: `CHANGELOG.md`, plans, `decisions/`) or test
   fixture (never edit: `tests/conformance/cases/`). At planning time `bin/cli.js`, the installers,
   the generator and the adapter checks held 83 occurrences.
2. Rename in `package.json` (`name`, `bin`, `description`, `repository`, `homepage`, `bugs`),
   `bin/cli.js` (usage and help text, report messages), `install.sh` / `install.ps1` (banners,
   messages), both generators (the `<!-- QA Skills … -->` adapter header) and the adapter checks
   that read it (`tests/verify-adapters.sh:70` and its PowerShell twin), the commands' and skills'
   product name (`qa.md` line 3: `**QA Skills** | Marco Amaral`), `README.md`, `CLAUDE.md`,
   `CONTRIBUTING.md`, `SECURITY.md`, `DISTRIBUTION_GUIDE.md`, `USAGE_EXAMPLES.md`.
3. Keep the slash commands as they are (`/qa`, `/qa-cases`, …): they describe what each does, and
   users invoke them by habit.
4. **Version**: renaming the command breaks anyone who scripted `qa-skills`, so this is a breaking
   change (`feat!:` with a `BREAKING CHANGE:` footer naming the old and new command). Release
   Please then proposes 3.0.0, which doubles as the launch version.
5. Lifecycle suites and conformance runners call the CLI by path (`bin/cli.js`); check whether any
   assert on output that contains the old name, and update the assertion, not the behaviour.
6. Regenerate adapters and run the full CI check list. `./generate-known-hashes.sh --check` must
   still pass (renamed text is not a released file yet).

## Part B: the public repository (prepared here, performed by Marco)

### What goes public

The current tree of `main` after part A, **minus**:

- anything gitignored (it is not in the tree): `docs/`, `CTFL/`, `EngSW/`, `.tmp_repos/`;
- `.claude/settings.local.json` (local paths; untrack it in this repository first);
- `prompt-history/`: only templates, so it may stay; decide when exporting.
  **Decided by Marco, 2026-10-20**: it stays in the public tree.

Review before export: plans 014-016 mention the employer (allowed by plan 019) and describe daily
work in general terms; reread them once for anything Marco would not publish.

**Changelog** (DECISION, Marco): its entries link to commits in this private repository, which
404 for the public. Recommended: keep the entries as text, add one line at the top saying versions
before 3.0.0 were developed in a private repository, and drop the dead commit links. Alternative:
start the changelog fresh at 3.0.0.

### Steps (Claude prepares, Marco runs)

1. **Export**: `git archive main | tar -x -C <new dir>`, apply the exclusions, rerun the privacy
   scan's checks on the result (gitleaks, the term list, emails), and confirm
   `CTFL/`, `EngSW/` and every intranet host are absent.
2. **Author identity**: in the new repository set `user.email` to Marco's GitHub noreply address
   before the first commit.
3. **First commit**: one commit, message naming the private repository's final `main` SHA as its
   origin, so the two records link.
4. **Release Please**: in the new repository set `.release-please-manifest.json` to the current
   version and `bootstrap-sha` in `release-please-config.json` to the first commit, so it proposes
   3.0.0 from the rename rather than re-releasing every version.
5. **CI**: the workflows come with the tree; check that the PR-title, CI and Release Please
   workflows pass on the first push, on all three platforms.
6. **Marco**: create `MarcoAmaral/bem-te-vi`, push, run plan 019 phase 8's checklist there (public,
   description and topics, `npm publish --access public`, the clean-directory install check).
   **Added 2026-10-20 (pre-launch review):** package.json now carries
   `"publishConfig": {"access": "public"}`, so a bare `npm publish` of the scoped package is public
   too; `--access public` stays in the step and does no harm.
7. **Marco**: archive this repository (read-only). It stays private, as the monograph's record of
   the work before launch.

### Working after the cut-over

All work moves to the public repository: issues, PRs, releases, npm. Plan 019 phases 9-13 run
there, with the same conventions (`CONTRIBUTING.md`, conventional commits, default merge commits,
no AI attribution). This repository receives no further commits.

## Rejected approaches

- **Rewrite this repository's history** (`git filter-repo`) and make it public: changes every SHA,
  breaking release tags, changelog links and the audit trail the monograph cites.
- **Keep developing privately and push release snapshots to the public repository**: outside PRs
  and issues land in public and must be copied back by hand, release tooling must live in one of
  the two, and public history becomes coarse release dumps.
- **Rename the internal file names too** (option C): needs an installer migration and a major
  version for no user-visible gain.
- **Keep "qa-skills"**: see `decisions/name.md`.

## Verification

- Part A: the full CI check list green on Linux, Windows and macOS; `grep` shows no user-visible
  "QA Skills"/`qa-skills` left outside the keep-list; `npm pack --dry-run` shows the new name;
  `node bin/cli.js --help` prints `bem-te-vi`.
- Part B: the export passes the privacy checks; the public repository's first CI run is green;
  `npx @marcoamaral/bem-te-vi@latest init --editor claude` works in a clean directory after
  Marco publishes.

## Decisions and findings (2026-10-14)

- **Changelog** (Marco chose the recommendation): keep every entry as text, add one line at the top
  saying versions before the public repository were developed in a private repository, and drop
  the commit and compare links, which would 404. This repository's changelog stays unaltered.
- **Employer product name** (privacy scan finding 7, `CHANGELOG.md` v2.2 entry): reworded in the
  public copy only, for the same reason.
- **Plans 014-016 and 025 reread for publication**: no client, product, system, person, repository
  or ticket names. They name the employer and describe its QA practice in general terms, which
  plan 019 allows. Marco decided they stay as written, employer name included.
- **Plan 032 comes first.** A tagless dry run of step 1 (export of `7d33cbf`, `git init`, one
  commit) failed 2 of 15 CI steps: the known-hash generator needs tags, and lifecycle Test 20 reads
  a release tag. Without the fix, the first public release would also drop the hashes of every
  release shipped from here.
- **Step 4 is stale**: the manifest takes the last version released from this repository (not
  3.0.0), and `bootstrap-sha` the public repository's first commit.

## Added 2026-10-18: snapshot the PR descriptions before step 7 (plan 038)

Plan 038's open question 1, decided by Marco on 2026-10-14 (its default): before step 7 archives
this repository, snapshot every pull request's description into a committed file here, so the
build-record index can read them by ref. Run, in this repository:

```bash
gh pr list --state all --limit 1000 --json number,title,body,mergedAt,mergeCommit > plans/pull-requests.json
```

and commit it (`docs:`). PR bodies may name the employer, so the file stays in this private
repository only: leave it out of the step 1 export. `generate-corpus.js` reads it from that path
and indexes nothing for PRs while it is absent.
