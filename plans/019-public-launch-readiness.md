# Plan 019: Get qa-skills ready for its public launch

> **To the Claude session in the qa-skills repo.** Marco pasted this plan in. It was written on
> 2026-10-08 in his portfolio repo, after comparing qa-skills (v2.8.0, `main` @ `63bdd5d`) with the other
> public QA skill packs. Read it fully before acting. Work **one phase at a time, one PR per phase**,
> and stop at every **STOP** and **DECISION (Marco)** marker.
>
> **Copied into this repo on 2026-10-08 (Phase 1), with these edits.** The Phase 6 search pattern
> listed client and product names. Committing them would put the names Phase 6 looks for into a
> repository about to go public, against plan 015's rule, so they are replaced by a pointer to the
> portfolio copy. Absolute local paths are replaced by repo-relative references, and table separators
> are spaced for this repo's markdownlint. Nothing else changed.

## 0. Before you touch anything

### Files to read first (same machine, outside this repo; read-only)

| File | Why |
| --- | --- |
| `docs/research/qa-skills-competitors.md` (portfolio repo) | Who the competitors are, how qa-skills differs, the name clash |
| `docs/handoff/qa-skills-018-add-license-file.md` (portfolio repo; now `plans/018-add-license-file.md`) | Full plan for Phase 2 (the LICENSE) |
| `docs/handoff/qa-skills-launch-readiness.md` (portfolio repo) | The gap analysis this plan expands (short version) |

Don't edit anything in the portfolio repo.

### Ground rules

- **The working tree may be dirty.** At planning time the repo was on `docs/coverage-and-plan-statuses`
  with uncommitted edits to `CLAUDE.md`, `README.md`, `plans/017-…md` and `plans/README.md`. Run
  `git status` first. **STOP if anything is uncommitted** and ask Marco whether to commit, stash or keep
  it. Switching branches would carry those edits into this plan's PRs.
- Every phase starts from fresh `main` on its own branch. Follow `CONTRIBUTING.md`: Conventional Commits,
  atomic commits (no "and"), never edit `CHANGELOG.md` or the version (Release Please owns them). `feat:`/`fix:`
  only for changes that reach installed users.
- **Before each PR, run the CI checks locally**, as `.github/workflows/ci.yml` runs them:

  ```bash
  shellcheck install.sh generate-adapters.sh generate-known-hashes.sh tests/*.sh tests/conformance/run.sh .claude/hooks/*.sh
  npm audit --omit=dev --audit-level=high
  ./generate-known-hashes.sh --check
  npx --yes markdownlint-cli@0.49.1 --dot "**/*.md" --ignore node_modules --ignore .git --ignore adapters
  ./generate-adapters.sh --clean && ./tests/verify-adapters.sh
  ./tests/conformance/run.sh
  ./tests/test-check-test-evidence.sh
  ./tests/test-lifecycle.sh
  ```

  (Read `ci.yml` for the exact ShellCheck file list; the line above may lag.) Paste the output into the PR.
  Windows and macOS run in CI; you can't run `install.ps1` here, so say so in the PR.
- **Never do these yourself:** push to `main`, make the repo public, `npm publish`, rewrite git history,
  or submit to directories. Prepare them and hand them to Marco.
- If what you find in the repo contradicts this plan, the repo wins. Report the difference, don't force the plan.

### Phase map

| Phase | What | Priority | Size | PR type |
| --- | --- | --- | --- | --- |
| 1 | Register this plan and plan 018 in `plans/` | — | S | `docs:` |
| 2 | Ship the MIT LICENSE (plan 018) | P0 | S | `fix:` |
| 3 | Frontmatter for skills and commands | P0 | M | `fix:` + `test:` |
| 4 | English as the default response language | P0 | S | `fix:` |
| 5 | Name decision brief | P0 | S | DECISION (Marco), no code |
| 6 | Pre-public secrets and privacy scan | P0 | S | report only |
| 7 | README: remove placeholders, add "What runs on your machine" | P0 | M | `docs:` |
| 8 | Launch checklist (Marco performs it) | P0 | S | checklist only |
| 9 | Context diet for always-loaded rules | P1 | L | own plan first |
| 10 | Claude Code plugin marketplace and Agent Skills install | P1 | M | own plan first |
| 11 | `examples/` with real output on a public app | P1 | M | `docs:` |
| 12 | Directory submissions (drafts for Marco) | P1 | S | none |
| 13 | New skills that match Marco's services | P2 | L | one plan per skill |

