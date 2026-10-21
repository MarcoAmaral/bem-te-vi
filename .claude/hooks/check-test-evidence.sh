#!/usr/bin/env bash
# check-test-evidence.sh — Test Evidence Checker
# Scans Playwright specs for evidence that breaks the test-evidence rule:
#   - fullPage: true screenshots
#   - element-level .screenshot( calls (a locator's own screenshot, not the page viewport)
#   - screenshot/video path: values containing non-ASCII characters
# With --runner-standard (or EVIDENCE_RUNNER_STANDARD=1), for suites built on a shared helper library:
#   - page.goto( without a "goto-ok: <reason>" comment on the same or the preceding line
#   - a bare .click( that does not go through a project click helper
# A file whose FIRST line is "// evidence-check: probe" is reconnaissance, never evidence:
# it is exempt from the goto and click checks, and must not capture (screenshot( / shot( is flagged).
# Usage: check-test-evidence.sh [--runner-standard] [--click-helper <name>]... <spec-file-or-directory> [...]
#   --runner-standard      also run the goto and click checks (off by default).
#   --click-helper <name>  extra allowed click helper (comma-separated, repeatable), e.g. ui.click.
#                          Also read from $EVIDENCE_CLICK_HELPERS. "click" is always allowed.
# Exit: 0 clean, 1 findings, 2 usage error. Line-based heuristics: mechanical checks only.

set -u

USAGE="Usage: $0 [--runner-standard] [--click-helper <name>]... <spec-file-or-directory> [...]"
RUNNER_STANDARD="${EVIDENCE_RUNNER_STANDARD:-0}"
CLICK_HELPERS="click${EVIDENCE_CLICK_HELPERS:+,$EVIDENCE_CLICK_HELPERS}"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --runner-standard) RUNNER_STANDARD=1; shift ;;
    --click-helper)
      if [ "$#" -lt 2 ]; then echo "$USAGE" >&2; exit 2; fi
      CLICK_HELPERS="$CLICK_HELPERS,$2"
      shift 2
      ;;
    --) shift; break ;;
    -*) echo "$USAGE" >&2; exit 2 ;;
    *) break ;;
  esac
done

if [ "$#" -eq 0 ]; then
  echo "$USAGE" >&2
  exit 2
fi

# "click,ui.click" -> (^|[^A-Za-z0-9_.])(click|ui\.click)[[:space:]]*\(  (a helper call, not a method on a locator)
HELPER_NAMES="$(printf '%s' "$CLICK_HELPERS" | tr ',' '\n' | sed -e 's/[[:space:]]//g' -e '/^$/d' -e 's/\./\\./g' | paste -sd'|' -)"
HELPER_CALL="(^|[^A-Za-z0-9_.])(${HELPER_NAMES})[[:space:]]*\\("
COMMENT_LINE='^[[:space:]]*(//|\*)'

# Any byte outside printable ASCII and tab (matched under LC_ALL=C).
NON_ASCII="[^ -~$(printf '\t')]"
# A page-level call: page.screenshot(, this.page.screenshot(, authPage.screenshot( ...
PAGE_CALL='(^|[^A-Za-z0-9_])([A-Za-z_]*[Pp]age)[[:space:]]*\.screenshot[[:space:]]*\('

# Findings name $REPORT_AS (the file as the caller gave it) while the checks read a normalised copy.
REPORT_AS=""

# scan <file> <regex> <message> <fix> [<exclude-regex>]
# Prints "file:line: message" plus a fix line for each matching line.
scan() {
  LC_ALL=C grep -nE -- "$2" "$1" | while IFS= read -r hit; do
    if [ -n "${5:-}" ] && printf '%s\n' "${hit#*:}" | LC_ALL=C grep -qE -- "$5"; then
      continue
    fi
    printf '%s:%s: %s\n    fix: %s\n' "$REPORT_AS" "${hit%%:*}" "$3" "$4"
  done
}

