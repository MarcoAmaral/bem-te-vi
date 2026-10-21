#!/usr/bin/env bash
#
# dedupe-changelog.sh — remove CHANGELOG.md entries generated from GitHub's
# "Merge pull request" commits.
#
# Merging a PR through the GitHub UI creates a merge commit whose body is the
# PR title, and release-please parses that body as a conventional commit.
#
# Whether release-please ALSO lists the PR's own commits depends on their
# dates. It walks history newest-first and stops at the previous release
# commit (src/manifest.ts, `releaseCommitsFound >= expectedShas` -> break), so a
# PR commit dated before the previous release was merged is never visited,
# even though it is new to this release. The merge commit, dated at merge
# time, is always visited. 2.7.0 and 2.7.1 were attributed entirely to merge
# commits for exactly this reason.
#
# So a merge-commit entry is removed only when it is a real duplicate: when at
# least one of that PR's own commits (merge^1..merge^2) is also listed in the
# section. Otherwise it is the PR's only record and is kept. See
# CONTRIBUTING.md for the full explanation.
#
# Only the *first* version section in CHANGELOG.md (the release currently
# being prepared) is touched. Every historical section is left untouched.
#
# As a last line of defence the script still refuses, and exits non-zero without
# writing the file, if removals would leave the section empty. Under the rule
# above that cannot happen — every removal leaves the sibling entry that
# justified it — so reaching it means the sibling detection itself is wrong.
#
# Usage: dedupe-changelog.sh [CHANGELOG.md]
#
# Requires the referenced commits to be present locally — a shallow clone of
# depth 1 will not have them. Fetch full history before running this.
set -euo pipefail

changelog="${1:-CHANGELOG.md}"

if [ ! -f "$changelog" ]; then
  echo "dedupe-changelog: $changelog not found" >&2
  exit 1
fi

parent_count() {
  local sha parents
  sha="$1"
  parents=$(git rev-list --parents -n 1 "$sha" 2>/dev/null) || {
    echo "dedupe-changelog: commit $sha not found locally (fetch full history first)" >&2
    exit 1
  }
  echo $(( $(echo "$parents" | wc -w) - 1 ))
}

start_line=$(awk '/^## \[/ { print NR; exit }' "$changelog")
if [ -z "$start_line" ]; then
  echo "dedupe-changelog: no version section found in $changelog, nothing to do"
  exit 0
fi

second_line=$(awk '/^## \[/ { c++; if (c == 2) { print NR; exit } }' "$changelog")
if [ -n "$second_line" ]; then
  end_line=$(( second_line - 1 ))
else
  end_line=$(wc -l < "$changelog" | tr -d ' ')
fi

tmp_head=$(mktemp)
tmp_section=$(mktemp)
tmp_tail=$(mktemp)
tmp_del=$(mktemp)
tmp_out=$(mktemp)
trap 'rm -f "$tmp_head" "$tmp_section" "$tmp_tail" "$tmp_del" "$tmp_out"' EXIT

head -n "$((start_line - 1))" "$changelog" > "$tmp_head"
sed -n "${start_line},${end_line}p" "$changelog" > "$tmp_section"
tail -n "+$((end_line + 1))" "$changelog" > "$tmp_tail"

# Pass 1: every commit the section's bullets link to, by full SHA.
listed=$(grep -E '^[-*+] ' "$tmp_section" | grep -oE '/commit/[0-9a-f]{40}\)' | grep -oE '[0-9a-f]{40}' || true)

# Pass 2 input: the (section-local) line numbers of bullet entries linked to a
# merge commit whose PR has at least one of its own commits listed too.
: > "$tmp_del"
line_no=0
while IFS= read -r line; do
  line_no=$((line_no + 1))
  case "$line" in
    # release-please writes "*" bullets; the markdownlint --fix step that runs *after*
    # this script rewrites them to "-". Both forms must be recognised, or this runs
    # against the pre-normalised file and sees no entries at all.
    '- '*|'* '*|'+ '*)
      sha=$(printf '%s\n' "$line" | grep -oE '/commit/[0-9a-f]{7,40}\)' | grep -oE '[0-9a-f]{7,40}' | head -n 1) || true
      [ -n "$sha" ] || continue
      [ "$(parent_count "$sha")" -ge 2 ] || continue
      for member in $(git rev-list --no-merges "$sha^1..$sha^2"); do
        if grep -qx -- "$member" <<< "$listed"; then
          echo "$line_no" >> "$tmp_del"
          break
        fi
      done
      ;;
  esac
done < "$tmp_section"

# Pass 2: drop those bullet lines, then drop any "### " heading that is left
# with no surviving bullet under it before the next heading or section end.
awk -v delfile="$tmp_del" '
  BEGIN {
    while ((getline dline < delfile) > 0) { deleted[dline] = 1 }
    close(delfile)
  }
  {
    lines[NR] = $0
    if ($0 ~ /^### /) {
      heading = NR
      has_content[heading] = 0
      headings[++hn] = NR
    } else if (heading && $0 ~ /^[-*+] /) {
      if (NR in deleted) { removed_under[heading] = 1 } else { has_content[heading] = 1 }
    }
  }
  END {
    for (h = 1; h <= hn; h++) {
      hi = headings[h]
      # Only a heading we actually emptied is an orphan. A heading with no surviving
      # bullets and nothing deleted under it means the bullets were never recognised —
      # removing it then would destroy a section this script was not asked to touch.
      if (!has_content[hi] && removed_under[hi]) deleted[hi] = 1
    }
    for (i = 1; i <= NR; i++) {
      if (!(i in deleted)) print lines[i]
    }
  }
' "$tmp_section" > "$tmp_out"

# Defence in depth. Pass 1 only removes an entry whose PR has a sibling entry in
# this section, so removals can never empty it. If they would anyway, the sibling
# detection is wrong, and writing the file would publish a release with an empty
# changelog — silent data loss, as happened to 2.7.0 before this rule existed.
# Refuse, leaving the CHANGELOG untouched.
bullets_before=$(grep -c '^[-*+] ' "$tmp_section" || true)
bullets_after=$(grep -c '^[-*+] ' "$tmp_out" || true)

if [ "$bullets_before" -gt 0 ] && [ "$bullets_after" -eq 0 ]; then
  version=$(sed -n '1s/^## \[\([^]]*\)\].*/\1/p' "$tmp_section")
  cat >&2 <<EOF
dedupe-changelog: refusing to empty the changelog section ${version:-(first section)}.

Removing $bullets_before merge-commit entries would leave it with none, which the
sibling check is meant to make impossible. Something is wrong with that check.

$changelog has been left unchanged. Write the section by hand from the commits in
the release range, then re-run this script if duplicates remain.
EOF
  exit 1
fi

cat "$tmp_head" "$tmp_out" "$tmp_tail" > "$changelog"