Order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → **8 (go public)** → 9–12 → 13.

---

## Phase 1: Register the plans

1. Copy the portfolio repo's `docs/handoff/qa-skills-018-add-license-file.md` to
   `plans/018-add-license-file.md`, and this file to `plans/019-public-launch-readiness.md` (use the next
   free numbers if 018/019 are taken, and fix the cross-references).
2. Add rows to the execution table in `plans/README.md`, matching its columns and status style.
3. Markdownlint both files. Commit: `docs(plans): plan 018 license and plan 019 launch readiness`.
   If commitlint objects to the "and", make it two commits.

---

## Phase 2: Ship the MIT LICENSE

Execute `plans/018-add-license-file.md` exactly. Summary: add a root `LICENSE` with the standard MIT
text, `Copyright (c) 2026 Marco Amaral`. No other file changes. Verify `npm pack --dry-run` lists it
(39 → 40 files) and the conformance suite still passes. Commit:
`fix: ship the MIT LICENSE file the package already declares`.

---

## Phase 3: Frontmatter for skills and commands (the most important fix)

### Problem

Both `.claude/skills/*/SKILL.md` files start straight with a `# Skill: …` heading, and all ten
`.claude/commands/*.md` start with `# QA — …`. Only the four agents have YAML frontmatter.

Claude Code, and every runtime that follows the Agent Skills standard, decides **when to auto-load a skill**
from its frontmatter `description`. Without it, the runtime falls back to the heading. In a project with
qa-skills installed, Claude's skill list shows `qa-explore: Skill: Session-Based Exploratory Testing & SBTM`,
a title, not a "use when…" trigger. So the auto-loaded skills fire less often than they should. Every
competitor ships standard frontmatter, and directories and `npx skills add` depend on it.

### Steps

1. **Check the current spec before writing anything.** Use the Claude Code docs (or the `claude-code-guide`
   agent) to confirm the current fields and limits:
   - Skills: `name` (lowercase, hyphens, must match the folder name) and `description` (what it does
     **and when to use it**). Check the length limit.
   - Commands: `description`, and `argument-hint` where the command takes input. Don't add `allowed-tools`
     or `model`: that would change behavior, which is out of scope.
2. **Find everything that reads the first line of these files** before changing them:
   `grep -rn -E "head -(n )?1|firstLine|\[0\]|\^#" bin install.sh install.ps1 generate-adapters.* tests .claude/hooks`,
   then read the hits. Expect noise, so judge each one.
   `generate-adapters.sh` already strips leading frontmatter (`strip_frontmatter`). Check the `.ps1`
   generator does the same, and that the hooks (`validate-tc-format.sh`) don't care.
   **STOP** if any installer, hook or test depends on line 1 being a heading. Report it instead of patching around it.
3. **Write a description per file, derived from its body, not invented.** Pattern:
   `"<What it produces/does>. Use when <the user's situations, in their words>."` Starting drafts, which
   you must check against each file:

   | File | Draft description |
   | --- | --- |
   | `skills/qa-explore` | Plans and runs session-based exploratory testing (SBTM): charters, heuristics, time-boxed sessions, debrief notes. Use when asked to explore a feature, run a bug bash, write test charters or test without scripted cases. |
   | `skills/qa-plan` | Builds test strategies, test plans and risk registers (5×5 likelihood × impact) with entry/exit criteria and quality gates, per ISTQB CTFL v4.0 ch. 5. Use when asked for a test plan, QA strategy, risk assessment or release criteria. |
   | `commands/qa` | Senior QA analyst and engineer: answers QA questions and routes to the right /qa-* command. |
   | `commands/qa-cases` | Writes formal test cases (TC-CODE-NNN) using ISTQB techniques, tagged by suite, level and priority. |
   | `commands/qa-defect` | Writes a defect report with severity, priority, steps to reproduce, and expected vs actual. |
   | `commands/qa-bdd` | Writes BDD scenarios in Gherkin and ATDD acceptance tests. |
   | `commands/qa-automate` | Scaffolds Playwright E2E (Page Object Model) and Vitest tests from test cases. |
   | `commands/qa-tdd` | Guides a TDD red-green-refactor cycle and lists edge cases before code is written. |
   | `commands/qa-refinement` | Reviews stories in agile refinement for testability, missing acceptance criteria and risks. |
   | `commands/qa-review` | Reviews a branch's code for testability, correctness, security and error handling. |
   | `commands/qa-static` | Static testing: reviews a ticket, spec, ADR or API schema for defects before anything runs. |
   | `commands/qa-agentic` | Runs the three-stage pipeline (groomer → designer → writer) from a ticket to traceable test cases. |

   Add `argument-hint` to the commands that take input (e.g. `qa-cases`: `"<feature or ticket>"`).
