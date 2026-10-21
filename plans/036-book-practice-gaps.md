# Plan 036: Bring the testing and delivery practice of *Engenharia de Software Moderna* into the package

> **Executor instructions**: Do this plan **after plan 034 has merged**: 034 splits `qa-automate.md`
> into references, restructures `/qa-defect`, removes duplicated text and fixes how commands point to
> references, so several targets below move. Follow it item by item; each item (or group marked
> below) is one small PR. Run every verification command and confirm the expected result before
> moving on. If anything in "STOP conditions" occurs, stop and report; do not improvise. When done,
> update this plan's row in `plans/README.md`.
>
> **Drift check (run first)**: `git diff --stat a2f08e7..HEAD -- .claude/skills/qa-reference .claude/skills/qa-plan/SKILL.md .claude/commands/qa-automate.md .claude/commands/qa-review.md .claude/commands/qa-tdd.md .claude/commands/qa-refinement.md .claude/agents/qa-engineer.md .claude/rules/testing-guidelines.md .claude/rules/code-style-qa.md`
> Drift is **expected** from 034 (and from plan 035 if it landed first). For every item, re-locate
> the excerpt quoted in "Current state" in the live tree. If an excerpt no longer exists anywhere,
> treat that item as a STOP condition; if it only moved, apply the item at its new location.

## Status

- **Priority**: P2 (practice the package lacks or states one-sidedly; nothing here is a wrong CTFL
  claim, which is plan 035's ground)
- **Effort**: L overall (twelve items, each S; items 7-11 are one reference section each)
- **Risk**: LOW (text only; no installer, hook or format-contract change)
- **Depends on**: plan 034 merged. Item 6 needs items 1-3. Shares one new reference with plan 035
  (see "Coordination with plan 035"); either plan may land first.
- **Category**: content (new practice guidance and two one-sided framings corrected)
- **Planned at**: commit `a2f08e7`, 2026-10-14 (backlog "From the book", audit after 4.0.0)
- **Decided by Marco, 2026-10-14**: keep the 20/30/50 preset with the cost caveat (item 12).

## Why this matters

The audit after 4.0.0 read chapters 3, 8, 9 and 10 of Marco Tulio Valente's *Engenharia de Software
Moderna* against the package. The package tells an assistant to "apply FIRST principles" without
saying what they demand, has no vocabulary for test doubles or for what mocking costs, flags
untestable code without saying how to fix it, never reviews test code, and says nothing about the
practices that decide whether a test result means anything in a delivery pipeline: CI that is
really continuous, a broken build, delivery versus deployment, feature flags, canary releases, A/B
experiments. Two passages frame a trade-off from one side only: an MVP is presented purely as
speed, and an E2E-heavy test distribution is offered with no word on its cost.

## Copyright and wording (read before writing anything)

The book is copyrighted. **Every sentence this plan adds is written in the package's own words**, in
English, and cites the book by chapter and section, e.g. `(Valente, *Engenharia de Software
Moderna*, §8.3)`. Do not translate passages, do not reuse the book's examples or code (the BMI
servlet, the asynchronous PI function, the book-search mock, the stack test, the Zappos and Dropbox
MVPs, the A/B sample-size figures, the Chrome feature-flag study). Write fresh examples in the
package's own stack (TypeScript, Vitest, Playwright). The audit after 4.0.0 found no copied text in
the package (`plans/README.md`, "Findings considered and rejected"); the Done criteria re-check it.

Where a concept is not the book's, say whose it is: "characterization test" is Michael Feathers'
term (*Working Effectively with Legacy Code*, 2004); "test spy" is Gerard Meszaros' (*xUnit Test
Patterns*, 2007). The book cites Meszaros for the double vocabulary.

## Conventions you must follow

- **New content goes in on-demand files, not rules.** The always-loaded rules have a 25,000-byte
  cap (`tests/test-rules-size.sh`, 21,439 bytes at `a2f08e7`). Do not add bytes to
  `.claude/rules/*.md`. Targets are the `qa-reference` references, the commands and the agents.
