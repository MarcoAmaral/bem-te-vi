#!/usr/bin/env bash
#
# Tests dedupe-changelog.sh against real fixtures from this repo's own
# history, committed under tests/fixtures/dedupe-changelog/. The first is
# the 2.5.0 section of CHANGELOG.md as it existed at commit 6a204fe, before
# PR #53 removed its merge-commit duplicates by hand.
#
# Three of that section's entries are linked to merge commits (two parents):
#   26cd5f0, 6c00d65, 3c0c1db
# Every other entry in that section is linked to a commit with exactly one
# parent and must survive untouched, and every historical section below it
# must be byte-for-byte unchanged.
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
script="$repo_root/dedupe-changelog.sh"
fixtures="$repo_root/tests/fixtures/dedupe-changelog"

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

# The fixtures link to commits that only this repository's history has, and
# dedupe-changelog.sh asks git two things about a linked commit: how many
# parents it has, and which commits a merge brought in (merge^1..merge^2).
# So the test rebuilds that shape in a scratch repository, and rewrites each
# fixture's links to the scratch commits. A clone without the history (or a
# shallow one) runs every case.
history="$work_dir/history"
sha_map="$work_dir/sha-map"   # "<fixture short sha> <scratch full sha>" per line
: > "$sha_map"
hgit() { git -C "$history" -c user.name=fixture -c user.email=fixture@example.invalid -c commit.gpgsign=false "$@"; }
git init -q -b main "$history"
hgit commit -q --allow-empty -m "base"
base=$(hgit rev-parse HEAD)
commit_count=0

# pr_branch <name> <sha|->...: a pull request branch off base, one commit per
# argument; "-" is a commit of that PR the changelog does not list.
pr_branch() {
  local name="$1" sha
  shift
  hgit checkout -q -b "$name" "$base"
  for sha in "$@"; do
    commit_count=$((commit_count + 1))
    hgit commit -q --allow-empty -m "commit $commit_count"
    [ "$sha" = "-" ] || echo "$sha $(hgit rev-parse HEAD)" >> "$sha_map"
  done
}

# pr_merge <sha> <branch>: GitHub's "Merge pull request" commit, base first.
pr_merge() {
  hgit checkout -q --detach "$base"
  hgit merge -q --no-ff -m "Merge pull request ($1)" "$2"
  echo "$1 $(hgit rev-parse HEAD)" >> "$sha_map"
}

# The real topology, reduced to what the script can observe. 26cd5f0 and
# 3c0c1db merged the same commits; 6c00d65's PR lists five of its own.
pr_branch pr-2.5.0-a 7771e42 5bcbf9f 6fc8d3d - -
pr_merge 26cd5f0 pr-2.5.0-a
pr_merge 3c0c1db pr-2.5.0-a
pr_branch pr-2.5.0-b ab6f121 0769eaa 252f909 3255cb1 6ea8221 -
pr_merge 6c00d65 pr-2.5.0-b
pr_branch pr-67 - f839ced
pr_merge ae641db pr-67
pr_branch pr-69 - - -
pr_merge 588da35 pr-69
pr_branch pr-70 - -
pr_merge 715f68a pr-70
pr_branch pr-74 -
pr_merge 7354feb pr-74

# new_sha <fixture short sha>: the scratch commit standing in for it.
new_sha() {
  local sha
  sha=$(awk -v s="$1" '$1 == s { print $2; exit }' "$sha_map")
  [ -n "$sha" ] || { echo "test setup error: no scratch commit for $1" >&2; exit 1; }
  echo "$sha"
}

# fixture <name> <dest>: copy a fixture, linking its first section to scratch
# commits. Every listed commit not made above is a plain one-parent commit.
fixture() {
  local src="$fixtures/$1" dest="$2" sha short sed_script="$work_dir/rewrite.sed"
  while IFS= read -r sha; do
    short=${sha:0:7}
    grep -q "^$short " "$sha_map" && continue
    hgit checkout -q --detach "$base"
    commit_count=$((commit_count + 1))
    hgit commit -q --allow-empty -m "commit $commit_count"
    echo "$short $(hgit rev-parse HEAD)" >> "$sha_map"
  done < <(awk '/^## \[/ { c++ } c == 1' "$src" | grep -oE '/commit/[0-9a-f]{40}\)' | grep -oE '[0-9a-f]{40}')
  awk '{ printf "s#/commit/%s[0-9a-f]{33}\\)#/commit/%s)#g\ns#\\[%s\\]#[%s]#g\n", $1, $2, $1, substr($2, 1, 7) }' "$sha_map" > "$sed_script"
  sed -E -f "$sed_script" "$src" > "$dest"
}

