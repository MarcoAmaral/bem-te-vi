#!/usr/bin/env bash
# tests/test-ctfl-citations.sh — every syllabus citation in shipped content names a section that
# exists, and every line that names CTFL cites one (plan 038 step 3).
#
# In shipped content (.claude/**/*.md), `§` followed by a number means a CTFL v4.0.1 section and
# nothing else; other documents' sections are named in words. Two checks:
#
#   1. Every `§N(.N)*` is a section in tests/fixtures/ctfl-v4.0.1-sections.txt, the list read once
#      from the official syllabus PDF. A failure names the file, the line and the section.
#   2. Every line outside the frontmatter that contains `CTFL` also carries a `§` or a
#      `Chapter N`, unless it matches an entry in tests/fixtures/ctfl-uncited-allow.txt
#      (`<path>:<fixed text>`, with a reason comment above it). An entry that no longer matches
#      any line is an error too, so the allowlist can only shrink.
#
# Then it prints the coverage: distinct sections cited out of the list, and files citing at least
# one section out of all shipped Markdown files.
#
# Claims that never say "CTFL" cannot be found mechanically; they are covered by reading.
#
# Usage: tests/test-ctfl-citations.sh [repo-dir]    (default: self-test, then this repository)

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SECTIONS="$REPO/tests/fixtures/ctfl-v4.0.1-sections.txt"
ALLOW="$REPO/tests/fixtures/ctfl-uncited-allow.txt"

# Byte semantics for `§` (two bytes in UTF-8) in every awk, whatever the locale.
export LC_ALL=C

# check_tree <root> <allowlist>: prints every finding and the coverage; returns 0 when all pass.
check_tree() {
  local root="$1" allow="$2" list
  if [ ! -d "$root/.claude" ]; then
    echo "  ✘ $root/.claude does not exist; nothing there can be checked"
    return 1
  fi
  list="$(cd "$root" && find .claude -type f -name '*.md' | sed 's|^\./||' | sort)"
  if [ -z "$list" ]; then
    echo "  ✘ no Markdown files under $root/.claude"
    return 1
  fi
  # shellcheck disable=SC2086  # the list holds repository paths without spaces
  (cd "$root" && awk -v sections="$SECTIONS" -v allow="$allow" '
    BEGIN {
      while ((getline l < sections) > 0) {
        if (l ~ /^#/ || l == "") continue
        split(l, cols, "\t"); known[cols[1]] = 1; total++
      }
      close(sections)
      if (total == 0) { print "  ✘ no sections read from " sections; bad = 1 }
      while ((getline l < allow) > 0) {
        if (l ~ /^#/ || l == "") continue
        i = index(l, ":")
        if (i < 2) { print "  ✘ allowlist entry without <path>:<text>: " l; bad = 1; continue }
        na++; apath[na] = substr(l, 1, i - 1); atext[na] = substr(l, i + 1); aused[na] = 0
      }
      close(allow)
    }
    FNR == 1 { files++; infm = ($0 == "---"); if (infm) next }
    {
      # Check 1, on every line (frontmatter included).
      rest = $0
      while (match(rest, /§[0-9]+(\.[0-9]+)*/)) {
        s = substr(rest, RSTART, RLENGTH); sub(/^§/, "", s)
        if (!(s in known)) {
          print "  ✘ " FILENAME ":" FNR ": §" s " is not a CTFL v4.0.1 section"; bad = 1
        } else {
          cited[s] = 1; citing[FILENAME] = 1
        }
        rest = substr(rest, RSTART + RLENGTH)
      }
    }
    infm { if ($0 == "---") infm = 0; next }
    /CTFL/ {
      # Check 2, outside the frontmatter.
      if ($0 ~ /§[0-9]/ || tolower($0) ~ /chapter [0-9]/) next
      for (k = 1; k <= na; k++)
        if (apath[k] == FILENAME && index($0, atext[k]) > 0) { aused[k] = 1; next }
      print "  ✘ " FILENAME ":" FNR ": names CTFL but cites no section: " substr($0, 1, 100); bad = 1
    }
    END {
      for (k = 1; k <= na; k++)
        if (!aused[k]) { print "  ✘ allowlist entry matches no line: " apath[k] ":" atext[k]; bad = 1 }
      for (s in cited) nc++
      for (p in citing) nf++
      printf "  Sections cited: %d of %d. Files citing a section: %d of %d.\n", nc, total, nf, files
      exit bad
    }' $list)
}

# self_test: the check must fail on a bad section, on an uncited CTFL line and on a stale
# allowlist entry, and pass on a clean tree.
self_test() {
  local t ok=0
  t="$(mktemp -d)"
  mkdir -p "$t/.claude/rules"
  printf '%s\n' '---' 'id: a' 'description: CTFL in frontmatter is not checked' '---' \
    '# A' 'Two-value BVA (CTFL §4.2.2).' '> Banner | ISTQB CTFL v4.0 |' 'Tools (CTFL Chapter 6).' \
    > "$t/.claude/rules/a.md"
  printf '%s\n' '# reason' '.claude/rules/a.md:> Banner | ISTQB CTFL v4.0 |' > "$t/allow"
  check_tree "$t" "$t/allow" >/dev/null || { echo "  ✘ self-test: a clean tree failed"; ok=1; }
  printf '%s\n' 'Bad (§4.6).' >> "$t/.claude/rules/a.md"
  check_tree "$t" "$t/allow" | grep -q 'a.md:9: §4.6 is not' ||
    { echo "  ✘ self-test: a section that does not exist passed"; ok=1; }
  printf '%s\n' '# A' 'The CTFL says so.' > "$t/.claude/rules/a.md"
  check_tree "$t" "$t/allow" | grep -q 'a.md:2: names CTFL but cites no section' ||
    { echo "  ✘ self-test: an uncited CTFL line passed"; ok=1; }
  check_tree "$t" "$t/allow" | grep -q 'allowlist entry matches no line' ||
    { echo "  ✘ self-test: a stale allowlist entry passed"; ok=1; }
  rm -rf "$t"
  return "$ok"
}

if [ $# -eq 0 ]; then
  self_test || { echo "Self-test failed: the check does not catch what it must."; exit 1; }
  echo "✔ Self-test: a bad section, an uncited CTFL line and a stale allowlist entry are caught."
fi
ROOT="${1:-$REPO}"
if check_tree "$ROOT" "$ALLOW"; then
  echo "✔ Every § names a CTFL v4.0.1 section, and every line naming CTFL cites one."
else
  echo "CTFL citation check failed."
  exit 1
fi
