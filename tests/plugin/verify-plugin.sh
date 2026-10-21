#!/usr/bin/env bash
# tests/plugin/verify-plugin.sh — the Claude Code plugin manifests only *reference* the shipped
# content under .claude/, so they can drift from it without anything else noticing (plan 022).
#
#   - .claude-plugin/plugin.json and marketplace.json parse as JSON
#   - the marketplace lists one plugin, named like the manifest, with "source": "."
#   - every path the manifest names (commands, skills, agents) exists inside the repository
#   - the manifest's agent list equals .claude/agents/*.md (the platform takes files, not a
#     directory, so a new or removed agent must be mirrored in plugin.json)
#   - plugin.json "version" equals package.json "version" (Release Please bumps both)
#   - when the `claude` CLI is installed, `claude plugin validate .` passes
#
# Usage: tests/plugin/verify-plugin.sh [repo-dir]    (default: this repository)

set -u

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
PLUGIN="$ROOT/.claude-plugin/plugin.json"
MARKET="$ROOT/.claude-plugin/marketplace.json"
FAILED=0

fail() { echo "  ✘ $1"; FAILED=1; }
pass() { echo "  ✔ $1"; }

command -v node >/dev/null 2>&1 || { echo "node is required"; exit 2; }

# json_get <file> <js expression over d> — prints the value; empty output if absent. The
# expressions are literals in this script (never external input), so eval is safe here.
json_get() {
  node -e '
    const d = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
    const v = eval(process.argv[2]);
    if (v !== undefined && v !== null) console.log(Array.isArray(v) ? v.join("\n") : v);
  ' "$1" "$2" 2>/dev/null
}

echo "Plugin manifests ($ROOT)"

for f in "$PLUGIN" "$MARKET"; do
  if [ ! -f "$f" ]; then
    fail "${f#"$ROOT"/} is missing"
  elif ! node -e 'JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"))' "$f" 2>/dev/null; then
    fail "${f#"$ROOT"/} is not valid JSON"
  else
    pass "${f#"$ROOT"/} parses"
  fi
done
if [ "$FAILED" -ne 0 ]; then echo "FAILED"; exit 1; fi

# Marketplace entry matches the manifest
pname="$(json_get "$PLUGIN" 'd.name')"
mname="$(json_get "$MARKET" 'd.plugins.length === 1 ? d.plugins[0].name : ""')"
msource="$(json_get "$MARKET" 'd.plugins[0] && d.plugins[0].source')"
if [ -z "$pname" ] || [ "$pname" != "$mname" ]; then
  fail "marketplace must list exactly one plugin named like plugin.json (plugin: '$pname', marketplace: '$mname')"
else
  pass "marketplace entry name matches plugin.json ('$pname')"
fi
if [ "$msource" != "." ]; then
  fail "marketplace entry source must be \".\" (got '$msource')"
else
  pass 'marketplace entry source is "."'
fi

# Every referenced path exists
refs="$(json_get "$PLUGIN" '[].concat(d.commands || [], d.skills || [], d.agents || [])')"
if [ -z "$refs" ]; then
  fail "plugin.json names no commands, skills or agents"
fi
while IFS= read -r ref; do
  [ -z "$ref" ] && continue
  case "$ref" in
    ./*) ;;
    *) fail "path '$ref' must start with ./"; continue ;;
  esac
  case "$ref" in
    *..*) fail "path '$ref' must stay inside the plugin root"; continue ;;
  esac
  if [ -e "$ROOT/$ref" ]; then pass "exists: $ref"; else fail "missing: $ref"; fi
done <<< "$refs"

# Agent list equals the files on disk
listed="$(json_get "$PLUGIN" 'd.agents || []' | sort)"
ondisk="$(cd "$ROOT" && for f in .claude/agents/*.md; do [ -e "$f" ] && echo "./$f"; done | sort)"
if [ "$listed" = "$ondisk" ]; then
  pass "agent list matches .claude/agents/*.md"
else
  fail "agent list drifted from .claude/agents/*.md"
  diff <(echo "$listed") <(echo "$ondisk") | sed 's/^/      /'
fi

# Versions agree
pv="$(json_get "$PLUGIN" 'd.version')"
npmv="$(json_get "$ROOT/package.json" 'd.version')"
if [ -n "$pv" ] && [ "$pv" = "$npmv" ]; then
  pass "plugin.json version equals package.json ($pv)"
else
  fail "plugin.json version '$pv' differs from package.json '$npmv'"
fi

# The platform's own validator, when present
if command -v claude >/dev/null 2>&1; then
  if out="$(cd "$ROOT" && claude plugin validate . 2>&1)"; then
    pass "claude plugin validate ."
    printf '%s\n' "$out" | sed 's/^/      /'
  else
    fail "claude plugin validate . failed"
    printf '%s\n' "$out" | sed 's/^/      /'
  fi
  # `.` validates the marketplace; the manifest is validated by pointing at its file. The
  # CLAUDE.md warning is expected: plugins cannot ship one, and this repository's is project guidance.
  if out="$(cd "$ROOT" && claude plugin validate .claude-plugin/plugin.json 2>&1)"; then
    pass "claude plugin validate .claude-plugin/plugin.json"
    printf '%s\n' "$out" | sed 's/^/      /'
  else
    fail "claude plugin validate .claude-plugin/plugin.json failed"
    printf '%s\n' "$out" | sed 's/^/      /'
  fi
else
  echo "  - claude CLI not installed: skipping 'claude plugin validate .'"
fi

if [ "$FAILED" -ne 0 ]; then echo "FAILED"; exit 1; fi
echo "OK"
