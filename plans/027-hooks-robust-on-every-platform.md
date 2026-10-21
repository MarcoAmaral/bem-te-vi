# Plan 027: The two shipped hooks give the right answer on every platform

> **Executor instructions**: Follow this plan step by step. Run every verification command and
> confirm the expected result before moving on. If anything in "STOP conditions" occurs, stop and
> report; do not improvise. When done, update this plan's row in `plans/README.md`.
>
> **Drift check (run first)**: `git diff --stat 5b45cfa..HEAD -- .claude/hooks tests/test-validate-tc-format.sh tests/test-check-test-evidence.sh tests/fixtures/tc-format tests/fixtures/test-evidence .github/workflows/ci.yml`
> If any of these changed since this plan was written, compare the "Current state" excerpts with the
> live files; on a mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: M (two PRs: one per hook, plus a third for CI)
- **Risk**: LOW-MED (stricter checks may newly reject malformed files that passed before)
- **Depends on**: none
- **Category**: bug, tests
- **Planned at**: commit `5b45cfa`, 2026-10-13 (audit after 4.0.0)

## Why this matters

The package ships two hooks to its users. `validate-tc-format.sh` checks every test-case file
(`TC-*.md`) against the template, and is installed as a git pre-commit hook. `check-test-evidence.sh`
is the check the evidence rule tells agents to "run first". Both were written and tested on Linux
only. It was reproduced that **a valid test-case file is rejected as soon as it has CRLF line
endings or a UTF-8 BOM** (exit 1, "File must start with '---'"). Git for Windows with
`core.autocrlf=true` and PowerShell 5.1's `Out-File -Encoding utf8` produce exactly those files, so
Windows users have their commits blocked with a misleading error. Other checks never fire (an
unclosed frontmatter passes), and the evidence checker floods CRLF files with false findings and
prints "clean" when it scanned nothing.

## Current state

### `.claude/hooks/validate-tc-format.sh` (156 lines, `set -euo pipefail`)

- `:84`: `if [[ $(head -n 1 "$FILE") != "---" ]]; then` — a CRLF first line is `---\r`, a BOM
  file starts with `\xEF\xBB\xBF---`. There is no CR or BOM handling anywhere in the file.
- `:18-26`: `check_key` runs `grep -qE "^${KEY}:" "$FILE"` over the **whole file**, so a key that
  appears only in the body (for example a `spec:` line in a step) satisfies the frontmatter check.
- `:111-118`: the closing-boundary check is dead code:

  ```bash
  if ! grep -qE "^---" "$FILE" | head -n 2 | tail -n 1 >/dev/null; then
  ```

  With `pipefail` this is true only when the file has no `---` line at all, which `:84` already
  reports, so an unclosed frontmatter passes.
- `:29-64`, `check_case_fields` (awk): `id` is reset only by a `## TC-…:` heading, so rows of a
  later non-TC section attach to the previous case; `split($0, cells, "|")` cuts a cell at any
  inner pipe; a CRLF row with no trailing pipe leaves `val` as `"\r"`, which is not reported empty.
- `:70-72`: a missing path returns 0. `:153-155`: only `$1` is validated, so
  `validate-tc-format.sh good.md bad.md` exits 0.
- `:121`: `success "Prisinte formatting! $FILE is 100% compliant ..."` — typo, and "100%
  compliant" overstates a presence check.

### `.claude/hooks/check-test-evidence.sh` (134 lines)

- `:48`: `NON_ASCII="[^ -~$(printf '\t')]"` matched under `LC_ALL=C`; a `\r` is outside that class,
  so on a CRLF spec every line containing `path:` is reported as a non-ASCII file name.
- `:73-75`: `is_probe` reads `head -n 1` and requires `^[[:space:]]*//`; a BOM defeats it.
- `:108`: `find ... -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.mjs'` misses `.cjs`,
  `.mts`, `.cts`, `.jsx`, and does not prune `node_modules`.
- `:118-134`: when no file matched, the loop does nothing and the script prints
  `check-test-evidence: clean` with exit 0.

### Tests and CI

- `tests/test-validate-tc-format.sh` uses two helpers on fixtures in `tests/fixtures/tc-format/`:
  `expect_ok <fixture>` and `expect_rejected <fixture> <message-fragment>`. Model new checks on them.
