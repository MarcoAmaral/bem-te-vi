# Plan 042: The `qa-a11y` skill (accessibility audit workflow, WCAG 2.2 AA)

> **Executor instructions**: This plan is **not approved**. Marco reads it and decides before any
> file named in it is created (see "Approval gate"). When approved, work on `feat/qa-a11y-skill`:
> first the reference fix, then the skill with its frontmatter check passing, then the README, then
> the worked example. One concern per commit. Run every verification command and read its output. If
> anything in "STOP conditions" occurs, stop and report. When done, update this plan's row in
> `plans/README.md`.
>
> **Drift check (run first)**: `git diff --stat a2f08e7..HEAD -- .claude/rules/accessibility-qa.md .claude/skills/qa-reference .claude/rules/test-evidence.md .claude/commands/qa.md .claude/commands/qa-automate.md .claude/skills .claude-plugin generate-adapters.sh README.md examples plans/034-*.md`
> A change to `accessibility-qa.md` or `accessibility-checks.md` since planning means the overlap
> table below must be redone before anything else.
>
> **Note, 2026-10-18.** The first paragraph says "not approved"; that was true when the plan was
> drafted. Marco approved it on 2026-10-14 (see "Approval gate"), so the gate is passed. The text is
> kept as written.

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: LOW (new shipped file; one correction to a shipped reference)
- **Depends on**: plan 032 (see "Known hashes"), plan 034 (where shared reference content lives; it
  may move `accessibility-checks.md`), plan 019 phase 3 and phase 11
- **Category**: feature (new shipped skill) plus one `fix:` to a reference
- **Planned at**: commit `a2f08e7` (`github/main`), 2026-10-14
- **Decided by Marco, 2026-10-14**: approved as planned (see "Approval gate").
- **Implemented**: 2026-10-18, branch `feat/qa-a11y-skill` (see "Outcome").
- **Source**: plan 019 phase 13, row `qa-a11y` ("accessibility audit workflow on top of `accessibility-qa`")
- **Implementation target**: in this private repository, before plan 020 part B's public cut-over

## Why this matters