# Lines with page.goto( lacking "goto-ok:" on the same or the preceding line.
scan_goto() {
  awk '
    /[Pp]age[ \t]*[.][ \t]*goto[ \t]*[(]/ && $0 !~ /^[ \t]*(\/\/|[*])/ && $0 !~ /goto-ok:/ && !last_ok { print NR }
    { last_ok = ($0 ~ /goto-ok:/) }
  ' "$1" | while IFS= read -r n; do
    printf '%s:%s: page.goto( without a goto-ok reason (direct navigation skips the interface)\n    fix: reach the screen through the interface, or add "// goto-ok: <reason>" on the same or the preceding line (setup only)\n' "$REPORT_AS" "$n"
  done
}

is_probe() {
  head -n 1 "$1" | LC_ALL=C grep -qE '^[[:space:]]*//[[:space:]]*evidence-check:[[:space:]]*probe([[:space:]]|$)'
}

# Writes $1 without a UTF-8 BOM and without CR line endings (Git for Windows with core.autocrlf,
# PowerShell 5.1 Out-File), so the checks see the same bytes on every platform. Only a BOM and
# trailing CRs are removed, so line numbers are unchanged. printf builds the bytes: BSD sed knows
# neither \xEF nor \r.
normalise() {
  local BOM CR
  BOM="$(printf '\357\273\277')"
  CR="$(printf '\r')"
  LC_ALL=C sed -e "1s/^${BOM}//" -e "s/${CR}\$//" "$1"
}

check_file() {
  local norm
  norm="$(mktemp)"
  normalise "$1" > "$norm"
  REPORT_AS="$1"
  check_normalised "$norm"
  rm -f "$norm"
}

check_normalised() {
  if is_probe "$1"; then
    scan "$1" '(^|[^A-Za-z0-9_])(screenshot|shot)[[:space:]]*\(' \
      "probe captures evidence (a probe is reconnaissance, never evidence)" \
      "remove the capture, or drop the '// evidence-check: probe' first line and make this a real evidence spec" \
      "$COMMENT_LINE"
    return
  fi
  if [ "$RUNNER_STANDARD" = "1" ]; then
    scan_goto "$1"
    scan "$1" '\.click[[:space:]]*\(' \
      "bare .click( (the recording shows no pointer path)" \
      "click through the project helper (default click(page, target); others via --click-helper or EVIDENCE_CLICK_HELPERS), or mark the file '// evidence-check: probe'" \
      "${COMMENT_LINE}|${HELPER_CALL}"
  fi
  scan "$1" 'fullPage[[:space:]]*:[[:space:]]*true' \
    "full-page screenshot" \
    "capture the viewport at a fixed size: scroll the subject into view and call page.screenshot() without fullPage"
  scan "$1" '\.screenshot[[:space:]]*\(' \
    "element-level screenshot (no surrounding context)" \
    "capture the page viewport with page.screenshot() after scrolling the subject into view" \
    "$PAGE_CALL"
  scan "$1" "path[[:space:]]*:.*${NON_ASCII}" \
    "non-ASCII character in evidence file name" \
    "use ASCII letters, digits, '-', '_' and '.' only, e.g. TC-CART-001-total.png" \
    '^[[:space:]]*(//|\*)'
}

collect() {
  for target in "$@"; do
    if [ -d "$target" ]; then
      find "$target" -mindepth 1 \( -name node_modules -o -name dist -o -name .git \) -prune -o -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.mts' -o -name '*.cts' -o -name '*.js' -o -name '*.jsx' -o -name '*.mjs' -o -name '*.cjs' \) -print | sort
    elif [ -f "$target" ]; then
      printf '%s\n' "$target"
    else
      echo "check-test-evidence: no such file or directory: $target" >&2
      return 1
    fi
  done
}

FILES="$(collect "$@")" || exit 2
if [ -z "$FILES" ]; then
  echo "check-test-evidence: no spec files found in $*" >&2
  exit 2
fi

OUTPUT=""
while IFS= read -r f; do
  [ -n "$f" ] && OUTPUT="${OUTPUT}$(check_file "$f")"$'\n'
done <<EOF
$FILES
EOF

OUTPUT="$(printf '%s' "$OUTPUT" | grep -v '^$' || true)"
if [ -n "$OUTPUT" ]; then
  printf '%s\n' "$OUTPUT"
  COUNT="$(printf '%s\n' "$OUTPUT" | grep -c 'fix: ' || true)"
  echo "check-test-evidence: $COUNT finding(s). See the test-evidence rule" >&2
  exit 1
fi
echo "check-test-evidence: clean ($(printf '%s\n' "$FILES" | grep -c .) files)"
