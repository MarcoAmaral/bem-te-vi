#!/usr/bin/env bash
# generate-adapters.sh — Generate editor adapter files from the modular QA commands
# Source: Compiled recursively from .claude/{rules,commands,skills,agents}
# Version: 2.0.0

set -euo pipefail

# Byte order for every glob and sort, so the merged adapters come out identical whatever the
# locale (en_US collation ignores hyphens) and identical to generate-adapters.ps1's ordinal sort.
export LC_COLLATE=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMANDS_DIR="$SCRIPT_DIR/.claude/commands"
OUT_DIR="$SCRIPT_DIR/adapters"

# Build a merged source file for non-Claude editors
# (Claude Code supports separate files natively; other editors need one big file)
MERGED_TMP="$(mktemp /tmp/qa-merged-XXXX.md)"
trap 'rm -f "$MERGED_TMP"' EXIT

# Print a source file without its leading YAML frontmatter (e.g. agent name/model).
# Frontmatter is Claude Code metadata; inside a merged adapter it is just noise.
# An unclosed frontmatter block is printed unchanged.
strip_frontmatter() {
    awk 'NR == 1 && $0 == "---" { infm = 1; next }
         infm { buf = buf $0 ORS; if ($0 == "---") { infm = 0; buf = "" }; next }
         { print }
         END { if (infm) printf "---%s%s", ORS, buf }' "$1"
}

