# Plan 007: Add conventional-commits.md and linting-standards.md rules for target repos

> **Executor instructions**: Follow this plan step by step. Run every verification command
> and confirm the expected result before moving to the next step. If anything in "STOP
> conditions" occurs, stop and report. When done, update the status row for this plan in
> `plans/README.md` — unless a reviewer dispatched you and told you they maintain the index.
>
> **Drift check (run first)**: `git diff --stat 0dc3af8..HEAD -- .claude/rules .claude/commands/qa.md`

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: direction (feature)
- **Planned at**: commit `0dc3af8`, 2026-07-30

## Why this matters

`docs/specs/qa-skill-overhaul.md` §4 asks for two new rule files that ship to **target
repos** (the projects that install this package, not this repo itself — distinct from plan
006, which is tooling for developing *this* package): `conventional-commits.md` (enforce
conventional commits for AI-generated commits in consuming projects) and
`linting-standards.md` (instruct the AI to adhere to whatever linting setup the target repo
already has, rather than imposing this package's own opinions). Today `.claude/rules/`
contains four rules (`accessibility-qa.md`, `code-style-qa.md`, `security-qa.md`,
`testing-guidelines.md`) — all QA-technique rules — but nothing about commit hygiene or
respecting a host repo's existing lint config. This is a same-shaped, much smaller version of
plan 003's pattern: two new files following an existing convention, wired into `qa.md`, and
picked up automatically by `generate-adapters.sh`.

## Current state

- `.claude/rules/code-style-qa.md` §"Git & Version Control Standards" (bottom of file)
  already documents Atomic Commits (one concept per commit, "AND rule", conventional-commit
  format) — but scoped specifically to *test automation code*. The new
  `conventional-commits.md` rule should be the general-purpose version of this guidance for
  **all** commits an AI makes in a target repo (not just test code), and should reference this
  existing section as prior art rather than duplicating its wording, to avoid the two rules
  drifting apart on the same topic.
- Rule file convention (see any of the four existing files, e.g. `.claude/rules/security-qa.md`):
  starts with `# Title`, then a `> **Bold tag** | Tag | Tag | Tag` blockquote line, then a
  one-paragraph intro stating when AI agents must apply the rule, then `---`-separated `##`
  sections.
- `.claude/commands/qa.md` "Declarative Rules & Auto-loaded Skills" list (bullet list, see
  existing bullets like
  `` - **Testing Rules** (`rules/testing-guidelines.md`): Applied automatically to govern... ``)
  is where new rules get registered so they're discoverable via `/qa`.
- `generate-adapters.sh` lines 42–53 already walk **every** file under `.claude/rules/*.md`
  and append it into the merged adapter blob — no compiler changes needed, same as plan 003's
  agents.

## Scope

**In scope**:

- `.claude/rules/conventional-commits.md` (new)
- `.claude/rules/linting-standards.md` (new)
- `.claude/commands/qa.md` (modify — add two bullets to "Declarative Rules & Auto-loaded
  Skills"; do not touch any other section of this file)
- `adapters/**` (regenerated only, via `./generate-adapters.sh --clean`)

**Out of scope**:

- `.claude/rules/code-style-qa.md` — do not edit its existing "Git & Version Control
  Standards" section; the new rule references it, doesn't replace it.
- `CONTRIBUTING.md`, root `CLAUDE.md` — those govern *this* repo's own contribution process
  and are unrelated to what ships to target repos.
- `generate-adapters.sh` — no change needed.

## Git workflow

- Branch: `feat/target-repo-rules`.
- Commits:
  1. `feat: add conventional-commits rule for AI-generated commits in target repos`
  2. `feat: add linting-standards rule to respect target repo lint config`
  3. `docs: register new rules in qa dispatcher`
  4. `chore: regenerate adapters for target-repo rules`
- Do NOT push or open a PR unless instructed.

## Steps

### Step 1: Create `conventional-commits.md`

Create `.claude/rules/conventional-commits.md`, matching the existing rule-file convention
(title, blockquote tag line, intro paragraph, `##` sections):

- Title: `# Conventional Commits Rules & Guidelines`
- Cover: the standard type list (`feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`,
  `chore`) with one-line meaning each; the atomic-commit rule ("one concept per commit"; if
  the message needs "and", split it) **stated as a cross-reference** to
  `.claude/rules/code-style-qa.md` §"Atomic Commits" rather than restated verbatim (name the
  file and section explicitly so a reader knows where the canonical wording lives); breaking
  change notation (`!` suffix or `BREAKING CHANGE:` footer).
- State explicitly: this rule applies to commits the AI makes **in the target/consuming
  repository**, not to this `qa-skills` package's own repo (which has its own
  `CONTRIBUTING.md`).

**Verify**: `head -3 .claude/rules/conventional-commits.md` shows the title/blockquote shape
matching the other four rule files. `grep -n "code-style-qa.md" .claude/rules/conventional-commits.md`
confirms the cross-reference exists instead of duplicated wording.

### Step 2: Create `linting-standards.md`

Create `.claude/rules/linting-standards.md`:

- Title: `# Linting Standards Rules & Guidelines`
- Core instruction: before writing or editing any code in a target repo, the AI must detect
  and respect the repo's **existing** lint/format configuration (ESLint, Prettier, Stylelint,
  Rubocop, golangci-lint, etc. — whatever config files are present, e.g. `.eslintrc*`,
  `.prettierrc*`, `pyproject.toml` `[tool.ruff]`, etc.) rather than imposing this package's own
  opinions or a different style. If no lint config exists in the target repo, the AI should
  not silently invent one — it should follow the target repo's *observed* code style (existing
  file conventions) and only propose adding tooling if explicitly asked.