- **New reference files are listed** in `.claude/skills/qa-reference/SKILL.md` (contents table, and
  the `description:` if the topic is new; 534 of 1024 characters today).
- **Point to references the way 034 settled.** 034 step 3 replaces `.claude/skills/...` paths with
  skill-relative ones, `qa-reference/references/<file>.md`; new reference files sit flat in
  `qa-reference/references/` and get a `verify-adapters.sh` marker. `tests/test-reference-links.sh`
  must pass.
- **Do not contradict a rule.** Several items sit next to an always-loaded rule (the STOP LINE at
  `testing-guidelines.md:105`, "No Conditional Assertions" and "Independent Test Isolation" at
  `code-style-qa.md:38,40`). Extend or point to the rule; if the book disagrees with a rule, report it.
- Regenerate the adapters after any edit under `.claude/`; references are inlined into every
  single-file adapter, so keep additions to what an assistant needs to act.
- Branch per item or group, e.g. `feat/test-smells`. Commit types (CONTRIBUTING.md): new content
  reaching installed users is `feat:`; a correction of wrong or one-sided guidance is `fix:`. One
  concept per commit. Never add AI attribution lines to commits or PRs.

## Commands you will need

| Purpose | Command | Expected on success |
| --- | --- | --- |
| Book text (read only) | a local copy of the book, kept outside the repository (copyrighted) | ~690 KB file; grep the section you need, do not read it whole |
| Adapters | `./generate-adapters.sh --clean && ./tests/verify-adapters.sh` | exit 0 |
| Rules size | `./tests/test-rules-size.sh` | total unchanged by this plan |
| Reference links | `./tests/test-reference-links.sh` | `✔ All N reference pointers resolve.` |
| Frontmatter | `./tests/test-frontmatter.sh` | exit 0 |
| Markdown lint | `npx --yes markdownlint-cli@0.49.1 --dot <changed .md files>` | no output |
| Code samples | in a scratch project: `npm i -D vitest@3 typescript && npx tsc --noEmit --strict <file>.ts` | exit 0 for every new TypeScript sample |

Book sections used (find them with `grep -n '^<heading>' "$S/book.md"`): §3.5 "Produto Mínimo Viável
(MVP)", §3.6 "Testes A/B", §8.1 introduction (the pyramid), §8.3 "Princípios e Smells" ("Princípios
FIRST", "Test Smells", "Número de assert por Teste"), §8.5 "Testabilidade", §8.6 "Mocks" ("Mocks vs
Stubs"), §8.9 "Testes de Sistema", §9.3 "Prática de Refactoring", §10.3 "Integração Contínua" ("Boas
Práticas para Uso de CI", "Desenvolvimento Baseado no Trunk"), §10.4 "Deployment Contínuo" ("Entrega
Contínua", "Feature Flags", canary releases).

## Scope

**In scope**: `qa-reference/references/automation-code.md` (AAA and Page Object detail; 034 keeps it
and moves the Vitest unit pattern to the new `vitest-patterns.md` and flakiness and CI to
`automation-ci.md`);
`.claude/skills/qa-reference/references/testing-design.md` (mocking section and pyramid presets
only); the shared new reference `testing-in-delivery.md`; `.claude/skills/qa-reference/SKILL.md`;
`.claude/skills/qa-plan/SKILL.md` (pyramid preset line only); `.claude/agents/qa-engineer.md`;
`.claude/commands/qa-review.md`, `qa-tdd.md`, `qa-refinement.md`, `qa-automate.md` (the FIRST line,
wherever 034 left it); `plans/README.md`.

**Out of scope**:

- Everything in plan 035 (CTFL topics, coverage measures, regression and confirmation testing,
  DevOps and shift-left, the three CTFL wording fixes).
- Code coverage and the coverage-targets table, including the book's §8.4 view on coverage
  targets: plan 035 item 4 owns it.
- The always-loaded rules; the `qa-designer`/`qa-writer` contracts; the hooks.
- The CI pipeline YAML in `qa-automate.md` (034 moves it; this plan adds guidance, not YAML).

## Coordination with plan 035

