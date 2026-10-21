# Plan 038: Every syllabus claim cites a section, and every chunk has a stable, citable identity

> **Executor instructions**: Do this plan **after** plans 034 (restructure), 035 and 036 (new
> content) have merged, and after plan 032. The ids assigned here are the file names those plans
> leave behind, so metadata is added once and not redone after a rename. Run every verification
> command. If anything in "STOP conditions" occurs, stop and report. When done, update this plan's
> row in `plans/README.md`.
>
> **Drift check (run first)**: `git diff --stat a2f08e7..HEAD -- .claude generate-adapters.sh generate-adapters.ps1 tests/verify-adapters.sh tests/test-frontmatter.sh tests/test-rules-size.sh plans/README.md decisions CHANGELOG.md CONTRIBUTING.md`
> Drift **is expected**: 034-036 change `.claude/`. Re-measure every number in "Current state"
> before Step 1 and write the new figures in the PR description beside the ones below.

## Status

- **Priority**: P1 (what makes the package citable as monograph evidence and queryable as a corpus)
- **Effort**: L
- **Risk**: LOW-MEDIUM (touches every shipped Markdown file once; the adapters must not change)
- **Depends on**: plans 034, 035, 036 (content and file names settle first); plan 032 (the tree
  builds without private history, which the record index also relies on)
- **Category**: feat (shipped metadata and citations), build, test
- **Planned at**: commit `a2f08e7`, 2026-10-14
- **Decided by Marco, 2026-10-14**: every default in "Open questions" (PR descriptions are snapshotted into this repository before plan 020 part B archives it; no per-file anchors in adapters; no index attached to releases; steps 1 and 3 may land early).
- **Source**: plan 014 Phase D (D1, D2, D3)
- **Decision (D3), decided by Marco, 2026-10-14**: the corpus is **both** the shipped content (what
  the package teaches: rules, commands, skills, agents, references) **and** the build record (plans,
  PR descriptions, `CHANGELOG.md`, `decisions/`). They chunk differently: shipped content by
  heading, under a stable file id; the build record by plan, step and decision, with dates and
  commit/PR links.
- **Decisions for Marco**: three, in "Open questions" at the end; defaults are written into the
  steps.

## Why this matters

Plan 014 D1 measured, on 2026-09-24, **zero** section citations in shipped content. That is no
longer true (see below), but citation is still uneven: 26 of 36 shipped files cite no section, and
nothing checks that a cited section exists. A retrieved chunk saying "two-value BVA tests min-1,
min, max, max+1" is checkable only if it names §4.2.2 and §4.2.2 is real.

Plan 014 D2 found no retrieval metadata in rules and commands. Commands and skills have since gained
frontmatter (plan 019 phase 3), but only `description`/`name`/`argument-hint`: fields for a runtime,
not identities for a citation. A file renamed by plan 034 would leave every citation of its old path
dangling. The build record, the monograph's actual subject, has no index at all: its status lives
in a hand table, its dates in free-text "Planned at" lines in three different formats, and its PR
descriptions only on GitHub, which plan 020 part B leaves behind in the private repository.

## Current state (measured 2026-10-14 at `a2f08e7`)

### Shipped content: frontmatter

`find .claude -name '*.md'` → 36 shipped files. Frontmatter by kind (first line `---`):

| Kind | Files | Frontmatter | Fields today |
| --- | --- | --- | --- |
| commands | 11 | all | `description`, `argument-hint` (`qa-review.md`: `description` only) |
| skills (`SKILL.md`) | 4 | all | `name`, `description` |
| agents | 4 | all | `name`, `description`, `model`, `tools` |
| rules | 9 | **none** | — |
| `qa-reference/references/*.md` | 8 | **none** | — |

No file carries an `id`, an `istqb` field or a `version`. Basenames are **not** unique: the rule
`test-tools.md` and the reference `references/test-tools.md` collide, and four files are `SKILL.md`.

### Shipped content: citations

| Measure | Command | Result |
| --- | --- | --- |
| `§N.N` citations | `grep -rEo '§[0-9]+(\.[0-9]+)*' .claude --include=*.md \| wc -l` | **99** (36 distinct sections) |
| Chapter-only citations | `grep -rnEi '(ch\.\|chapter) ?[0-9]' .claude --include=*.md` | 4 (`qa-plan` ×2, `qa-static`, rule `test-tools`) |
| Lines naming CTFL | `grep -rn 'CTFL' .claude --include=*.md \| wc -l` | 70 |
| …of which with no `§` | `… \| grep -v '§' \| wc -l` | **23** (mostly role banners `> **Senior QA …** \| ISTQB CTFL v4.0`; the rest listed in Step 3) |
| Files citing ≥1 section | `grep -rcE '§[0-9]' .claude --include=*.md \| grep -v ':0$'` | 10 of 36: `qa-static` 19, `qa-plan` 22, `testing-guidelines` 5, `qa-migrate` 4, `qa-trace` 4, reference `test-tools` 4, `qa-refinement` 3, `testing-design` 2, `qa-cases` 1, `qa-explore` 1 |
| Cited sections that do not exist | the 36 distinct sections compared with the PDF's table of contents | **none** (matches plan README "Findings considered and rejected": every numbered citation matches v4.0.1) |

