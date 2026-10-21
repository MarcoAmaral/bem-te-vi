#!/usr/bin/env bash
# tests/test-tc-contracts.sh — every place that tells an assistant how to write a TC file
# describes a format the TC hook accepts.
#
# Three files describe the test case format: the /qa-cases template, the /qa quick reference and
# the qa-writer agent's output contract (the /qa-agentic pipeline's last stage). When they drift,
# an assistant follows one of them and writes test cases the pre-commit hook rejects. That happened:
# the hook gained required fields, /qa-cases followed, and the other two did not.
#
# For each source, the fenced ```markdown block(s) under the named heading are assembled into a TC
# file, placeholder IDs (TC-[CODE]-NNN) are made concrete, and .claude/hooks/validate-tc-format.sh
# must accept the result.
#
# It also checks that the /qa-agentic pipeline offers every technique the technique reference
# teaches, that the ISTQB Technique rows of the TC templates name the same ones, that the
# qa-writer agent reads every field a qa-designer checklist entry has, and no other (plan 055), and
# that every Source value /qa-cases lists as accepted or rejected gets that verdict from the hook.
#
# And it checks that /qa-defect's template and examples follow the command's own rules, where
# plan 048's benchmark pilot found they did not: Root Cause stays N/A until analysis, with a
# separate field for suspicions, and every good title example has the rule's `when` clause.
#
# Usage: tests/test-tc-contracts.sh

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$ROOT/.claude/hooks/validate-tc-format.sh"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/tc-contracts.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
FAILED=0

# Print the contents of every ```markdown fence between the heading line that starts with $2 and
# the next level-2 heading.
blocks_under() {
  awk -v want="$2" '
    index($0, want) == 1 { inside = 1; next }
    inside && /^## / && !fence { inside = 0 }
    inside && /^```markdown/ { fence = 1; next }
    inside && fence && /^```/ { fence = 0; next }
    inside && fence { print }
  ' "$1"
}

check() {  # <label> <source file> <heading prefix>
  local label="$1" src="$ROOT/$2" heading="$3" out="$WORK/TC-$1.md"
  blocks_under "$src" "$heading" |
    sed -e 's/TC-\[CODE\]-NNN/TC-CODE-001/g' -e 's/^feature_code: \[CODE\]/feature_code: CODE/' > "$out"
  if ! grep -qE '^## TC-[A-Z0-9]+-[0-9]+:' "$out"; then
    echo "  ✘ $label: no test case block found under '$heading' in $2"
    FAILED=1
    return
  fi
  if bash "$HOOK" "$out" > "$WORK/$label.log" 2>&1; then
    echo "  ✔ $label ($2) passes the TC hook"
  else
    echo "  ✘ $label ($2) describes a format the TC hook rejects:"
    grep -F '[ERR]' "$WORK/$label.log" | sed -e 's/\x1b\[[0-9;]*m//g' -e "s#$WORK/##" -e 's/^/      /' | head -12
    FAILED=1
  fi
}

check qa-cases-example ".claude/commands/qa-cases.md" "## Complete Example"
check qa-quick-reference ".claude/commands/qa.md" "## 📋 TC Format Quick Reference"
check qa-writer-contract ".claude/agents/qa-writer.md" "## 📋 Output Contract"

# The runbook key: the hook still accepts its old name, `cdt`, so passing the hook does not show
# that a template writes the current one. The hook and all three templates must name `runbook`.
if grep -qE 'check_key [^ ]+ "runbook"' "$HOOK"; then
  echo "  ✔ the TC hook requires the runbook key"
else
  echo "  ✘ the TC hook does not require the runbook key"
  FAILED=1
fi
for label in qa-cases-example qa-quick-reference qa-writer-contract; do
  if grep -q '^runbook:' "$WORK/TC-$label.md" && ! grep -q '^cdt:' "$WORK/TC-$label.md"; then
    echo "  ✔ $label writes the runbook key"
  else
    echo "  ✘ $label does not write the runbook key (or still writes cdt, its old name)"
    FAILED=1
  fi
done

# The /qa-agentic pipeline's technique list. qa-designer's Technique enum must offer every technique
# in the reference's technique table, so that every technique the package teaches can be chosen in
# the pipeline. The ISTQB Technique row of qa-writer's contract and of the /qa quick reference must
# name the same techniques as the enum: the writer copies the designer's choice. Names compare
# case-insensitively: the table's abbreviation when it gives one ("Equivalence Partitioning (EP)"
# is EP), otherwise its name without " Testing".
REF="$ROOT/.claude/skills/qa-reference/references/testing-design.md"
awk '/^## ISTQB Test Design Techniques/ { on = 1; next } on && /^#/ { on = 0 } on && /^\| \*\*/ { print }' "$REF" |
  sed -E -e 's/^\| \*\*([^*]+)\*\*.*/\1/' -e 's/^.*\(([A-Z]+)\)$/\1/' -e 's/ Testing$//' > "$WORK/techniques-reference"
