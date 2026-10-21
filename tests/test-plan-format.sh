#!/usr/bin/env bash
# tests/test-plan-format.sh — every plan from 038 on can be dated and placed by the corpus index
# (plan 038 step 5).
#
# generate-corpus.js reads a plan's status, priority, effort and planning point from the plan
# itself and from plans/README.md, never from a copy kept by hand. Plans before 038 wrote the
# "Planned at" line in three formats, and one has no Status block; the index reports those and
# leaves the fields null. From 038 on, a plan must have:
#
#   - a "## Status" section
#   - in it, a "- **Planned at**: commit `<sha>`" item with a YYYY-MM-DD date on the same line,
#     e.g. "- **Planned at**: commit `a2f08e7`, 2026-10-14"
#
# Older plans are never inspected, so nothing retroactive is required (plans are append-only,
# CONTRIBUTING.md section 5).
#
# Usage: tests/test-plan-format.sh [repo-dir]    (default: this repository)

set -u

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
FIRST=38
FAILED=0
checked=0

for plan in "$ROOT"/plans/[0-9][0-9][0-9]-*.md; do
  [ -e "$plan" ] || continue
  name="${plan##*/}"
  number=$((10#${name%%-*}))
  [ "$number" -ge "$FIRST" ] || continue
  checked=$((checked + 1))
  status="$(awk '/^## Status[[:space:]]*$/ { on = 1; next } /^## / { on = 0 } on' "$plan")"
  if [ -z "$status" ]; then
    echo "  ✘ plans/$name: no \"## Status\" section"
    FAILED=1
    continue
  fi
  # shellcheck disable=SC2016  # the backticks are literal Markdown, not a command substitution
  if ! printf '%s\n' "$status" |
    grep -qE '^- \*\*Planned at\*\*: commit `[0-9a-f]{7,40}`.*[0-9]{4}-[0-9]{2}-[0-9]{2}'; then
    echo "  ✘ plans/$name: Status has no \"- **Planned at**: commit \`<sha>\`, YYYY-MM-DD\" line"
    FAILED=1
  fi
done

if [ "$checked" -eq 0 ]; then
  echo "  ✘ no plan numbered $FIRST or above under $ROOT/plans"
  exit 1
fi
if [ "$FAILED" -ne 0 ]; then
  echo "Plan format check failed."
  exit 1
fi
echo "✔ All $checked plans from $(printf '%03d' "$FIRST") on record their planning commit and date."