- `tests/test-check-test-evidence.sh` does the same for `tests/fixtures/test-evidence/`.
- **`.gitattributes` forces LF** on every file except `tests/conformance/cases/**`:
  `* text=auto eol=lf`. A committed CRLF fixture would be normalised to LF. **Generate CRLF and
  BOM variants at test time** into a `mktemp -d` directory, from the existing LF fixtures.
- `.github/workflows/ci.yml:141-149` runs both hook tests in the Linux job only. The Windows job
  (`test-windows`) and the macOS job never run them.

## Commands you will need

| Purpose | Command | Expected on success |
| --- | --- | --- |
| TC hook tests | `./tests/test-validate-tc-format.sh` | last line `All test case format hook tests passed` |
| Evidence tests | `./tests/test-check-test-evidence.sh` | exit 0 |
| Contract tests (they run the TC hook on templates) | `./tests/test-tc-contracts.sh` | exit 0 |
| `/qa-trace` fixture test (runs the TC hook) | `./tests/test-qa-trace.sh` | `All /qa-trace fixture checks passed` |
| Shell lint | `npx --yes shellcheck@3.1.0 .claude/hooks/*.sh tests/test-validate-tc-format.sh tests/test-check-test-evidence.sh` | no output |
| Adapters still build | `./generate-adapters.sh --clean && ./tests/verify-adapters.sh` | exit 0 |

## Scope

**In scope**: `.claude/hooks/validate-tc-format.sh`, `.claude/hooks/check-test-evidence.sh`,
`tests/test-validate-tc-format.sh`, `tests/test-check-test-evidence.sh`, new LF fixtures in
`tests/fixtures/tc-format/` and `tests/fixtures/test-evidence/`, `.github/workflows/ci.yml` (only to
run the two hook tests on Windows and macOS), `plans/README.md`.

**Out of scope**:

- The TC template itself (field names, the nine frontmatter keys, the eleven rows, the `Source`
  rule). Contracts in `tests/test-tc-contracts.sh` depend on them.
- The installers' git hooks that call the validator (plan 026).
- The `--runner-standard` rules' meaning (opt-in by design).

## Git workflow

- Branches `fix/tc-hook-line-endings`, `fix/evidence-checker-line-endings`, `ci/hook-tests-everywhere`.
- Conventional Commits, atomic, no "and" in a message. Never add AI attribution lines.
- Red first: add each failing test before the fix, run it, and keep the failing output for the PR.

## Steps

### Step 1: normalise input once in the TC hook

In `validate_file`, after the existence check, create a normalised copy:
`NORM="$(mktemp)"; trap 'rm -f "$NORM"' RETURN`, then
`LC_ALL=C sed -e '1s/^\xEF\xBB\xBF//' -e 's/\r$//' "$FILE" > "$NORM"` and run **every** check on
`"$NORM"`, while every message still names `"$FILE"`. Use `printf '\357\273\277'` instead of `\xEF`
if BSD sed (macOS) does not accept the hex escape; the macOS CI job will tell you.

**Verify**: the new tests in step 5 for `complete.md` as CRLF and as BOM pass.

### Step 2: make the frontmatter checks look only at the frontmatter

1. Fail if line 1 of `$NORM` is not `---`.
2. Find the closing `---`: `END=$(awk 'NR>1 && /^---$/ {print NR; exit}' "$NORM")`. If empty or
   greater than 40, report `Missing closing frontmatter boundary '---' in $FILE` and count one error.
3. Rewrite `check_key` to grep only `sed -n "2,$((END-1))p" "$NORM"`.
4. Delete the dead block at `:111-118`.

### Step 3: harden the case parser

In the awk program:

1. On any line matching `/^#{1,6} /` that is not a TC heading, call `flush()` and set `id = ""`.
2. Before splitting a row, replace escaped pipes: `gsub(/\\\|/, "\001")`, then split, then restore
   `\001` to `|` in `name` and `val`.
3. Warn (not fail) when a file whose name matches `TC-*.md` has no `## TC-…:` heading at all:
   `info "No '## TC-CODE-NNN:' heading found in $FILE; nothing validated"`.

### Step 4: arguments and messages

1. Loop over all arguments; exit 1 if any file fails.
2. A path that does not exist is an error (exit 1, `No such file: <path>`).
3. Replace the success line with `success "$FILE matches the TC-CODE-NNN template."`