4. **Add a CI guard** so this can't regress: a small test (bash + the PowerShell twin if the repo pairs them,
   or extend `tests/verify-adapters.*`) that fails when any shipped `SKILL.md` or command lacks frontmatter
   with a non-empty `description`, or when a skill's `name` doesn't match its folder. Wire it into `ci.yml`
   next to the related checks. Prove it fails on a file without frontmatter before it passes on the fixed files.
5. Regenerate adapters (`./generate-adapters.sh --clean`, plus the `.ps1` twin if adapters are committed),
   then run the full check list.
6. **Check it in a real session:** install into a temp project (`node bin/cli.js init --editor claude` in an
   empty dir) and confirm the skill list now shows the new descriptions.

### Known hashes and conformance

These are installed files, so their hashes change. That's expected: `.qa-skills-known-hashes` records
**released** files (`./generate-known-hashes.sh --check` must still pass without regenerating). Existing
installs will see the files as package files from an older release and update them normally. Confirm with
the conformance suite (case 003, "older release adopted").

### Commits (one PR)

- `test: fail CI when a shipped skill or command lacks a description`
- `fix: add frontmatter so skills and commands trigger and list correctly`

---

## Phase 4: English as the default response language

### Problem

All ten commands say *"Respond in the language of the user's prompt (default: PT-BR)"*, and
`qa-automate.md`'s title is Portuguese (*"QA — Automação: Playwright & Vitest"*). For an international
launch, an ambiguous prompt (a bare `/qa-cases`) gets a Portuguese answer. Every competitor defaults to English.

### Steps

1. `grep -rn "PT-BR\|Português\|Automação" .claude adapters` for the full list (ignore `.claude/worktrees/`
   and `tests/conformance/cases/` fixtures: **never edit fixtures**, they are copies of old releases).
2. Change to *"Respond in the language of the user's prompt (default: English)"*. Translate the
   `qa-automate` title to *"QA — Automation: Playwright & Vitest"*. Leave all Portuguese *support* in place:
   it's a selling point for Brazilian users.
3. Mention PT-BR support in the README features (one line).
4. Regenerate adapters, run the checks.

Commit: `fix: default to English when the prompt's language is unclear`.

---

## Phase 5: Name decision brief, then **DECISION (Marco)**

### Problem

"qa-skills" is also the unscoped npm package `qa-skills` (AZANIR, GPL-3.0, created 2026-03-08), and two
GitHub repos use the name: `petrkindlmann/qa-skills` (166★) and `neonwatty/qa-skills` (33★). The
`@marcoamaral/` scope prevents a technical clash, but searches and word of mouth will mix them up.
Renaming after launch loses stars, links and installs. Renaming before launch is cheap.

### Steps (no code)

1. Count every place the name lives: `grep -rn "qa-skills" --exclude-dir=node_modules --exclude-dir=.git . | wc -l`,
   and list the **user-facing contract** separately: npm package name, `bin` command `qa-skills`, the
   `.qa-skills-manifest` / `.qa-skills-known-hashes` / `.qa-skills-editor-map` file names (changing those is a
   **breaking change** for existing installs), the GitHub repo URL, README badges.
2. Write `docs/decisions/name.md` (or wherever the repo keeps decisions): the clash evidence, three options
   (keep / rename the package and command but keep the internal file names / full rename), the cost of
   each, and what a rename would need (npm deprecate message, GitHub redirect, migration of the manifest names).
3. **STOP.** Don't rename anything. Marco decides. If he renames, that becomes its own plan.

---

## Phase 6: Secrets and privacy scan before going public, **report only**

The repo has been private since 2026-03-24 (366+ commits). Making it public exposes the **whole history**,
not just today's files.

1. **Secrets:** scan all history with gitleaks (`docker run --rm -v "$PWD:/repo" zricethezav/gitleaks:latest
   detect --source /repo -v`, or the release binary). Also check whether `gh-token.txt` (since gitignored) was
   ever committed: `git log --all --oneline -- gh-token.txt`. At planning time: never committed.