- **Shared reference `testing-in-delivery.md`.** Plan 035 owns its CTFL sections (DevOps and
  testing §2.1.4, shift-left §2.1.5, confirmation and regression §2.2.3, maintenance §2.3). **This
  plan owns** items 7-11: CI preconditions, the broken-build rule, delivery vs deployment, feature
  flags, canary and A/B. Whichever plan lands first creates the file (title, one-paragraph purpose,
  its own sections) and the contents-table row; the second appends and adds cross-links: 035's
  DevOps section → this plan's CI section; this plan's feature-flag section → 035's regression
  section ("removing a flag is a change: regression-test it"). Never link a heading that does not
  exist yet.
- **`testing-design.md`**: this plan edits only the mocking section (item 3) and the UI-heavy preset
  (item 12). 035 edits other sections. Rebase rather than resolve conflicts by hand.
- **`qa-engineer.md:10`**: 035 replaces "Static Analysis"; this plan makes "FIRST" resolve (item 1).
  Items 4 and 6 also edit `qa-engineer.md` (the gates), which 035 does not touch.

---

## Item 1: FIRST is defined where it is demanded (book §8.3)

**Current state.** `qa-automate.md:606` `3. **Apply FIRST principles** (Fast, Independent, Repeatable,
Self-checking, Timely)`: five words, no criteria. `qa-engineer.md:10` names "FIRST Principles" with
no expansion. `grep -rn FIRST .claude` finds nothing else that explains it.

**Target.** `qa-reference/references/automation-code.md`, new section "FIRST: what each letter
requires". The `qa-automate` "How to Respond" step (034 step 5 keeps it in the command) and
`qa-engineer.md:10` point to it. Link the flakiness section 034 moved to `automation-ci.md` from
"Repeatable".

**What to write** (outline, own words): for each letter, the property and a check an assistant can
apply to a test it writes or reviews.

- **Fast**: unit tests run in milliseconds; slow ones are split into a separately scheduled group
  (map to the suite tags in `testing-guidelines.md`).
