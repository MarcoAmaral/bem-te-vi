# Plan 005: Add GitHub pull request template

> **Executor instructions**: Follow this plan step by step. Run every verification command
> and confirm the expected result before moving to the next step. If anything in "STOP
> conditions" occurs, stop and report. When done, update the status row for this plan in
> `plans/README.md` — unless a reviewer dispatched you and told you they maintain the index.
>
> **Drift check (run first)**: `git diff --stat 0dc3af8..HEAD -- .github CONTRIBUTING.md`

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: dx / docs
- **Planned at**: commit `0dc3af8`, 2026-07-30

## Why this matters

`docs/specs/qa-skill-overhaul.md` §2 proposes a structured PR template. Release Please and CI
are already live (`.github/workflows/release-please.yml`, `.github/workflows/ci.yml`), but
`.github/pull_request_template.md` does not exist — GitHub currently shows contributors (and
the repo owner) a blank PR body. `CLAUDE.md` §"Git & PR Workflow" already states the process
this template should encode: title prefixed with conventional-commit type, detailed
description, explicit approval before merge.

## Current state

- `.github/` currently contains only `workflows/ci.yml` and `workflows/release-please.yml` —
  no `pull_request_template.md` (verify: `ls .github/`).
- `CONTRIBUTING.md` §2 "Conventional Commits" defines the allowed types (`feat`, `fix`, `docs`,
  `style`, `refactor`, `perf`, `test`, `chore`) and the atomic-commit "AND rule" — the template
  should point contributors back at this file rather than re-deriving the same rules inline.
- `CLAUDE.md` §"Git & PR Workflow" (repo root) states: PRs pre-fill Title (prefixed
  `feat(v2.0): ...` style) and a detailed Description; approval is required before merge.
- `.github/workflows/ci.yml` runs, on every PR: shellcheck on `install.sh`/`generate-adapters.sh`/
  `tests/test-lifecycle.sh`, markdownlint on all `.md` files, an adapter-freshness check
  (`./generate-adapters.sh --clean` must produce no diff), and `./tests/test-lifecycle.sh`. The
  template's checklist should mirror exactly these four gates so a contributor self-checks
  before CI runs, not invents new ones.

## Scope

**In scope**: `.github/pull_request_template.md` (new file only).

**Out of scope**: `CONTRIBUTING.md`, `CLAUDE.md`, CI workflow files — do not modify; only
reference them from the template.

## Git workflow

- Branch: `docs/pr-template`.
- One commit: `docs: add GitHub pull request template`.
- Do NOT push or open a PR unless instructed.

## Steps

### Step 1: Create the template

Create `.github/pull_request_template.md`:

```markdown
## Summary

<!-- What does this PR change, and why? 1-3 bullet points. -->

## Type of change

- [ ] `feat` — new feature
- [ ] `fix` — bug fix
- [ ] `docs` — documentation only
- [ ] `refactor` — no behavior change
- [ ] `test` — test-only change
- [ ] `chore` — tooling / build / auxiliary

## Checklist

- [ ] Commits follow [Conventional Commits](../CONTRIBUTING.md#2-conventional-commits) and are atomic (no "and" in any commit message)
- [ ] `./generate-adapters.sh --clean` was run and the resulting `adapters/` diff (if any) is committed
- [ ] `markdownlint "**/*.md" --ignore node_modules --ignore .git --ignore adapters` passes locally
- [ ] `./tests/test-lifecycle.sh` passes locally
- [ ] I edited source files under `.claude/`, never `adapters/` directly (see `CLAUDE.md`)

## Test plan

<!-- How did you verify this change? Commands run, manual steps, screenshots if relevant. -->
```

**Verify**: `test -f .github/pull_request_template.md && echo EXISTS`.
`npx --yes markdownlint-cli ".github/pull_request_template.md"` → exit 0.

## Test plan

No automated test — GitHub renders this file automatically on new PRs; there is no local way
to simulate that. Manual verification is Step 1's two commands.

## Done criteria

- [ ] `.github/pull_request_template.md` exists
- [ ] `npx markdownlint-cli ".github/pull_request_template.md"` exits 0
- [ ] `git status --porcelain` shows only this one new file
- [ ] `plans/README.md` row for 005 updated

## STOP conditions

- `CONTRIBUTING.md` no longer has a "2. Conventional Commits" section at that anchor — update
  the relative link target to whatever heading now covers conventional commits, or stop and
  report if none exists.

## Maintenance notes

If CI's exact gates change (new lint tool, dropped check), this checklist should be updated to
match — it's meant to mirror CI, not diverge from it.
