#!/usr/bin/env bash
#
# verify-merge-commits.sh — fail if a pull request was merged without
# conventional-commit text in its merge commit.
#
# Release Please walks history newest-first and stops at the previous release
# commit, so a PR whose commits predate that release is only ever seen through
# its merge commit. GitHub's default merge writes the PR title into the merge
# commit's body, and the PR Title check makes that title conventional. A merge
# made with an empty body (`gh pr merge --body ""`) or a non-conventional title
# can leave the PR with no changelog entry and no version bump at all.
#
# Only "Merge pull request #N ..." commits are checked. Branch-sync merges such
# as "Merge branch 'main' into feat/x" are not PR merges and carry no title.
#
# The merge has already happened, so this cannot undo it; it makes the gap
# visible while the release PR can still be corrected. See CONTRIBUTING.md.
#
# Usage: verify-merge-commits.sh [<git range>]     Default: HEAD~1..HEAD
set -euo pipefail

range="${1:-HEAD~1..HEAD}"
conventional='^(feat|fix|docs|style|refactor|perf|test|chore|ci|build|revert)(\([^)]*\))?!?: .'

checked=0
fail=0
for sha in $(git rev-list --merges "$range" 2>/dev/null || true); do
  subject=$(git log -1 --format=%s "$sha")
  case "$subject" in
    "Merge pull request #"*) ;;
    *) continue ;;
  esac
  checked=$((checked + 1))
  if ! grep -qE "$conventional" <<< "$(git log -1 --format=%B "$sha")"; then
    fail=1
    echo "verify-merge-commits: $(git rev-parse --short "$sha") has no conventional-commit text" >&2
    echo "    $subject" >&2
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "verify-merge-commits: $checked pull request merge(s) in $range carry a conventional title"
  exit 0
fi

cat >&2 <<'MSG'

Release Please may never see the pull request(s) above: if their commits predate
the previous release, the merge commit was their only record, and it says
nothing it can parse.

Before merging the next release PR, check that each of these PRs appears in its
CHANGELOG section, and add the entry by hand if it does not. In future, merge
with GitHub's default merge commit, never with an empty body.
MSG
exit 1
