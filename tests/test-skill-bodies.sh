#!/usr/bin/env bash
# tests/test-skill-bodies.sh — every Agent Skill body stays under the format's size recommendation,
# and the detail moved out of a body is still where the body says it is (plan 056).
#
# Every command, agent and skill under .claude/ becomes an Agent Skill for the editors other than
# Claude Code (generate-adapters.sh). The Agent Skills specification recommends a SKILL.md body
# of "< 5000 tokens", and Cline's documentation says "Keep SKILL.md under 5k tokens". Tokens are
# estimated as bytes / 4, the estimate tests/test-rules-size.sh uses, on the whole source file,
# frontmatter included, so the figure is never under the real body. The cap is 20,000 bytes.
#
# Plan 056 brought the qa-plan skill and /qa-cases under that cap by moving examples, variant
# tables and conditional procedures into qa-reference references, with a pointer in the body at
# the point the detail is needed. A pointer names the reference and the section, as
# the `qa-reference` skill's `references/<file>.md`, "<Section>" (the form plan 057 set; the text
# is read with its whitespace collapsed, so a wrapped pointer counts). For each moved section
# listed below, this check
# fails unless:
#
#   - the body still carries that pointer (the reference path, and the quoted section name unless
#     the body sends the model to the whole file),
#   - the reference exists and has a level-2 heading starting with the section name, and
#   - every key term of the moved text is present in that section, so the model that follows the
#     pointer finds what the body used to hold.
#
# It fails closed: a missing file or an empty row list is an error, never a pass.
#
# Usage: tests/test-skill-bodies.sh [repo-dir]    (default: this repository)

set -u

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
MAX_BYTES=20000
FAILED=0

# --- Size: every source that becomes an Agent Skill -------------------------------------------
count=0
for f in "$ROOT"/.claude/commands/*.md "$ROOT"/.claude/agents/*.md "$ROOT"/.claude/skills/*/SKILL.md; do
  [ -f "$f" ] || continue
  count=$((count + 1))
  size=$(wc -c < "$f" | tr -d ' ')
  if [ "$size" -gt "$MAX_BYTES" ]; then
    echo "  ✘ ${f#"$ROOT"/} is $size bytes, about $((size / 4)) tokens; the cap is $MAX_BYTES bytes (5,000 tokens)."
    echo "    Move long examples, variant tables or conditional procedures into a reference under"
    echo "    .claude/skills/qa-reference/references/ and point to it where the detail is needed."
    FAILED=1
  fi
done
if [ "$count" -eq 0 ]; then
  echo "  ✘ no commands, agents or skills found under $ROOT/.claude"
  exit 1
fi
[ "$FAILED" -eq 0 ] && echo "  ✔ all $count Agent Skill sources are at most $MAX_BYTES bytes (about 5,000 tokens)"