2. **Personal and client data**, in tracked files **and history**:
   `git log --all -p | grep -n -i -E "<client and product names>|visualstudio\.com|swareco"`, with the
   client and product names taken from the portfolio repo's copy of this plan. They are not repeated here.
   Employer names (Swareco, POWR and Marco's earlier employers) are fine in Marco's own author text; **product and client names
   are not**. Also check `@` emails other than Marco's.
3. **Review what's tracked but personal:** `prompt-history/` is tracked (excluded from npm by `.npmignore`, but
   it **will** be visible on GitHub). Check `prompt-history/*`, `plans/*` and `docs/*` for client names,
   internal URLs, Jira/ADO IDs and anything Marco wouldn't want public. `interview.txt` and `.tmp_repos/` were
   untracked at planning time. Confirm.
4. Write the findings as a short report (finding → file/commit → suggested fix). **STOP.** History rewrites,
   or deciding to publish a fresh-history repo instead, are Marco's call.

---

## Phase 7: README, remove placeholders and say what runs

### Problems

- Placeholders: `<!-- TODO: Replace with project logo -->`, the placehold.co *"CLI Demo — coming soon"*
  image, two *"TODO: Replace with actual screenshot"* blocks. Visitors judge in seconds.
- The README doesn't say what runs on the user's machine. `init` copies `hooks/` and makes them executable
  (`chmodHooks` in `bin/cli.js`) but doesn't register them in `settings.json`, so they're inert until the
  user wires them up. "Nothing auto-runs, no API key, no network" is a trust point competitors lead with.

### Steps

1. **Demo:** you can't record an interactive Claude session. Instead, write `docs/demo-script.md`: the exact
   commands, a short storyboard (install → `/qa-cases` on a ServeRest feature → output), and the recording
   commands (`asciinema rec demo.cast`, `agg demo.cast demo.gif`). Marco records it. Until then, **replace the
   fake image with a real text transcript**: run `/qa-cases` yourself on a small public feature and paste
   the real output in a `<details>` block. Delete the placeholder image and TODO comments.
2. **"What this installs and what runs" section:** list the installed directories per editor, state hooks
   are inert until registered (with the exact `settings.json` snippet to enable each, checked against the
   current Claude Code hooks docs), and state no network calls and no telemetry. **Verify each claim first:**
   `grep -rn -E "https?\.|fetch\(|net\.|child_process" bin/ install.sh install.ps1`. At planning time no network
   calls were found in `bin/`.
3. **Positioning:** add a short "How it differs" list (facts only, from the competitor scan): ISTQB CTFL v4.0
   grounding with section citations, the traceable groomer → designer → writer pipeline, six editors from
   one source, an installer that never destroys user edits (manifest + known hashes), and rules for a11y,
   security, linting and commits. No claims about competitors' quality.

Commits: `docs: replace README placeholders with real output`, `docs: explain what the package installs and runs`.

---

## Phase 8: Launch checklist, **Marco performs this**

Prepare it as a checklist in the PR or an issue. Don't execute any of it.

- [ ] Phases 2–7 merged; Phase 5 decided; Phase 6 findings resolved.
- [ ] Release Please release for the fixes is merged and tagged.
- [ ] Make the GitHub repo public (Settings → Danger Zone).
- [ ] Repo description, website (`https://marcoamaral.com` once live), topics: `qa`, `testing`, `istqb`,
      `playwright`, `claude-code`, `agent-skills`, `cursor`, `test-automation`, `ai-agents`; social preview image.
- [ ] `npm publish --access public`. The release workflow doesn't publish to npm (checked
      `release-please.yml` at planning time), so this is manual. Enable npm 2FA and provenance if possible.
- [ ] Check in a clean temp directory: `npx @marcoamaral/qa-skills@latest init --editor claude`, then
      `qa-skills update`, then `qa-skills uninstall`.
- [ ] `gh api repos/MarcoAmaral/qa-skills --jq .license.spdx_id` → `MIT`.

---

## Phase 9: Context diet for the always-loaded rules (P1), **write a plan first**

### Problem

`.claude/rules/` is 8 files, ~38 KB / ~5,400 words (roughly 7–10k tokens), loaded into **every**
conversation in an installed project, including ones unrelated to testing. Cost-aware teams notice this
first, and competitors advertise the opposite ("lean SKILL.md, heavy references loaded on demand").
Large parts are only needed while writing tests: the Playwright/axe template in `accessibility-qa.md`,
the XSS payload spec in `security-qa.md`, the POM and assertion examples in `code-style-qa.md`.

### Steps