grep -m1 -E '^- Technique: \[' "$ROOT/.claude/agents/qa-designer.md" | sed -E 's/^- Technique: \[//; s/\].*$//' |
  tr '|' '\n' | sed -E 's/^ +//; s/ +$//' > "$WORK/techniques-designer"
if [ ! -s "$WORK/techniques-reference" ] || [ ! -s "$WORK/techniques-designer" ]; then
  echo "  ✘ could not read the technique table in testing-design.md or the qa-designer Technique enum"
  FAILED=1
else
  missing=""
  while IFS= read -r t; do
    grep -qixF -- "$t" "$WORK/techniques-designer" || missing="$missing, $t"
  done < "$WORK/techniques-reference"
  if [ -z "$missing" ]; then
    echo "  ✔ the qa-designer Technique enum offers every technique in the technique table"
  else
    echo "  ✘ the qa-designer Technique enum lacks techniques the reference teaches: ${missing#, }"
    FAILED=1
  fi
  designer="$(tr '[:upper:]' '[:lower:]' < "$WORK/techniques-designer" | sort)"
  for pair in "qa-writer-contract:.claude/agents/qa-writer.md" "qa-quick-reference:.claude/commands/qa.md"; do
    label="${pair%%:*}" src="${pair#*:}"
    grep -m1 -E '^\| \*\*ISTQB Technique\*\* ' "$ROOT/$src" | awk -F'|' '{ print $3 }' | tr '/' '\n' |
      sed -E 's/^ +//; s/ +$//' > "$WORK/techniques-$label"
    if [ "$(tr '[:upper:]' '[:lower:]' < "$WORK/techniques-$label" | sort)" = "$designer" ]; then
      echo "  ✔ $label's ISTQB Technique row names the qa-designer techniques"
    else
      echo "  ✘ $label's ISTQB Technique row ($src) and the qa-designer enum differ:"
      echo "      designer: $(paste -s -d '|' "$WORK/techniques-designer")"
      echo "      $label: $(paste -s -d '/' "$WORK/techniques-$label")"
      FAILED=1
    fi
  done
fi

# The hand-off between the last two stages. The fields of a checklist entry are the "- <Field>:"
# lines of the qa-designer's output contract; qa-writer names each field it reads as `<Field>:` in
# its "Where each value comes from in `checklist.md`" list. A field the designer writes and the
# writer never reads is lost on the way to the test case; a field the writer reads and the designer
# never writes is invented. The two lists must be equal.
blocks_under "$ROOT/.claude/agents/qa-designer.md" "## 📋 Output Contract" |
  sed -nE 's/^- ([A-Z][A-Za-z ]*):.*/\1/p' | sort -u > "$WORK/fields-designer"
# shellcheck disable=SC2016  # the backticks are literal Markdown, not a command substitution
awk 'index($0, "Where each value comes from in `checklist.md`") == 1 { on = 1; next }
     on && NF && !/^[- ]/ { on = 0 }
     on' "$ROOT/.claude/agents/qa-writer.md" |
  grep -oE '`[A-Z][A-Za-z ]*:`' | tr -d '`:' | sort -u > "$WORK/fields-writer"
if [ ! -s "$WORK/fields-designer" ] || [ ! -s "$WORK/fields-writer" ]; then
  echo "  ✘ could not read the qa-designer entry fields or the qa-writer \"Where each value comes from\" list"
  FAILED=1
else
  unread="$(comm -23 "$WORK/fields-designer" "$WORK/fields-writer" | paste -s -d ',' - | sed 's/,/, /g')"
  invented="$(comm -13 "$WORK/fields-designer" "$WORK/fields-writer" | paste -s -d ',' - | sed 's/,/, /g')"
  if [ -z "$unread" ] && [ -z "$invented" ]; then
    echo "  ✔ qa-writer reads every field of a qa-designer checklist entry: $(paste -s -d ',' "$WORK/fields-designer" | sed 's/,/, /g')"
  else
    [ -z "$unread" ] || echo "  ✘ qa-designer writes fields qa-writer never says it reads: $unread"
    [ -z "$invented" ] || echo "  ✘ qa-writer reads fields a qa-designer entry does not have: $invented"
    FAILED=1
  fi