Uncited files include `qa-bdd`, `qa-tdd`, `qa-defect`, `qa-automate`, `qa-review`, `qa-agentic`
and all four agents. The **official syllabus PDF** is
`<local copy of ISTQB_CTFL_Syllabus_v4.0.1.pdf>`, SHA-256
`3b072f81db5c7671aadacc42553e726faa93913a969cc7a89e9dc28c2318d1f1`, 78 pages, table of contents on
PDF pages 4-7, **no PDF outline** (pypdf `reader.outline` is empty). Its contents list 102 numbered
entries: 0-0.11 (introduction), **85 in chapters 1-6** (6 chapter headings, 79 sections and
subsections), and 7-11 (references, appendices, index). Chapter headings carry a duration suffix
("1 Fundamentals of Testing – 180 minutes") that must be stripped.

### Build record

| Measure | Result |
| --- | --- |
| Plans `plans/0*.md` | 32; **none** has frontmatter |
| `## Status` block | 31 of 32 (`019-public-launch-readiness.md` has none, nor a "Planned at") |
| "Planned at" formats | three: ``commit `sha`, date``; bare date (`2026-10-02`); date plus prose ("against v2.9.0 on `main`") |
| Steps as `### Step N` | 65 headings in 15 plans; others use phases (2 plans), items or numbered lists |
| `§` in plans | 65 (34 distinct); **ambiguous**: `CLAUDE.md §5`, `spec §1`, `CONTRIBUTING.md §3` also use `§` (`plans/002:149`, `plans/003:26`, `CLAUDE.md:138`) |
| Status and PR numbers | only in the hand-kept table, `plans/README.md` |
| Corrections | `> **Correction, YYYY-MM-DD.**` blockquotes, e.g. 3 in `plans/014`, 1 in `plans/016` (CONTRIBUTING.md §5 convention) |
| `decisions/` | 1 file, `decisions/name.md`, status in its first blockquote |
| PRs | 132 on GitHub (`gh pr list --state all --json number --jq length`); 147 merge commits on `github/main` |

### The generator and the rules budget

- `generate-adapters.sh:21-29` `strip_frontmatter` removes a leading `---` block from **every**
  source file before merging (called at `:35`, `:48`, `:61`, `:76`, `:85`, `:99`).
  `generate-adapters.ps1:46-60` does the same with a regex. So **no source frontmatter reaches any
  adapter today**.
- The only frontmatter in adapters is the generator's own: Cursor `.mdc` (`generate-adapters.sh:162-167`,
  `description` + `alwaysApply`) and Antigravity `SKILL.md` (`:205-211`, `name: qa` + `description`).
  The universal adapters must carry none (`tests/verify-adapters.sh:82-88`). `verify-adapters.sh:69-80`
  checks the two constrained headers.
- `tests/test-rules-size.sh:14`: cap 25,000 bytes over raw file bytes, frontmatter included. Today
  21,439 bytes (9 rules), headroom 3,561. An `id`-only block costs 261 bytes for the 9 rules
  (`---\nid: <basename>\n---\n\n`).
- `tests/test-frontmatter.sh` checks `description` (≤1024 chars) for skills and commands and
  `name` = folder for skills. Nothing checks rules, references or agents.
- Rules with `paths:` frontmatter load conditionally in Claude Code (`test-rules-size.sh:3-4`
  comment), so a rule's frontmatter must never gain `paths:` here.
- Versions: `release-please-config.json` writes the version to `package.json` and, via
  `extra-files`, `.claude-plugin/plugin.json`. `.qa-skills-known-hashes` holds 128 lines across all
  tags.

## Commands you will need

| Purpose | Command | Expected |
| --- | --- | --- |
| Adapters before/after | `./generate-adapters.sh --clean && sha256sum adapters/*/* adapters/*/*/*` (save, re-run, `diff`) | identical |
| Adapter checks | `./tests/verify-adapters.sh` | exit 0 |
| Frontmatter | `./tests/test-frontmatter.sh` | exit 0 |
| Rules budget | `./tests/test-rules-size.sh` | exit 0, total printed |
| Citations (new) | `./tests/test-ctfl-citations.sh` | exit 0 |
| Corpus index (new) | `node generate-corpus.js --ref HEAD > /tmp/c.jsonl` | exit 0, one JSON object per line |
| Not shipped | `npm pack --dry-run 2>&1 \| grep -c corpus` | 0 |
| Full suites | `./tests/test-lifecycle.sh`, `./tests/conformance/run.sh`, markdownlint per `ci.yml` | exit 0 |

## Scope

