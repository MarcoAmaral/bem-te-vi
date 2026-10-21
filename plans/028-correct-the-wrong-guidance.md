# Plan 028: Every technique, template and example the package teaches is correct

> **Executor instructions**: Follow this plan item by item; each item is one small PR. Run every
> verification command and confirm the expected result before moving on. If anything in "STOP
> conditions" occurs, stop and report; do not improvise. When done, update this plan's row in
> `plans/README.md`.
>
> **Drift check (run first)**: `git diff --stat 5b45cfa..HEAD -- .claude/skills/qa-reference/references .claude/commands/qa-cases.md .claude/commands/qa-automate.md .claude/commands/qa-defect.md .claude/commands/qa.md .claude/agents/qa-writer.md .claude/rules/accessibility-qa.md .claude/skills/qa-explore/SKILL.md`
> If any of these changed since this plan was written, compare the excerpts below with the live
> files; on a mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: M overall (seven items, each S)
- **Risk**: LOW (text and examples only)
- **Depends on**: none. Item 5 edits an always-loaded rule and must stay **byte-neutral** until plan
  029 has freed space under the rules size cap.
- **Category**: bug (content correctness)
- **Planned at**: commit `5b45cfa`, 2026-10-13 (audit after 4.0.0)

## Why this matters

Bem-te-vi is a package of prompts: whatever its commands and references say, an AI assistant will
do. An audit after 4.0.0, checked against the official ISTQB CTFL v4.0.1 syllabus, Playwright 1.64's
own type definitions and the WCAG 2.2 criteria list, found guidance that is plainly wrong. A boundary
value analysis rule misses the values where off-by-one defects live. Security and accessibility
templates cannot fail. The headline Playwright scaffold fails on its first run. A defect report
records exit code 0 for failing commands. An exploratory heuristic is misnamed. The automation score
uses a wrong maximum. Each item is small; together they are the difference between a package that
teaches testing and one that has to be second-guessed.

## Conventions you must follow

- These files are prompts shipped to other people's repositories. Write plain, imperative English.
  Match the surrounding Markdown (tables, `**bold**` labels, fenced code with a language).
- After editing anything under `.claude/`, regenerate the adapters:
  `./generate-adapters.sh --clean && ./tests/verify-adapters.sh`.
- The always-loaded rules (`.claude/rules/*.md`) total 24,696 of a 25,000-byte cap enforced by
  `tests/test-rules-size.sh`. Do not add bytes to them in this plan.
- Never add AI attribution lines to commits or PRs. Conventional Commits, one concept per commit.
  Branch per item, e.g. `fix/bva-definition`.

## Commands you will need

| Purpose | Command | Expected on success |
| --- | --- | --- |
| Adapters | `./generate-adapters.sh --clean && ./tests/verify-adapters.sh` | exit 0 |
| Markdown lint | `npx --yes markdownlint-cli@0.49.1 --dot <changed .md files>` | no output |
| Rules size | `./tests/test-rules-size.sh` | `✔ The 9 always-loaded rules total N bytes (cap 25000).` with N ≤ 24696 |
| Template contracts | `./tests/test-tc-contracts.sh` | exit 0 |
| Reference links | `./tests/test-reference-links.sh` | exit 0 |
| Playwright types (for item 3 and 2) | in a scratch dir: `npm i -D @playwright/test@1.64.0 @axe-core/playwright typescript && npx tsc --noEmit --strict <file>.ts` | exit 0 |

## Scope

**In scope**: `.claude/skills/qa-reference/references/testing-design.md`,
`.claude/skills/qa-reference/references/security-checks.md`,
`.claude/skills/qa-reference/references/accessibility-checks.md`,
`.claude/commands/qa-cases.md`, `.claude/commands/qa-automate.md`, `.claude/commands/qa-defect.md`,
`.claude/commands/qa.md`, `.claude/agents/qa-writer.md`, `.claude/rules/accessibility-qa.md`
(byte-neutral), `.claude/skills/qa-explore/SKILL.md`, `plans/README.md`.

**Out of scope**:

- Test fixtures under `tests/fixtures/` that contain `57.5`: they test the format hook, which only
  checks the field is non-empty. Leave them.
- Restructuring `qa-automate.md` (plan 031 lists it), the tag taxonomy and release gates (plan 029),
  `/qa-agentic` (plan 030).
- Adding the CTFL content gaps (test levels, white-box…): plan 031.

---

## Item 1: boundary value analysis follows CTFL §4.2.2

**Current state.** `.claude/skills/qa-reference/references/testing-design.md:52` (the agent
`qa-designer` names this file as its source of truth):

