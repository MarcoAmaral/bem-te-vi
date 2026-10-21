#!/usr/bin/env bash
# tests/test-reference-links.sh — every pointer to a skill reference file resolves (plan 021),
# and no pointer uses a path that resolves in only one kind of install (plan 034).
#
# Detail that used to sit in the always-loaded rules now lives in skill reference files, read on
# demand. A command, skill, agent or rule that names one is the only route to it, so a pointer
# to a file that was renamed or never written silently loses that content. Every
# `references/<file>.md` mentioned under .claude/{commands,skills,agents,rules} must be written:
#
#   - "the `<skill>` skill's `references/<file>.md`", where <skill> is a folder under
#     .claude/skills/ holding a SKILL.md and the file exists in its references/ folder (plan 057:
#     the reader loads the skill, which tells it where the skill's folder is in this install)
#   - or a bare `references/<file>.md` inside a skill's own SKILL.md, relative to its folder
#
# A SKILL.md that names another skill's file must also say the file is "in the `<skill>` skill's
# folder, not this skill's": Claude Code loads a skill with its own folder as the base directory,
# and a reader otherwise looks for the file there.
#
# Any path with a folder before references/ (`qa-reference/references/<file>.md`, the form of
# plan 034, or a `skills/` or `..` prefix) is rejected: a reader takes it as a path from the
# project root, where it does not exist in any install (plan 057, the spot check of 2026-10-19).
#
# A `.claude/rules/`, `.claude/skills/` or `.claude/commands/` path resolves only in a Claude Code
# project install, so none may appear under .claude/{commands,skills,agents,rules,hooks}: a rule
# is named by its name, a reference as above, a command by its slash name.
#
# The check fails closed: a missing source folder, a file it cannot read, or a tree in which it
# finds no pointer at all is an error, never a pass. Run with no argument, it first proves that on
# throwaway trees (self-test), then checks this repository.
#
# Usage: tests/test-reference-links.sh [repo-dir]    (default: self-test, then this repository)