**In scope**: frontmatter `id` in the 36 (post-034/036: however many) shipped `.md` files;
`§` citations added to shipped content; `tests/fixtures/ctfl-v4.0.1-sections.txt` (new);
`tests/test-ctfl-citations.sh` (new); `tests/test-frontmatter.sh` (extended); `generate-corpus.js`
(new, not shipped); `.gitignore` (`corpus/`); `ci.yml` (two steps); `CONTRIBUTING.md` (the citation
and id conventions); `plans/README.md`.

**Out of scope**: changing what any adapter contains; `version` fields in shipped files (rejected,
Step 2); frontmatter in plans (rejected, Step 5); a vector store, embeddings or any retrieval
service (the index is the input to one, not one); rewriting content beyond adding citations and
fixing the uncited CTFL lines listed in Step 3.

## Git workflow

Branch `feat/citable-sources`. One concept per commit (CONTRIBUTING.md §2):

| Commit | Type | Why that type |
| --- | --- | --- |
| Section list fixture | `test:` | never installed |
| Citation check + CI step | `test:` / `ci:` | never installed |
| Citations added to shipped files | `feat:` | changes what installed users read; one commit per file kind if large |
| `id` frontmatter in shipped files | `feat:` | reaches every installed copy; new citable identity |
| Frontmatter test extended | `test:` | |
| Corpus index generator | `build:` | a repository tool; not in `package.json` `files` |
| CONTRIBUTING conventions | `docs:` | |

Never `feat:` on the generator or the tests (the 2.6.0 lesson in CONTRIBUTING.md §2).

## Steps

### Step 1: the list of syllabus sections, extracted once from the official PDF

Extract the numbered entries of chapters 1-6 from the table of contents on PDF pages 4-7 of
`<local copy of ISTQB_CTFL_Syllabus_v4.0.1.pdf>` (no outline exists; read the page
text). Use **only this PDF**: never the Markdown conversion in git history, which is pre-errata and
misnumbered (plans/README.md, "Findings considered and rejected").

Commit `tests/fixtures/ctfl-v4.0.1-sections.txt`: one `<number><TAB><title>` per line, chapter
duration suffixes stripped, 85 lines, header comment lines naming the PDF file name, its SHA-256,
the pages read, the date and the extraction method. The PDF itself is never committed
(`CTFL/` is gitignored; copyrighted). The extraction script stays outside the repository: this list
is produced once and never regenerated (a new syllabus version is a new fixture file).

Verify: 85 data lines; chapters 1-6 present; `4.2.2<TAB>Boundary Value Analysis`,
`5.1.6<TAB>Test Pyramid`, `6.2<TAB>Benefits and Risks of Test Automation` present; every one of the 36
currently cited sections is in it (`comm -23` of the two sorted lists is empty).

### Step 2: the schema for shipped content (D2), settled field by field

| Field | Where it lives | How it is produced | Why |
| --- | --- | --- | --- |
| `id` | frontmatter, hand-written once | basename for rules, commands, agents; folder name for skills; `ref-<basename>` for references (resolves the `test-tools` collision) | the one thing a rename must not change; it cannot be derived from the path because the path is what changes |
| `title` | **not a field** | derived from the file's first H1 by the index (Step 6) | a frontmatter copy would drift from the heading |
| `istqb` | **not a field** | derived per chunk from the `§` citations in the chunk's own text (Step 6) | a file-level list would duplicate the body and go stale; per chunk is more precise |
| `version` | **not a field** | stamped on every index record from `package.json` and `git rev-parse` at the ref being indexed | see below |
| chunk anchor | not stored | `<id>#<heading-slug>`, valid within the version recorded beside it | headings change; a citation pins the version in which the anchor resolved |

**Version is omitted from shipped files, deliberately.** Writing it there would need one Release
Please `extra-files` entry (generic updater, `x-release-please-version` marker) per shipped file,
and every release would then rewrite every shipped file. Each release would add ~36 lines to
`.qa-skills-known-hashes` (128 today across all tags), and every user who had edited any file
would get a backup on every update for a change that is only a version number. The version a chunk
came from is a property of the build, so the index records it. Nothing hand-written can go stale.

**Format**: `id: <slug>` as a top-level key, `^[a-z0-9]+(-[a-z0-9]+)*$`, unique across the package.
Rules and references gain a block containing only `id`; existing blocks gain one line. Before
writing, check the current Agent Skills specification (agentskills.io) as plan 019 phase 3 did: if
it forbids unknown top-level keys in `SKILL.md`, put the id under `metadata:` (`metadata:\n  id: …`)
in the four `SKILL.md` files only, and have the test and the index read either form.

