#!/usr/bin/env bash
# tests/test-rules-size.sh — the always-loaded rules stay small (plan 021).
#
# Claude Code loads every .claude/rules/*.md without `paths:` frontmatter at launch, in every
# conversation of an installed project, whether or not it is about testing. Long templates and
# examples therefore live in the qa-reference skill (.claude/skills/qa-reference/references/),
# which is read only when the work needs it. This check fails if the rules regrow past the cap,
# so the diet cannot be undone one paragraph at a time.
#
# It also prints what the rules cost in context, in tokens, because that is the unit editors and
# model providers report (plan 050). The figure is an estimate: bytes divided by 4, the usual rule
# of thumb for English text. Bytes rather than characters, because `wc -c` behaves the same on every
# platform and `wc -m` depends on the locale; the rules are almost all ASCII, so the two differ by
# under 1%. An exact count needs one model's tokenizer, and the package is model-agnostic.
#
# Usage: tests/test-rules-size.sh [repo-dir]    (default: this repository)

set -u

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
MAX_BYTES=25000

total=0
count=0
for rule in "$ROOT"/.claude/rules/*.md; do
  [ -e "$rule" ] || continue
  size=$(wc -c < "$rule" | tr -d ' ')
  printf '  %6s B  %s\n' "$size" "${rule#"$ROOT"/}"
  total=$((total + size))
  count=$((count + 1))
done

if [ "$count" -eq 0 ]; then
  echo "  ✘ no rules found under $ROOT/.claude/rules"
  exit 1
fi
if [ "$total" -gt "$MAX_BYTES" ]; then
  echo "  ✘ the $count always-loaded rules total $total bytes; the cap is $MAX_BYTES."
  echo "    Move templates, examples and long procedures into a reference file under"
  echo "    .claude/skills/qa-reference/references/ and point to it from the rule."
  exit 1
fi
tokens=$(((total + 2) / 4))
echo "✔ The $count always-loaded rules total $total bytes (cap $MAX_BYTES), about $tokens tokens of"
echo "  context in every conversation (an estimate: bytes / 4)."
