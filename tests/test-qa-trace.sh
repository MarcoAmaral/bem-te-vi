#!/usr/bin/env bash
# tests/test-qa-trace.sh — the /qa-trace fixture's expected report is consistent with its inputs.
#
# /qa-trace is prompt text, so no script can run it. What a script can check is the worked example
# the command is held to: a ticket folder (requirements.md, testcases.md, results.txt) and the
# report expected-trace.md says the command must produce from it. Every fact in that report that
# can be derived mechanically is derived here from the inputs and compared:
#
#   - every requirement appears in the Coverage table, and no unknown requirement does
#   - a link is "traced" exactly when the test case's Note says "Traces to <requirement>" or its Source
#     row cites the AC-n that requirements.md gives the requirement as its Origin;
#     anything else is "inferred" — an inferred link is never promoted to traced, and a recorded
#     trace is never dropped or downgraded
#   - Technique and Automation match the test case's ISTQB Technique row and automation tag
#   - Last result matches results.txt, and a case with no result reads "not run", never "pass"
#   - the Gaps table lists exactly the gaps the inputs imply, in the documented order, with
#     sequential TR-NNN IDs (so a re-run produces the same IDs)
#   - the Metrics figures are the ones the Coverage table implies
#   - the fixture's test cases pass the TC format hook, so the example uses the real format
#
# Usage: tests/test-qa-trace.sh [ticket-folder]   (default: the password-reset fixture)

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIR="${1:-$ROOT/tests/fixtures/qa-trace/password-reset}"
REQS="$DIR/requirements.md"
TCS="$DIR/testcases.md"
RESULTS="$DIR/results.txt"
EXPECTED="$DIR/expected-trace.md"
HOOK="$ROOT/.claude/hooks/validate-tc-format.sh"
FAILS=0

pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; FAILS=$((FAILS + 1)); }

# expect_eq <label> <got> <want>
expect_eq() {
  if [ "$2" = "$3" ]; then pass "$1: $2"; else fail "$1: report says '$2', expected '$3'"; fi
}

# Requirement IDs: item n of the numbered list in requirements.md is REQ-n.
req_ids() { sed -n 's/^\([0-9][0-9]*\)\. .*/REQ-\1/p' "$REQS"; }

# Test case IDs, in file order.
tc_ids() { sed -n 's/^## \(TC-[A-Z0-9]*-[0-9]*\):.*/\1/p' "$TCS"; }

# tc_field <TC-ID> <field label>: the value of that row in that test case's table.
tc_field() {
  awk -v tc="$1" -v label="**$2**" '
    /^## TC-/ { inside = (index($0, "## " tc ":") == 1); next }
    inside && /^\|/ {
      n = split($0, c, "|"); key = c[2]; val = c[3]
      gsub(/^ +| +$/, "", key); gsub(/^ +| +$/, "", val)
      if (key == label) { print val; exit }
    }' "$TCS"
}

# Automation status from the test case's tags.
tc_automation() {
  case "$(tc_field "$1" Tags)" in
    *@automated*)   echo automated ;;
    *@candidate*)   echo candidate ;;
    *@manual-only*) echo manual-only ;;
    *)              echo unknown ;;
  esac
}

# The requirement IDs a test case traces to, one per line: those its Note names, and those whose
# `Origin: AC-n` in requirements.md is an AC-n its Source row cites.
tc_traces() {
  tc_field "$1" Note | grep -oE 'Traces to (REQ-[0-9]+(, )?)+' | grep -oE 'REQ-[0-9]+'
  tc_field "$1" Source | grep -oE 'AC-[0-9]+' | while IFS= read -r ac; do
    sed -n "s/^\([0-9][0-9]*\)\. .*Origin: $ac\([^0-9].*\)\{0,1\}\$/REQ-\1/p" "$REQS"
  done
}

# Last result of a test case in results.txt, or "not run".
tc_result() {
  local r
  r="$(awk -v tc="$1" '$2 == tc { print $1; exit }' "$RESULTS")"
  printf '%s\n' "${r:-not run}"
}

# Rows of the table under a level-2 heading, as trimmed cells joined by "|", header excluded.
table_rows() {
  awk -v want="## $1" '
    $0 == want { inside = 1; next }
    inside && /^## / { inside = 0 }
    inside && /^\|/ {
      if (++row <= 2) next
      n = split($0, c, "|"); out = ""
      for (i = 2; i < n; i++) { v = c[i]; gsub(/^ +| +$/, "", v); out = out (i > 2 ? "|" : "") v }
      print out
    }' "$EXPECTED"
}

for f in "$REQS" "$TCS" "$RESULTS" "$EXPECTED"; do
  [ -f "$f" ] || { echo "FAIL  missing fixture file ${f#"$ROOT"/}"; exit 1; }
done

# 1. The fixture's test cases are in the real TC format.
if "$HOOK" "$TCS" >/dev/null 2>&1; then
  pass "fixture test cases pass the TC format hook"
else
  fail "fixture test cases are rejected by $HOOK"
fi

COVERAGE="$(table_rows Coverage)"

# 2. Every requirement has a Coverage row; no row names an unknown requirement.
for req in $(req_ids); do
  if printf '%s\n' "$COVERAGE" | grep -q "^$req|"; then
    pass "$req has a Coverage row"
  else
    fail "$req is missing from the Coverage table"
  fi