**Survival through `generate-adapters.sh`**: the ids do **not** reach the merged adapters, and must
not. Both generators strip all source frontmatter (`generate-adapters.sh:21-29`,
`generate-adapters.ps1:57-60`); Cursor's and Antigravity's headers are the generator's own
(`:162-167`, `:205-211`). The property to prove is that the adapters are **byte-identical** before
and after this step. The corpus is indexed from the `.claude/` tree, which is also what the
Claude Code, plugin and Agent Skills installs copy verbatim, so ids are present wherever the files
are installed as files. Per-file anchors inside adapters are Open question 2.

**Rules budget**: an `id`-only block costs ~29 bytes per rule (261 bytes for 9 today). Measure after
034-036: **STOP** if the total would exceed 25,000.

### Step 3: the citation rule and its check (D1)

The rule, written in `CONTRIBUTING.md` (it governs how this package's content is authored, not
target repositories, so it is not a shipped rule and costs no rules budget, per CLAUDE.md §6):

- In shipped content, `§` followed by a number means a CTFL v4.0.1 section **and nothing else**.
  Other documents' sections are named in words.
- A sentence that states what the syllabus says cites the section beside it: `(CTFL §4.2.2)`, or
  `§`-only inside a paragraph or banner that already names CTFL. A chapter-only citation is allowed
  where the whole chapter is meant (`qa-static`: Chapter 3).
- Package practice that is not syllabus content says so, as `qa-migrate/SKILL.md:28` already does
  ("Not ISTQB content: …").

`tests/test-ctfl-citations.sh` (bash 3.2-safe, `shellcheck` clean), over every `.md` under
`.claude/`:

1. Every `§N(.N)*` is a line in `tests/fixtures/ctfl-v4.0.1-sections.txt`. Failure names file,
   line and section.
2. Every line containing `CTFL` outside frontmatter has a `§` or `Chapter N` on it, unless it
   matches an entry in `tests/fixtures/ctfl-uncited-allow.txt` (`<path>:<fixed text>` plus a reason
   comment). Seed the allowlist with the role banners (`> **Senior QA …** | ISTQB CTFL v4.0 | …`)
   and template placeholders (`qa-cases.md:72`, `| **Methodology** | ISTQB CTFL v4.0 — [Techniques
   used] |`). Exemptions live in the test fixture, not as markers in shipped files (bytes, noise).
3. Prints the coverage figure: distinct sections cited / 85, and files citing ≥1 section / total.

Claims that never say "CTFL" cannot be found mechanically. Step 4 covers them by reading.

Measured today, the lines that would fail check 2 and need a citation or a rewording:
`testing-design.md:60,64` ("CTFL Test Levels": §2.2.1), `qa-cases.md:11` (techniques: §4.2-4.4),
`qa-designer.md:18`, `qa.md:9`, `qa-reference/SKILL.md:23` (tool categories: §6.1). Re-run after
034-036; their content may have moved.

Add the check to the Linux job of `ci.yml` beside "Skill and Command Frontmatter". Prove it bites:
change one citation to `§4.6` and one banner-free line to cite nothing, run, see both failures
named, revert.

### Step 4: add the missing citations

Read each of the 26 uncited files (or whatever 034-036 leave) and cite the syllabus section beside
each claim that comes from it, using the fixture list as the only source of numbers. Start from the
areas plan 031 found uncited: the seven principles (§1.3), the technique tables (§4.2.1-4.2.4,
§4.4.1-4.4.3), `/qa-bdd` (§4.5.1-4.5.3), `/qa-tdd` (§2.1.3), `/qa-refinement` (§2.1.5, §4.5),
`qa-explore` (§4.4.2), `/qa-defect` (§5.5, §1.2.3), the agents (pipeline stages map to §1.4.1 test
analysis/design/implementation). Do not add a citation where the content is package practice; say
so instead. Keep rule files within the budget: a citation in a rule is ~8 bytes.

Commit per file kind (`feat:`). `./tests/test-ctfl-citations.sh` passes after each.

### Step 5: the schema for the build record (D2, D3)

**No frontmatter in plans.** CONTRIBUTING.md §5's append-only convention protects what was
believed and when (content); a metadata block would not violate it, and adding one would be
allowed. It is rejected anyway, because everything it would hold already exists in the plan or in
git: the Status block (priority, effort, depends on, planned-at), the `plans/README.md` row (status,
PR numbers) and the commit that added the file (date, SHA). Copying those by hand into 32 files
creates a second source that drifts from the first. Generation reads the originals.

Record kinds and where each field comes from:

| Kind | Chunk | Fields (source) |
| --- | --- | --- |
| plan | each `##`/`###` section of `plans/NNN-*.md` | `plan` (file name), `title` (H1), `heading`, `step` (from `### Step N` or `### Phase N`, else null), `status` and `prs` (the README row), `priority`/`effort`/`depends_on` (Status block), `planned_at` {commit, date} (Status block; null if absent, e.g. plan 019), `added` {commit, date} (`git log --diff-filter=A --format='%h %as' -- <file>`), `prs_in_text` (`#NNN` in the chunk), `corrections` (dates of `Correction, YYYY-MM-DD` in the chunk) |
| plan status | each row of the README table | plan, title, priority, effort, depends on, status text, PR numbers |
| decision | each heading of `decisions/*.md` | `status` and `decided` date (first blockquote), heading |
| release | each version section of `CHANGELOG.md` | version, date, linked PRs and commits |
| merge | each merge commit on the indexed ref | PR number, title (merge body), merge SHA, date |
| pr | each PR description, if a snapshot exists (Open question 1) | number, title, body, merged-at, merge SHA |