The package states **what** WCAG 2.2 AA requires and gives an axe-core template and a manual
checklist, but no **audit**: which pages and states to cover, what to do with the results an
automated scanner cannot decide, which criteria need a human, and how to report findings so a
claim of conformance survives someone checking it. The package's own example shows the gap: the
migrated TodoMVC contrast test asserts `results.violations` is empty, while axe reported the
contrast rule as **incomplete** (needs review) in two of three states
(`examples/todomvc-cypress-to-playwright/migration/run-output/axe-rules-compare.txt`: "state: two
todos … incomplete=[color-contrast]"). The test passes; nobody looked at what axe could not decide.
The failure the skill prevents is **"axe is green, so it is accessible"**.

## Current state (overlap check)

What exists, and must be **referenced, not restated**:

| Content | Where | Notes |
| --- | --- | --- |
| Always-on must-list (nine lines, WCAG 2.2 AA) | `.claude/rules/accessibility-qa.md` (1,510 B per plan 029's measure) | Policy; the skill never restates it |
| Full criteria incl. the 2.2 additions (2.4.11, 2.5.7, 2.5.8, 3.2.6, 3.3.7, 3.3.8) and "4.1.1 obsolete" | `.claude/skills/qa-reference/references/accessibility-checks.md:9-44` | The criteria the audit checks against |
| `@axe-core/playwright` template | `accessibility-checks.md:48-85` | Tags `wcag2a … wcag22aa` (`:65`); asserts `violations` only (`:68`) |
| Manual checklist (tab, modal trap, colour, screen reader) | `accessibility-checks.md:89-99` | Four items; no per-criterion mapping |
| Routing | `.claude/commands/qa.md:54`, `:88` ("axe" → QA Reference Skill); `qa-automate.md:21-22` | |
| `@a11y` feature tag example | `testing-guidelines.md:95` | |
| NFR in DoD "accessibility … for web UI" | `testing-guidelines.md:121` | |
| `cypress-axe` → `AxeBuilder` mapping | `qa-migrate/SKILL.md:103` | |
| Evidence rules (viewport, pointer, label, ASCII names, checker) | `.claude/rules/test-evidence.md`; `references/evidence-capture.md` | Applies to every screenshot the audit keeps |
| Tool categories ("accessibility scanners" are non-functional testing tools) | `references/test-tools.md:19` | |

Defects found in the reused reference while planning (they would propagate into every audit the
skill drives):

- `accessibility-checks.md:74`: `await page.click("button#open-settings")` — a CSS id selector,
  against the locator order in `code-style-qa.md` ("NEVER USE … structural CSS/XPATH selectors").
- `accessibility-checks.md:61`, `:75`: `page.waitForSelector(...)` instead of a web-first assertion
  (`automation-code.md:31-44`).
- `:68` asserts only `violations`; `incomplete` results are silently dropped (the TodoMVC evidence above).

Measured gap (`grep -rn -i "a11y\|accessib\|axe\|wcag" .claude --include=*.md`, planning time): no
audit scope (pages × states, including error, empty, modal, zoom 200%, small viewport); no triage of
axe's `violations` / `incomplete` / `passes` / `inapplicable`; no map from each WCAG 2.2 AA
criterion to "automatable", "partly" or "manual only"; no findings format (criterion, element,
impact, evidence, fix); no statement of what an audit can and cannot claim.

**Verdict: build, scoped.** The criteria, template and checklist stay where they are. The skill adds
the workflow and the triage, and corrects the template it depends on.

Package plumbing (as in plan 039): discovery by folder (`generate-adapters.sh:69-91`,
`.claude-plugin/plugin.json`); `adapters/` gitignored (`.gitignore:33-34`); router
`qa.md:54,58-61,82-88`; README `:153`, `:196-206` (an "Accessibility Rules" row exists at `:202`
pointing to the rule), `:442`; examples table `examples/README.md:7-12`.

## ISTQB CTFL v4.0.1 grounding

Verified against `<local copy of ISTQB_CTFL_Syllabus_v4.0.1.pdf>` (v4.0.1,
2024-09-15), section text read on 2026-10-14:

| Section | What it supports |
| --- | --- |
| §2.2.2 Test Types | Non-functional testing checks quality characteristics; the ISO/IEC 25010 list includes "Usability (also known as interaction capability)"; non-functional tests are often derived from functional ones; some need a specific environment. Accessibility is audited as part of that characteristic. The syllabus does **not** name accessibility; the skill must not say it does |
| §2.2.1 Test Levels | System testing: "For some non-functional quality characteristics, it is preferable to test them on a complete system in a representative test environment (e.g., usability)" — audit the deployed UI, not components alone |
| §4.4.3 Checklist-Based Testing | Checklist items phrased as questions, each checkable "separately and directly"; checklists "should not contain items that can be checked automatically"; update them from defects; keep them short. This is the rule for splitting the scanner's work from the manual checklist |
| §5.1.7 Testing Quadrants | Q3 holds usability testing, "often manual"; Q4 non-functional tests (except usability), "often automated": an audit has both halves |
| §6.1 Tool Support for Testing | Non-functional testing tools "allow the tester to perform non-functional testing that is difficult or impossible to perform manually" |
| §6.2 Benefits and Risks of Test Automation | Risks: "Using a test tool when manual testing is more appropriate"; "Relying on a tool too much" |
| §1.1.1 Test Objectives | "Verifying that a test object complies with contractual, legal, and regulatory requirements" — where accessibility is a legal requirement, the audit report is that evidence |
| §5.5 Defect Management | Findings become defect reports with severity, environment, steps, screenshots |

**Not cited, because the syllabus does not say it:** WCAG, accessibility, axe-core, assistive
technology. "accessib*" does not occur in the extracted text. WCAG 2.2 (W3C Recommendation) is the
external standard and is cited as such; the skill names its version.

## Research basis

Read for scope, never copied; headings and descriptions only, 2026-10-14:

- `petrkindlmann/qa-skills` (MIT) `skills/accessibility-testing/SKILL.md` (293 lines: axe-core with
  Playwright, manual keyboard and screen-reader checklist, WCAG quick reference, ARIA snapshots,
  legal compliance mapping, anti-patterns).
- `QAIA-Project/QAIA` (MIT) `docs/outreach/qaskills/accessibility-audit/SKILL.md` (axe on every key
  screen, failing on critical and serious, plus manual checks a DOM scanner cannot perform). Its
  description gives a figure for the share of criteria automation reaches; **not verified**, so the
  skill states no such percentage unless the executor finds and cites a primary source (e.g. the
  axe-core project's own documentation) on the run date.
- External standard: WCAG 2.2, `https://www.w3.org/TR/WCAG22/`.

Not adopted: a legal-compliance mapping per jurisdiction (it ages fast and is legal advice); a
"fail only on critical and serious" default (a team choice; the skill asks for it and records it).

## What the skill does

`.claude/skills/qa-a11y/SKILL.md`, target ≤ 10 KB, five steps, one living file `a11y/audit.md`:

1. **Scope.** Pages × states to audit (default, empty, error, loading, modal open, focus on each
   form control), viewports (the evidence rule's fixed viewport plus one narrow one), zoom 200%
   (1.4.4). Conformance target (WCAG 2.2 AA unless the team states otherwise) and the team's
   blocking threshold, recorded.
2. **Automated scan.** Per page and state, the corrected template in `accessibility-checks.md`;
   keep the raw results. **Triage all four result groups**: every `violation` becomes a finding;
   every `incomplete` is a manual check to do, not a pass; `passes` are recorded as "automated pass",
   never as "conformant"; `inapplicable` is listed so a reader sees what was not exercised.
3. **Manual checks** only for what the scanner cannot decide (§4.4.3): a short table mapping each
   WCAG 2.2 AA criterion in `accessibility-checks.md` to *automated*, *partly* or *manual*, with the
   question to ask for the manual ones (keyboard path, focus order and visibility, focus not obscured,
   target size, dragging alternative, error identification and suggestion, consistent help,
   redundant entry, accessible authentication, meaningful names). The checklist itself stays in the
   reference; the skill holds the mapping and the questions.
4. **Findings.** One row each: ID, WCAG criterion (number and name), page/state, element, observed
   vs expected, impact on a user, source (axe rule ID or manual), evidence file, suggested fix,
   severity per `/qa-defect`. Screenshots follow `test-evidence.md`.
5. **Report the claim honestly.** "No violations found by automated scan" and "conformant" are
   different statements; the report says which criteria were checked by which means and which were
   not checked at all.

## Commands you will need

| Purpose | Command | Expected |
| --- | --- | --- |
| Frontmatter | `./tests/test-frontmatter.sh` | exit 0, counts the new skill |
| Reference pointers | `./tests/test-reference-links.sh` | exit 0 |
| Adapters | `./generate-adapters.sh --clean && ./tests/verify-adapters.sh` | exit 0 |
| Plugin | `./tests/plugin/verify-plugin.sh` | exit 0 |
| Known hashes | `./generate-known-hashes.sh --check` | exit 0, unchanged |
| Lifecycle, conformance | `./tests/test-lifecycle.sh`, `./tests/conformance/run.sh` | pass |
| Rules size | `./tests/test-rules-size.sh` | unchanged (no rule edited) |
| Evidence | `.claude/hooks/check-test-evidence.sh examples/serverest/qa-a11y/playwright` and with `--runner-standard` | clean, or each finding explained |
| Template has no CSS-id selector | `grep -n 'button#\|waitForSelector' .claude/skills/qa-reference/references/accessibility-checks.md` | no match after commit 1 |
| Markdown lint | `npx --yes markdownlint-cli@0.49.1 --dot <changed .md files>` | no output |

## Scope

**In scope**: `.claude/skills/qa-a11y/SKILL.md`; `accessibility-checks.md` (the template fixes only,
`:48-85`); `qa.md` (skill line; routing rows `:88` split so "accessibility audit", "WCAG audit",
"a11y" go to the skill and "axe template" still goes to the reference); `README.md`;
`examples/serverest/qa-a11y/`; `examples/README.md`; `plans/README.md`.

**Out of scope**: `accessibility-qa.md` (rule; cap in `tests/test-rules-size.sh`); the criteria text
in `accessibility-checks.md:9-44` and the manual checklist `:89-99` (reused as is); screen-reader
automation; legal advice; mobile native apps.

## Git workflow

Branch `feat/qa-a11y-skill`. Conventional Commits, one concept each, **no AI attribution lines**:

1. `fix: use role locators and web-first waits in the axe-core template` (`accessibility-checks.md`;
   this reaches installed users, so `fix:`)
2. `fix: keep axe-core incomplete results visible in the audit template` (only if Marco accepts
   decision 2: the template also logs or asserts on `incomplete`)
3. `feat: add the qa-a11y skill for accessibility audits` (skill + `qa.md` router lines)
4. `docs: list the qa-a11y skill in the README`
5. `docs: add the qa-a11y worked example on the ServeRest front end`
6. `docs(plans): record plan 042 outcome`

## Steps

### Step 1: re-run the overlap check

Repeat the grep and the table. **STOP** if an audit workflow or result triage now exists elsewhere.

### Step 2: placement

Plan 034 (`plans/034-public-content-and-structure.md`, drafted in parallel, read at the end of this
planning session) keeps `accessibility-checks.md` in `qa-reference/references/` and fixes how to
point at it (034 step 3): `qa-reference/references/accessibility-checks.md`, rules by name ("the
`accessibility-qa` rule"), the evidence checker by name with its Claude Code location and a fallback
(`check-test-evidence.sh`). No `.claude/...` paths in the skill. Implement after 034's PR B.

The criterion-to-means mapping table goes in `SKILL.md` if it keeps the file ≤ 10 KB. Otherwise it
becomes `qa-reference/references/a11y-criteria-by-means.md` under 034's rules for new references
(flat, a contents-table row in `qa-reference/SKILL.md` with "read it when", a `verify-adapters.sh`
marker). If 034 is rejected or changed, follow what merged.

### Step 3: correct the template (commits 1-2)

Replace `page.click("button#open-settings")` with `page.getByRole("button", { name: … })`, and
`waitForSelector` with web-first `expect(...).toBeVisible()`; keep the WCAG tags. With decision 2,
add an explicit handling of `results.incomplete` (attach it to the report; never treat it as a pass).

### Step 4: write and route the skill (commit 3)

Frontmatter draft (≤ 1024 characters):

```yaml
---
name: qa-a11y
description: "Runs an accessibility audit against WCAG 2.2 AA: scopes pages and states, runs axe-core with Playwright and triages every result group (violations, incomplete, passes, inapplicable), does the manual checks a scanner cannot decide, and reports findings by WCAG criterion with evidence and what the audit can and cannot claim. Use when asked for an accessibility or WCAG audit, an a11y review of a page or flow, or whether a UI is accessible."
---
```

The body opens with "The criteria are `accessibility-qa.md` and `accessibility-checks.md`; this
skill runs the audit and restates neither."

### Step 5: README (commit 4)

`README.md:153` count and list, a row in the auto-loaded table, the `:442` comment; point the "Accessibility Rules" row (`:202`) at the skill for audits.

### Step 6: worked example on the ServeRest front end

Target: `https://front.serverest.dev` (HTTP 200 on 2026-10-14), the public front end of the API used
by every other ServeRest example. Its front end was **not** explored before
(`examples/serverest/qa-automate/behaviour-profile.md:3`), so this is new ground. Scope: the login
page and the sign-up ("cadastro") page, in states default, validation error (empty submit, invalid
email), and after a successful sign-up with a throwaway user (deleted afterwards through the API).

Success criteria, written before running:

- `a11y/audit.md` lists scope, conformance target, threshold, tool versions (`@axe-core/playwright`
  and the axe-core it bundles), date, and the build/version seen.
- Every axe result group is triaged; every `incomplete` item has a manual verdict or "not checked".
- The manual checks cover at least keyboard-only completion of both forms, focus visibility, error
  identification (3.3.1) and target size (2.5.8), each with a verdict and evidence.
- Every finding names its WCAG criterion and has a viewport screenshot that meets
  `test-evidence.md` (1440×900, visible pointer and case label, ASCII name such as
  `A11Y-LOGIN-001-error-not-announced.png`); each recording, if any, is opened before it is kept.
- `.claude/hooks/check-test-evidence.sh` runs clean on the audit specs, or each finding it reports
  is explained in the README.
- The report's conclusion says which criteria were not checked.

Kept in `examples/serverest/qa-a11y/`: `README.md` (prompt, model, date, version, tooling, honest
limits), `a11y/audit.md`, the audit specs, raw axe JSON per page/state, screenshots, run output.
Unedited apart from redacted scratch paths. Row in `examples/README.md`. Commit 5.

### Step 7: verify and record (commit 6)

Run the commands table, write an "Outcome" section here and update `plans/README.md`.

## Known hashes and plan 032

The new `SKILL.md` is in no tag, so `.qa-skills-known-hashes` is unchanged and `--check` passes.
Commits 1-2 edit a released file (`accessibility-checks.md`); older hashes stay in the list, so an
untouched older copy is still adopted (conformance case 003). Plan 032 keeps its frozen list open until the cut-over (`# state: open`), so a private release of this skill is added to it by the release workflow's refresh step; nothing extra is needed.

## Done criteria

- [ ] All commands pass; outputs in the PR.
- [ ] `git diff a2f08e7 -- .claude/rules/accessibility-qa.md` is empty.
- [ ] The skill contains no WCAG criterion text copied from `accessibility-checks.md` beyond the
      criterion number and name in the mapping table.
- [ ] No sentence cites CTFL for accessibility or WCAG, and no automation-coverage percentage
      appears without a primary source.
- [ ] The example meets its criteria or its README says which failed.
- [ ] `plans/README.md` row for 042 added and updated.

## STOP conditions

- The overlap check finds an audit workflow already shipped.
- Plan 034 moves the reference and is not merged yet: ask which path to use.
- The audit would need a rule change (e.g. a different conformance level by default).
- `front.serverest.dev` is unreachable or requires credentials beyond a throwaway sign-up: report;
  do not switch targets silently (fallback candidate for Marco: `https://demo.playwright.dev/todomvc/`,
  HTTP 200 on 2026-10-14, already the subject of the migration example).

## Rejected approaches

- **Grow the rule or the reference into the workflow**: the rule is capped and always loaded
  (plan 021, 029); the reference is the "what", the skill the "how".
- **Assert zero violations and stop**: that is the current template's gap; see "Why this matters".
- **A conformance score or percentage**: hides which criterion failed and invites a claim the audit
  cannot support.
- **Screen-reader automation**: unreliable across readers and platforms; kept as manual checks.

## Approval gate

Approved by Marco on 2026-10-14. Decisions:

1. Target: the ServeRest front end.
2. The shipped template surfaces `incomplete` results (commit 2).
3. Blocking threshold: ask the team and record it per audit.
4. Released before the public cut-over.

## Outcome (2026-10-18)

Implemented on `feat/qa-a11y-skill` from `github/next` at `71312a3` (plans 032, 033 items 1-9 and 034
merged there). Marco asked on 2026-10-18 for all remaining work to be done; every decision here had
a documented default in the approval gate, so no "default used" entry was needed except where noted.

### Drift check

`git diff --stat a2f08e7..HEAD -- <the listed paths>` showed changes from plan 034 in
`accessibility-qa.md` (2 lines), `accessibility-checks.md` (4 lines), `test-evidence.md`, the router,
the skills and the README. Read in full, the changes to the two accessibility files are pointer text
only (`.claude/skills/qa-reference/references/...` became `qa-reference/references/...`, and the
reference header was reworded). The criteria, the template and the checklist are unchanged, so the
overlap table still holds. No audit workflow or result triage exists elsewhere (Step 1 STOP did not
fire). Plan 034 is merged, so the Step 2 STOP ("034 moves the reference and is not merged yet") did
not fire either.

> **Correction, 2026-10-18.** The done criterion "`git diff a2f08e7 -- accessibility-qa.md` is
> empty" cannot hold literally: plan 034 changed that file's pointer line after `a2f08e7`. The check
> that matters, "this plan did not change the rule", holds: `git diff 71312a3 --
> .claude/rules/accessibility-qa.md` is empty.

### What was done, by commit

1. `fix: use role locators and web-first waits in the axe-core template`. Before: the template had
   `page.waitForSelector("main")`, `page.click("button#open-settings")` and
   `page.waitForSelector("role=dialog")` (`grep -n 'button#\|waitForSelector'` matched them). After:
   `getByRole("button", { name: "Settings" }).click()` and `expect(...).toBeVisible()`; the grep
   matches nothing.
2. `fix: keep axe-core incomplete results visible in the audit template` (decision 2). Both
   template tests attach `results.incomplete` to the report, and a sentence under the template says
   an empty `violations` list is not a pass and names the four groups.
3. `feat: add the qa-a11y skill for accessibility audits`: `.claude/skills/qa-a11y/SKILL.md` (8,854
   bytes, under the 10 KB target) and two router edits in `qa.md` (an auto-loaded skill line and a
   routing row for "accessibility audit", "WCAG audit", "a11y"; the "axe" row became "axe template"
   so the template still routes to the reference).
4. `docs: list the qa-a11y skill in the README`: the skills-only count and list, the auto-loaded
   modules table, the "Accessibility Rules" row (now points to the skill for a full audit) and the
   project-structure comment.
5. `docs: add the qa-a11y worked example on the ServeRest front end`:
   `examples/serverest/qa-a11y/` and a row in `examples/README.md`.
6. This record.

### Decisions taken inside the plan

- **Placement (Step 2).** The criterion-to-means mapping table fits in `SKILL.md` (8,854 bytes), so no
  `a11y-criteria-by-means.md` reference was created. The skill names files by the 034 convention
  (rules by name, the reference by `qa-reference/references/...`, the checker by file name with its
  Claude Code location), and contains no `.claude/...` path other than that location.
- **Read-only (instruction from the coordinator).** The plan's example scope included a successful
  sign-up with a throwaway user. The run was required to be read-only on the public site, so the
  success states (and every page behind login) are listed as **not audited** in `audit.md`. Every
  write the pages attempted was refused with 400, and the specs fail if one is answered 2xx. This is
  the one place the example falls short of the plan's scope; the success criterion "keyboard-only
  completion of both forms" is met for login and only partly for sign-up (stopped by the browser's
  email validation).
  **Decided by Marco, 2026-10-20**: this limit is accepted as stated; the example stays read-only.
- **Model name.** The example's run table first left the model out, because the work instructions
  for this implementation read "no AI attribution" too broadly. Corrected on 2026-10-18: like the
  other examples, the run table names the model that ran the skill, as a record of how the example
  was produced; the attribution rule covers commit and pull request authorship only.
- **Blocking threshold (decision 3).** No team to ask; `audit.md` records "not given" and marks no
  finding as blocking.
- **200% zoom** is emulated as a 720 x 450 CSS viewport at device scale factor 2, so the screenshot
  is still 1440 x 900. Said in the example's limits.

### Findings of the example worth keeping

axe reported two rule types (`image-alt`, `color-contrast`). The audit found nine failures: four from
axe's `violations`, one from axe's `incomplete` group (the close glyph, 2.17:1) and four only by hand:
two controls that are `<a>` with no `href` (never reached by Tab, no role), `lang="en"` on Portuguese
content (axe passes it), a 1.49:1 field border and a 1.19:1 to 1.34:1 focus ring. `link-name` was
inapplicable because the pages hold no link with an `href`, which is what pointed at the first.

### Verification

| Check | Result |
| --- | --- |
| `./tests/test-frontmatter.sh` | 16 skills and commands valid |
| `./tests/test-reference-links.sh`, `verify-adapters.sh`, `verify-plugin.sh`, `test-rules-size.sh`, `generate-known-hashes.sh --check` | pass, known hashes unchanged |
| `check-test-evidence.sh`, plain and `--runner-standard`, on the example's specs | `clean (4 files)` both |
| markdownlint on every changed file | clean |
| Local Linux CI (`~/qa-ci-local.sh`) on this branch | 16 of 17 steps pass; `lifecycle` fails only at Test 20, the known failure of plan 033's follow-up (PR from `fix/update-adopts-current-files`) |
| Lifecycle with that fix merged into a scratch copy of this branch | passes (all 49 tests) |
| Windows PowerShell | Not run: no PowerShell file was changed |

### Done criteria

- [x] All commands pass; outputs in the PR (lifecycle: see the known Test 20 failure above).
- [x] The rule is unchanged by this plan (see the correction above).
- [x] The skill contains no WCAG criterion text beyond number and name in the mapping table; the
      "question for a person" column is the skill's own wording, not the reference's.
- [x] No sentence cites CTFL for accessibility or WCAG, and no automation-coverage percentage appears.
- [x] The example meets its criteria except the sign-up success state (read-only run; stated in its
      README).
- [x] `plans/README.md` row for 042 updated to DONE.