# --- Moved detail: pointer in the body, section in the reference, key terms in the section ----
# <body>|<reference file>|<section heading prefix>|<section name the body quotes, or - when the body
# points to the whole file>|<key term>;<key term>;...
MOVED='
.claude/commands/qa-cases.md|test-case-writing.md|Tracker Link Formats|Tracker Link Formats|Linear;Azure DevOps (ADO);Jira;Shortcut;GitHub Issues;GitLab Issues;visualstudio.com/_workitems/edit;app.shortcut.com
.claude/commands/qa-cases.md|test-case-writing.md|ISTQB Test Design Techniques in TC Format|ISTQB Test Design Techniques in TC Format|Equivalence Partitioning (EP);EP3 (invalid: too long);Two-value BVA;Three-value BVA;min+1;R3 and R4 can merge;0-switch coverage;all transitions coverage;Stale closures;Concurrent editing
.claude/commands/qa-cases.md|test-case-writing.md|Runbook Format|Runbook Format|§5.1.5;tc_ids:;How to use this runbook;Actual result;VERIFIED BY DEV;DISCARDED
.claude/commands/qa-cases.md|test-reporting.md|Reporting Every Case|Reporting Every Case|copied verbatim;Not run — resume point;What it proves;Where it was checked;link the defect for a fail;scripted run;summary verbatim
.claude/skills/qa-plan/SKILL.md|test-planning.md|Testing Quadrants|Testing Quadrants|Brian Marick;Q1;Q2;Q3;Q4;Component and component integration tests;usability testing;performance: not covered yet
.claude/skills/qa-plan/SKILL.md|test-planning.md|Estimation Techniques|Estimation Techniques|Estimation by ratios;3:2;Extrapolation;Wideband Delphi;Planning Poker;Three-point estimation;E = (a + 4m + b) / 6;10 ± 2 person-hours
.claude/skills/qa-plan/SKILL.md|test-planning.md|Test Execution Order|Test Execution Order|Risk-based;Coverage-based;additional coverage;Requirements-based;Dependencies;Resources;numbered list under the release gate table
.claude/skills/qa-plan/SKILL.md|test-planning.md|Suite-Level Artifacts|Suite-Level Artifacts|Master test plan;Risk register;Tagging standard;Traceability matrix;§1.4.4;Status matrix
.claude/skills/qa-plan/SKILL.md|test-planning.md|Roles and Independence|Roles and Independence|test management role;testing role;Very high;What independence brings;What it can cost;safety-critical;§1.5.2
.claude/skills/qa-plan/SKILL.md|test-planning.md|Configuration Management for Testware|Configuration Management for Testware|§5.4;version controlled;never "the latest build";baseline;change control;CI/CD pipeline
.claude/skills/qa-plan/SKILL.md|test-reporting.md|Monitor:|-|§5.3.1;defect detection percentage;risk coverage;residual risk level
.claude/skills/qa-plan/SKILL.md|test-reporting.md|Control:|-|Reprioritize tests;Adjust the schedule;Add resources
.claude/skills/qa-plan/SKILL.md|test-reporting.md|Report:|-|Progress report;Completion report;§5.3.2;§5.3.3;dashboards
.claude/skills/qa-plan/SKILL.md|test-reporting.md|Complete:|-|keep the testware
.claude/skills/qa-plan/SKILL.md|test-reporting.md|Retrospectives:|-|§2.1.6;What worked and should be kept;Bring evidence, not impressions;owner and a date
'

# The lines of the level-2 section whose heading starts with $2, up to the next level-2 heading
# outside a code fence.
section() {  # <file> <heading prefix>
  awk -v want="## $2" '
    /^```/ { fence = !fence }
    !fence && /^## / { on = (index($0, want) == 1); if (on) found = 1; next }
    on { print }
    END { if (!found) exit 3 }
  ' "$1"
}

rows=0
while IFS='|' read -r body ref heading pointer terms; do
  [ -n "$body" ] || continue
  rows=$((rows + 1))
  body_file="$ROOT/$body" ref_file="$ROOT/.claude/skills/qa-reference/references/$ref"
  if [ ! -f "$body_file" ] || [ ! -f "$ref_file" ]; then
    echo "  ✘ $body or qa-reference/references/$ref does not exist"
    FAILED=1
    continue
  fi
  # The pointer: the reference path, and the section name in quotes, both in the body.
  if ! tr -s '[:space:]' ' ' < "$body_file" | grep -qiF "the \`qa-reference\` skill's \`references/$ref\`"; then
    echo "  ✘ $body does not point to the \`qa-reference\` skill's \`references/$ref\`"
    FAILED=1
  fi
  if [ "$pointer" != - ] && ! grep -qF "\"$pointer\"" "$body_file"; then
    echo "  ✘ $body does not name the section \"$pointer\" of $ref"
    FAILED=1
  fi
  if ! text="$(section "$ref_file" "$heading")"; then
    echo "  ✘ qa-reference/references/$ref has no section '## $heading'"
    FAILED=1
    continue
  fi
  missing=""
  IFS=';' read -r -a list <<< "$terms"
  for term in "${list[@]}"; do
    printf '%s\n' "$text" | grep -qF -- "$term" || missing="$missing; $term"
  done
  if [ -n "$missing" ]; then
    echo "  ✘ $ref '$heading' lacks what $body used to hold: ${missing#; }"
    FAILED=1
  else
    echo "  ✔ $body → $ref '$heading' (${#list[@]} key terms)"
  fi
done <<< "$MOVED"

if [ "$rows" -eq 0 ]; then
  echo "  ✘ no moved sections listed; nothing was checked"
  exit 1
fi
if [ "$FAILED" -ne 0 ]; then
  echo "An Agent Skill body is over the cap, or detail moved out of a body cannot be found."
  exit 1
fi
echo "✔ Every Agent Skill body is under 5,000 tokens, and the detail moved out of qa-plan and"
echo "  /qa-cases is in the reference section each body points to."
