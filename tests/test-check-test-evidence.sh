#!/usr/bin/env bash
# tests/test-check-test-evidence.sh — runs the evidence checker against fixture specs.
# Asserts exit codes and the file:line each violation is reported at.

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHECKER="$ROOT/.claude/hooks/check-test-evidence.sh"
FIX="$ROOT/tests/fixtures/test-evidence"
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

# expect_violation <fixture-or-absolute-path> <line> <message-fragment> [checker args placed before the fixture]
expect_violation() {
  local out rc
  out="$("$CHECKER" "${@:4}" "$(fixture_path "$1")" 2>&1)"
  rc=$?
  if [ "$rc" -eq 1 ] && printf '%s\n' "$out" | grep -q "$1:$2: .*$3" \
    && [ "$(printf '%s\n' "$out" | grep -c 'fix: ')" -eq 1 ]; then
    pass "$1 reported at line $2 ($3)"
  else
    fail "$1: expected exit 1 and exactly one finding at line $2 ($3); got exit $rc"
    printf '%s\n' "$out"
  fi
}

out="$("$CHECKER" "$FIX/clean.spec.ts" 2>&1)"
rc=$?
if [ "$rc" -eq 0 ]; then pass "clean.spec.ts exits 0"; else fail "clean.spec.ts exited $rc"; printf '%s\n' "$out"; fi

expect_violation full-page.spec.ts 4 "full-page screenshot"
expect_violation element.spec.ts 4 "element-level screenshot"
expect_violation non-ascii.spec.ts 4 "non-ASCII"

# The goto and click rules are opt-in (--runner-standard or EVIDENCE_RUNNER_STANDARD=1).
expect_violation goto-no-reason.spec.ts 4 "page.goto" --runner-standard
expect_violation bare-click.spec.ts 4 "bare .click" --runner-standard
expect_violation qualified-click.spec.ts 5 "bare .click" --runner-standard
expect_violation probe-capture.spec.ts 5 "probe"

# expect_clean <description> <fixture-or-absolute-path> [checker args placed before the fixture]
expect_clean() {
  local desc="$1" fixture="$2" out rc
  shift 2
  out="$("$CHECKER" "$@" "$(fixture_path "$fixture")" 2>&1)"
  rc=$?
  if [ "$rc" -eq 0 ]; then pass "$desc"; else fail "$desc: exited $rc"; printf '%s\n' "$out"; fi
}

expect_clean "goto-ok.spec.ts (same-line and preceding-line reasons) exits 0" goto-ok.spec.ts --runner-standard
expect_clean "click-helper.spec.ts (default helper) exits 0" click-helper.spec.ts --runner-standard
expect_clean "probe.spec.ts (goto and click exempt) exits 0" probe.spec.ts --runner-standard
expect_clean "--click-helper ui.click accepts a namespaced helper" qualified-click.spec.ts --runner-standard --click-helper ui.click
expect_clean "goto without a reason is not flagged by default" goto-no-reason.spec.ts
expect_clean "a bare .click( is not flagged by default" bare-click.spec.ts

# Windows hands the checker CRLF files (core.autocrlf) and BOMs (PowerShell 5.1 Out-File).
expect_clean "clean.spec.ts as CRLF exits 0" "$(variant clean.spec.ts crlf)"
expect_violation "$(variant full-page.spec.ts crlf)" 4 "full-page screenshot"
expect_clean "probe.spec.ts with a BOM is still a probe" "$(variant probe.spec.ts bom)" --runner-standard

out="$(EVIDENCE_CLICK_HELPERS="foo.click,ui.click" "$CHECKER" --runner-standard "$FIX/qualified-click.spec.ts" 2>&1)"
rc=$?
if [ "$rc" -eq 0 ]; then pass "EVIDENCE_CLICK_HELPERS accepts a namespaced helper"; else fail "EVIDENCE_CLICK_HELPERS: exited $rc"; printf '%s\n' "$out"; fi

out="$(EVIDENCE_RUNNER_STANDARD=1 "$CHECKER" "$FIX/bare-click.spec.ts" 2>&1)"
rc=$?
if [ "$rc" -eq 1 ]; then pass "EVIDENCE_RUNNER_STANDARD=1 turns the runner rules on"; else fail "EVIDENCE_RUNNER_STANDARD=1: exited $rc"; printf '%s\n' "$out"; fi

"$CHECKER" "$FIX" >/dev/null 2>&1
rc=$?
if [ "$rc" -eq 1 ]; then pass "directory scan exits 1 when any fixture violates"; else fail "directory scan exited $rc"; fi

"$CHECKER" "$FIX/does-not-exist" >/dev/null 2>&1
rc=$?
if [ "$rc" -eq 2 ]; then pass "missing path exits 2"; else fail "missing path exited $rc"; fi

# A scan that read nothing must not report "clean".
mkdir "$TMP/docs-only"
printf '# Notes\n' > "$TMP/docs-only/README.md"
out="$("$CHECKER" "$TMP/docs-only" 2>&1)"
rc=$?
if [ "$rc" -eq 2 ] && printf '%s\n' "$out" | grep -q "no spec files found in $TMP/docs-only"; then
  pass "a directory with no spec files exits 2"
else
  fail "directory with no spec files: expected exit 2 naming it, got $rc"; printf '%s\n' "$out"
fi

# The success line says how many files were read.
mkdir "$TMP/two-clean"
cp "$FIX/clean.spec.ts" "$TMP/two-clean/a.spec.ts"
cp "$FIX/clean.spec.ts" "$TMP/two-clean/b.spec.ts"
out="$("$CHECKER" "$TMP/two-clean" 2>&1)"
rc=$?
if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -q "check-test-evidence: clean (2 files)"; then
  pass "clean line counts the scanned files"
else
  fail "clean line: expected 'clean (2 files)', got exit $rc"; printf '%s\n' "$out"
fi

# Every JavaScript and TypeScript spec extension is scanned.
for ext in cjs mts cts jsx; do
  mkdir "$TMP/ext-$ext"
  cp "$FIX/full-page.spec.ts" "$TMP/ext-$ext/full-page.spec.$ext"
  out="$("$CHECKER" "$TMP/ext-$ext" 2>&1)"
  rc=$?
  if [ "$rc" -eq 1 ] && printf '%s\n' "$out" | grep -q "full-page.spec.$ext:4: full-page screenshot"; then
    pass ".$ext specs are scanned"
  else
    fail ".$ext specs: expected exit 1 at line 4, got $rc"; printf '%s\n' "$out"
  fi
done

# Dependencies and build output are not specs: node_modules, dist and .git are pruned.
mkdir -p "$TMP/pruned/e2e" "$TMP/pruned/node_modules/pkg" "$TMP/pruned/dist" "$TMP/pruned/.git"
cp "$FIX/clean.spec.ts" "$TMP/pruned/e2e/clean.spec.ts"
for d in node_modules/pkg dist .git; do
  cp "$FIX/full-page.spec.ts" "$TMP/pruned/$d/full-page.spec.js"
done
out="$("$CHECKER" "$TMP/pruned" 2>&1)"
rc=$?
if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -q "clean (1 files)"; then
  pass "node_modules, dist and .git are not scanned"
else
  fail "pruned directories: expected exit 0 with 1 file read, got $rc"; printf '%s\n' "$out"
fi

if [ "$FAILS" -ne 0 ]; then
  printf '%s check(s) failed\n' "$FAILS"
  exit 1
fi
echo "All evidence checker tests passed"
