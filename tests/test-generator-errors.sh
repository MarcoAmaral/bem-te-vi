#!/usr/bin/env bash
# tests/test-generator-errors.sh — generate-adapters.sh refuses a source tree it would turn into
# broken adapters, and says why (plan 054).
#
# Every command and agent becomes the skill its frontmatter id names, and every skill folder keeps
# its own name. A command with no id once became adapters/skills//SKILL.md, and an id equal to a
# skill folder's name let one silently overwrite the other. This plants each case from
# tests/fixtures/generator-errors.txt in a scratch tree, runs a copy of the generator there, and
# compares every error line it prints with the file. tests/test-generator-errors.ps1 does the same
# for generate-adapters.ps1 against the same file, so both generators print the same words.
# tests/verify-adapters.sh runs this script.
#
# Usage: tests/test-generator-errors.sh [repo-dir]    (default: this repository)

set -u

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
CASES="$ROOT/tests/fixtures/generator-errors.txt"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FAILED=0
COUNT=0

# plant <tree> <path> [<id>]: a small Markdown file, with that id in its frontmatter if one is given.
plant() {
    mkdir -p "$(dirname "$1/$2")"
    {
        echo "---"
        [ -z "${3:-}" ] || echo "id: $3"
        echo "description: \"Planted by tests/test-generator-errors (plan 054).\""
        echo "---"
        echo "# ${2##*/}"
    } > "$1/$2"
}

# run_case <name> <plants> <expected error lines>
run_case() {
    local NAME="$1" TREE="$TMP/$1" P ID OUT RC GOT BAD=0
    COUNT=$((COUNT + 1))
    mkdir -p "$TREE"
    cp "$ROOT/generate-adapters.sh" "$TREE/"
    while read -r P ID; do
        [ -n "$P" ] && plant "$TREE" "$P" "$ID"
    done <<EOF
$2
EOF
    OUT="$(bash "$TREE/generate-adapters.sh" --no-color 2>&1)"
    RC=$?
    GOT="$(printf '%s\n' "$OUT" | tr -d '\r' | grep '^\[ERR\]' || true)"
    if [ -z "$3" ]; then
        if [ "$RC" -ne 0 ] || [ -n "$GOT" ]; then
            echo "  ✘ $NAME: expected a clean run, got exit $RC"; printf '%s\n' "$OUT" | sed 's/^/      | /'
            FAILED=1; return
        fi
        if [ ! -f "$TREE/adapters/skills/qa/SKILL.md" ] || [ ! -f "$TREE/adapters/skills/qa-plan/SKILL.md" ]; then
            echo "  ✘ $NAME: the skills qa and qa-plan were not generated"; FAILED=1; return
        fi
    else
        if [ "$RC" -eq 0 ]; then
            echo "  ✘ $NAME: expected a non-zero exit, got 0"; BAD=1
        fi
        if [ "$GOT" != "$3" ]; then
            echo "  ✘ $NAME: error lines differ from tests/fixtures/generator-errors.txt"
            echo "      expected:"; printf '%s\n' "$3" | sed 's/^/      | /'
            echo "      got:"; printf '%s\n' "${GOT:-(none)}" | sed 's/^/      | /'
            BAD=1
        fi
        if [ -e "$TREE/adapters" ]; then
            echo "  ✘ $NAME: adapters/ was written although the generator refused the tree"; BAD=1
        fi
        if [ "$BAD" -ne 0 ]; then FAILED=1; return; fi
    fi
    echo "  ✔ $NAME"
}

NL='
'
BASE=""; NAME=""; PLANTS=""; ERRS=""
while IFS= read -r LINE || [ -n "$LINE" ]; do
    case "$LINE" in
        '#'*|'') continue ;;
        '== '*)
            [ -z "$NAME" ] || run_case "$NAME" "$BASE$PLANTS" "$ERRS"
            NAME="${LINE#== }"; PLANTS=""; ERRS="" ;;
        'plant '*)
            if [ -z "$NAME" ]; then BASE="$BASE${LINE#plant }$NL"; else PLANTS="$PLANTS${LINE#plant }$NL"; fi ;;
        '[ERR]'*) ERRS="${ERRS:+$ERRS$NL}$LINE" ;;
        *) echo "  ✘ unreadable line in $CASES: $LINE"; FAILED=1 ;;
    esac
done < "$CASES"
[ -z "$NAME" ] || run_case "$NAME" "$BASE$PLANTS" "$ERRS"

if [ "$FAILED" -ne 0 ]; then
    echo "Generator error check failed."
    exit 1
fi
echo "✔ generate-adapters.sh handled all $COUNT planted trees as tests/fixtures/generator-errors.txt says."