build_merged_source() {
    # Start with the main dispatcher
    if [ -f "$COMMANDS_DIR/qa.md" ]; then
        {
            strip_frontmatter "$COMMANDS_DIR/qa.md"
            echo ""
            echo ""
            echo "---"
            echo ""
        } > "$MERGED_TMP"
    fi

    # Append each sub-command module
    for CMD_FILE in "$COMMANDS_DIR"/qa-*.md; do
        if [ -f "$CMD_FILE" ]; then
            {
                echo ""
                strip_frontmatter "$CMD_FILE"
                echo ""
                echo "---"
            } >> "$MERGED_TMP"
        fi
    done

    # Append all rules under .claude/rules/
    if [ -d "$SCRIPT_DIR/.claude/rules" ]; then
        for RULE_FILE in "$SCRIPT_DIR"/.claude/rules/*.md; do
            if [ -f "$RULE_FILE" ]; then
                {
                    echo ""
                    strip_frontmatter "$RULE_FILE"
                    echo ""
                    echo "---"
                } >> "$MERGED_TMP"
            fi
        done
    fi

    # Append all skills under .claude/skills/, each followed by its references/*.md.
    # Claude Code reads a skill's reference files on demand; the other editors only get this
    # one merged file, so the references must be in it. Byte (C locale) order keeps it fixed.
    if [ -d "$SCRIPT_DIR/.claude/skills" ]; then
        find "$SCRIPT_DIR/.claude/skills" -type f -name "SKILL.md" | LC_ALL=C sort | while read -r SKILL_FILE; do
            {
                echo ""
                strip_frontmatter "$SKILL_FILE"
                echo ""
                echo "---"
            } >> "$MERGED_TMP"
            REF_DIR="$(dirname "$SKILL_FILE")/references"
            [ -d "$REF_DIR" ] || continue
            find "$REF_DIR" -maxdepth 1 -type f -name "*.md" | LC_ALL=C sort | while read -r REF_FILE; do
                {
                    echo ""
                    strip_frontmatter "$REF_FILE"
                    echo ""
                    echo "---"
                } >> "$MERGED_TMP"
            done
        done
    fi

    # Append all agents under .claude/agents/
    if [ -d "$SCRIPT_DIR/.claude/agents" ]; then
        for AGENT_FILE in "$SCRIPT_DIR"/.claude/agents/*.md; do
            if [ -f "$AGENT_FILE" ]; then
                {
                    echo ""
                    strip_frontmatter "$AGENT_FILE"
                    echo ""
                    echo "---"
                } >> "$MERGED_TMP"
            fi
        done
    fi
}

build_merged_source
SOURCE="$MERGED_TMP"

# --- Flags -------------------------------------------------------------------
CLEAN=false
OPT_NO_COLOR=false
for arg in "$@"; do
  case "$arg" in
    --clean)    CLEAN=true ;;
    --no-color) OPT_NO_COLOR=true ;;
    -h|--help)
      echo "Usage: $(basename "$0") [--clean] [--no-color]"
      echo "  --clean     Remove adapters/ directory before generating"
      echo "  --no-color  Disable colored output"
      exit 0 ;;
    *) echo "Unknown flag: $arg"; exit 1 ;;
  esac
done

# --- Colors -------------------------------------------------------------------
# Colour is on for a human at a terminal, off when piped or redirected.
# GITHUB_ACTIONS is checked because Actions is not a TTY but its log viewer
# does render ANSI — without it, CI logs would lose all colour.
use_colour() {
    [ -n "${NO_COLOR:-}" ] && return 1
    [ -n "${FORCE_COLOR:-}" ] && return 0
    [ -n "${GITHUB_ACTIONS:-}" ] && return 0
    [ -t 1 ]
}

if [[ "$OPT_NO_COLOR" == true ]]; then
  GREEN="" YELLOW="" RED="" RESET=""
elif use_colour; then
  GREEN="\033[0;32m" YELLOW="\033[0;33m" RED="\033[0;31m" RESET="\033[0m"
else
  GREEN="" YELLOW="" RED="" RESET=""
fi

info()    { printf "${YELLOW}[INFO]${RESET}  %s\n" "$1"; }
success() { printf "${GREEN}[OK]${RESET}    %s\n" "$1"; }
error()   { printf "${RED}[ERR]${RESET}   %s\n" "$1" >&2; }

# --- Validate source ----------------------------------------------------------
if [[ ! -f "$SOURCE" ]]; then
  error "Source file not found: $SOURCE"
  exit 1
fi

# --- Clean --------------------------------------------------------------------
if [[ "$CLEAN" == true ]]; then
  info "Removing $OUT_DIR"
  rm -rf "$OUT_DIR"
fi

# --- Cursor MDC frontmatter ---------------------------------------------------
CURSOR_FRONT='---
description: "Senior QA Analyst + QA Engineer — aligned with ISTQB CTFL v4.0; Playwright, Vitest, BDD and CI/CD"
alwaysApply: false
---
'

# --- Adapter definitions ("key:relative path", in generation order) ------------
# Plain indexed array, not an associative one: macOS ships bash 3.2, which has no
# `declare -A`, and would abort here under `set -u`.
ADAPTERS=(
  "cursor:cursor/qa.mdc"
  "windsurf:windsurf/qa.md"
  "copilot:copilot/copilot-instructions.md"
  "cline:cline/.clinerules"
  "antigravity:antigravity/qa/SKILL.md"
  # Universal — no IDE-specific frontmatter, plain markdown
  # AGENTS.md: recognized by Codex, Devin, Claude Code (--agents-file), and most modern agents
  # CLAUDE.md: recognized by Claude Code globally when placed in ~/.claude/
  "agents:universal/AGENTS.md"
  "claude_global:universal/CLAUDE.md"
)

# --- Generate -----------------------------------------------------------------
info "Source: compiled recursively from .claude/ folder structure"
info "Output: $OUT_DIR"
echo ""

declare -a GENERATED=()

for entry in "${ADAPTERS[@]}"; do
  key="${entry%%:*}"
  rel="${entry#*:}"
  dest="$OUT_DIR/$rel"
  mkdir -p "$(dirname "$dest")"

  case "$key" in
    cursor)
      # Prepend MDC YAML frontmatter
      printf '%s\n' "$CURSOR_FRONT" > "$dest"
      cat "$SOURCE" >> "$dest"
      ;;
    antigravity)
      # Prepend Antigravity YAML frontmatter (name + description)
      cat > "$dest" << 'AG_FRONT'
---
name: qa
description: "Senior QA Analyst + QA Engineer — aligned with ISTQB CTFL v4.0; Playwright, Vitest, BDD and CI/CD"
---
AG_FRONT
      cat "$SOURCE" >> "$dest"
      ;;
    agents|claude_global)
      # Universal adapter — plain merged markdown, no IDE-specific frontmatter
      # AGENTS.md is the emerging cross-editor standard (Codex, Devin, Claude Code --agents-file)
      # CLAUDE.md is Claude Code's global skill file format (~/.claude/CLAUDE.md)
      cat > "$dest" << 'UNIVERSAL_HEADER'
<!-- Bem-te-vi — Senior QA Analyst + QA Engineer (ISTQB CTFL v4.0)
     Universal adapter: no IDE-specific frontmatter.
     Compatible with: Claude Code (CLAUDE.md / --agents-file), Codex, Devin,
     GitHub Copilot (paste into instructions), and any agent that reads markdown.
     Install globally:
       cp adapters/universal/CLAUDE.md ~/.claude/CLAUDE.md        # Claude Code global
       cp adapters/universal/AGENTS.md ~/AGENTS.md                # Codex / Devin / others
       cp adapters/universal/AGENTS.md <project-root>/AGENTS.md   # Project-level universal
-->

UNIVERSAL_HEADER
      cat "$SOURCE" >> "$dest"
      ;;
    *)
      cp "$SOURCE" "$dest"
      ;;
  esac

  GENERATED+=("$dest")
  success "Generated $rel"
done

# --- Optional: install universals globally -----------------------------------
echo ""
if [[ "${GLOBAL:-false}" == "true" ]]; then
  info "Installing global adapters..."

  # Claude Code global skill (~/.claude/CLAUDE.md)
  CLAUDE_GLOBAL="$HOME/.claude/CLAUDE.md"
  mkdir -p "$(dirname "$CLAUDE_GLOBAL")"
  cp "$OUT_DIR/universal/CLAUDE.md" "$CLAUDE_GLOBAL"
  success "Installed Claude Code global: $CLAUDE_GLOBAL"

  # Universal AGENTS.md in home directory
  AGENTS_GLOBAL="$HOME/AGENTS.md"
  cp "$OUT_DIR/universal/AGENTS.md" "$AGENTS_GLOBAL"
  success "Installed universal global: $AGENTS_GLOBAL"
else
  printf "%b[TIP]%b   To install globally, run: GLOBAL=true ./generate-adapters.sh\n" "${YELLOW}" "${RESET}"
  printf "        Claude Code global  → cp adapters/universal/CLAUDE.md ~/.claude/CLAUDE.md\n"
  printf "        Universal (Codex…)  → cp adapters/universal/AGENTS.md ~/AGENTS.md\n"
  printf "        Project-level       → cp adapters/universal/AGENTS.md <project>/AGENTS.md\n"
fi

# --- Summary table ------------------------------------------------------------
echo ""
printf "%b%-50s %8s  %s%b\n" "${YELLOW}" "FILE" "SIZE" "SHA256" "${RESET}"
printf '%.0s-' {1..110}; echo ""

for f in "${GENERATED[@]}"; do
  rel="${f#"$OUT_DIR/"}"
  size=$(stat --printf='%s' "$f" 2>/dev/null || stat -f '%z' "$f")
  hash=$(sha256sum "$f" 2>/dev/null | awk '{print $1}') \
    || hash=$(shasum -a 256 "$f" | awk '{print $1}')
  printf "%-50s %6s B  %s\n" "$rel" "$size" "$hash"
done

echo ""
success "All adapters generated (${#GENERATED[@]} files)"