done
printf '%s\n' "$COVERAGE" | cut -d'|' -f1 | sort -u | while IFS= read -r req; do
  req_ids | grep -qx "$req" || echo "FAIL  Coverage names $req, which is not in requirements.md"
done | grep . && FAILS=$((FAILS + 1))

# 3. Each Coverage row agrees with the test case and the results.
while IFS='|' read -r req tc tech auto basis result; do
  [ -n "$req" ] || continue
  if [ "$tc" = "—" ]; then
    others="$(printf '%s\n' "$COVERAGE" | grep -c "^$req|TC-")"
    if [ "$others" -eq 0 ] && [ "$tech|$auto|$basis|$result" = "—|—|—|—" ]; then
      pass "$req: uncovered row is empty and the requirement has no other row"
    else
      fail "$req: an uncovered row must be all dashes and the only row for the requirement"
    fi
    continue
  fi
  if ! tc_ids | grep -qx "$tc"; then
    fail "$req: Coverage names $tc, which is not in testcases.md"
    continue
  fi
  if tc_traces "$tc" | grep -qx "$req"; then want_basis=traced; else want_basis=inferred; fi
  expect_eq "$req → $tc link basis (from the Note)" "$basis" "$want_basis"
  expect_eq "$req → $tc technique" "$tech" "$(tc_field "$tc" "ISTQB Technique")"
  expect_eq "$req → $tc automation (from the tags)" "$auto" "$(tc_automation "$tc")"
  expect_eq "$req → $tc last result (from results.txt)" "$result" "$(tc_result "$tc")"
done <<EOF
$COVERAGE
EOF

# 4. A trace recorded in a Note is never dropped from the report.
for tc in $(tc_ids); do
  for req in $(tc_traces "$tc"); do
    printf '%s\n' "$COVERAGE" | grep -q "^$req|$tc|" \
      || fail "$tc traces to $req in its Note, but the Coverage table has no such row"
  done
done

# 5. The gaps the inputs imply, in the documented order: No test, Inferred only, No passing test
#    (per requirement, in requirement order), then No requirement (per test case, in file order).
want_gaps="$(
  for req in $(req_ids); do
    printf '%s\n' "$COVERAGE" | grep -q "^$req|TC-" || echo "No test|$req"
  done
  for req in $(req_ids); do
    rows="$(printf '%s\n' "$COVERAGE" | grep "^$req|TC-")"
    [ -n "$rows" ] || continue
    printf '%s\n' "$rows" | cut -d'|' -f5 | grep -qx traced || echo "Inferred only|$req"
  done
  for req in $(req_ids); do
    rows="$(printf '%s\n' "$COVERAGE" | grep "^$req|TC-")"
    [ -n "$rows" ] || continue
    printf '%s\n' "$rows" | cut -d'|' -f6 | grep -qx pass || echo "No passing test|$req"
  done
  for tc in $(tc_ids); do
    printf '%s\n' "$COVERAGE" | cut -d'|' -f2 | grep -qx "$tc" || echo "No requirement|$tc"
  done
)"
GAPS="$(table_rows Gaps)"
got_gaps="$(printf '%s\n' "$GAPS" | cut -d'|' -f2,3)"
if [ "$got_gaps" = "$want_gaps" ]; then
  pass "Gaps table lists exactly the implied gaps, in order"
else
  fail "Gaps table differs from the gaps the inputs imply"
  printf '  expected:\n%s\n  got:\n%s\n' "$want_gaps" "$got_gaps"
fi
want_ids="$(i=0; printf '%s\n' "$GAPS" | while IFS= read -r _; do i=$((i + 1)); printf 'TR-%03d\n' "$i"; done)"
got_ids="$(printf '%s\n' "$GAPS" | cut -d'|' -f1)"
expect_eq "gap IDs run TR-001, TR-002, ... in table order" "$got_ids" "$want_ids"

# 6. Metrics follow from the Coverage table.
total="$(req_ids | wc -l | tr -d ' ')"
count_reqs() { printf '%s\n' "$COVERAGE" | awk -F'|' -v col="$1" -v val="$2" \
  '$2 ~ /^TC-/ && (col == 0 || $col == val) { print $1 }' | sort -u | wc -l | tr -d ' '; }
pct() { echo $(( $1 * 100 / total )); }
tested="$(count_reqs 0 x)"
traced="$(count_reqs 5 traced)"
passing="$(count_reqs 6 pass)"
ntc="$(tc_ids | wc -l | tr -d ' ')"
orphans="$(printf '%s\n' "$want_gaps" | grep -c '^No requirement|')"
for line in \
  "- Requirements: $total" \
  "- With at least one test (traced or inferred): $tested of $total ($(pct "$tested")%)" \
  "- With at least one traced test: $traced of $total ($(pct "$traced")%)" \
  "- With at least one passing test: $passing of $total ($(pct "$passing")%)" \
  "- Test cases: $ntc; with no requirement: $orphans"; do
  if grep -qxF -- "$line" "$EXPECTED"; then pass "metric: ${line#- }"; else fail "metric line missing or wrong: '$line'"; fi
done

if [ "$FAILS" -ne 0 ]; then
  printf '%s check(s) failed\n' "$FAILS"
  exit 1
fi
echo "All /qa-trace fixture checks passed"