- **Independent**: same result in any order or in parallel; no state shared through globals,
  storage or a database (point to the rule's "Independent Test Isolation").
- **Repeatable**: same result every run; sleeps, clocks, randomness, network and concurrency are the
  usual causes; a non-repeatable test is flaky and goes through the rule's quarantine protocol.
- **Self-checking**: pass or fail is decided by assertions, never by a person reading output.
- **Timely**: written before or with the code (`/qa-tdd`).

**Commit**: `feat: define each FIRST property with a check`.

**Verify**: `grep -rn 'Self-checking' .claude` → a match in the reference, with more than the word.

## Item 2: test smells (book §8.3; code smells in general, §9.5)

**Current state.** "test smell": no match in `.claude`. One smell is already a rule:
`code-style-qa.md:38` "No Conditional Assertions"; another is the "No Hardcoded Sleeps" rule. No
guidance on assertions per test or on refactoring test code.

**Target.** `automation-code.md`, section "Test smells".

**What to write** (outline): a smell is a warning to examine, not a ban. Cover the three the book
names (a long, hard-to-read test; conditional logic or loops in a test; duplicated test code),
linking the two existing rules rather than restating them; the assertions-per-test question (one
behaviour per test; several assertions on the fields of one result are fine; a test that can fail
for two unrelated reasons should be two tests); test code is refactored like production code. A
short TypeScript before/after example of the package's own.

**Commit**: `feat: add test smells to the automation reference`.

## Item 3: test-double vocabulary and what mocking costs (book §8.6)

**Current state.** `testing-design.md:31-37` "Mocking Principles Matrix" says what to mock and not
to mock; it names no kind of double and no cost. `qa-automate.md:158-173` shows `vi.mock` hoisting.
"stub" appears only in unrelated senses (charter stub, Cypress mapping), "fake" and "dummy" nowhere.

**Target.** `testing-design.md`, directly after the matrix; link the `vi.mock` hoisting example that
034 step 5 moves to `qa-reference/references/vitest-patterns.md`.

**What to write** (outline):

- Vocabulary (Meszaros, cited by the book): dummy (fills a parameter, never used), stub (returns
  canned answers; the test checks state), fake (a working lightweight implementation, e.g. an
  in-memory repository), mock (the test verifies the calls made to it: interaction testing), spy
  (records calls on a real or stubbed object). Map each to Vitest: `vi.fn().mockReturnValue`,
  an in-memory class, `expect(fn).toHaveBeenCalledWith`, `vi.spyOn`.
- Costs: a mock couples the test to how the code calls its dependency, so refactoring breaks tests
  that should not break (prefer a stub and a state assertion when the call itself is not the
  behaviour); a double can hide a disagreement with the real dependency, so each mocked boundary
  needs at least one test against the real thing (component integration or a contract test); some
  constructs cannot be replaced without changing the design, which is a testability finding
  (item 4).

**Commit**: `feat: name the kinds of test double and what mocking costs`.

**Verify**: the Vitest sample type-checks (see Commands).

## Item 4: the testability gate says how to fix what it flags (book §8.5)

**Current state.** `qa-engineer.md:26-31` "Testability (Strict Quality Gate)" checks single
responsibility, dependency injection, pure functions and `data-testid`; `:55` classifies
"Testability issues (such as static coupling preventing mocks)" as `[Should Fix]`. No remedy is given,
so a finding says what is wrong and stops.

**Target.** `qa-engineer.md`, the Testability gate (an agent file: loaded only when dispatched).

**What to write** (outline): for each check, one remedy the reviewer proposes with the finding:
move domain logic out of framework, transport or UI code into a plain module that can be tested
alone; give asynchronous code a synchronous core and test that; inject dependencies, the clock and
randomness; add the missing `data-testid` (product change). One sentence of principle: testing the
extracted part beats leaving the whole untested, and good design (cohesion, low coupling,
dependency inversion) is what produces testability.

**Commit**: `feat: give each testability finding a remedy`.

## Item 5: characterization tests before refactoring untested code (book §9.3)

**Current state.** `qa-tdd.md:25-29` describes RED → GREEN → REFACTOR, which assumes the tests came
first. Nothing covers changing code that has no tests: "characteriz", "legacy": no match in
`.claude`.

**Finding about the backlog line**: the backlog files this under the book's chapter 8. The book's
anchor is §9.3 ("Prática de Refactoring": refactoring safely depends on a good unit-test suite), in
chapter 9, and the book does not use the term "characterization test"; that is Feathers'. Cite both.

**Target.** `qa-tdd.md`, new section "Before refactoring code that has no tests".

**What to write** (outline): pin the current behaviour first with tests that assert what the code
**does now**, not what the specification says; record each surprising behaviour as a question or
defect, not as a fix inside the refactoring; refactor in small steps with those tests green; then
replace pinned outputs with specified expectations through the normal RED → GREEN loop. Same idea as
the parity gate in the `qa-migrate` skill: nothing old is removed until something proven replaces it.

**Commit**: `feat: add characterization tests to /qa-tdd`.

## Item 6: `/qa-review` reviews test code too (book §8.3; CTFL v4.0 §3.1.1)

**Current state.** `qa-review.md:29` and `:37` apply "all four quality gates" to every changed file;
the four gates (`qa-engineer.md:24-46`) are about production code. A changed spec file is reviewed
for SRP and logging, never for whether it can fail. CTFL v4.0 §3.1.1 lists test cases among the
work products static testing examines.

**Target.** `qa-engineer.md`: a fifth gate "Test code" applied to changed test files; `qa-review.md:29,37`
"all four" → "all five" (and its report wording if it names four).

**What to write** (outline): the gate checks FIRST (item 1), test smells (item 2), doubles and
their cost (item 3), the locator and no-sleep rules (`code-style-qa.md`), tags and IDs, and the
red-green proof (a test that cannot fail is a finding: `[Must Fix — Blocker]` on a critical path,
`[Should Fix]` elsewhere). Point to the sections; do not restate them.

**Commit**: `feat: review changed test code in /qa-review`.

**Verify**: `grep -n 'all four' .claude/commands/qa-review.md` → no match.

## Item 7: what CI requires before its results mean anything (book §10.3)

**Current state.** `testing-design.md:88-111` gives tag-filter syntax; `qa-automate.md:523-574` gives a
GitLab pipeline (034 step 5 moves it, with flakiness hunting, to `automation-ci.md`); the rule gives
suite duration targets. Nothing states what makes
integration continuous. "trunk": no match in `.claude`.

**Target.** `testing-in-delivery.md`, section "CI: preconditions" (create the file if plan 035 has
not; see Coordination).

**What to write** (outline, own words): an automated build with no manual step; a build fast enough
to run on every integration (tie to the smoke duration target); automated tests in the pipeline at
the levels that give fast feedback; integration into the main line at least daily; a long-lived
feature branch built automatically is continuous building, not integration; trunk-based development
as the usual companion. Testing consequences: the CI run, not a local run, is the result (point to
"Localhost Is a Dry Run" in `testing-design.md`); a build that passes locally and fails in CI usually
means an uncommitted file or a dependency version drift, so pin versions (lockfile, `npm ci`).
Link the pipeline example in `automation-ci.md` instead of adding YAML.

**Commit** (items 7 and 8 together): `feat: add CI preconditions and the broken-build rule`.

## Item 8: the broken-build rule (book §10.3)

**Current state.** `testing-guidelines.md:105` (rule): "**Smoke Failures**: **STOP LINE**. Block the
Merge Request or Deployment immediately." It covers a failing smoke suite, not a broken main build,
and says nothing about reverting or about not testing on a broken build.

**Target.** `testing-in-delivery.md`, section "When the main build breaks", consistent with the rule.

**What to write** (outline): a broken main build blocks everyone, so fixing it comes first; reverting
the offending commit is a legitimate fix; whoever pushed waits for the CI result before moving on;
QA does not start a test session on a build that has not passed, and records which build was tested
(link the deployment-record heuristic in `testing-design.md`).

## Item 9: continuous delivery versus continuous deployment (book §10.4)

**Current state.** "continuous delivery", "continuous deployment": no match in `.claude`.
`qa-plan/SKILL.md:110` defines the release gate without saying who or what opens it.

**Target.** `testing-in-delivery.md`, section "Delivery or deployment: where the release gate sits".

**What to write** (outline): delivery makes every change releasable and leaves the release to a
decision; deployment releases every change that passes the pipeline. Consequence for testing: with
continuous deployment the release gate is the pipeline, so every gate case must be automated and
tagged; with continuous delivery the gate's evidence goes to the person who decides. Post-release
`@sanity` either way. Link `qa-plan`'s release gate.

**Commit**: `feat: explain delivery versus deployment for the release gate`.

## Item 10: testing behind feature flags (book §10.4)

**Current state.** Flags are asked about, never tested: `qa-refinement.md:44` ("Do we have a feature
flag?"), `qa-plan/SKILL.md:77` (a flag as a non-test risk measure), `qa-static.md:137` (flags as a
testability need), `context-discovery.md:24` (flags as a tier-2 source). No guidance on how to test
flagged code.

**Target.** `testing-in-delivery.md`, section "Feature flags".

**What to write** (outline): test both states, and treat the **off** state as the one production
runs today; several interacting flags are a decision table (link `testing-design.md`), reduced by
risk; record the flag states in the test case precondition and in the defect report's environment;
read each environment's flag defaults from its configuration, not from the code's defaults;
removing a flag is a change to regression-test (link 035's regression section); stale flags are
debt to report.

**Commit**: `feat: add feature-flag testing to the delivery reference`.

## Item 11: canary releases and A/B experiments are valid only under conditions (book §10.4, §3.6)

**Current state.** "canary", "A/B": no match in `.claude`. `qa-refinement.md:50-52` ("Expected Gain
Validation") and the rule `testing-guidelines.md:45` ask QA to validate the expected gain with no
method.

**Target.** `testing-in-delivery.md`, section "Canary releases and A/B experiments"; one pointer
line in `qa-refinement.md`'s Expected Gain Validation.

**What to write** (outline):

- Canary: a small share of users gets the change first; it limits the damage of a defect that
  testing missed and replaces no testing. Before it starts: the health signals watched, the
  threshold that halts it, and the rollback, written down.
- A/B validity: random assignment; one success metric chosen before starting; the sample size
  computed before starting and the experiment run to it (stopping when the result first looks good
  is a classic error); an A/A run to prove the assignment and measurement work; more than two arms
  are possible. Small products may never reach the sample an A/B test needs; say so rather than
  report noise.
- What QA tests: the experiment itself: assignment really is random and sticky per user, both arms
  work, the metric's events fire in both arms, the flag routing is right.

**Commit**: `feat: add canary and A/B validity conditions`.

## Item 12a: an MVP tests a hypothesis, not only a deadline (book §3.5)

**Current state.** `qa-refinement.md:32-36` "Scope Negotiation (MVP Focus)": advise the PO to mark
low-reach, high-effort edge cases "Won't" "for the MVP to accelerate time-to-market".
`qa-refinement.md:144`: "**Advise on Scope**: Suggest trimming edge cases to hit MVP faster."

**Target.** `qa-refinement.md:32-36` and `:144`.

**What to write** (outline): an MVP exists to test a business hypothesis, measured by an actionable
metric; it needs only the quality that keeps that measurement honest, and no less: an MVP that is
down or confusing produces a false negative, rejecting a hypothesis that was true. So trimming is
right for edge cases that do not affect the measured journey and wrong for those that do; ask which
metric the MVP is measured by before advising cuts. MVPs suit uncertain products, not
mission-critical ones.

**Commit**: `fix: frame MVP scope by the hypothesis it tests`.

## Item 12b: an E2E-heavy distribution states its cost (book §8.1, §8.9; CTFL v4.0 §5.1.6)

**Current state.** `testing-design.md:15` and `qa-plan/SKILL.md:51` (the same preset twice; 034 may
keep one): "UI-Heavy / Interactive Canvas / Mapping: 20% Unit · 30% Integration · 50% E2E", with
no caveat. The book (§8.1, §8.9) and CTFL v4.0 §5.1.6 both describe top-layer tests as slower, more
expensive and more brittle, so few are needed.

**Target.** The preset line, wherever 034 left it (both places if both remain).

**What to write**: keep the numbers (see Decision) and add a caveat: the share is a cost accepted
because logic lives in the UI, not a goal; before accepting it, move logic out of the canvas or UI
into units that can be tested alone (item 4), use component tests and visual regression for
rendering, and check the E2E suite still fits the suite duration targets in `testing-guidelines.md`.

**Decision for Marco**: keep 20/30/50 with the caveat (default), or lower the E2E share.

**Commit**: `fix: state the cost of the UI-heavy test distribution`.

---

## Done criteria

- [ ] Every item's verify command gives the expected result; every new TypeScript sample type-checks.
- [ ] `./generate-adapters.sh --clean && ./tests/verify-adapters.sh` exits 0.
- [ ] `./tests/test-rules-size.sh`: total unchanged from before this plan.
- [ ] `./tests/test-reference-links.sh` and `./tests/test-frontmatter.sh` pass; every new reference is in the `qa-reference` contents table.
- [ ] **Citation check**: every book citation names a chapter and section that exists
      (`grep -n` the heading in `book.md`); every CTFL section cited (items 6 and 12b) passes plan
      035's citation check against the official PDF.
- [ ] **No book text**: the word 4-gram comparison the audit used finds no hit that is book text:

      ```bash
      python3 -I - "$S/book.md" $(git diff --name-only github/main...HEAD -- .claude) <<'EOF'
      import re, sys
      def grams(text, n=4):
          w = re.findall(r"\w+", text.lower())
          return {" ".join(w[i:i + n]) for i in range(len(w) - n + 1)}
      book = grams(open(sys.argv[1], encoding="utf-8").read())
      for path in sys.argv[2:]:
          hits = grams(open(path, encoding="utf-8").read()) & book
          if hits:
              print(path, sorted(hits)[:20])
      EOF
      ```

      Review each hit by hand: shared code identifiers or English terms (`continuous integration`,
      `feature flags`) are fine; any phrase of the book is not. Also confirm no book example listed
      in "Copyright and wording" appears.
- [ ] Markdown lint clean on every changed file.
- [ ] `plans/README.md` row for 036 updated; the backlog line "From the book" marked as planned.

## STOP conditions

- Plan 034 has not merged.
- An excerpt quoted above exists nowhere in the live tree (moved is fine; gone is not).
- An item would need bytes in `.claude/rules/`, or would contradict a rule (report the conflict).
- The 4-gram check finds book text you cannot rewrite without losing the point: report it.
- A section heading cited here is not in the book file (the book's numbering is from its chapter
  introductions; confirm before citing).

## Maintenance notes

- The book is cited as background; the package's rules stay the authority. If a later edition of the
  book renumbers sections, update the citations, not the guidance.
- Items 7-11 describe practice, not tools. If the package later ships pipeline templates (the
  GitLab job 034 moved, or others), link them from these sections rather than duplicating them.
- Item 12b's decision may be revisited once plan 035 item 7 places the testing quadrants next to the
  pyramid presets.

## Execution record, 2026-10-18

**Default used (Marco asked for all remaining work on 2026-10-18).** Item 12b's decision has the
documented default, which Marco had already confirmed on 2026-10-14: keep 20/30/50 and add the cost
caveat. No other item had an open decision.

**Base.** Plan 035 was not on `next` yet, and it created `testing-in-delivery.md`, the file items 7-11
append to. Every branch here starts from `next` with plan 035's four content branches merged
(`feat/ctfl-test-design`, `feat/ctfl-testing-in-delivery`, `feat/ctfl-planning`,
`fix/ctfl-wording`, PRs #149, #151, #153, #154), so each PR's diff shows 035's commits until those
land. Plan 035's record branch (#155) was not merged in.

**Pull requests.** One per item, items 7 and 8 together, as the plan says. Items that add to the same
part of a file are stacked so that no two PRs conflict; merge each stack in order:

| PR | Item | Branch | Stacked on |
| --- | --- | --- | --- |
| #158 | 1, FIRST | `feat/first-properties` | |
| #159 | 2, test smells | `feat/test-smells` | #158 |
| #160 | 3, test doubles | `feat/test-doubles` | #159 |
| #161 | 6, test code in `/qa-review` (needs 1-3) | `feat/review-test-code` | #160 |
| #162 | 4, testability remedies | `feat/testability-remedies` | |
| #163 | 5, characterization tests | `feat/characterization-tests` | |
| #164 | 7 and 8, CI preconditions and the broken build | `feat/ci-preconditions` | |
| #165 | 9, delivery or deployment | `feat/delivery-vs-deployment` | #164 |
| #166 | 10, feature flags | `feat/feature-flag-testing` | #165 |
| #167 | 11, canary and A/B | `feat/canary-ab-validity` | #166 |
| #168 | 12a, MVP | `fix/mvp-hypothesis` | |
| #169 | 12b, UI-heavy preset | `fix/ui-heavy-preset-cost` | |

All branches merged together into a scratch copy without a conflict. The README row and this record
are this separate docs PR, to merge last.

**Commits for items 7 and 8.** The plan gives one commit for both, `feat: add CI preconditions and
the broken-build rule`. Its message needs "and", which CONTRIBUTING.md's atomic-commit rule forbids,
so the PR carries two commits, one per item, and stays one PR as the plan groups it.

**Drift check.** Drift from 034 and 035 was as expected; no excerpt was gone. Moved lines: the FIRST
step of `/qa-automate` at 102 (was 606), the TDD loop at `qa-tdd.md:22-37` (was 25-29),
`qa-refinement.md:146` (was 144),
the mocking matrix at `testing-design.md:33-39` (was 31-37), the `qa-plan` preset at 49 (was 51) and
its release gate at 136-138 (was 110), the `qa-plan` feature-flag line at 90 (was 77). Item 12b's two
preset lines both still existed (034 kept both), so the caveat went into both: in full in
`testing-design.md`, short with a pointer in `qa-plan`.

**Where the book and the package differ.**

- **Conditional logic in tests.** The book calls it a smell, a warning to weigh, not a ban (§8.3);
  the `code-style-qa` rule forbids conditional assertions outright. No rule changed: the test-smells
  section says the rule decides for the two smells it already covers.
- **Mocks and stubs.** The book chooses not to separate them and uses "mock" for both (§8.6). The
  package now uses Meszaros' five kinds, because the difference decides whether a test checks state
  or calls; the section says the book does not draw the line.
- **Test distribution.** The book repeats the generic 70/20/10 split and calls system tests the
  costliest and most brittle (§8.1, §8.9). The package keeps a 50% E2E preset for UI-heavy products,
  by Marco's decision, now with the cost stated.
- **Branches and CI.** The book holds that a branch living longer than a day is incompatible with CI
  (§10.3). `automation-code.md` ("Isolate Parallel Ticket Work") recommends a branch or worktree per
  ticket. They do not contradict each other as long as those branches are short-lived, and the CI
  section says so; nothing in the reference was changed.
- **Broken build.** The rule's STOP LINE covers a failing smoke suite at the gate; the book's rule is
  about the main build. They agree; the new section extends the rule rather than changing it.

**Not attributed to the book.** Three points in the new text are the package's own and are written
without a citation: the second mocking cost (a double can disagree with the real dependency; the
book raises it only as an exercise), the canary's written halt threshold and rollback, and what QA
tests inside an A/B experiment. "Characterization test" is credited to Feathers and the double
vocabulary to Meszaros, as the plan asks.

**Verification.**

- Every item's verify command gives the expected result: `Self-checking` in `automation-code.md`
  with its check; no `all four` in `qa-review.md`; `trunk`, `continuous delivery`, `canary` and
  `A/B` now found in `testing-in-delivery.md`.
- TypeScript samples: the test-smells example (with a declaration of the function it tests) and the
  test-double example type-check with `tsc --noEmit --strict` (TypeScript 7.0.2, Vitest 3); the
  test-double example also runs and passes in Vitest. A deliberately broken copy fails the check, so
  the check is not vacuous.
- Book citations: every section cited (§3.5, §3.6, §8.1, §8.3, §8.5, §8.6, §8.9, §9.3, §9.5, §10.3,
  §10.4) exists with that number in the book file's table of contents and chapter introductions,
  with the topic the sentence gives it. CTFL citations (§3.1.1, §5.1.6) checked against the
  v4.0.1 PDF text: §3.1.1 lists test cases among examinable work products; §5.1.6 says the top
  layer's tests are slower. The cost and brittleness claim is cited to the book only.
- Book 4-gram check on every changed file under `.claude`: the only hits are the book's title and
  "Test-Driven Development (TDD)" already in `qa-tdd.md` before this plan. No banned example appears.
- `./tests/test-rules-size.sh`: 21,415 bytes on the base and on every branch; no rule was edited.
- Local CI (`bash ~/qa-ci-all.sh <worktree> linux`) on every branch, first run: 16 of 17 steps
  passed; the one failure was lifecycle Test 20 (".claude survived uninstall after a no-manifest
  upgrade"), the known failure until #146 landed. All twelve branches merged together with #146 in
  a scratch copy passed 17 of 17 (`ALL LOCAL CI (plan-036-all @ 7ef0e63): linux=PASS`).
- #146 then landed on `next`. `github/next` was merged into every branch (no conflict) and the same
  command rerun on each head: `linux=PASS`, 17 of 17, on all thirteen branches, this one included.
  Content only, so the macOS and Windows local jobs were not run.
- GitHub CI did not run on any PR: Actions billing is blocked, and CI is local only by Marco's
  decision of 2026-10-18.

**Left open.**

- Merge order: each stack in the order above. This docs PR touches the same README rows as plan
  035's record (#155); if it conflicts there, keep both rows.