```markdown
| **Boundary Value Analysis (BVA)** | Test boundary values (min, min+1, max-1, max) | Numeric inputs, date ranges, limits               |
```

`.claude/commands/qa-cases.md:166-173`:

```markdown
Test at the exact boundaries: min, min+1, max-1, max.

Version name length: min=1, max=62
Test values: 0 (invalid), 1 (min), 2 (min+1), 61 (max-1), 62 (max), 63 (invalid)
```

The rule omits the invalid neighbours its own example uses. CTFL v4.0.1 §4.2.2: in **2-value BVA**
each boundary value is tested together with its closest neighbour in the **adjacent** partition; in
**3-value BVA** also the neighbour on the inside. BVA applies only to ordered partitions.

**Change.**

- `testing-design.md:52` method cell: `2-value: each boundary and its neighbour in the adjacent partition (min-1, min, max, max+1); 3-value adds min+1 and max-1 (CTFL §4.2.2)`. Keep the table aligned.
- `qa-cases.md:168`: replace the sentence with
  `Two-value BVA (CTFL §4.2.2): each boundary plus its closest neighbour in the adjacent partition — min-1, min, max, max+1. Three-value BVA also tests min+1 and max-1. Use three-value where an off-by-one in either direction is likely. BVA applies only to ordered partitions.`
  Keep the example; label it `(three-value)`.

**Verify**: `grep -n 'min, min+1, max-1, max' .claude -r` → no matches; adapters regenerate.

## Item 2: the security and accessibility templates can fail

**Current state.** `security-checks.md:70-100`: the XSS spec fills, clicks and reloads, **then**
registers `page.on("dialog", …)`; Playwright auto-dismisses a dialog that has no listener, so an
alert fired earlier is never seen. It ends with `await expect(nameElement).not.toHaveHTML(payload);`
— there is **no `toHaveHTML` matcher** in `@playwright/test` 1.64 (`grep -c toHaveHTML
node_modules/playwright/types/test.d.ts` → 0). It uses CSS ids (`input#display-name`) against the
locator rule. `security-checks.md:23` requires `SameSite=Strict`; its checklist at `:115` accepts
`Strict` or `Lax`; the always-loaded `security-qa.md:12` says `Strict`. Heading `:46` promises
Semgrep but shows only `npm audit`; `:62` has the typo "Playloads".

`accessibility-checks.md:58`: `.withTags(["wcag2a", "wcag2aa", "wcag22aa"])` — axe tags are per WCAG
version, so the 2.1 rules (`wcag21a`, `wcag21aa`) never run. `:71`: `.include("role=dialog")` —
`AxeBuilder.include` takes a CSS selector, and `role=dialog` is Playwright's selector engine, not CSS.

**Change.**

- XSS spec: collect dialogs from the start, then assert none fired:

  ```typescript
  const dialogs: string[] = [];
  page.on("dialog", async (dialog) => {
    dialogs.push(`${dialog.type()}: ${dialog.message()}`);
    await dialog.dismiss();
  });
  await page.goto("/profile/edit");
  await page.getByLabel("Display name").fill(payload);
  await page.getByRole("button", { name: "Save" }).click();
  await page.reload();
  expect(dialogs).toEqual([]);
  await expect(page.locator("main script")).toHaveCount(0);
  await expect(page.getByTestId("profile-name-display")).toHaveText(payload);
  ```

  (`toHaveText(payload)` proves the payload is rendered as text, not markup.)
- SameSite: make `security-checks.md:23` and `:115` agree with the rule: `Strict`, or `Lax` only
  with a recorded reason. Rename heading `:46` to "Dependency audit (npm audit)" or add a real Semgrep
  example; fix "Playloads".
- Accessibility: tags `["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"]` in both tests;
  `.include('[role="dialog"]')`.

**Verify**: copy both specs into a scratch project with `@playwright/test@1.64.0` and
`@axe-core/playwright`, run `npx tsc --noEmit --strict` → exit 0.

## Item 3: the `/qa-automate` scaffold runs first time

**Current state.** `qa-automate.md:224` `testDir: "./playwright/tests"`; `:242` setup project
`testMatch: /.*\.setup\.ts/` (matched inside `testDir`); `:278` the setup file is
`// playwright/fixtures/auth.setup.ts` — outside `testDir`, so it is never found and the storage
state `playwright/tests/auth/.auth/user.json` (`:249`) is never written. `:284-289` calls
`page.evaluate(() => { localStorage.clear(); ... })` before the first `goto`, on `about:blank`.
`:162-170`:

```typescript
const mockPaymentClient = vi.fn();
vi.mock("@my-company/payment-sdk/client", () => ({
  default: mockPaymentClient,
}));
```

`vi.mock` is hoisted above the `const`, so the factory hits the temporal dead zone; Vitest's
documented fix is `vi.hoisted`. CI (`:529-576`) runs `npx playwright test --grep @smoke
--reporter=junit,list` (a CLI `--reporter` replaces the config's reporters, so the configured JUnit
`outputFile` is not used) and uploads `test-results/e2e-junit.xml`, which is never produced.
`:575` `allow_failure: true` on regression is fine for a nightly job, but say so beside the
release-gate rule.

**Change.**

1. Move the setup file to `playwright/tests/auth/auth.setup.ts` (inside `testDir`) and update the
   comment header. Delete the pre-`goto` storage clearing (each test context starts clean).
2. Add `playwright/tests/auth/.auth/` to the `.gitignore` guidance next to the reports line.
3. Replace the mock with:

   ```typescript
   const { mockPaymentClient } = vi.hoisted(() => ({ mockPaymentClient: vi.fn() }));
   vi.mock("@my-company/payment-sdk/client", () => ({ default: mockPaymentClient }));
   ```

   and change the comment above it to say `vi.mock` is hoisted, so values it uses must come from
   `vi.hoisted`.
4. In the Playwright config set the JUnit reporter's `outputFile` to `test-results/e2e-junit.xml`
   and the HTML reporter's `outputFolder` to `playwright-report`; remove `--reporter=…` from the CI
   commands so the config is used. Make the uploaded paths match.
5. Add one line under the nightly job: "A failing `@p0`/`@p1` test must still block the release
   (see the release gate in `testing-guidelines.md`); this job only reports."

**Verify**: in a scratch Playwright project, copy the config, the setup file and one spec; with a
stub login page served locally, `npx playwright test --list` shows the `setup` project's test.
`npx tsc --noEmit` on the Vitest snippet with `vitest` installed → exit 0.

## Item 4: `/qa-defect` evidence tells the truth and fits any stack

**Current state.** `qa-defect.md:310-311`:

```bash
<failing-command> 2>&1 | tee docs/qa/evidence/DR-XXX-description.txt
echo "EXIT_CODE:$?" >> docs/qa/evidence/DR-XXX-description.txt
```

`$?` is `tee`'s status, so a failing command is recorded as `EXIT_CODE:0`. `:318` writes a fixed
`/tmp/dr-tmp`. `:260-298` "Step 0 — Collect System Info Before Filing (MANDATORY)" runs
`npx next --version` and a Python reader of `package.json`, which only fits a Node/Next project;
`:302-441` are Azure DevOps upload and field-mapping steps in a command that `:14-21` says must
follow the team's own tracker schema. `:47` the Status picklist lacks `Reopened`, which the
lifecycle at `:129-143` uses.

**Change.**

1. `echo "EXIT_CODE:${PIPESTATUS[0]}" >> …` and use `tmp="$(mktemp)"` instead of `/tmp/dr-tmp`.
2. Retitle Step 0 "Collect system info (adapt to the stack)": keep `node`/`npm` lines under "If the
   project is Node", and add one generic line: "record the runtime and the versions of the
   components under test, from the project's own manifest".
3. Introduce the Azure DevOps steps with: "If the team's tracker is Azure DevOps; otherwise map the
   same fields to the tracker the repository uses." Do not delete them.
4. Add `Reopened` to the Status picklist.

**Verify**: `grep -n 'EXIT_CODE:\$?' .claude -r` → no matches.

## Item 5: WCAG references cite the right criteria

**Current state.** `.claude/rules/accessibility-qa.md:12` (always loaded):
`- **Contrast (1.4.3)**: 4.5:1 for normal text; 3:1 for large text (≥18pt, or ≥14pt bold) and UI components.`
UI-component contrast is WCAG **1.4.11 Non-text Contrast**, not 1.4.3. The rule and
`accessibility-checks.md:9` are titled "WCAG 2.2 AA", but no criterion added in WCAG 2.2 appears
anywhere in the package.

**Change.**

- Rule line 12, byte-neutral: `- **Contrast (1.4.3, 1.4.11)**: 4.5:1 normal text; 3:1 large text (≥18pt, ≥14pt bold) and UI components.`
  Run `./tests/test-rules-size.sh` and confirm the total did not grow.