Every record carries `corpus: "record"`, `repo` (from `git remote get-url origin`, normalised),
`ref` and `commit`. `§` in the build record is **not** checked against the syllabus (it is
ambiguous there, see "Current state"); the index records `istqb` only for `§` on a line that also
says `CTFL` or `syllabus`.

For future plans only, add `tests/test-plan-format.sh`: a plan numbered 038 or above must have a
`## Status` block with ``**Planned at**: commit `<sha>`, YYYY-MM-DD``. It never inspects older plans,
so nothing retroactive is required.

### Step 6: `generate-corpus.js`, the index generator

Node ≥18, no dependencies, CommonJS like `bin/cli.js`, at the repository root beside the other
generators. Not listed in `package.json` `files`, so never published (verify with
`npm pack --dry-run`).

```text
node generate-corpus.js [--ref <git ref>] [--only package|record] [--out <file>]
```

- Reads every file through `git show <ref>:<path>` and `git ls-tree`, never the working tree, so
  the index of any tag is reproducible from git alone. Default ref `HEAD`.
- Emits JSON Lines sorted by `corpus`, path, then position: byte-identical output for the same ref.
- Package records (`corpus: "package"`): `id`, `kind` (from the path), `path`, `title`,
  `heading`, `heading_path`, `anchor`, `istqb` (sections cited in the chunk, each with its title
  from the fixture), `version` (`package.json` at the ref), `commit`, `text`.