- State explicitly: this rule is about the **target repo's own code**, not about linting this
  `qa-skills` package itself (that's plan 006's concern, scoped to this repo only).

**Verify**: `grep -n "existing" .claude/rules/linting-standards.md` shows the "respect what's
already there" instruction is present, not a prescriptive style of its own.

### Step 3: Register both rules in `qa.md`

Add two bullets to the "Declarative Rules & Auto-loaded Skills" list in
`.claude/commands/qa.md`, matching the existing bullet format exactly:

```markdown
- **Conventional Commits Rule** (`rules/conventional-commits.md`): Applied automatically to govern commit message format and atomicity when the AI commits on behalf of the user.
- **Linting Standards Rule** (`rules/linting-standards.md`): Applied automatically to ensure the AI respects the target repo's existing lint/format configuration instead of imposing its own.
```

**Verify**: `grep -n "conventional-commits.md\|linting-standards.md" .claude/commands/qa.md`
returns 2 matches.

### Step 4: Regenerate adapters

Run `./generate-adapters.sh --clean`.

**Verify**: exits 0, "All adapters generated (7 files)". Then confirm presence in all 7:
`for f in adapters/cursor/qa.mdc adapters/windsurf/qa.md adapters/copilot/copilot-instructions.md adapters/cline/.clinerules adapters/antigravity/qa/SKILL.md adapters/universal/AGENTS.md adapters/universal/CLAUDE.md; do grep -q "conventional-commits" "$f" || echo "MISSING $f"; done`
→ no output.

## Test plan

No automated test validates rule *content*. Manual verification is Steps 1–4's grep checks,
plus `npx markdownlint-cli ".claude/rules/conventional-commits.md" ".claude/rules/linting-standards.md" ".claude/commands/qa.md"`
→ exit 0, and `./tests/test-lifecycle.sh` → exits 0.

## Done criteria

- [ ] Both new rule files exist, matching the existing header convention
- [ ] `grep -n "conventional-commits.md\|linting-standards.md" .claude/commands/qa.md` returns 2 matches
- [ ] `./generate-adapters.sh --clean` exits 0; both new rules present in all 7 adapters
- [ ] `npx markdownlint-cli` on the 3 changed/new files exits 0
- [ ] `./tests/test-lifecycle.sh` exits 0
- [ ] `git status --porcelain` shows only the in-scope files changed
- [ ] `plans/README.md` row for 007 updated

## STOP conditions

- `.claude/rules/code-style-qa.md`'s "Atomic Commits" section (or its heading) no longer
  exists to cross-reference — re-verify the section name before assuming it's still there.

## Maintenance notes

- If this repo's own commit tooling (plan 006's commitlint) and this rule
  (`conventional-commits.md`, for target repos) ever diverge on the allowed type list, reconcile
  them — they describe the same convention at two different layers (enforced here via husky,
  documented there for AI-authored commits elsewhere).
