## Summary

<!-- What does this PR change, and why? 1-3 bullet points. -->

## Type of change

- [ ] `feat` — new feature
- [ ] `fix` — bug fix
- [ ] `docs` — documentation only
- [ ] `style` — formatting only, no change in meaning
- [ ] `refactor` — no behavior change
- [ ] `perf` — performance improvement
- [ ] `test` — test-only change
- [ ] `chore` — tooling / auxiliary
- [ ] `ci` — CI configuration or scripts
- [ ] `build` — build system or dependencies
- [ ] `revert` — reverts a previous commit

## Checklist

- [ ] Commits follow [Conventional Commits](../CONTRIBUTING.md#2-conventional-commits) and are atomic (no "and" in any commit message)
- [ ] `./generate-adapters.sh --clean` and `./tests/verify-adapters.sh` pass (`adapters/` is generated and not committed)
- [ ] `markdownlint --dot "**/*.md" --ignore node_modules --ignore .git --ignore adapters` passes locally
- [ ] The other [checks](../CONTRIBUTING.md#running-the-checks-locally) that cover what I changed pass locally (`./tests/test-lifecycle.sh` and `./tests/conformance/run.sh` for an installer)
- [ ] I edited source files under `.claude/`, never `adapters/` directly (see `CLAUDE.md`)
- [ ] Every syllabus claim I added cites its CTFL v4.0.1 section ([the evidence bar](../CONTRIBUTING.md#8-the-evidence-bar))
- [ ] For an installer change: the test I wrote first failed before the fix, and its output is quoted below

## Test plan

<!-- How did you verify this change? Commands run, manual steps, screenshots if relevant. -->