# dedupe <file>: run the script against the scratch history.
dedupe() {
  (cd "$history" && "$script" "$1")
}

# Every commit the checks below name must have a scratch stand-in; a typo in
# the topology above fails the setup here instead of weakening a check.
for sha in 26cd5f0 3c0c1db 6c00d65 7771e42 5bcbf9f 6fc8d3d ab6f121 0769eaa \
           252f909 3255cb1 6ea8221 ae641db f839ced 588da35 715f68a 7354feb; do
  new_sha "$sha" > /dev/null
done

before="$work_dir/before.md"
after="$work_dir/after.md"

fixture CHANGELOG.before.md "$before"
cp "$before" "$after"

echo "== before (2.5.0 section) =="
sed -n '/^## \[2\.5\.0\]/,/^## \[2\.4\.1\]/p' "$before"

dedupe "$after"

echo
echo "== after (2.5.0 section) =="
sed -n '/^## \[2\.5\.0\]/,/^## \[2\.4\.1\]/p' "$after"

fail=0

for merge_sha in 26cd5f0 6c00d65 3c0c1db; do
  if grep -q "$(new_sha "$merge_sha")" "$after"; then
    echo "FAIL: merge-commit entry $merge_sha was not removed" >&2
    fail=1
  fi
done

for kept_sha in 7771e42 5bcbf9f 0769eaa ab6f121 3255cb1 6fc8d3d 252f909 6ea8221; do
  if ! grep -q "$(new_sha "$kept_sha")" "$after"; then
    echo "FAIL: real entry $kept_sha was removed but should have been kept" >&2
    fail=1
  fi
done

removed_count=$(($(wc -l < "$before" | tr -d ' ') - $(wc -l < "$after" | tr -d ' ')))
if [ "$removed_count" -ne 3 ]; then
  echo "FAIL: expected exactly 3 lines removed, got $removed_count" >&2
  fail=1
fi

# Every section other than 2.5.0 (i.e. everything from the 2.4.1 heading
# onward) must be untouched.
before_tail="$work_dir/before-tail.md"
after_tail="$work_dir/after-tail.md"
sed -n '/^## \[2\.4\.1\]/,$p' "$before" > "$before_tail"
sed -n '/^## \[2\.4\.1\]/,$p' "$after" > "$after_tail"
if ! diff -q "$before_tail" "$after_tail" > /dev/null; then
  echo "FAIL: a historical section was modified" >&2
  diff "$before_tail" "$after_tail" >&2 || true
  fail=1
fi

# Running the script again must be a no-op.
after2="$work_dir/after2.md"
cp "$after" "$after2"
dedupe "$after2"
if ! diff -q "$after" "$after2" > /dev/null; then
  echo "FAIL: script is not idempotent" >&2
  diff "$after" "$after2" >&2 || true
  fail=1
fi

# release-please writes "*" bullets and the markdownlint --fix step rewrites them to "-"
# only AFTER this script runs, so production input is the "*" form. Reading the already
# normalised CHANGELOG from main hid that: on its first live run the script recognised no
# bullets at all, concluded both headings were empty, and deleted them.
echo
echo "Checking the raw release-please form, with '*' bullets..."

star_in="$work_dir/star-in.md"
star_out="$work_dir/star-out.md"

# 7698908 is the 2.6.0 release commit: "*" bullets, two entries, neither a merge commit.
fixture CHANGELOG.at-7698908.md "$star_in"
cp "$star_in" "$star_out"
dedupe "$star_out" > /dev/null

if ! diff -q "$star_in" "$star_out" > /dev/null; then
  echo "FAIL: a section with no merge commits must be left byte-identical" >&2
  diff "$star_in" "$star_out" >&2 || true
  fail=1
fi

star_headings=$(awk '/^## \[2\.6\.0\]/,/^## \[2\.5\.0\]/' "$star_out" | grep -c '^### ' || true)
if [ "$star_headings" -ne 2 ]; then
  echo "FAIL: expected 2 headings to survive in the '*' form, found $star_headings" >&2
  fail=1
fi

# 99acff3 is the 2.5.0 release commit: "*" bullets including three merge-commit entries.
star2="$work_dir/star2.md"
fixture CHANGELOG.at-99acff3.md "$star2"
dedupe "$star2" > /dev/null