- In `accessibility-checks.md`, under the matching principle headings, add the WCAG 2.2 A/AA
  additions, one line each: **2.4.11 Focus Not Obscured (Minimum)** (AA), **2.5.7 Dragging Movements**
  (AA), **2.5.8 Target Size (Minimum)** (AA, at least 24×24 CSS px or enough spacing), **3.2.6
  Consistent Help** (A), **3.3.7 Redundant Entry** (A), **3.3.8 Accessible Authentication (Minimum)**
  (AA). Note that 4.1.1 Parsing is obsolete in WCAG 2.2. Move the UI-component sentence under 1.4.11.

**Verify**: `grep -c '2\.5\.8' .claude/skills/qa-reference/references/accessibility-checks.md` → 1
or more; rules size not increased.

## Item 6: exploratory testing uses the real heuristic and keeps its learning loop

**Current state.** `.claude/skills/qa-explore/SKILL.md:71-82` expands "FEW HICCUPS" as Frequency,
Error handling, Workflow, Hardware, Interruption, Control, Configuration, User scenarios,
Performance, Security. The heuristic (Michael Bolton, from James Bach's work; spelled FEW HICCUPPS)
is a list of **consistency oracles**: Familiarity (familiar problems), Explainability, World,
History, Image, Comparable products, Claims, User expectations, Product, Purpose, Statutes and
standards. The charter template (`:22-56`) has no session notes or debrief. `:97-100` turns an
exploratory session run by someone else into "a linear, numbered script", which makes it scripted.

**Change.**

1. Replace the list with the real oracles, one line each with what inconsistency it detects; title
   it "FEW HICCUPPS (consistency oracles)". If the existing risk prompts are worth keeping, keep them
   under a new heading "Risk-area prompts (package checklist)".
2. Add a "Session sheet and debrief" block to the charter: start/end time, % on charter vs
   opportunity, notes, bugs (with DR ids), issues/questions, coverage achieved, and a debrief section
   (what was learned, what to explore next). Cite CTFL §4.4.2 (exploratory testing, session-based).
3. Reword `:97-100` to apply to **checklist runs**; for an exploratory session handed to someone
   else, hand over the charter and the debrief questions, not steps.

**Verify**: `grep -n 'Frequency' .claude/skills/qa-explore/SKILL.md` → no match.

## Item 7: the automation score uses its real maximum

**Current state.** `qa-cases.md:129-143`: eight weights ×2, ×2, ×2, ×1.5, ×1.5, ×1.5, ×2, ×1 sum to
13.5, so the maximum is 13.5 × 5 = **67.5**; the table prints `**/57.5**`; bands are `45–57.5`
HIGH, `30–44` MEDIUM, `< 30` LOW, so a total of 44.5 (scores move in 0.5 steps) matches no band.
`/57.5` also appears at `qa-cases.md:86,268,286,304`, `qa.md:110`, `qa-writer.md:50`.

**Change.** Use `/67.5` everywhere listed. Keep the bands' proportions (45/57.5 ≈ 78%,
30/57.5 ≈ 52%) and make them contiguous: **HIGH ≥ 52.5**, **MEDIUM ≥ 35 and < 52.5**,
**LOW < 35**. Update the example values so each stays in its band (e.g. `HIGH (58/67.5)`,
`MEDIUM (42/67.5)`).

**Verify**: `grep -rn '57\.5' .claude` → no matches; `./tests/test-tc-contracts.sh` passes.

---

## Done criteria

- [ ] All seven items' verify commands give the expected result.
- [ ] `./generate-adapters.sh --clean && ./tests/verify-adapters.sh` exits 0.
- [ ] `./tests/test-rules-size.sh` total ≤ 24,696 bytes.
- [ ] `./tests/test-tc-contracts.sh`, `./tests/test-reference-links.sh`, `./tests/test-frontmatter.sh` pass.
- [ ] Markdown lint clean on every changed file.
- [ ] `plans/README.md` row for 028 updated.

## STOP conditions

- An excerpt above does not match the live file.
- A Playwright or axe API named here does not exist in the version you install (check the type
  definitions); report instead of inventing another.
- Item 5 cannot be made byte-neutral: wait for plan 029.
- Rescaling the score bands (item 7) would change an example's band in `examples/`: report it; do
  not edit `examples/` (their outputs are committed unedited on purpose).

## Maintenance notes

- Item 7's thresholds are a judgment that kept the old proportions; Marco may prefer other values.
- Items 2 and 3 are code samples. A future plan could compile every TypeScript sample in CI
  (extract fenced `typescript` blocks and run `tsc --noEmit`), which would have caught both.
