#!/usr/bin/env bash
# tests/test-validate-tc-format.sh — runs the test-case format hook against fixture files.
# Asserts the exit code and that the error names the missing field.

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$ROOT/.claude/hooks/validate-tc-format.sh"
FIX="$ROOT/tests/fixtures/tc-format"
FAILS=0
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; FAILS=$((FAILS + 1)); }

# fixture_path <fixture-or-absolute-path>
fixture_path() {
  case "$1" in
    /*) printf '%s' "$1" ;;
    *) printf '%s' "$FIX/$1" ;;
  esac
}

# variant <fixture> <crlf|bom>: writes a converted copy of an LF fixture and prints its path.
# .gitattributes forces LF on committed files, so these variants exist only at test time.
variant() {
  local dst="$TMP/$2-$1"
  case "$2" in
    crlf) awk '{ printf "%s\r\n", $0 }' "$FIX/$1" > "$dst" ;;
    bom) { printf '\357\273\277'; cat "$FIX/$1"; } > "$dst" ;;
  esac
  printf '%s' "$dst"
}

# expect_ok <fixture-or-absolute-path>
expect_ok() {
  local out rc
  out="$("$HOOK" "$(fixture_path "$1")" 2>&1)"
  rc=$?
  if [ "$rc" -eq 0 ]; then pass "$1 passes"; else fail "$1: expected exit 0, got $rc"; printf '%s\n' "$out"; fi
}

# expect_rejected <fixture-or-absolute-path> <message-fragment>
expect_rejected() {
  local out rc
  out="$("$HOOK" "$(fixture_path "$1")" 2>&1)"
  rc=$?
  if [ "$rc" -eq 1 ] && printf '%s\n' "$out" | grep -q "$2"; then
    pass "$1 rejected ($2)"
  else
    fail "$1: expected exit 1 mentioning '$2', got $rc"
    printf '%s\n' "$out"
  fi
}

expect_ok complete.md
expect_ok na-reason.md

# The runbook key: `runbook` is its name; `cdt`, its old name, still passes and is reported.
expect_ok runbook-key.md
out="$("$HOOK" "$FIX/complete.md" 2>&1)"
if printf '%s\n' "$out" | grep -q "'cdt' is the old name of 'runbook'"; then
  pass "complete.md (cdt) is reported as the old name of runbook"
else
  fail "complete.md (cdt): expected the old-name notice"; printf '%s\n' "$out"
fi
out="$("$HOOK" "$FIX/runbook-key.md" 2>&1)"
if printf '%s\n' "$out" | grep -q "old name"; then
  fail "runbook-key.md: no old-name notice expected"; printf '%s\n' "$out"
else
  pass "runbook-key.md carries no old-name notice"
fi
grep -v '^cdt:' "$FIX/complete.md" > "$TMP/no-runbook-key.md"
expect_rejected "$TMP/no-runbook-key.md" "Missing required frontmatter key: 'runbook'"
expect_rejected missing-field.md "TC-AUTH-001 is missing template field 'Manual Env'"
expect_rejected empty-field.md "TC-AUTH-001 has an empty template field 'Manual Env'"
expect_rejected missing-frontmatter-key.md "Missing required frontmatter key: 'tracker_issues'"

# Every case names its origin: an acceptance criterion, or "Added by QA (<reason>)".
expect_ok source-added-by-qa.md
expect_ok source-ac-multiple.md
expect_rejected source-missing.md "TC-AUTH-001 is missing template field 'Source'"
expect_rejected source-empty.md "TC-AUTH-001 has an empty template field 'Source'"
expect_rejected source-vague.md "TC-AUTH-001 has a Source that is neither an AC nor 'Added by QA (reason)'"
expect_rejected source-added-no-reason.md "TC-AUTH-001 has a Source that is neither an AC nor 'Added by QA (reason)'"

# Windows hands the hook CRLF files (core.autocrlf, PowerShell 5.1 Out-File) and BOMs.
expect_ok "$(variant complete.md crlf)"
expect_ok "$(variant complete.md bom)"
expect_rejected "$(variant empty-field.md crlf)" "has an empty template field 'Manual Env'"

# The closing frontmatter boundary is required.
expect_rejected unclosed-frontmatter.md "Missing closing frontmatter boundary"

# A key counts only inside the frontmatter, never in the body.
expect_rejected key-only-in-body.md "Missing required frontmatter key: 'spec'"

# A table cell may hold an escaped pipe; rows of a later section belong to no case.
expect_ok source-with-pipe.md
expect_rejected rows-after-non-tc-section.md "TC-AUTH-001 is missing template field 'Note'"

# A file named TC-*.md with no case heading is not silently ignored.
printf '# Nothing here\n' > "$TMP/TC-no-heading.md"
out="$("$HOOK" "$TMP/TC-no-heading.md" 2>&1)"
rc=$?
if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -q "No '## TC-CODE-NNN:' heading found"; then
  pass "TC-no-heading.md warns that nothing was validated"
else
  fail "TC-no-heading.md: expected exit 0 with a warning, got $rc"; printf '%s\n' "$out"
fi

# Every file passed is validated, not only the first.
"$HOOK" "$FIX/complete.md" "$FIX/missing-field.md" >/dev/null 2>&1
rc=$?
if [ "$rc" -eq 1 ]; then pass "complete.md then missing-field.md exits 1"; else fail "two files, second bad: expected exit 1, got $rc"; fi

# A path that does not exist is an error, not a pass.
out="$("$HOOK" "$FIX/does-not-exist.md" 2>&1)"
rc=$?
if [ "$rc" -eq 1 ] && printf '%s\n' "$out" | grep -q "No such file: $FIX/does-not-exist.md"; then
  pass "missing path exits 1 (No such file)"
else
  fail "missing path: expected exit 1 naming the file, got $rc"; printf '%s\n' "$out"
fi

# The success line states what was checked, without overclaiming.
out="$("$HOOK" "$FIX/complete.md" 2>&1)"
if printf '%s\n' "$out" | grep -q "complete.md matches the TC-CODE-NNN template\."; then
  pass "success message names the template"
else
  fail "success message: expected 'matches the TC-CODE-NNN template.'"; printf '%s\n' "$out"
fi

# A template shown inside a code fence is documentation, not a test case.
expect_ok fenced-example.md

# The workspace scan skips a runbook: it carries `## TC-` headings but is not a test-case file.
# Runbooks are recognised by the `tc_ids` frontmatter key of the /qa-cases runbook template.
WS="$TMP/workspace"
mkdir -p "$WS/runbooks"
cat > "$WS/runbooks/RB-AUTH-login.md" <<'RUNBOOK'
---
feature: Login
feature_code: AUTH
tc_ids: [TC-AUTH-001]
last_updated: 2026-10-16
---

# Runbook — Login

## TC-AUTH-001: Sign in with valid credentials

**Precondition:** The account exists.
**Steps:**

1. Open the sign-in page.
**Expected result:** The dashboard loads.
**Status:** NOT RUN
RUNBOOK
out="$(cd "$WS" && "$HOOK" 2>&1)"
rc=$?
if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -q "No test case files found in the workspace"; then
  pass "workspace scan skips a runbook"
else
  fail "workspace scan: a runbook must not be validated as a test-case file (exit $rc)"; printf '%s\n' "$out"
fi

if [ "$FAILS" -ne 0 ]; then
  printf '%s check(s) failed\n' "$FAILS"
  exit 1
fi
echo "All test case format hook tests passed"