for sha in 26cd5f0 6c00d65 3c0c1db; do
  if grep -q "$(new_sha "$sha")" "$star2"; then
    echo "FAIL: merge-commit entry $sha survived in the '*' form" >&2
    fail=1
  fi
done

star2_headings=$(awk '/^## \[2\.5\.0\]/,/^## \[2\.4\.1\]/' "$star2" | grep -c '^### ' || true)
if [ "$star2_headings" -ne 2 ]; then
  echo "FAIL: removing entries must not remove their still-populated headings (found $star2_headings)" >&2
  fail=1
fi

# release-please walks history newest-first and stops at the previous release
# commit, so a PR commit dated before that release was merged is never listed —
# only the PR's merge commit is. A merge-commit entry is therefore removed only
# when one of its PR's own commits is listed beside it; otherwise it is the PR's
# only record. Each case below is a real release-please output from this repo.
check_section() {  # <fixture commit> <version> <removed shas> <kept shas>
  local fixture="$1" version="$2" removed="$3" kept="$4"
  local in="$work_dir/fx-$fixture.md" orig="$work_dir/fx-$fixture.orig" status sha
  fixture "CHANGELOG.at-$fixture.md" "$in"
  cp "$in" "$orig"
  set +e
  dedupe "$in" > "$work_dir/fx-$fixture.out" 2>&1
  status=$?
  set -e
  if [ "$status" -ne 0 ]; then
    echo "FAIL: $version: expected exit 0, got $status" >&2
    cat "$work_dir/fx-$fixture.out" >&2
    fail=1
  fi
  for sha in $removed; do
    if grep -q "$(new_sha "$sha")" "$in"; then
      echo "FAIL: $version: merge entry $sha duplicates a listed PR commit and should have been removed" >&2
      fail=1
    fi
  done
  for sha in $kept; do
    if ! grep -q "$(new_sha "$sha")" "$in"; then
      echo "FAIL: $version: entry $sha was removed, but it is its PR's only record" >&2
      fail=1
    fi
  done
  if [ -z "$removed" ] && ! diff -q "$orig" "$in" > /dev/null; then
    echo "FAIL: $version: nothing should have been removed, but the file changed" >&2
    diff "$orig" "$in" >&2 || true
    fail=1
  fi
}

echo
echo "Checking merge entries against their PRs' own commits, on real release-please output..."

# 2.6.1 (86d91b2): #67's merge commit ae641db, and its own commit f839ced beside it.
check_section 86d91b2 2.6.1 "ae641db" "f839ced"

# 2.7.0 (09a8f3e): #69 and #70 were opened before 2.6.1 was released, so none of
# their commits were listed — only the two merge commits. The previous rule removed
# both and left the release empty; they must now be kept.
check_section 09a8f3e 2.7.0 "" "588da35 715f68a"

# 2.7.1 (6e00b4e): the same for #74, whose commit predates the 2.7.0 release.
check_section 6e00b4e 2.7.1 "" "7354feb"

# A section that legitimately has no entries at all must not trip the guard —
# nothing was removed, so there is nothing to protect.
echo
echo "Checking that an already-empty section is a no-op, not a refusal..."

empty_in="$work_dir/empty-in.md"
empty_out="$work_dir/empty-out.md"
cat > "$empty_in" <<'FIXTURE'
# Changelog

## [9.9.9](https://example.invalid/compare/v9.9.8...v9.9.9) (2026-01-01)

## [9.9.8](https://example.invalid/compare/v9.9.7...v9.9.8) (2026-01-01)

### Bug Fixes

- something real ([1111111](https://example.invalid/commit/1111111))
FIXTURE
cp "$empty_in" "$empty_out"

set +e
"$script" "$empty_out" > /dev/null 2>&1
empty_status=$?
set -e

if [ "$empty_status" -ne 0 ]; then
  echo "FAIL: an already-empty section must not be treated as data loss (exit $empty_status)" >&2
  fail=1
fi
if ! diff -q "$empty_in" "$empty_out" > /dev/null; then
  echo "FAIL: an already-empty section must be left byte-identical" >&2
  diff "$empty_in" "$empty_out" >&2 || true
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo
  echo "PASS: removed only merge entries whose PR's own commits are listed (2.5.0,"
  echo "      2.6.1), kept those that are a PR's only record (2.7.0, 2.7.1), handled"
  echo "      the raw '*' bullet form, and left an already-empty section alone"
  exit 0
fi

exit 1