### Step 5: tests for the TC hook

In `tests/test-validate-tc-format.sh`:

- Add a helper `variant <fixture> <crlf|bom>` that writes the converted file to a `mktemp -d`
  directory and prints its path; teach `expect_ok`/`expect_rejected` to accept an absolute path.
- New expectations: `complete.md` as CRLF passes; as BOM passes; `empty-field.md` as CRLF is
  rejected with `has an empty template field 'Manual Env'`.
- New LF fixtures: `unclosed-frontmatter.md` (rejected, `Missing closing frontmatter boundary`),
  `key-only-in-body.md` (frontmatter lacks `spec:`, a step contains `spec: x`; rejected with
  `Missing required frontmatter key: 'spec'`), `source-with-pipe.md` (Source
  `Added by QA (a \| b)`; passes), `rows-after-non-tc-section.md` (a TC missing `Note`, followed by
  `## Notes` with a `| **Note** | x |` table; rejected with `missing template field 'Note'`).
- Two-argument call: `complete.md missing-field.md` exits 1. Missing path exits 1.

**Verify**: `./tests/test-validate-tc-format.sh`, `./tests/test-tc-contracts.sh` and
`./tests/test-qa-trace.sh` all pass.

### Step 6: the evidence checker

1. In `check_file`, scan a normalised copy (same `sed` as step 1); report the original path and
   line numbers (unchanged, since only a BOM and trailing CRs are removed).
2. Extend `find` to `*.ts *.tsx *.mts *.cts *.js *.jsx *.mjs *.cjs`, and prune `node_modules`,
   `dist` and `.git`.
3. Count the files scanned. When it is 0, print `check-test-evidence: no spec files found in <args>`
   to stderr and exit 2. On success print `check-test-evidence: clean (N files)`.

### Step 7: tests for the evidence checker

In `tests/test-check-test-evidence.sh`: `clean.spec.ts` as CRLF is clean; `probe.spec.ts` with a BOM
is still treated as a probe; a directory holding only `README.md` exits 2; a `.cjs` copy of
`full-page.spec.ts` is found. Update any existing assertion on the exact `clean` line.

### Step 8: run the hook tests on Windows and macOS

In `.github/workflows/ci.yml`, add to the macOS job and to the Windows job (with `shell: bash`,
which is Git Bash on the Windows runner) steps that run `./tests/test-validate-tc-format.sh` and
`./tests/test-check-test-evidence.sh`. Copy the step shape from the Linux job (`ci.yml:141-149`).

**Verify**: the PR's CI shows both steps passing on all three runners.

## Done criteria

- [ ] A CRLF copy and a BOM copy of `tests/fixtures/tc-format/complete.md` pass the TC hook.
- [ ] `grep -n 'head -n 2 | tail -n 1' .claude/hooks/validate-tc-format.sh` → no match.
- [ ] `grep -n 'Prisinte' .claude/hooks/*.sh` → no match.
- [ ] `./tests/test-validate-tc-format.sh`, `./tests/test-check-test-evidence.sh`,
      `./tests/test-tc-contracts.sh`, `./tests/test-qa-trace.sh` pass.
- [ ] `.claude/hooks/check-test-evidence.sh /tmp/empty-dir` exits 2.
- [ ] CI runs both hook tests on Linux, macOS and Windows, all green.
- [ ] `./generate-known-hashes.sh --check` passes (hooks are new unreleased content; it should be
      unaffected, but confirm).
- [ ] `plans/README.md` row for 027 updated.

## STOP conditions

- An existing fixture, an `examples/` test-case file or `tests/test-tc-contracts.sh` starts failing
  after step 2 or 3 and the cause is a real template problem rather than the stricter check:
  report which file and why instead of loosening the check.
- BSD sed or awk on macOS cannot express a step and no POSIX alternative is obvious.
- The Windows runner's bash cannot run the tests (for example `mktemp` missing).

## Maintenance notes

- The validator is also run by the installers' git hooks and by `tests/test-tc-contracts.sh`; any
  new check is user-visible on the next commit of every installed project. Keep new checks to
  real defects.
- If the template gains a field, update the awk `REQ` list, the qa-writer agent, `/qa-cases` and the
  contracts test together (they are tested together by `tests/test-tc-contracts.sh`).