- Fails (exit 1, message naming the file) on a shipped file without an `id` or on a duplicate id;
  reports, without failing, a build-record field it could not parse (e.g. plan 019's missing Status).
- Output goes to stdout or `corpus/` (gitignored). The index is **not committed**: any version's
  index is regenerated from its tag. Attaching it to GitHub releases is Open question 3.

CI: one Linux step runs it on `HEAD` and validates every line with `node -e` JSON parsing plus a
count check (package records ≥ number of shipped files). A test fixture repository is not needed.

### Step 7: extend `tests/test-frontmatter.sh`

Every shipped `.md` (rules, commands, agents, skills, references) opens with a closed frontmatter
block carrying an `id` (top-level, or under `metadata:` for `SKILL.md` per Step 2) that matches the
slug pattern and is unique. Existing checks unchanged. Rename the header comment's scope
accordingly.

### Step 8: prove nothing a user sees changed except the files' first lines

- Adapters: hashes before Step 2 equal hashes after Step 7 (`diff` of the two `sha256sum` lists),
  on `generate-adapters.sh`; also `generate-adapters.ps1` if `pwsh` is available, else say so.
- In a temporary project, `./install.sh --target project --editor claude --non-interactive`, then
  open Claude Code there and confirm the rules still load unconditionally (a rule whose frontmatter
  holds only `id` must not become path-scoped) and `/qa-cases` still lists with its description.
- `./tests/plugin/verify-plugin.sh`, lifecycle and conformance suites, markdownlint: green.
- Record the final measurements (sections cited / 85, files citing / total, uncited `CTFL` lines,
  rules bytes) in this plan's Outcome section.

## Done criteria

- [ ] `tests/fixtures/ctfl-v4.0.1-sections.txt`: 85 entries from the official PDF, header names its SHA-256.
- [ ] `./tests/test-ctfl-citations.sh` exits 0 and fails when a bad section is planted; runs in CI.
- [ ] Every shipped `.md` has a unique `id`; `./tests/test-frontmatter.sh` enforces it.
- [ ] No shipped file has a `version`, `title` or `istqb` frontmatter field.
- [ ] Adapters byte-identical to their pre-plan hashes; `./tests/verify-adapters.sh` passes.
- [ ] `./tests/test-rules-size.sh` passes; total recorded.
- [ ] `node generate-corpus.js --ref HEAD` emits valid JSON Lines for both corpora, deterministic across two runs; `npm pack --dry-run` lists no corpus files.
- [ ] CONTRIBUTING.md states the citation rule and the id rule (ids are permanent; a removed file's id is never reused).
- [ ] CI green on Linux, Windows and macOS; `plans/README.md` row for 038 updated.

## STOP conditions

- Any adapter's hash changes: the frontmatter strip did not hold; do not ship.
- The rules would exceed 25,000 bytes with ids and citations: report the numbers; do not move
  content to make room inside this plan.
- Claude Code treats a rule with `id`-only frontmatter as conditional, or a command or skill stops
  listing: report; do not add `paths:` or other fields to work around it.
- A section number needed for a citation is not in the fixture list: the claim may not be from the
  syllabus; leave it uncited and list it.
- The PDF's SHA-256 differs from `3b072f81…d1f1`: it is a different file; ask.
- Plans 034-036 are not merged: ids would be assigned to names about to change.

## Maintenance notes

- An `id` is permanent. Renaming or moving a file keeps its id; a deleted file's id is never
  reused. Merged files keep the id of the one that remains and the other id is recorded in the PR.
- A new CTFL version is a new fixture file and a deliberate citation migration, never an edit of
  the v4.0.1 list.
- Anchors (`id#heading`) are valid per version; citations in the monograph should give the version
  (or commit) beside the anchor.
- `ctfl-uncited-allow.txt` should only shrink. A new entry needs a reason a reviewer accepts.

## Open questions (defaults in brackets)

1. **PR descriptions.** The 132 PR bodies live only on GitHub in the private repository, which plan
   020 part B archives and which "receives no further commits" afterwards. Snapshot them
   (`gh pr list --state all --json number,title,body,mergedAt,mergeCommit`) into a committed file
   **in the private repository before it is archived**, so the record index can read them by ref?
   PR bodies may name the employer, so they are not exported to the public repository. [Yes: take
   the snapshot as a step of 020 part B, before its step 7, even if 038 runs later.]
2. **Anchors inside adapters.** Emit `<!-- bem-te-vi:id=<id> -->` before each merged file so a
   Cursor or Copilot user's retrieval can cite too? Costs ~45 bytes × 36 in each adapter and changes
   all seven outputs. [No: index from `.claude/`; revisit if someone asks.]
3. **Publishing the index.** Attach `corpus-<version>.jsonl` to each GitHub release from the
   release workflow? [No for now: regenerable from any tag; decide when a consumer exists.]
4. **Land Steps 1 and 3 early?** The section list and its check are not metadata and would guard
   the new content of 035/036 as it is written. [Optional: a separate `test:` PR before 035, if
   Marco wants it; the rest of the plan keeps its order.]

## Execution record (2026-10-18)

Executed on branch `feat/citable-sources`, from `next` after plans 033-037 and 039-042 (the four
skill PRs #147, #152, #143, #156 and #171 were merged into the branch first; #172 was not yet on
`next` and was merged from its branch). Default used (Marco asked for all remaining work on
2026-10-18) for every open question: the defaults in brackets, already decided by Marco on
2026-10-14.

### Drift check: the "Current state" figures re-measured

Measured at `8f0ff7d` (this branch before its own commits) beside the figures above:

| Measure | 2026-10-14 at `a2f08e7` | 2026-10-18 at `8f0ff7d` |
| --- | --- | --- |
| Shipped `.md` files | 36 | 47 (11 commands, 8 skills, 4 agents, 9 rules, 15 references) |
| Frontmatter | commands, skills, agents; none in rules or references | the same |
| `§N.N` occurrences | 99 (36 distinct) | 209 (72 distinct: 60 CTFL sections and 12 sections of *Engenharia de Software Moderna*) |
| Chapter-only citations | 4 | 4 |
| Lines naming CTFL | 70 | 115 |
| ...with no `§` and no chapter | 23 | 25 |
| Files citing a CTFL section | 10 of 36 | 18 of 47 |
| Rules bytes | 21,439 | 21,415 |
| Plans `plans/0*.md` | 32 | 42; still only plan 019 lacks a Status block |
| `### Step N` headings | 65 in 15 plans | 101 in 19 plans |
| PRs on GitHub / merge commits on `github/main` | 132 / 147 | 172 / 157 |
| `.qa-skills-known-hashes` lines | 128 | 152 |

The PDF's SHA-256 is `3b072f81db5c7671aadacc42553e726faa93913a969cc7a89e9dc28c2318d1f1`, as
expected; 78 pages, no outline.

### Finding: the book's citations used `§` too

Plan 036 cited *Engenharia de Software Moderna* as `(Valente, ..., §8.3)`, which is the form its own
"Copyright and wording" section prescribed. This plan's citation rule (Step 3) says `§` means a CTFL
v4.0.1 section and nothing else, and its check fails every `§8.x`, `§9.x`, `§10.x`, `§3.5` and
`§3.6`. Plan 038 depends on 036 and its rule is the later of the two in execution order, so the
rule was applied: the 23 book citations in 6 files now read "section 8.3", "sections 10.4 and
3.6" (commit `fix:`, numbers and claims unchanged). Book numbers and syllabus numbers overlap in
form, and `§3.6` next to CTFL text was a real ambiguity for a reader or an index. Plan 036's text
is not changed (append-only); this note is its correction.

- Rejected: teaching the check to skip a `§` on a line that names Valente. Several book citations
  sit on a continuation line or in a short form ("(§8.6)", "in general, §9.5"), so the exemption
  would have needed context the line check does not have, and the ambiguity for a reader would stay.

### What was done, step by step

- **Step 1**: `tests/fixtures/ctfl-v4.0.1-sections.txt`, 85 lines (6 chapters, 79 sections and
  subsections) read from the table of contents on PDF pages 4-7 with pypdf 6.21.1, by the method of
  plan 035's citation check (with `cryptography` blocked from import, because the system package
  is broken on this machine and pypdf does not need it to read an unencrypted file). `4.2.2 Boundary
  Value Analysis`, `5.1.6 Test Pyramid` and `6.2 Benefits and Risks of Test Automation` are present;
  every CTFL section cited before this plan is in the list.
- **Step 2**: ids as specified. The Agent Skills specification lists six frontmatter fields and its
  reference validator (`skills-ref`, `ALLOWED_FIELDS`) rejects any other ("Unexpected fields in
  frontmatter"), so the eight `SKILL.md` files hold `metadata:\n  id: <folder>`. Every other file
  has a top-level `id`. Rules and references got `---\nid: <id>\n---` with no blank line after it,
  because the generators print what follows the closing `---` and a blank line there would have
  changed the adapters.
- **Step 3**: `tests/test-ctfl-citations.sh` and `tests/fixtures/ctfl-uncited-allow.txt` (18
  entries: 10 role banners, the router's role statement, one template placeholder, one "not ISTQB
  content" line, `/qa-static`'s statement of its own convention, and 4 lines whose citation is on
  the next line or the heading above). Beyond the plan: a self-test (as `test-reference-links.sh`
  has) that plants a bad section, an uncited line and a stale allowlist entry and fails if any
  passes; and a stale allowlist entry is itself an error, so the list can only shrink. Proven to
  bite on the real tree too: with `§4.2.2` changed to `§4.6` in `qa-cases.md` and an uncited
  sentence naming CTFL added to `qa-tdd.md`, the check failed with
  `qa-cases.md:165: §4.6 is not a CTFL v4.0.1 section` and
  `qa-tdd.md:11: names CTFL but cites no section`; both reverted.
- **Step 4**: citations added by reading every uncited file, sections taken only from the fixture,
  each heading reread in the PDF text. Where content is the package's own, the text now says so
  rather than borrowing a citation (the pyramid presets, the 5x5 risk scales, the severity and
  priority scales, the defect workflow, the Definition of Ready items, the sad-path list,
  testing-guidelines' tagging and failure protocols). Commits per file kind.
- **Step 5**: no frontmatter in plans (as decided). `tests/test-plan-format.sh` checks plans 038 on.
  Plans 039-042 write ``commit `a2f08e7` (`github/main`), 2026-10-14``, so the check requires the
  commit in backticks and a date later on the same line rather than the exact ``commit `sha`,
  date`` form; plans are append-only and those four were not rewritten for it.
- **Step 6**: `generate-corpus.js`. Choices the plan left open, each recorded here:
  - Package chunks are cut at every heading level outside code fences; plan chunks at `##` and
    `###` (deeper headings stay in their section), decisions at levels 1-3, changelog releases at
    level 2. Each record also carries `line` (the chunk's first line in the file), used for the
    sort and for citing a position; package records also carry `repo` and `ref`, like record ones.
  - Anchors follow GitHub's heading slugs, so an emoji heading gives `#-agent-identity--persona`.
  - `repo` is `origin`'s URL, or the first remote's when there is no `origin` (this clone's remote
    is `github`), with credentials and `.git` removed.
  - The PR snapshot path is `plans/pull-requests.json` (the `gh pr list --state all --json
    number,title,body,mergedAt,mergeCommit` output). It does not exist yet; open question 1's
    default puts taking it in plan 020 part B, recorded there today.
  - A tag older than this plan has no ids, so `--only package` fails on it (by design: a shipped
    file without an id cannot be cited); `--only record` works on any ref (v4.0.1: 717 chunks).
- **Step 7**: `tests/test-frontmatter.sh` also requires a closed block with a unique slug `id` in all
  47 files (under `metadata:` in a `SKILL.md`, top level elsewhere), and refuses `version`, `title`
  and `istqb` keys and a rule's `paths:`. Proven to bite on a copy with a missing id, a duplicate, a
  malformed id, an id at the wrong level, a `version:` and a `paths:` (all seven failures named).
- **Step 8**: see Outcome.

### Claims not tied to a section, and what was done with each

No claim needed a section that is missing from the fixture list, so no STOP condition fired.
These claims are not syllabus content and were left uncited, said so where a reader could mistake
them for syllabus:

- "Three Amigos" (`/qa-bdd`, `/qa-refinement`): not in the syllabus; `/qa-bdd` now says it is
  industry practice and maps the meeting to the specification workshop of §4.5.3.
- SMART acceptance criteria (`/qa-bdd`, `/qa-refinement`): not in the syllabus; left as package
  practice (the acceptance-criteria formats beside them cite §4.5.2).
- INVEST applied to features: §4.5.1 names INVEST for user stories; the citation says so.
- Test pyramid percentages, coverage floors, the 5x5 risk scale and its levels, severity and
  priority scales and who sets them, the defect workflow, the automation ROI score, the tagging
  taxonomy, failure protocols and Definition of Done items, the release gate's size: the package's
  own; the pyramid, the risk score, the defect fields and testing-guidelines now say which part is
  syllabus and which is not.
- SFDPOT, FEW HICCUPPS and the exploratory tours: attributed to their authors already; not cited.
- AAA, Page Object Model, FIRST, test smells, test doubles: package practice or the book; not cited.
- WCAG 2.2 and OWASP content (`accessibility-qa`, `security-qa` and their references): external
  standards named by their own numbers, which are not `§` citations.

Files still citing no section (21 of 47), each because it holds no syllabus claim: `qa-automate`,
`qa-review`, `qa` (router), the rules `accessibility-qa`, `code-style-qa`, `conventional-commits`,
`linting-standards`, `security-qa`, `test-evidence`, and the references `accessibility-checks`,
`automation-ci`, `automation-code`, `context-sources`, `defect-system-info`, `evidence-capture`,
`playwright-patterns`, `repo-conventions`, `security-checks`, `tracker-azure-devops`,
`vitest-patterns`, `written-records`.

## Outcome (2026-10-18)

| Measure | Before (`8f0ff7d`) | After |
| --- | --- | --- |
| CTFL sections cited | 60 of 85 | 64 of 85 |
| Files citing a CTFL section | 18 of 47 | 26 of 47 |
| `§` occurrences | 209 (186 CTFL, 23 the book's) | 227, all CTFL |
| Lines naming CTFL with no `§` or chapter, outside the allowlist | 25 | 0 (18 allowlisted with reasons) |
| Rules bytes | 21,415 | 21,855 (citations +188, ids +252; cap 25,000) |
| Shipped files with an id | 0 | 47, unique |
| Corpus at the branch head | none | 398 package and 1,095 record chunks, byte-identical over two runs |

- **Adapters**: the citations change the adapters on purpose (they are content). The ids do not:
  the seven adapters generated from the tree just before the id commit and just after it have the
  same SHA-256 (`generate-adapters.sh`); `generate-adapters.ps1` is compared byte for byte with the
  bash output by the Windows part of the local CI run (see the PR).
- **Not shipped**: `npm pack --dry-run` lists no corpus file, no `generate-corpus.js` and no
  `ctfl-` fixture.
- **Claude Code load check (Step 8), not run.** Installed into a temporary project
  (`./install.sh --target project --editor claude --non-interactive`), the rules arrive with their
  `id` block; asking Claude Code which rules it loaded failed with "You've hit your weekly limit"
  on this account (Claude Code 2.1.224). What stands instead: the Claude Code memory documentation
  (code.claude.com/docs/en/memory, "Rule frontmatter reference") says "`paths` is the only field
  Claude Code reads from a rule; any other field is ignored without an error. Claude Code removes
  the frontmatter before loading the rule into context", and "Rules without a `paths` field are
  loaded unconditionally". `claude plugin validate` (in `tests/plugin/verify-plugin.sh`) passes with
  the new frontmatter on commands, agents and skills. Run the check by hand once the limit resets.
  - **Run on 2026-10-18 (coordinator), passed.** The public export of `next` (plan 020 part B)
    installed with `install.sh --target project --editor claude --non-interactive --no-hooks` into
    a temporary project; Claude Code 2.1.291 (`claude -p --model haiku`, every tool disallowed)
    listed all nine rules under `.claude/rules` as in its context and quoted the security rule's
    cookie attributes exactly (`HttpOnly`, `Secure`, `SameSite=Strict`). The `id` block did not
    stop any rule from loading.

### Done criteria

- [x] Fixture with 85 entries from the official PDF, its SHA-256 in the header.
- [x] `./tests/test-ctfl-citations.sh` exits 0, fails on a planted bad section, runs in CI (Linux).
- [x] Every shipped `.md` has a unique `id`; `./tests/test-frontmatter.sh` enforces it.
- [x] No shipped file has a `version`, `title` or `istqb` frontmatter field (also enforced).
- [x] Adapters byte-identical with and without the ids; `./tests/verify-adapters.sh` passes.
- [x] `./tests/test-rules-size.sh` passes: 21,855 bytes.
- [x] `node generate-corpus.js --ref HEAD` emits valid JSON Lines for both corpora, the same bytes
  on two runs; `npm pack --dry-run` lists no corpus files.
- [x] CONTRIBUTING.md section 6 states the citation rule and the id rule.
- [ ] CI green on Linux, Windows and macOS: GitHub CI does not run on pull requests into `next`;
  the local three-platform run is quoted in the PR. `plans/README.md` row updated.