# Backticks in the pointer text below are Markdown, never command substitutions.
# shellcheck disable=SC2016
set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# check_tree <root>: prints every finding; returns 0 only when pointers were found and all resolve.
check_tree() {
  local root="$1" failed=0 checked=0 files=0 d list file rel refs rc ref target
  for d in commands skills agents rules; do
    if [ ! -d "$root/.claude/$d" ]; then
      echo "  ✘ $root/.claude/$d does not exist; nothing there can be checked"
      failed=1
    fi
  done
  [ "$failed" -eq 0 ] || return 1

  if ! list="$(find "$root/.claude/commands" "$root/.claude/skills" "$root/.claude/agents" \
                    "$root/.claude/rules" -type f -name '*.md')"; then
    echo "  ✘ could not list the files under $root/.claude"
    return 1
  fi
  list="$(printf '%s\n' "$list" | LC_ALL=C sort)"

  # The one pointer form (plan 057): the `<skill>` skill's `references/<file>.md`. Text is read
  # with its whitespace collapsed, so a pointer wrapped across two lines is still one pointer.
  local re_named re_bare re_path text
  re_named='^[Tt]he `([A-Za-z0-9_-]+)` skill'"'"'s `references/([A-Za-z0-9_-][A-Za-z0-9_.-]*\.md)$'
  re_bare='^`?references/([A-Za-z0-9_-][A-Za-z0-9_.-]*\.md)$'
  re_path='[A-Za-z0-9_.-]/references/'

  while IFS= read -r file; do
    [ -n "$file" ] || continue
    files=$((files + 1))
    rel="${file#"$root"/}"
    if ! text="$(tr -s '[:space:]' ' ' < "$file" 2>/dev/null)"; then
      echo "  ✘ could not read $rel"
      failed=1
      continue
    fi
    # A `<folder>/references/` path, the form plan 034 used, reads as a path from the project root
    # and does not open in a Claude Code install (plan 057): name the skill instead.
    if printf '%s\n' "$text" | grep -qE "$re_path"; then
      echo "  ✘ $rel names a path with a folder before references/; write the \`<skill>\` skill's \`references/<file>.md\`:"
      printf '%s\n' "$text" | grep -oE "[A-Za-z0-9_./-]*${re_path}[A-Za-z0-9_.<>-]*" | LC_ALL=C sort -u | sed 's/^/      /'
      failed=1
    fi
    refs="$(printf '%s\n' "$text" | grep -oE "([Tt]he \`[A-Za-z0-9_-]+\` skill's )?\`?[A-Za-z0-9_./-]*references/[A-Za-z0-9_.-]+\.md")"
    while IFS= read -r ref; do
      [ -n "$ref" ] || continue
      checked=$((checked + 1))
      if [[ "$ref" =~ $re_named ]]; then
        if [ ! -f "$root/.claude/skills/${BASH_REMATCH[1]}/SKILL.md" ]; then
          echo "  ✘ $rel points to '$ref', but '${BASH_REMATCH[1]}' is not a skill (no .claude/skills/${BASH_REMATCH[1]}/SKILL.md)"
          failed=1
          continue
        fi
        target="$root/.claude/skills/${BASH_REMATCH[1]}/references/${BASH_REMATCH[2]}"
        # Another skill's SKILL.md loads with its own folder as the base: unless it says the file
        # is in the named skill's folder, a reader looks for it in the wrong one (plan 057).
        if [ "${file##*/}" = SKILL.md ] && [ "$(basename "$(dirname "$file")")" != "${BASH_REMATCH[1]}" ] &&
           ! printf '%s\n' "$text" | grep -qF "in the \`${BASH_REMATCH[1]}\` skill's folder, not this skill's"; then
          echo "  ✘ $rel names '$ref' but does not say the file is \"in the \`${BASH_REMATCH[1]}\` skill's folder, not this skill's\""
          failed=1
        fi
      elif [[ "$ref" =~ $re_bare ]] && [ "${file##*/}" = SKILL.md ]; then
        # A skill's own SKILL.md names its own folder's files.
        target="$(dirname "$file")/references/${BASH_REMATCH[1]}"
      elif [[ "$ref" =~ $re_bare ]]; then
        echo "  ✘ $rel uses '$ref'; outside a skill's SKILL.md, write the \`<skill>\` skill's \`references/<file>.md\`"
        failed=1
        continue
      else
        case "$ref" in */references/*) continue ;; esac   # reported above as a folder path
        echo "  ✘ $rel points to '$ref', which is not the \`<skill>\` skill's \`references/<file>.md\`"
        failed=1
        continue
      fi
      if [ ! -f "$target" ]; then
        echo "  ✘ $rel points to '$ref', which does not exist (looked for ${target#"$root"/})"
        failed=1
      fi
    done <<EOF
$(printf '%s\n' "$refs" | LC_ALL=C sort -u)
EOF
  done <<EOF
$list
EOF

  if [ "$files" -eq 0 ] || [ "$checked" -eq 0 ]; then
    echo "  ✘ found $files file(s) and $checked reference pointer(s) under $root/.claude; expected some of each"
    failed=1
  fi

  local old line
  old="$(grep -rnE '\.claude/(rules|skills|commands)/' "$root/.claude/commands" "$root/.claude/skills" \
    "$root/.claude/agents" "$root/.claude/rules" "$root/.claude/hooks")"
  rc=$?
  if [ "$rc" -gt 1 ]; then
    echo "  ✘ could not search $root/.claude for project-only paths"
    failed=1
  elif [ "$rc" -eq 0 ]; then
    echo "  ✘ pointers that resolve only in a Claude Code project install (name the rule, the"
    echo "    <skill>/references/<file>.md path or the /command instead):"
    # The root is stripped as text, never built into a sed or regex expression.
    while IFS= read -r line; do
      printf '      %s\n' "${line#"$root"/}"
    done <<EOF
$old
EOF
    failed=1
  fi

  [ "$failed" -eq 0 ] && echo "  ✔ $checked reference pointers in $files files resolve"
  return "$failed"
}

if [ $# -gt 0 ]; then
  if check_tree "$1"; then exit 0; fi
  echo "Reference link check failed."
  exit 1
fi

# --- Self-test: the check must fail closed on each of these trees ----------------------------
WORK="$(mktemp -d "${TMPDIR:-/tmp}/reference-links.XXXXXX")"
trap 'chmod -R u+rwx "$WORK" 2>/dev/null; rm -rf "$WORK"' EXIT
SELF_FAILED=0

# tree <name>: a minimal valid tree (one skill, one reference, one command pointing to it).
tree() {
  local t="$WORK/$1"
  mkdir -p "$t/.claude/commands" "$t/.claude/skills/s/references" "$t/.claude/agents" \
           "$t/.claude/rules" "$t/.claude/hooks"
  printf -- '---\nname: s\n---\nRead references/a.md.\n' > "$t/.claude/skills/s/SKILL.md"
  printf 'A reference.\n' > "$t/.claude/skills/s/references/a.md"
  printf 'See the `s` skill'"'"'s `references/a.md`.\n' > "$t/.claude/commands/qa-x.md"
  printf '%s' "$t"
}

# expect <pass|fail> <label> <root>
expect() {
  local out rc
  out="$(check_tree "$3" 2>&1)"
  rc=$?
  if { [ "$1" = pass ] && [ "$rc" -eq 0 ]; } || { [ "$1" = fail ] && [ "$rc" -ne 0 ]; }; then
    echo "  ✔ self-test: $2 ($1)"
  else
    echo "  ✘ self-test: $2: expected $1, got exit $rc"
    printf '%s\n' "$out" | sed 's/^/      /'
    SELF_FAILED=1
  fi
}

expect pass "a valid tree" "$(tree valid)"

mkdir -p "$WORK/empty"
expect fail "a tree with no .claude folder" "$WORK/empty"

T="$(tree no-pointers)"
printf 'No pointer here.\n' > "$T/.claude/commands/qa-x.md"
printf -- '---\nname: s\n---\nNothing.\n' > "$T/.claude/skills/s/SKILL.md"
expect fail "a tree with no reference pointer at all" "$T"

T="$(tree unreadable)"
printf 'See the `s` skill'"'"'s `references/missing.md`.\n' > "$T/.claude/rules/r.md"
chmod 000 "$T/.claude/rules/r.md"
if [ -r "$T/.claude/rules/r.md" ]; then
  echo "  - self-test: an unreadable file (not run: this user can read a mode-000 file)"
else
  expect fail "an unreadable file" "$T"
fi

T="$(tree missing)"
printf 'See the `s` skill'"'"'s `references/missing.md`.\n' > "$T/.claude/commands/qa-y.md"
expect fail "a pointer to a reference that does not exist" "$T"

T="$(tree old-style)"
printf 'Apply .claude/rules/r.md.\n' > "$T/.claude/commands/qa-y.md"
expect fail "a project-only .claude/rules/ path" "$T"

# The resolution rule is the one the package states (plan 057) and the generators follow (they
# copy a skill's own references/*.md, one level deep): a bare `references/<file>.md` only inside a
# skill's SKILL.md, the named form only for a folder that is a skill.
T="$(tree wrapped)"
printf 'See the `s`\nskill'"'"'s `references/a.md`, wrapped.\n' > "$T/.claude/rules/r.md"
expect pass "the named form wrapped across two lines" "$T"

T="$(tree path-form)"
printf 'See `s/references/a.md`.\n' > "$T/.claude/rules/r.md"
expect fail "a <skill>/references/<file>.md path (plan 034's form; read from the project root)" "$T"

T="$(tree folder-form)"
printf 'Files in `s/references/`.\n' > "$T/.claude/commands/qa-y.md"
expect fail "a <skill>/references/ folder path" "$T"

T="$(tree other-skill)"
mkdir -p "$T/.claude/skills/t"
printf -- '---\nname: t\n---\nSee the `s` skill'"'"'s `references/a.md`.\n' > "$T/.claude/skills/t/SKILL.md"
expect fail "another skill's SKILL.md naming the file without saying whose folder it is in" "$T"
printf -- '---\nname: t\n---\nFiles named so are in the `s` skill'"'"'s folder, not this skill'"'"'s.\nSee the `s` skill'"'"'s `references/a.md`.\n' \
  > "$T/.claude/skills/t/SKILL.md"
expect pass "another skill's SKILL.md that says whose folder the file is in" "$T"

T="$(tree skills-prefix)"
printf 'See skills/s/references/a.md.\n' > "$T/.claude/commands/qa-y.md"
expect fail "a skills/<skill>/references/ path (resolves only in a project install)" "$T"

T="$(tree not-a-skill)"
mkdir -p "$T/.claude/skills/notes/references"
printf 'A note.\n' > "$T/.claude/skills/notes/references/b.md"
printf 'See the `notes` skill'"'"'s `references/b.md`.\n' > "$T/.claude/commands/qa-y.md"
expect fail "a named skill whose folder has no SKILL.md" "$T"

T="$(tree dot-dot)"
printf 'See s/../s/references/a.md.\n' > "$T/.claude/commands/qa-y.md"
expect fail "a path with .. in it" "$T"

T="$(tree nested)"
mkdir -p "$T/.claude/skills/s/x/references"
printf 'Nested.\n' > "$T/.claude/skills/s/x/references/c.md"
printf 'See s/x/references/c.md.\n' > "$T/.claude/commands/qa-y.md"
expect fail "a references/ folder below a skill's own" "$T"

T="$(tree bare-outside-skill)"
mkdir -p "$T/.claude/commands/references"
printf 'Stray.\n' > "$T/.claude/commands/references/d.md"
printf 'See references/d.md.\n' > "$T/.claude/commands/qa-y.md"
expect fail "a bare references/ path outside a SKILL.md" "$T"

# Paths and pointer text are data: a folder name with sed or shell metacharacters, and pointer
# text holding a command substitution, must be reported as they are and never run.
T="$(tree 'meta#&;root')"
printf 'Apply .claude/rules/r.md.\n' > "$T/.claude/commands/qa-y.md"
out="$(check_tree "$T" 2>&1)"
if printf '%s\n' "$out" | grep -qF '      .claude/commands/qa-y.md:1:Apply .claude/rules/r.md.'; then
  echo "  ✔ self-test: a root path with # & ; is stripped from the report as text"
else
  echo "  ✘ self-test: a root path with # & ; garbled the report:"
  printf '%s\n' "$out" | sed 's/^/      /'
  SELF_FAILED=1
fi

T="$(tree injection)"
# shellcheck disable=SC2016 # the command substitution is the data under test, never expanded
printf 'See $(touch %s/ran)s/references/a.md and .claude/rules/$(touch %s/ran2).md\n' "$WORK" "$WORK" \
  > "$T/.claude/commands/qa-y.md"
check_tree "$T" > /dev/null 2>&1
if [ -e "$WORK/ran" ] || [ -e "$WORK/ran2" ]; then
  echo "  ✘ self-test: pointer text was executed"
  SELF_FAILED=1
else
  echo "  ✔ self-test: pointer text holding \$(...) is never executed"
fi

if [ "$SELF_FAILED" -ne 0 ]; then
  echo "Reference link self-test failed."
  exit 1
fi

if check_tree "$REPO"; then
  echo "✔ All reference pointers resolve."
  exit 0
fi
echo "Reference link check failed."
exit 1