fi

# The Source values /qa-cases lists are the ones the hook decides on: every value on its
# "- **Accepted**" line passes the hook, every value on its "- **Rejected**" line fails it with the
# Source error. Each is put into the otherwise valid fixture case in place of its Source.
CASES="$ROOT/.claude/commands/qa-cases.md"
for kind in Accepted Rejected; do
  grep -m1 -E "^- \*\*$kind\*\*" "$CASES" | grep -oE "\`[^\`]+\`" | tr -d '`' > "$WORK/source-$kind"
  if [ ! -s "$WORK/source-$kind" ]; then
    echo "  ✘ qa-cases lists no $kind Source values (a '- **$kind**' line with \`values\`)"
    FAILED=1
    continue
  fi
  n=0
  while IFS= read -r value; do
    n=$((n + 1))
    awk -v v="$value" '/^\| \*\*Source\*\*/ { print "| **Source** | " v " |"; next } { print }' \
      "$ROOT/tests/fixtures/tc-format/complete.md" > "$WORK/TC-source-$kind-$n.md"
    if bash "$HOOK" "$WORK/TC-source-$kind-$n.md" > "$WORK/source-$kind-$n.log" 2>&1; then
      verdict=accepted
    elif grep -q "has a Source that is neither an AC nor" "$WORK/source-$kind-$n.log"; then
      verdict=rejected
    else
      verdict="rejected for another reason"
    fi
    if { [ "$kind" = Accepted ] && [ "$verdict" = accepted ]; } ||
       { [ "$kind" = Rejected ] && [ "$verdict" = rejected ]; }; then
      echo "  ✔ qa-cases lists Source '$value' as $kind; the hook agrees"
    else
      echo "  ✘ qa-cases lists Source '$value' as $kind; the hook says $verdict"
      FAILED=1
    fi
  done < "$WORK/source-$kind"
done

# /qa-defect's own template and examples obey its own rules. The lines of a level-2 section, up to
# the next level-2 heading:
section() {  # <file> <heading prefix>
  awk -v want="$2" 'index($0, want) == 1 { on = 1; next } on && /^## / { on = 0 } on { print }' "$1"
}
DEFECT="$ROOT/.claude/commands/qa-defect.md"

# Root Cause is a finding of root-cause analysis, never a suspicion: the template's Root Cause
# starts as N/A, a Suspicions field holds what someone suspects, and the complete example does both.
for part in "## Defect Report Format" "## Complete Example"; do
  if section "$DEFECT" "$part" | grep -qE '^Root Cause +: N/A — not yet analysed'; then
    echo "  ✔ qa-defect '$part': Root Cause starts as 'N/A — not yet analysed'"
  else
    echo "  ✘ qa-defect '$part': Root Cause does not start as 'N/A — not yet analysed'"
    FAILED=1
  fi
  if section "$DEFECT" "$part" | grep -qE '^Suspicions +: '; then
    echo "  ✔ qa-defect '$part' has a Suspicions field for unconfirmed leads"
  else
    echo "  ✘ qa-defect '$part' has no Suspicions field: a suspicion has nowhere to go but Root Cause"
    FAILED=1
  fi
done

# Every good title it shows follows its title rule, `[Component] – [What failed] when [condition]`:
# the ✅ Good rows of the title table and the complete example's Title.
{
  section "$DEFECT" "## Title Format Rules" | grep -E '^\| ✅ Good' | awk -F'|' '{ print $3 }' |
    sed -E 's/^ *"//; s/" *$//'
  section "$DEFECT" "## Complete Example" | grep -m1 -E '^Title +:' | sed -E 's/^Title +: *//'
} > "$WORK/defect-titles"
if [ "$(wc -l < "$WORK/defect-titles")" -lt 2 ]; then
  echo "  ✘ could not read qa-defect's good titles (title table and complete example)"
  FAILED=1
fi
while IFS= read -r title; do
  if printf '%s\n' "$title" | grep -qE '^[^ –].* – .+ when .+$'; then
    echo "  ✔ qa-defect good title follows its rule: $title"
  else
    echo "  ✘ qa-defect good title breaks its rule '[Component] – [What failed] when [condition]': $title"
    FAILED=1
  fi
done < "$WORK/defect-titles"

if [ "$FAILED" -ne 0 ]; then
  echo "TC format or defect report contracts disagree with the package's own rules."
  exit 1
fi
echo "✔ Every TC format description passes the TC hook and names the pipeline's techniques;"
echo "  /qa-defect's template and examples follow its own rules."
