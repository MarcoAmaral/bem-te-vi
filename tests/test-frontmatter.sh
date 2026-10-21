#!/usr/bin/env bash
# tests/test-frontmatter.sh — every shipped Markdown file carries the frontmatter it needs: the
# fields Claude Code (and any Agent Skills runtime) reads to list a skill or command and decide
# when to load it (plan 019 phase 3), and the stable `id` a citation or a retrieval index uses
# to name the file whatever its path becomes (plan 038).
#
#   - each .claude/skills/<name>/SKILL.md and .claude/commands/*.md opens with a closed
#     YAML frontmatter block
#   - that block has a non-empty `description:` of at most 1024 characters
#   - a skill's `name:` equals its folder name: 1-64 lowercase letters, digits and single hyphens
#
# Without a description the runtime falls back to the file's heading, which says what the file
# is, not when to use it. The limits are the Agent Skills specification's
# (agentskills.io/specification); Claude Code itself truncates a listed description at 1,536
# characters, so the stricter 1024 covers both.
#
# And for every shipped .md (rules, commands, agents, skills, skill references):
#
#   - it opens with a closed frontmatter block holding an `id` of lowercase letters, digits and
#     single hyphens, unique across the package. A SKILL.md holds it under `metadata:` (the
#     Agent Skills specification allows no other top-level key); every other file at top level.
#   - no `version`, `title` or `istqb` key: the index derives those, so a copy here would drift
#   - a SKILL.md also holds `author: Marco Amaral` under `metadata:`, so a copied skill still
#     names its author (plan 060); commands, agents and rules have no `metadata:` map
#   - no rule has `paths:`, which would make Claude Code load it only for matching files
#
# An id is permanent: renaming or moving a file keeps it, and a deleted file's id is never
# reused (CONTRIBUTING.md). So the check does not derive the id from the path.
#
# Usage: tests/test-frontmatter.sh [repo-dir]    (default: this repository)

set -u

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
FAILED=0

fail() { echo "  ✘ $1: $2"; FAILED=1; }

# Print the frontmatter body (between the opening and closing ---), or nothing if the file
# does not open with a closed block.
frontmatter() {
  awk 'NR == 1 { if ($0 != "---") exit; next } $0 == "---" { closed = 1; exit } { body = body $0 "\n" }
       END { if (closed) printf "%s", body }' "$1"
}

# Value of a top-level `key:` in a frontmatter body, without surrounding quotes.
field() {
  printf '%s' "$1" | sed -n "s/^$2:[[:space:]]*//p" | head -n 1 |
    sed -e 's/[[:space:]]*$//' -e 's/^"\(.*\)"$/\1/' -e "s/^'\(.*\)'$/\1/"
}

check() {  # <file> <expected skill name, or empty for a command>
  local file="$1" want_name="$2" rel fm desc name
  rel="${file#"$ROOT"/}"
  fm="$(frontmatter "$file")"
  if [ -z "$fm" ]; then
    fail "$rel" "no frontmatter block (the first line must be ---, closed by another ---)"
    return
  fi
  desc="$(field "$fm" description)"
  if [ -z "$desc" ]; then
    fail "$rel" "frontmatter has no non-empty description"
  elif [ "${#desc}" -gt 1024 ]; then
    fail "$rel" "description is ${#desc} characters; the limit is 1024"
  fi
  if [ -n "$want_name" ]; then
    name="$(field "$fm" name)"
    if [ "$name" != "$want_name" ]; then
      fail "$rel" "name is '$name', expected the folder name '$want_name'"
    elif [ "${#name}" -gt 64 ] || ! printf '%s' "$name" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
      fail "$rel" "name '$name' must be 1-64 lowercase letters, digits and single hyphens"
    fi
  fi
}

count=0
for skill in "$ROOT"/.claude/skills/*/SKILL.md; do
  [ -e "$skill" ] || continue
  check "$skill" "$(basename "$(dirname "$skill")")"
  count=$((count + 1))
done
for cmd in "$ROOT"/.claude/commands/*.md; do
  [ -e "$cmd" ] || continue
  check "$cmd" ""
  count=$((count + 1))
done

if [ "$count" -eq 0 ]; then
  echo "  ✘ no skills or commands found under $ROOT/.claude"
  exit 1
fi

# The value of a key in a frontmatter body: at top level (want=top) or indented under
# `metadata:` (want=metadata). Prints nothing when it is not there in that form.
key_of() {  # <frontmatter body> <top|metadata> <key>
  printf '%s\n' "$1" | awk -v want="$2" -v key="$3" '
    /^[^[:space:]]/ { inmeta = ($0 ~ /^metadata:[[:space:]]*$/) }
    want == "top" && index($0, key ":") == 1 { v = substr($0, length(key) + 2); sub(/^[[:space:]]*/, "", v); print v; exit }
    want == "metadata" && inmeta && $0 ~ ("^[[:space:]]+" key ":") { v = $0; sub("^[[:space:]]+" key ":[[:space:]]*", "", v); print v; exit }' |
    sed -e 's/[[:space:]]*$//' -e 's/^"\(.*\)"$/\1/' -e "s/^'\(.*\)'$/\1/"
}
id_of() { key_of "$1" "$2" id; }  # <frontmatter body> <top|metadata>

ids=""
shipped=0
while IFS= read -r file; do
  shipped=$((shipped + 1))
  fm="$(frontmatter "$ROOT/$file")"
  if [ -z "$fm" ]; then
    fail "$file" "no frontmatter block, so no id (the first line must be ---, closed by another ---)"
    continue
  fi
  case "$file" in
    */SKILL.md) want=metadata; other=top ;;
    *) want=top; other=metadata ;;
  esac
  id="$(id_of "$fm" "$want")"
  if [ -z "$id" ]; then
    if [ -n "$(id_of "$fm" "$other")" ]; then
      fail "$file" "id is at the wrong level: a SKILL.md holds it under metadata:, every other file at top level"
    else
      fail "$file" "frontmatter has no id"
    fi
  elif ! printf '%s' "$id" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
    fail "$file" "id '$id' must be lowercase letters, digits and single hyphens"
  else
    ids="$ids$id $file
"
  fi
  case "$file" in
    */SKILL.md)
      author="$(key_of "$fm" metadata author)"
      [ "$author" = "Marco Amaral" ] ||
        fail "$file" "metadata has no 'author: Marco Amaral' (found '${author}'); a copied skill must name its author" ;;
  esac
  for key in version title istqb; do
    if printf '%s\n' "$fm" | grep -qE "^$key:"; then
      fail "$file" "frontmatter has '$key:'; the index derives it, so a copy here would drift"
    fi
  done
  case "$file" in
    .claude/rules/*)
      if printf '%s\n' "$fm" | grep -qE '^paths:'; then
        fail "$file" "a rule with paths: is loaded only for matching files; shipped rules load always"
      fi ;;
  esac
done < <(cd "$ROOT" && find .claude -type f -name '*.md' | LC_ALL=C sort)
dups="$(printf '%s' "$ids" | awk '{ print $1 }' | LC_ALL=C sort | uniq -d)"
for id in $dups; do
  fail "id '$id'" "used by more than one file: $(printf '%s' "$ids" | awk -v id="$id" '$1 == id { printf "%s ", $2 }')"
done

if [ "$FAILED" -ne 0 ]; then
  echo "Frontmatter check failed."
  exit 1
fi
echo "✔ All $count skills and commands carry valid frontmatter, and all $shipped shipped files a unique id."