1. Measure: tokens per rule file (use the tokenizer the repo already uses, or note the method).
2. Write `plans/0NN-rules-context-diet.md`: what stays always-on (principles, tagging, context discovery,
   the short "must" lists), what moves into skill `references/` loaded on demand, how the other editors'
   adapters (one merged file) are affected, and the before/after token target.
3. **STOP for Marco's approval.** This changes behavior for every user, so it ships as its own reviewed
   plan, ideally after launch week with real feedback.

---

## Phase 10: Install via the Claude Code plugin marketplace and Agent Skills tools (P1), **plan first**

Competitors install in one line: `/plugin marketplace add owner/repo` or `npx skills add owner/repo`.
qa-skills installs only through its own CLI and shell installers.

1. Check the **current** formats in the docs: `.claude-plugin/marketplace.json`, `.claude-plugin/plugin.json`,
   whether plugin component paths can point at `.claude/commands|agents|skills|hooks`, and **whether plugins
   can ship rules at all**. If not, plugin installs would lack the rules, which must be stated in the README.
   Check how `npx skills add` (Vercel skills CLI) discovers skills (it depends on Phase 3's frontmatter).
2. Write `plans/0NN-plugin-marketplace.md` with what each install path delivers vs the CLI (the CLI keeps
   its manifest-safe update/uninstall, a real advantage), then implement after Marco approves.
3. Verify each path end to end in a temp project.

---

## Phase 11: `examples/` with real output (P1)

The most persuasive competitor README (QAIA) shows real output on someone else's software and states its
own limits. Claims about ISTQB grounding are cheap. Output is proof.

1. Target **ServeRest** (`https://serverest.dev`, front `https://front.serverest.dev`). Marco's public repo
   `MarcoAmaral/MoutsTI` covers it too, so the examples connect to his portfolio.
2. Run `/qa-static` on a ServeRest requirement, `/qa-agentic` on one user story (e.g. "a user can't add the
   same product to the cart twice"), and `/qa-automate` on the resulting cases.
3. Commit the output **unedited** under `examples/serverest/<command>/`, each with a `README.md`: the exact
   prompt, model and date, qa-skills version, and honest limits (what was wrong or needed a human fix).
4. Link it from the README. Commit: `docs: add unedited example outputs on ServeRest`.

---

## Phase 12: Directory submissions (P1), **drafts only**

Draft the text and links. Marco submits:

- **qaskills.sh** (PramodDutta/qaskills, 232★): directory, leaderboard, MCP registry listing. Read their
  contribution guide for the format.
- **awesome-claude-code** (hesreallyhim/awesome-claude-code): follow their resource-issue template.
  `petrkindlmann/qa-skills` submitted as issue #1774 (open at planning time). Read it for the expected shape.
- **claudemarketplaces.com** (testing category), **skills.sh** (Vercel), **claudepluginhub.com** (needs Phase 10).

For each: name, one-line description, the "How it differs" facts, the install command, license. Save as
`docs/launch/submissions.md`.

---

## Phase 13: New skills that match Marco's services (P2), one plan per skill

Competitors ship 33–50 skills. Don't chase the count. Each new skill should back a service Marco sells
(Fiverr/Upwork gigs), so it doubles as a portfolio piece:

| Skill | Backs | Competitor reference (read it for scope, don't copy it) |
| --- | --- | --- |
| `qa-migrate`: Cypress/Selenium → Playwright migration | Gig "migrate your tests to Playwright" | `petrkindlmann/qa-skills` `test-migration` |
| `qa-api`: REST/GraphQL testing, schema and contract checks | Automation framework gig | everyone has one |
| `qa-flaky`: detect, quarantine, fix flaky tests | Automation framework gig | `petrkindlmann` `test-reliability` |
| `qa-release`: release readiness, go/no-go sign-off | QA strategy offer | `petrkindlmann` `release-readiness`, QAIA `qaia-score` |
| `qa-a11y`: accessibility audit workflow on top of `accessibility-qa` | QA audit gig | common |

For each: a plan in `plans/` using the repo's existing format, ISTQB section citations like the existing
commands, frontmatter per Phase 3, an example in `examples/` per Phase 11, and a `feat:` commit. Ask Marco
which comes first. `qa-migrate` is suggested, because it backs his most distinctive gig.

---

## Done means

- Phases 1–7 merged with green CI on Linux, Windows and macOS; Phase 5 decided; Phase 6 findings resolved.
- Phase 8 checklist handed to Marco.
- Plans written for 9, 10 and 13, with `plans/README.md` rows updated as each phase lands.
