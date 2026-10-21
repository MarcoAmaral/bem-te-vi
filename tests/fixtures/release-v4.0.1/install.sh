#!/bin/bash

# Bem-te-vi - Installation Script
# Version: 2.0.0

set -e  # Exit on error

# ─── CLI Flag Defaults ───────────────────────────────────────────────────────

TARGET_FLAG=""
EDITOR_FLAG=""
NON_INTERACTIVE=false
OPT_NO_COLOR=false
NO_HOOKS=false
UPDATE_FLAG=false
UNINSTALL_FLAG=false
SHOW_HELP=false

# Cumulative uninstall reporting: how many recorded/matched files were actually removed vs.
# kept (changed since install, or read-only). The final summary is derived from these instead
# of assuming success.
UNINSTALL_REMOVED_COUNT=0
UNINSTALL_KEPT_COUNT=0

# ─── Parse CLI Flags ─────────────────────────────────────────────────────────

while [ $# -gt 0 ]; do
    case "$1" in
        --target)
            shift
            if [ -z "$1" ] || [[ "$1" == --* ]]; then
                echo "Error: --target requires a value (project|global|both)"
                exit 1
            fi
            TARGET_FLAG="$1"
            ;;
        --editor)
            shift
            if [ -z "$1" ] || [[ "$1" == --* ]]; then
                echo "Error: --editor requires a value (claude|cursor|windsurf|copilot|cline|antigravity|all)"
                exit 1
            fi
            EDITOR_FLAG="$1"
            ;;
        --non-interactive)
            NON_INTERACTIVE=true
            ;;
        --no-color)
            OPT_NO_COLOR=true
            ;;
        --no-hooks)
            NO_HOOKS=true
            ;;
        --update)
            UPDATE_FLAG=true
            ;;
        --uninstall|--remove)
            UNINSTALL_FLAG=true
            ;;
        --help)
            SHOW_HELP=true
            ;;
        *)
            echo "Unknown flag: $1"
            echo "Run with --help for usage information."
            exit 1
            ;;
    esac
    shift
done

# ─── Color codes ─────────────────────────────────────────────────────────────

# Colour is on for a human at a terminal, off when piped or redirected.
# GITHUB_ACTIONS is checked because Actions is not a TTY but its log viewer
# does render ANSI — without it, CI logs would lose all colour.
use_colour() {
    [ -n "${NO_COLOR:-}" ] && return 1
    [ -n "${FORCE_COLOR:-}" ] && return 0
    [ -n "${GITHUB_ACTIONS:-}" ] && return 0
    [ -t 1 ]
}

if [ "$OPT_NO_COLOR" = true ]; then
    GREEN=''
    YELLOW=''
    RED=''
    CYAN=''
    NC=''
elif use_colour; then
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    CYAN='\033[0;36m'
    NC='\033[0m'
else
    GREEN=''
    YELLOW=''
    RED=''
    CYAN=''
    NC=''
fi

# ─── Help ─────────────────────────────────────────────────────────────────────

if [ "$SHOW_HELP" = true ]; then
    cat << 'HELPTEXT'
Bem-te-vi - Installation Script v2.0.0

Usage: ./install.sh [OPTIONS]

Options:
  --target <project|global|both>
      Installation scope. Default: prompt interactively.

  --editor <claude|cursor|windsurf|copilot|cline|antigravity|all>
      Target editor. Default: claude (Claude Code).

  --non-interactive
      Skip all prompts, use defaults or specified flags.
      Defaults: --target project --editor claude

  --no-color
      Disable ANSI color codes in output.

  --no-hooks
      Skip registering the validate-tc-format.sh pre-commit validation hook.

  --update
      Force clean update (bypass overwrite conflict prompts).

  --uninstall, --remove
      Completely uninstall all rules, commands, skills, and clean up Git hooks.

  --help
      Show this help message and exit.

Examples:
  ./install.sh
  ./install.sh --target project --editor claude
  ./install.sh --target both --editor all --non-interactive
  ./install.sh --non-interactive --no-color
HELPTEXT
    exit 0
fi

# ─── Pre-flight checks ──────────────────────────────────────────────────────

# 0. Check bash version >= 3.2
BASH_MAJOR="${BASH_VERSINFO[0]:-0}"
BASH_MINOR="${BASH_VERSINFO[1]:-0}"
if [ "$BASH_MAJOR" -lt 3 ] || { [ "$BASH_MAJOR" -eq 3 ] && [ "$BASH_MINOR" -lt 2 ]; }; then
    printf '%b\n' "${RED}Error: bash >= 3.2 required (found $BASH_VERSION).${NC}"
    exit 1
fi

echo "╔════════════════════════════════════════════════╗"
echo "║   Bem-te-vi - Installation Script               ║"
echo "║   ISTQB CTFL v4.0 | v2.0 Modular Commands       ║"
echo "╚════════════════════════════════════════════════╝"
echo ""

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
QA_COMMANDS_DIR="$SCRIPT_DIR/.claude/commands"
QA_SKILL_FILE="$QA_COMMANDS_DIR/qa.md"
ADAPTERS_DIR="$SCRIPT_DIR/adapters"
EDITOR_MAP_FILE="$SCRIPT_DIR/.qa-skills-editor-map"

# 1. Check qa.md exists
if [ ! -f "$QA_SKILL_FILE" ]; then
    printf '%b\n' "${RED}Error: qa.md not found at $QA_SKILL_FILE${NC}"
    echo "Please ensure you're running this script from the QA package directory."
    exit 1
fi

# 2. Check Claude Code is installed
if ! command -v claude &>/dev/null; then
    printf '%b\n' "${YELLOW}Warning: 'claude' command not found in PATH.${NC}"
    echo "The skill file will be installed, but Claude Code may not be set up yet."
    echo "Install Claude Code from: https://docs.anthropic.com/claude-code"
    echo ""
    if [ "$NON_INTERACTIVE" = true ]; then
        echo "Non-interactive mode: continuing without Claude Code."
    else
        read -r -p "Continue anyway? (y/n): " CONTINUE_WITHOUT_CLAUDE
        CONTINUE_WITHOUT_CLAUDE="${CONTINUE_WITHOUT_CLAUDE:-n}"
        if [ "$CONTINUE_WITHOUT_CLAUDE" != "y" ]; then
            echo "Installation cancelled."
            exit 0
        fi
    fi
fi

# ─── WSL Detection ──────────────────────────────────────────────────────────

IS_WSL=false
if grep -qi microsoft /proc/version 2>/dev/null; then
    IS_WSL=true
fi

# 3. Check for version conflict (existing file that might be newer)
check_version_conflict() {
    local TARGET="$1"
    if [ -f "$TARGET" ]; then
        if [ "$OPERATION" = "update" ]; then
            return 0
        fi
        local EXISTING_VER
        EXISTING_VER=$(grep -m1 'Version:' "$TARGET" 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1 || echo "unknown")
        local NEW_VER
        NEW_VER=$(grep -m1 'Version:' "$QA_SKILL_FILE" 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1 || echo "unknown")
        printf '%b\n' "${YELLOW}Existing file found at: $TARGET${NC}"
        echo "  Installed version : $EXISTING_VER"
        echo "  Package version   : $NEW_VER"
        if [ "$NON_INTERACTIVE" = true ]; then
            echo "Non-interactive mode: overwriting."
            return 0
        fi
        read -r -p "Overwrite? (y/n): " OVERWRITE
        OVERWRITE="${OVERWRITE:-n}"
        if [ "$OVERWRITE" != "y" ]; then
            printf '%b\n' "${CYAN}Skipping $TARGET — no changes made.${NC}"
            return 1
        fi
    fi
    return 0
}

# ─── Validate CLI flag values ────────────────────────────────────────────────

if [ -n "$TARGET_FLAG" ]; then
    case "$TARGET_FLAG" in
        project|global|both) ;;
        *)
            printf '%b\n' "${RED}Error: invalid --target value '$TARGET_FLAG'. Use: project, global, or both.${NC}"
            exit 1
            ;;
    esac
fi

if [ -n "$EDITOR_FLAG" ]; then
    case "$EDITOR_FLAG" in
        claude|cursor|windsurf|copilot|cline|antigravity|all) ;;
        *)
            printf '%b\n' "${RED}Error: invalid --editor value '$EDITOR_FLAG'. Use: claude, cursor, windsurf, copilot, cline, antigravity, or all.${NC}"
            exit 1
            ;;
    esac
fi

# ─── Helper: generate Cursor .mdc file with YAML frontmatter ────────────────

generate_cursor_mdc() {
    local SOURCE="$1"
    local TARGET="$2"
    mkdir -p "$(dirname "$TARGET")"
    cat > "$TARGET" << 'FRONTMATTER'
---
description: "Senior QA Analyst + QA Engineer — aligned with ISTQB CTFL v4.0; Playwright, Vitest, BDD and CI/CD"
alwaysApply: false
---
FRONTMATTER
    cat "$SOURCE" >> "$TARGET"
}

# ─── Helper: check if adapter exists ──────────────────────────────────────────

check_adapter_exists() {
    local ADAPTER_PATH="$1"
    if [ ! -f "$ADAPTER_PATH" ]; then
        printf '%b\n' "${RED}Error: Adapter not found at $ADAPTER_PATH${NC}"
        echo "Run ./generate-adapters.sh first to generate the merged files."
        return 1
    fi
    return 0
}

# ─── Helper: register Git hooks ──────────────────────────────────────────────

# The marker line the project hook carries; uninstall and the "is this ours?" check match on it.
PROJECT_HOOK_MARKER="Pre-commit hook to validate test cases in qa-skills"

# Prints the hooks directory of the git repository rooted at $1 and fails when $1 is not the
# root of one. Asking git (rather than assuming $1/.git/hooks) handles a .git that is a file,
# as in a worktree or submodule.
project_hooks_dir() {
    local BASE="$1" DIR
    [ -e "$BASE/.git" ] || return 1
    DIR="$(git -C "$BASE" rev-parse --git-path hooks 2>/dev/null)" || return 1
    case "$DIR" in
        /*|[A-Za-z]:*) ;;
        *) DIR="$BASE/$DIR" ;;
    esac
    printf '%s\n' "$DIR"
}

# The global hook block is fenced by two exact marker lines so install and uninstall only ever
# touch their own lines of a hook that may be the user's. The old "Added by" line stays inside
# the block, and so does the old end line, so an older uninstaller still recognises it.
GLOBAL_HOOK_BEGIN="# >>> bem-te-vi global pre-commit >>>"
GLOBAL_HOOK_END="# <<< bem-te-vi global pre-commit <<<"
GLOBAL_HOOK_OLD_MARKER="# Added by qa-skills global installer"
GLOBAL_HOOK_OLD_END="# GLOBAL_PRECOMMIT_APPEND"
GLOBAL_HOOK_FRESH_HEADER="# Global pre-commit hook to validate test cases in qa-skills"

# Matches a first line that is a sh or bash shebang, the only hooks a bash block can be appended to.
SH_SHEBANG_RE='^#![[:space:]]*(/[^[:space:]]*/)?(env[[:space:]]+)?(ba)?sh([[:space:]]|$)'

global_hook_block() {
    cat << 'GLOBAL_PRECOMMIT_BLOCK'
# >>> bem-te-vi global pre-commit >>>
# Added by qa-skills global installer
GLOBAL_VALIDATOR="$HOME/.claude/hooks/validate-tc-format.sh"
if [ -f "$GLOBAL_VALIDATOR" ]; then
    # Validate every staged Markdown file, renamed ones included. The list is NUL-separated so
    # names with spaces, non-ASCII characters or glob characters arrive intact. bash does the
    # reading, so this block also works appended to a hook that runs under plain sh.
    git diff --cached --name-only -z --diff-filter=ACMR -- '*.md' | bash -c '
        while IFS= read -r -d "" FILE; do
            if grep -qE "^## TC-[A-Z0-9]+-[0-9]+:" "$FILE" 2>/dev/null; then
                if ! "$1" "$FILE"; then
                    printf "\033[0;31mError: Test case validation failed for %s. Commit aborted.\033[0m\n" "$FILE"
                    exit 1
                fi
            fi
        done' bash "$GLOBAL_VALIDATOR" || exit 1
fi
# GLOBAL_PRECOMMIT_APPEND
# <<< bem-te-vi global pre-commit <<<
GLOBAL_PRECOMMIT_BLOCK
}

# Prints $1 without the bem-te-vi block. The block is the lines between the two markers; for a hook
# written by an older release it runs from the old "Added by" line (or, for a fresh hook written by
# install.ps1, the header comment) to the first line that is exactly "fi", which is how the old
# block ends. One blank line right before the block, the separator the installer added, goes too.
# Exit status 3: no block found. Exit status 4: a block starts but its end cannot be found, so
# nothing is printed and the caller must leave the file alone.
strip_global_hook_block() {
    awk -v B="$GLOBAL_HOOK_BEGIN" -v E="$GLOBAL_HOOK_END" -v O="$GLOBAL_HOOK_OLD_MARKER" \
        -v A="$GLOBAL_HOOK_OLD_END" -v H="$GLOBAL_HOOK_FRESH_HEADER" '
        { line[NR] = $0; t = $0; sub(/\r$/, "", t); trim[NR] = t }
        END {
            s = 0; old = 0
            for (i = 1; i <= NR && !s; i++) if (trim[i] == B) s = i
            if (!s) { old = 1; for (i = 1; i <= NR && !s; i++) if (trim[i] == O) s = i }
            if (!s) { for (i = 1; i <= NR && !s; i++) if (trim[i] == H) s = i }
            if (!s) exit 3
            e = 0; want = old ? "fi" : E
            for (i = s + 1; i <= NR && !e; i++) if (trim[i] == want) e = i
            if (!e) exit 4
            if (old && trim[e + 1] == A) e++
            if (s > 1 && trim[s - 1] == "") s--
            for (i = 1; i <= NR; i++) if (i < s || i > e) print line[i]
        }' "$1"
}

register_git_hook() {
    local SCOPE="$1"        # project|global
    local BASE_DIR="$2"     # project path or $HOME

    if [ "$NO_HOOKS" = true ]; then
        printf '%b\n' "${YELLOW}  ⚠ Hooks disabled by --no-hooks flag — skipping hook registration.${NC}"
        return 0
    fi

    if [ "$SCOPE" = "project" ]; then
        local HOOK_DIR HOOKS_PATH_CFG
        if ! HOOK_DIR="$(project_hooks_dir "$BASE_DIR")"; then
            printf '%b\n' "${YELLOW}  ⚠ Not a git repository, skipping project-level git hook.${NC}"
            return 0
        fi

        # A hook manager (husky, lefthook, ...) that sets core.hooksPath makes git ignore
        # .git/hooks entirely, so writing there would only pretend to register something.
        HOOKS_PATH_CFG="$(git -C "$BASE_DIR" config core.hooksPath 2>/dev/null || true)"
        if [ -n "$HOOKS_PATH_CFG" ]; then
            printf '%b\n' "${YELLOW}  ⚠ core.hooksPath is set ($HOOKS_PATH_CFG); add the bem-te-vi check to your hook manager yourself:${NC}"
            printf '%b\n' "${CYAN}      bash .claude/hooks/validate-tc-format.sh <file>${NC}"
            return 0
        fi

        local HOOK_FILE="$HOOK_DIR/pre-commit"
        # Never replace a hook we did not write: it is the user's (or their hook manager's).
        if [ -L "$HOOK_FILE" ] || { [ -e "$HOOK_FILE" ] && ! grep -q "$PROJECT_HOOK_MARKER" "$HOOK_FILE"; }; then
            printf '%b\n' "${YELLOW}  ⚠ Kept your existing pre-commit hook: $HOOK_FILE${NC}"
            printf '%b\n' "${CYAN}      To validate test cases from it, run: bash .claude/hooks/validate-tc-format.sh <file>${NC}"
            return 0
        fi

        mkdir -p "$HOOK_DIR"
        
        # Create pre-commit script
        cat > "$HOOK_FILE" << 'PRECOMMIT'
#!/usr/bin/env bash
# Pre-commit hook to validate test cases in qa-skills

SCRIPT_DIR="$(git rev-parse --show-toplevel)"
VALIDATOR="$SCRIPT_DIR/.claude/hooks/validate-tc-format.sh"

if [ -f "$VALIDATOR" ]; then
    # Validate every staged Markdown file, renamed ones included. The list is NUL-separated so
    # names with spaces, non-ASCII characters or glob characters arrive intact.
    git diff --cached --name-only -z --diff-filter=ACMR -- '*.md' |
    while IFS= read -r -d '' FILE; do
        # Only validate if the file contains test cases
        if grep -qE "^## TC-[A-Z0-9]+-[0-9]+:" "$SCRIPT_DIR/$FILE" 2>/dev/null; then
            if ! "$VALIDATOR" "$SCRIPT_DIR/$FILE"; then
                printf '\033[0;31mError: Test case validation failed for %s. Commit aborted.\033[0m\n' "$FILE"
                exit 1
            fi
        fi
    done
    # The loop ran in a subshell, so its failure only shows up here.
    [ "${PIPESTATUS[1]}" -eq 0 ] || exit 1
fi
PRECOMMIT
        chmod +x "$HOOK_FILE"
        printf '%b\n' "${GREEN}  ✓ Registered project-level git pre-commit hook: $HOOK_FILE${NC}"
    else
        # Global registration
        local GLOBAL_HOOKS_DIR="$HOME/.git-templates/hooks"
        # Check if user has core.hooksPath set
        local EXISTING_HOOKS_PATH
        EXISTING_HOOKS_PATH=$(git config --global core.hooksPath || echo "")
        
        if [ -n "$EXISTING_HOOKS_PATH" ]; then
            # Expand tilde
            EXISTING_HOOKS_PATH="${EXISTING_HOOKS_PATH/#\~/$HOME}"
            GLOBAL_HOOKS_DIR="$EXISTING_HOOKS_PATH"
        fi
        
        local HOOK_FILE="$GLOBAL_HOOKS_DIR/pre-commit"
        mkdir -p "$GLOBAL_HOOKS_DIR"
        
        # Create global pre-commit or append to it
        if [ -L "$HOOK_FILE" ]; then
            printf '%b\n' "${YELLOW}  ⚠ Kept your existing global pre-commit hook (a symlink): $HOOK_FILE${NC}"
            printf '%b\n' "${CYAN}      To validate test cases from it, run: bash ~/.claude/hooks/validate-tc-format.sh <file>${NC}"
        elif [ -f "$HOOK_FILE" ] && ! grep -q "validate-tc-format.sh" "$HOOK_FILE"; then
            if head -n 1 "$HOOK_FILE" | grep -qE "$SH_SHEBANG_RE"; then
                # Finish an unterminated last line, then add a blank separator and our block.
                if [ -n "$(tail -c 1 "$HOOK_FILE")" ]; then printf '\n' >> "$HOOK_FILE"; fi
                { printf '\n'; global_hook_block; } >> "$HOOK_FILE"
                printf '%b\n' "${GREEN}  ✓ Appended global pre-commit hook: $HOOK_FILE${NC}"
            else
                printf '%b\n' "${YELLOW}  ⚠ Kept your existing global pre-commit hook (not a sh or bash script): $HOOK_FILE${NC}"
                printf '%b\n' "${CYAN}      To validate test cases from it, run: bash ~/.claude/hooks/validate-tc-format.sh <file>${NC}"
            fi
        elif [ ! -e "$HOOK_FILE" ]; then
            { printf '#!/usr/bin/env bash\n%s\n\n' "$GLOBAL_HOOK_FRESH_HEADER"; global_hook_block; } > "$HOOK_FILE"
            chmod +x "$HOOK_FILE"
            printf '%b\n' "${GREEN}  ✓ Created global git pre-commit hook: $HOOK_FILE${NC}"
        fi
        
        # Configure global git templates/hooks if core.hooksPath not set
        if [ -z "$EXISTING_HOOKS_PATH" ]; then
            local EXISTING_TEMPLATE_DIR
            EXISTING_TEMPLATE_DIR=$(git config --global init.templateDir || echo "")
            if [ -z "$EXISTING_TEMPLATE_DIR" ]; then
                git config --global init.templateDir "$HOME/.git-templates"
                printf '%b\n' "${CYAN}  i Configured git global init.templateDir to $HOME/.git-templates${NC}"
            else
                printf '%b\n' "${CYAN}  i Kept your existing git init.templateDir: $EXISTING_TEMPLATE_DIR${NC}"
            fi
        fi
    fi
}

# ─── Helper: install to a specific editor path ──────────────────────────────

# ─── Shared editor → target-path mapping ─────────────────────────────────────
# Single source of truth for every non-claude editor's adapter source, install
# targets, and display label, shared with install.ps1 and bin/cli.js. See
# .qa-skills-editor-map. Format: tab-separated
# "<editor>\t<adapter source>\t<project path>\t<global path or ->\t<label>".
# `claude` is not listed here: it copies the raw .claude/ tree, not a single
# compiled adapter file, and is handled separately in install_to_editor.

editor_map_field() {
    local ED="$1" COL="$2"
    awk -F'\t' -v ed="$ED" -v col="$COL" '
        $1 == ed {
            if (col == "source") print $2
            else if (col == "project") print $3
            else if (col == "global") print $4
            else if (col == "label") print $5
        }
    ' "$EDITOR_MAP_FILE"
}

# Removes each now-empty ancestor directory between $1 (a just-uninstalled file's
# parent dir) and $2 (BASE_DIR, exclusive), stopping at the first non-empty one.
# Reproduces, generically, the fixed-depth rmdir chains each editor's uninstall
# used to hand-write against its own hardcoded path.
remove_empty_ancestors() {
    local DIR="$1" STOP="$2"
    while [ "$DIR" != "$STOP" ] && [ -d "$DIR" ]; do
        rmdir "$DIR" 2>/dev/null || break
        DIR="$(dirname "$DIR")"
    done
}

# ─── Install manifest ─────────────────────────────────────────────────────────
# Every file the installer writes is recorded in <base>/.qa-skills-manifest as
# "<sha256>  <editor>  <path relative to base>". Uninstall then removes only files whose
# content still matches what was installed, so a project's own files are never destroyed —
# including ones whose names collide with the package's, and files this package shipped
# under a different name in an older version.
#
# The manifest is a portable format shared with install.ps1: no BOM, LF line endings,
# forward-slash path separators. install.ps1 writes the same bytes. Reads here tolerate a
# stray leading UTF-8 BOM and trailing \r so a manifest written by an older release, or by
# PowerShell's platform-native encoding, still parses correctly.

manifest_file() { echo "$1/.qa-skills-manifest"; }

hash_file() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        shasum -a 256 "$1" | awk '{print $1}'
    fi
}

# The package's own file with CRLF line endings (a Windows checkout with core.autocrlf, a
# Windows editor) is still the package's file. A file on disk therefore *matches* a hash if
# its bytes hash to it, or its bytes with every carriage return removed do — the same rule in
# install.ps1 and bin/cli.js (plans/017). Hashes are still recorded as the raw bytes.
hash_file_without_cr() {
    if command -v sha256sum >/dev/null 2>&1; then
        tr -d '\r' < "$1" | sha256sum | awk '{print $1}'
    else
        tr -d '\r' < "$1" | shasum -a 256 | awk '{print $1}'
    fi
}

file_matches() {   # file hash -> success if the file matches the hash, by the rule above
    [ -n "$2" ] || return 1
    [ "$(hash_file "$1")" = "$2" ] && return 0
    [ "$(hash_file_without_cr "$1")" = "$2" ]
}

# Reads a manifest file line by line on stdout, stripping a leading UTF-8 BOM (if present on
# the first line), any trailing \r (Windows CRLF), and normalizing recorded backslash path
# separators to forward slashes, so manifests written by either platform's installer — or by
# an older release — parse identically.
manifest_lines() {
    local MF="$1"
    [ -f "$MF" ] || return 0
    # shellcheck disable=SC1003 # the single quotes below hold one literal backslash, not an escape
    sed $'1s/^\xEF\xBB\xBF//' "$MF" | tr -d '\r' | tr '\\' '/'
}

manifest_lookup() {   # base editor rel -> recorded hash, empty when not recorded
    local MF="$1" ED="$2" REL="$3" HASH ENTRY_ED ENTRY_REL
    MF="$(manifest_file "$1")"
    [ -f "$MF" ] || return 0
    while read -r HASH ENTRY_ED ENTRY_REL; do
        if [ "$ENTRY_ED" = "$ED" ] && [ "$ENTRY_REL" = "$REL" ]; then
            printf '%s\n' "$HASH"
            return 0
        fi
    done < <(manifest_lines "$MF")
}

manifest_record() {   # base editor rel hash
    local MF ED="$2" REL="$3" HASH="$4" TMP EHASH EED EREL
    MF="$(manifest_file "$1")"
    TMP="$MF.tmp"
    : > "$TMP"
    if [ -f "$MF" ]; then
        while read -r EHASH EED EREL; do
            [ "$EED" = "$ED" ] && [ "$EREL" = "$REL" ] && continue
            printf '%s  %s  %s\n' "$EHASH" "$EED" "$EREL" >> "$TMP"
        done < <(manifest_lines "$MF")
    fi
    printf '%s  %s  %s\n' "$HASH" "$ED" "$REL" >> "$TMP"
    mv "$TMP" "$MF"
}

# Known-hash list: the SHA-256 of every file this package has ever shipped, across all tagged
# releases (see generate-known-hashes.sh and plans/011-release-hash-provenance.md). Lets the
# installer tell its own older file from the user's edit with certainty instead of guessing —
# loaded once per run, not once per file, since ~20 files get installed in a typical run.
KNOWN_HASHES=""
KNOWN_HASHES_LOADED=false

load_known_hashes() {
    [ "$KNOWN_HASHES_LOADED" = true ] && return 0
    KNOWN_HASHES_LOADED=true
    local LIST="$SCRIPT_DIR/.qa-skills-known-hashes"
    # Missing list (old checkout, trimmed package) is not an error: known_hash simply never
    # matches, and every differing destination falls back to today's back-up-and-warn behavior.
    [ -f "$LIST" ] || return 0
    # Same portable-format tolerance as manifest_lines: strip a leading UTF-8 BOM and any \r.
    # shellcheck disable=SC1003 # the single quotes below hold one literal backslash, not an escape
    KNOWN_HASHES="$(sed $'1s/^\xEF\xBB\xBF//' "$LIST" | tr -d '\r')"
}

known_hash() {   # sha256 -> success if some previous release shipped a file with this hash
    load_known_hashes
    [ -n "$KNOWN_HASHES" ] || return 1
    printf '%s\n' "$KNOWN_HASHES" | grep -q "^$1  "
}

backup_dest() {   # base editor rel dest src -> if dest's content differs from src/manifest,
                  # prints one of:
                  #   (nothing)      dest already matches src or the manifest — no action needed
                  #   ADOPTED        dest's hash matches a previous release's file — safe to
                  #                  overwrite, no backup needed
                  #   BACKUP <path>  dest is the user's own content — backed up to <path>
                  # (following symlinks, so a linked file's own content is backed up, not the link)
    local BASE="$1" ED="$2" REL="$3" DEST="$4" SRC="$5"
    local DEST_HASH SRC_HASH RECORDED PASS
    SRC_HASH="$(hash_file "$SRC")"
    RECORDED="$(manifest_lookup "$BASE" "$ED" "$REL")"
    # Raw bytes first; the carriage-return-free hash only when they match nothing (see
    # file_matches).
    for PASS in raw without-cr; do
        if [ "$PASS" = raw ]; then
            DEST_HASH="$(hash_file "$DEST")"
        else
            DEST_HASH="$(hash_file_without_cr "$DEST")"
        fi
        [ "$DEST_HASH" = "$SRC_HASH" ] && return 0
        [ "$DEST_HASH" = "$RECORDED" ] && return 0
        if known_hash "$DEST_HASH"; then
            echo "ADOPTED"
            return 0
        fi
    done
    local BACKUP SUFFIX N
    SUFFIX="$(date -u +%Y%m%dT%H%M%SZ)"
    BACKUP="$DEST.qa-skills-backup-$SUFFIX"
    N=1
    while [ -e "$BACKUP" ]; do
        BACKUP="$DEST.qa-skills-backup-$SUFFIX-$N"
        N=$((N + 1))
    done
    cp -p "$DEST" "$BACKUP"
    echo "BACKUP $BACKUP"
}

install_file() {      # base editor src dest
    # Prime the known-hash cache here, in the parent shell. backup_dest below runs inside a
    # command substitution, i.e. a subshell, so anything it loads is discarded when it returns;
    # loading here means the subshell inherits a populated cache and the list is read once per
    # run rather than once per file.
    load_known_hashes
    local BASE="$1" ED="$2" SRC="$3" DEST="$4"
    local REL="${DEST#"$BASE"/}"
    # REL is what gets recorded in the manifest and is later resolved as "$BASE/$REL" on
    # uninstall. If DEST doesn't actually live under BASE, the "${DEST#"$BASE"/}" strip is a
    # no-op (or leaves a path that climbs back out via "../"), producing an absolute or
    # out-of-tree entry that can never resolve against its own base — uninstall would then
    # skip it silently and drop the entry, orphaning the file forever. Refuse loudly instead:
    # this is a bug in the installer's own call site, not user data, so aborting the install
    # is preferable to continuing with a manifest entry we already know is unusable.
    case "$REL" in
        "$DEST"|/*|../*|..)
            printf '%b\n' "${RED}Error: refusing to install $DEST — it is not inside base $BASE, so it can never be recorded in the manifest.${NC}" >&2
            return 1
            ;;
    esac
    if [ -L "$DEST" ]; then
        # DEST is a symlink: never write through it (that would silently modify whatever
        # file it points at, outside the install tree). Back up the link target's content,
        # then replace the link itself with the package's file.
        local LINK_TARGET RESULT BACKUP
        LINK_TARGET="$(readlink "$DEST")"
        if [ -e "$DEST" ]; then
            RESULT="$(backup_dest "$BASE" "$ED" "$REL" "$DEST" "$SRC")"
            case "$RESULT" in
                ADOPTED)
                    printf '%b\n' "  i $REL is a symlink to $LINK_TARGET whose content matches an earlier release — updating (link target left untouched)"
                    ;;
                "BACKUP "*)
                    BACKUP="${RESULT#BACKUP }"
                    echo "$LINK_TARGET" > "$BACKUP.link-target"
                    printf '%b\n' "${YELLOW}  ! $REL is a symlink to $LINK_TARGET — its content was backed up to $(basename "$BACKUP") (link target left untouched)${NC}"
                    ;;
            esac
        else
            printf '%b\n' "${YELLOW}  ! $REL is a broken symlink to $LINK_TARGET — replacing with the package file${NC}"
        fi
        rm -f "$DEST"
    elif [ -f "$DEST" ]; then
        if [ ! -w "$DEST" ]; then
            # A read-only destination is a deliberate signal not to overwrite it: skip this
            # file and keep installing the rest of the tree instead of aborting under set -e
            # on a raw `cp: Permission denied`.
            printf '%b\n' "${YELLOW}  ! Skipped $REL — destination is read-only (existing file left untouched)${NC}"
            return 0
        fi
        local RESULT BACKUP
        RESULT="$(backup_dest "$BASE" "$ED" "$REL" "$DEST" "$SRC")"
        case "$RESULT" in
            ADOPTED)
                printf '%b\n' "  i $REL already existed and matches an earlier release — updating to the current version"
                ;;
            "BACKUP "*)
                BACKUP="${RESULT#BACKUP }"
                printf '%b\n' "${YELLOW}  ! $REL already existed and differs — backed up to $(basename "$BACKUP")${NC}"
                ;;
        esac
    fi
    mkdir -p "$(dirname "$DEST")"
    cp "$SRC" "$DEST"
    manifest_record "$BASE" "$ED" "$REL" "$(hash_file "$DEST")"
    if [ -n "${QA_SKILLS_DEBUG:-}" ]; then
        echo "  (debug) recorded $REL in $(manifest_file "$BASE")"
    fi
}

# A manifest path must stay inside the base it was recorded under. The manifest sits at the
# project root and is committed into consuming repositories, so its contents are
# attacker-controllable: an entry such as "../../../.ssh/config" would otherwise make uninstall
# delete a file outside the install tree. install_file refuses to *record* such a path; this
# refuses to act on one.
safe_manifest_rel() {   # rel -> 0 when the path stays inside its base
    case "$1" in
        ""|/*|../*|*/../*|*/..|..) return 1 ;;
        [A-Za-z]:*) return 1 ;;
    esac
    return 0
}

uninstall_recorded() {   # base editor — removes only recorded files that are unchanged
    local BASE="$1" ED="$2" MF HASH ENTRY_ED REL FILE TMP
    MF="$(manifest_file "$BASE")"
    [ -f "$MF" ] || return 0
    TMP="$MF.tmp"
    : > "$TMP"
    while read -r HASH ENTRY_ED REL; do
        if [ "$ENTRY_ED" != "$ED" ]; then
            printf '%s  %s  %s\n' "$HASH" "$ENTRY_ED" "$REL" >> "$TMP"
            continue
        fi
        if ! safe_manifest_rel "$REL"; then
            printf '%b\n' "${RED}  ✘ Refusing $REL — it points outside $BASE. The manifest may have been tampered with.${NC}" >&2
            printf '%s  %s  %s\n' "$HASH" "$ENTRY_ED" "$REL" >> "$TMP"
            continue
        fi
        FILE="$BASE/$REL"
        [ -f "$FILE" ] || continue
        if [ ! -w "$FILE" ]; then
            # A writable parent directory would let `rm -f` delete a read-only file anyway;
            # treat read-only the same deliberate way on removal as on install and keep it.
            printf '%b\n' "${YELLOW}  ! Kept $REL — destination is read-only${NC}"
            UNINSTALL_KEPT_COUNT=$((UNINSTALL_KEPT_COUNT + 1))
        elif file_matches "$FILE" "$HASH"; then
            rm -f "$FILE"
            UNINSTALL_REMOVED_COUNT=$((UNINSTALL_REMOVED_COUNT + 1))
        else
            printf '%b\n' "${YELLOW}  ! Kept $REL — changed since it was installed${NC}"
            UNINSTALL_KEPT_COUNT=$((UNINSTALL_KEPT_COUNT + 1))
        fi
    done < <(manifest_lines "$MF")
    if [ -s "$TMP" ]; then
        mv "$TMP" "$MF"
    else
        rm -f "$TMP" "$MF"
    fi
}

remove_if_matches() {    # src dest — fallback for installs made before manifests existed
    local SRC="$1" DEST="$2"
    [ -f "$DEST" ] || return 0
    if [ -f "$SRC" ] && file_matches "$DEST" "$(hash_file "$SRC")"; then
        rm -f "$DEST"
        UNINSTALL_REMOVED_COUNT=$((UNINSTALL_REMOVED_COUNT + 1))
    else
        printf '%b\n' "${YELLOW}  ! Kept $DEST — not installed by this package, or changed since install${NC}"
        UNINSTALL_KEPT_COUNT=$((UNINSTALL_KEPT_COUNT + 1))
    fi
}

had_manifest() { [ -f "$(manifest_file "$1")" ]; }

uninstall_single() {     # base editor dest adapter-relative-path
    # Read the manifest state first: uninstall_recorded deletes the manifest once nothing is left in
    # it, which would otherwise look like a pre-manifest install and delete a file it just kept.
    local HAD=0
    had_manifest "$1" && HAD=1
    uninstall_recorded "$1" "$2"
    [ "$HAD" = 1 ] || remove_if_matches "$SCRIPT_DIR/adapters/$4" "$3"
}

report_uninstall_result() {   # label scope removed kept — prints what actually happened
    local LABEL="$1" SCOPE="$2" REMOVED="$3" KEPT="$4"
    if [ "$KEPT" -gt 0 ]; then
        printf '%b\n' "${YELLOW}  ! $LABEL ($SCOPE): partially uninstalled — removed $REMOVED file(s), kept $KEPT.${NC}"
    elif [ "$REMOVED" -eq 0 ]; then
        printf '%b\n' "${CYAN}  i $LABEL ($SCOPE): nothing to remove (not installed).${NC}"
    else
        printf '%b\n' "${GREEN}  ✓ $LABEL ($SCOPE): uninstalled.${NC}"
    fi
}

install_to_editor() {
    local EDITOR_NAME="$1"    # claude|cursor|windsurf|copilot|cline
    local SCOPE="$2"          # project|global
    local BASE_DIR="$3"       # base directory (project dir or $HOME)

    case "$EDITOR_NAME" in
        claude)
            local TARGET_DIR="$BASE_DIR/.claude"
            local TARGET_PATH="$TARGET_DIR/commands/qa.md"
            if check_version_conflict "$TARGET_PATH"; then
                mkdir -p "$TARGET_DIR/rules" "$TARGET_DIR/commands" "$TARGET_DIR/skills" "$TARGET_DIR/agents" "$TARGET_DIR/hooks"
                
                # Copy all files
                for SUB in commands rules skills agents hooks; do
                    [ -d "$SCRIPT_DIR/.claude/$SUB" ] || continue
                    while IFS= read -r SRC_FILE; do
                        install_file "$BASE_DIR" claude "$SRC_FILE" "$TARGET_DIR/${SRC_FILE#"$SCRIPT_DIR"/.claude/}"
                    done < <(find "$SCRIPT_DIR/.claude/$SUB" -type f)
                done
                if [ -d "$TARGET_DIR/hooks" ]; then chmod +x "$TARGET_DIR/hooks"/*.sh 2>/dev/null || true; fi

                printf '%b\n' "${GREEN}  ✓ Claude Code ($SCOPE): $TARGET_DIR/ (scaffolded rules, commands, skills, agents, and hooks)${NC}"
                
                # Register Git Hook
                register_git_hook "$SCOPE" "$BASE_DIR"
            fi
            ;;
        *)
            # Every other editor: a single compiled adapter file, installed per the
            # shared mapping in $EDITOR_MAP_FILE (source / project path / global path
            # or "-" for "no global support" / display label).
            local GLOBAL_REL LABEL SOURCE_PATH TARGET_PATH
            GLOBAL_REL="$(editor_map_field "$EDITOR_NAME" global)"
            LABEL="$(editor_map_field "$EDITOR_NAME" label)"
            if [ "$SCOPE" = "global" ] && [ "$GLOBAL_REL" = "-" ]; then
                printf '%b\n' "${YELLOW}  ⚠ $LABEL only supports project-level install — skipping global.${NC}"
                return 0
            fi
            SOURCE_PATH="$ADAPTERS_DIR/$(editor_map_field "$EDITOR_NAME" source)"
            if [ "$SCOPE" = "project" ]; then
                TARGET_PATH="$BASE_DIR/$(editor_map_field "$EDITOR_NAME" project)"
            else
                TARGET_PATH="$BASE_DIR/$GLOBAL_REL"
            fi
            mkdir -p "$(dirname "$TARGET_PATH")"
            if check_adapter_exists "$SOURCE_PATH" && check_version_conflict "$TARGET_PATH"; then
                install_file "$BASE_DIR" "$EDITOR_NAME" "$SOURCE_PATH" "$TARGET_PATH"
                printf '%b\n' "${GREEN}  ✓ $LABEL ($SCOPE): $TARGET_PATH${NC}"
            fi
            ;;
    esac
}

# ─── Helper: purge Git hooks ─────────────────────────────────────────────────

purge_git_hook() {
    local SCOPE="$1"        # project|global
    local BASE_DIR="$2"     # project path or $HOME

    if [ "$SCOPE" = "project" ]; then
        # The hooks directory git reports, and the plain .git/hooks an earlier release wrote to.
        local HOOK_FILE HOOK_DIR
        for HOOK_DIR in "$(project_hooks_dir "$BASE_DIR" || true)" "$BASE_DIR/.git/hooks"; do
            [ -n "$HOOK_DIR" ] || continue
            HOOK_FILE="$HOOK_DIR/pre-commit"
            if [ -f "$HOOK_FILE" ] && [ ! -L "$HOOK_FILE" ]; then
                if grep -q "$PROJECT_HOOK_MARKER" "$HOOK_FILE"; then
                    rm -f "$HOOK_FILE"
                    printf '%b\n' "${GREEN}  ✓ Purged project-level git pre-commit hook: $HOOK_FILE${NC}"
                fi
            fi
        done
    else
        # Global registration
        local GLOBAL_HOOKS_DIR="$HOME/.git-templates/hooks"
        local EXISTING_HOOKS_PATH
        EXISTING_HOOKS_PATH=$(git config --global core.hooksPath || echo "")
        
        if [ -n "$EXISTING_HOOKS_PATH" ]; then
            EXISTING_HOOKS_PATH="${EXISTING_HOOKS_PATH/#\~/$HOME}"
            GLOBAL_HOOKS_DIR="$EXISTING_HOOKS_PATH"
        fi
        
        local HOOK_FILE="$GLOBAL_HOOKS_DIR/pre-commit"
        if [ -f "$HOOK_FILE" ] && [ ! -L "$HOOK_FILE" ]; then
            if grep -q "validate-tc-format.sh" "$HOOK_FILE"; then
                # Strip only our own block, leaving every other line of the hook as it was.
                local STRIPPED STRIP_STATUS=0
                STRIPPED="$(mktemp "${TMPDIR:-/tmp}/qa-hook.XXXXXX")"
                strip_global_hook_block "$HOOK_FILE" > "$STRIPPED" || STRIP_STATUS=$?
                if [ "$STRIP_STATUS" -eq 0 ]; then
                    cat "$STRIPPED" > "$HOOK_FILE"
                    printf '%b\n' "${GREEN}  ✓ Cleaned global git pre-commit hook: $HOOK_FILE${NC}"

                    # Remove if nothing is left but the shebang and our own header comments
                    if ! grep -qvE "^(#!.*|$GLOBAL_HOOK_FRESH_HEADER|$GLOBAL_HOOK_OLD_END|[[:space:]]*)\$" "$HOOK_FILE"; then
                        rm -f "$HOOK_FILE"
                        printf '%b\n' "${CYAN}  i Removed empty global hook file.${NC}"
                    fi
                else
                    printf '%b\n' "${YELLOW}  ! Kept global pre-commit hook — could not find the bem-te-vi block to remove: $HOOK_FILE${NC}"
                fi
                rm -f "$STRIPPED"
            fi
        fi
    fi
}

# ─── Helper: uninstall from a specific editor path ──────────────────────────

uninstall_from_editor() {
    local EDITOR_NAME="$1"    # claude|cursor|windsurf|copilot|cline|antigravity
    local SCOPE="$2"          # project|global
    local BASE_DIR="$3"       # base directory (project dir or $HOME)
    local ED_REMOVED_START=$UNINSTALL_REMOVED_COUNT
    local ED_KEPT_START=$UNINSTALL_KEPT_COUNT

    case "$EDITOR_NAME" in
        claude)
            local TARGET_DIR="$BASE_DIR/.claude"
            printf '%b\n' "${CYAN}  Removing Claude Code files...${NC}"
            
            # Remove only what was installed and is still unchanged (see the manifest helpers).
            # Files the project added or edited are kept, and reported.
            if had_manifest "$BASE_DIR"; then
                uninstall_recorded "$BASE_DIR" claude
            else
                # Installed before manifests existed: fall back to removing files whose content
                # still matches the package's current copy.
                uninstall_recorded "$BASE_DIR" claude
                for SUB in commands rules skills agents hooks; do
                    [ -d "$SCRIPT_DIR/.claude/$SUB" ] || continue
                    while IFS= read -r SRC_FILE; do
                        remove_if_matches "$SRC_FILE" "$TARGET_DIR/${SRC_FILE#"$SCRIPT_DIR"/.claude/}"
                    done < <(find "$SCRIPT_DIR/.claude/$SUB" -type f)
                done
            fi
            
            # Clean up directories if empty
            if [ -d "$TARGET_DIR/rules" ]; then rmdir "$TARGET_DIR/rules" 2>/dev/null || true; fi
            if [ -d "$TARGET_DIR/commands" ]; then rmdir "$TARGET_DIR/commands" 2>/dev/null || true; fi
            # Every emptied skill folder, deepest first (rmdir leaves any non-empty one alone)
            if [ -d "$TARGET_DIR/skills" ]; then find "$TARGET_DIR/skills" -depth -type d -exec rmdir {} \; 2>/dev/null || true; fi
            if [ -d "$TARGET_DIR/agents" ]; then rmdir "$TARGET_DIR/agents" 2>/dev/null || true; fi
            if [ -d "$TARGET_DIR/hooks" ]; then rmdir "$TARGET_DIR/hooks" 2>/dev/null || true; fi
            if [ -d "$TARGET_DIR" ]; then rmdir "$TARGET_DIR" 2>/dev/null || true; fi
            
            report_uninstall_result "Claude Code" "$SCOPE" "$((UNINSTALL_REMOVED_COUNT - ED_REMOVED_START))" "$((UNINSTALL_KEPT_COUNT - ED_KEPT_START))"

            # Purge Git Hook
            purge_git_hook "$SCOPE" "$BASE_DIR"
            ;;
        *)
            # Every other editor: a single compiled adapter file, uninstalled per the
            # shared mapping in $EDITOR_MAP_FILE. Editors with no global support (global
            # path "-") are simply never installed there, so there is nothing to do.
            local GLOBAL_REL SOURCE_REL LABEL TARGET_PATH
            GLOBAL_REL="$(editor_map_field "$EDITOR_NAME" global)"
            SOURCE_REL="$(editor_map_field "$EDITOR_NAME" source)"
            LABEL="$(editor_map_field "$EDITOR_NAME" label)"
            if [ "$SCOPE" = "global" ]; then
                [ "$GLOBAL_REL" = "-" ] && return 0
                TARGET_PATH="$BASE_DIR/$GLOBAL_REL"
            else
                TARGET_PATH="$BASE_DIR/$(editor_map_field "$EDITOR_NAME" project)"
            fi
            uninstall_single "$BASE_DIR" "$EDITOR_NAME" "$TARGET_PATH" "$SOURCE_REL"
            remove_empty_ancestors "$(dirname "$TARGET_PATH")" "$BASE_DIR"
            report_uninstall_result "$LABEL" "$SCOPE" "$((UNINSTALL_REMOVED_COUNT - ED_REMOVED_START))" "$((UNINSTALL_KEPT_COUNT - ED_KEPT_START))"
            ;;
    esac
}

# ─── Helper: git commit + optional push (Claude Code project files) ─────────

git_commit_and_push() {
    if [ -d .git ]; then
        echo ""
        if [ "$NON_INTERACTIVE" = true ]; then
            echo "Non-interactive mode: skipping git commit."
            return 0
        fi
        read -r -p "Add to git and commit? (y/n): " GIT_COMMIT
        GIT_COMMIT="${GIT_COMMIT:-n}"
        if [ "$GIT_COMMIT" = "y" ]; then
            # Commit only what the installer wrote: the paths in the project manifest, plus the
            # manifest itself. Whatever else the user has staged or edited stays out of the commit.
            local MANIFEST PATHS=() REL
            MANIFEST="$(manifest_file "$(pwd)")"
            while IFS= read -r REL; do
                [ -n "$REL" ] && [ -e "$REL" ] && PATHS+=("$REL")
            done < <(sed -e 's/\r$//' -e 's/^[0-9a-f]\{64\}  [^ ]*  //' "$MANIFEST" 2>/dev/null)
            [ -e "$MANIFEST" ] && PATHS+=("$(basename "$MANIFEST")")

            if [ "${#PATHS[@]}" -gt 0 ] \
                && git add -- "${PATHS[@]}" \
                && git commit -m "Add/update QA skill for AI-assisted editors (ISTQB CTFL v4.0)" -- "${PATHS[@]}"; then
                printf '%b\n' "${GREEN}✓ Committed to git${NC}"

                read -r -p "Push to remote? (y/n): " GIT_PUSH
                GIT_PUSH="${GIT_PUSH:-n}"
                if [ "$GIT_PUSH" = "y" ]; then
                    # Only the current branch's upstream, never every remote.
                    if git push; then
                        printf '%b\n' "${GREEN}✓ Pushed${NC}"
                    else
                        printf '%b\n' "${RED}✘ Push failed (does this branch have an upstream?)${NC}"
                    fi
                fi
            else
                printf '%b\n' "${RED}✘ Nothing was committed (see the git output above)${NC}"
            fi
        fi
    fi
}

# ─── Operation mode selection ────────────────────────────────────────────────

OPERATION="install" # default
if [ "$UPDATE_FLAG" = true ]; then
    OPERATION="update"
elif [ "$UNINSTALL_FLAG" = true ]; then
    OPERATION="uninstall"
elif [ "$NON_INTERACTIVE" = true ]; then
    OPERATION="install"
else
    echo "Bem-te-vi - Lifecycle Manager"
    echo "1. Install (Fresh deployment of Bem-te-vi)"
    echo "2. Update (Pull latest versions of all rules and commands)"
    echo "3. Uninstall / Remove (Purge all copied files & clean up git hooks)"
    echo ""
    read -r -p "Choose action (1/2/3) [1]: " OP_CHOICE
    OP_CHOICE="${OP_CHOICE:-1}"
    case "$OP_CHOICE" in
        1) OPERATION="install" ;;
        2) OPERATION="update" ;;
        3) OPERATION="uninstall" ;;
        *)
            printf '%b\n' "${YELLOW}Invalid choice, defaulting to Install.${NC}"
            OPERATION="install"
            ;;
    esac
    echo ""
fi

# ─── Installation scope selection ────────────────────────────────────────────

if [ -n "$TARGET_FLAG" ]; then
    case "$TARGET_FLAG" in
        project) OPTION="1" ;;
        global)  OPTION="2" ;;
        both)    OPTION="3" ;;
    esac
elif [ "$NON_INTERACTIVE" = true ]; then
    OPTION="1"   # default: project
else
    echo "Installation Options:"
    echo "1. Project-level (current project only)"
    echo "2. Global (all projects)"
    echo "3. Both"
    echo ""
    read -r -p "Choose option (1/2/3) [1]: " OPTION
    OPTION="${OPTION:-1}"
fi

# Validate input
if [[ ! "$OPTION" =~ ^[123]$ ]]; then
    printf '%b\n' "${RED}Invalid option '$OPTION'. Please enter 1, 2, or 3. Exiting.${NC}"
    exit 1
fi

# ─── Editor selection ────────────────────────────────────────────────────────

EDITORS=()

if [ -n "$EDITOR_FLAG" ]; then
    if [ "$EDITOR_FLAG" = "all" ]; then
        EDITORS=(claude cursor windsurf copilot cline antigravity)
    else
        EDITORS=("$EDITOR_FLAG")
    fi
elif [ "$NON_INTERACTIVE" = true ]; then
    EDITORS=(claude)   # default: Claude Code
else
    echo ""
    echo "Editor to install for:"
    echo "1. Claude Code — CLI & VS Code extension (default)"
    echo "2. Cursor / Trae"
    echo "3. Windsurf"
    echo "4. GitHub Copilot (VS Code)"
    echo "5. Cline (VS Code)"
    echo "6. Antigravity (Google)"
    echo "7. All editors"
    echo ""
    read -r -p "Choose editor (1-7) [1]: " EDITOR_CHOICE
    EDITOR_CHOICE="${EDITOR_CHOICE:-1}"

    case "$EDITOR_CHOICE" in
        1) EDITORS=(claude)   ;;
        2) EDITORS=(cursor)   ;;
        3) EDITORS=(windsurf)  ;;
        4) EDITORS=(copilot)   ;;
        5) EDITORS=(cline)     ;;
        6) EDITORS=(antigravity) ;;
        7) EDITORS=(claude cursor windsurf copilot cline antigravity) ;;
        *)
            printf '%b\n' "${YELLOW}Invalid editor choice '$EDITOR_CHOICE'. Defaulting to Claude Code.${NC}"
            EDITORS=(claude)
            ;;
    esac
fi

# ─── Perform action ──────────────────────────────────────────────────────────

echo ""

run_lifecycle_action() {
    local ACTION="$1"
    local SCOPE_OPT="$2"
    
    case $SCOPE_OPT in
        1)
            if [ "$ACTION" = "uninstall" ]; then
                printf '%b\n' "${YELLOW}Uninstalling from current project...${NC}"
                for EDITOR in "${EDITORS[@]}"; do
                    uninstall_from_editor "$EDITOR" "project" "$(pwd)"
                done
            else
                printf '%b\n' "${YELLOW}Deploying to current project (mode: $ACTION)...${NC}"
                for EDITOR in "${EDITORS[@]}"; do
                    install_to_editor "$EDITOR" "project" "$(pwd)"
                done
                git_commit_and_push
            fi
            ;;
        2)
            if [ "$ACTION" = "uninstall" ]; then
                printf '%b\n' "${YELLOW}Uninstalling globally...${NC}"
                for EDITOR in "${EDITORS[@]}"; do
                    uninstall_from_editor "$EDITOR" "global" "$HOME"
                done
            else
                printf '%b\n' "${YELLOW}Deploying globally (mode: $ACTION)...${NC}"
                for EDITOR in "${EDITORS[@]}"; do
                    install_to_editor "$EDITOR" "global" "$HOME"
                done
            fi
            ;;
        3)
            if [ "$ACTION" = "uninstall" ]; then
                printf '%b\n' "${YELLOW}Uninstalling from both locations...${NC}"
                echo ""
                printf '%b\n' "${CYAN}── Project-level ──${NC}"
                for EDITOR in "${EDITORS[@]}"; do
                    uninstall_from_editor "$EDITOR" "project" "$(pwd)"
                done
                echo ""
                printf '%b\n' "${CYAN}── Global ──${NC}"
                for EDITOR in "${EDITORS[@]}"; do
                    uninstall_from_editor "$EDITOR" "global" "$HOME"
                done
            else
                printf '%b\n' "${YELLOW}Deploying to both locations (mode: $ACTION)...${NC}"
                echo ""
                printf '%b\n' "${CYAN}── Project-level ──${NC}"
                for EDITOR in "${EDITORS[@]}"; do
                    install_to_editor "$EDITOR" "project" "$(pwd)"
                done
                echo ""
                printf '%b\n' "${CYAN}── Global ──${NC}"
                for EDITOR in "${EDITORS[@]}"; do
                    install_to_editor "$EDITOR" "global" "$HOME"
                done
                git_commit_and_push
            fi
            ;;
    esac
}

run_lifecycle_action "$OPERATION" "$OPTION"

# ─── WSL: offer Windows-side installation / uninstallation ─────────────────

if [ "$IS_WSL" = true ]; then
    echo ""
    INSTALL_WIN=false
    if [ "$NON_INTERACTIVE" = true ]; then
        echo "WSL detected. Non-interactive mode: skipping Windows-side operations."
    else
        printf '%b\n' "${CYAN}WSL detected.${NC}"
        if [ "$OPERATION" = "uninstall" ]; then
            read -r -p "Also uninstall from Windows-side user profile? (y/n) [n]: " WIN_ANSWER
        else
            read -r -p "Also install to Windows-side user profile? (y/n) [n]: " WIN_ANSWER
        fi
        WIN_ANSWER="${WIN_ANSWER:-n}"
        if [ "$WIN_ANSWER" = "y" ]; then
            INSTALL_WIN=true
        fi
    fi

    if [ "$INSTALL_WIN" = true ]; then
        WIN_HOME=$(wslpath "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')" 2>/dev/null)
        if [ -z "$WIN_HOME" ] || [ ! -d "$WIN_HOME" ]; then
            printf '%b\n' "${RED}Error: could not resolve Windows home directory.${NC}"
            echo "Tried: wslpath of %USERPROFILE%"
        else
            if [ "$OPERATION" = "uninstall" ]; then
                printf '%b\n' "${YELLOW}Uninstalling from Windows profile: $WIN_HOME${NC}"
                for EDITOR in "${EDITORS[@]}"; do
                    uninstall_from_editor "$EDITOR" "global" "$WIN_HOME"
                done
                printf '%b\n' "${GREEN}✓ Windows-side uninstallation complete.${NC}"
            else
                printf '%b\n' "${YELLOW}Installing to Windows profile: $WIN_HOME${NC}"
                for EDITOR in "${EDITORS[@]}"; do
                    install_to_editor "$EDITOR" "global" "$WIN_HOME"
                done
                printf '%b\n' "${GREEN}✓ Windows-side installation complete.${NC}"
            fi
        fi
    fi
fi

# ─── Done ────────────────────────────────────────────────────────────────────

echo ""
echo "════════════════════════════════════════════════"
echo ""

if [ "$OPERATION" = "uninstall" ]; then
    if [ "$UNINSTALL_KEPT_COUNT" -gt 0 ]; then
        printf '%b\n' "${YELLOW}Uninstallation finished with some files kept.${NC}"
        echo "Removed $UNINSTALL_REMOVED_COUNT file(s); kept $UNINSTALL_KEPT_COUNT (see warnings above)."
    elif [ "$UNINSTALL_REMOVED_COUNT" -eq 0 ]; then
        printf '%b\n' "${CYAN}Nothing to uninstall.${NC}"
        echo "No Bem-te-vi files were found installed."
    else
        printf '%b\n' "${GREEN}Uninstallation successful!${NC}"
        echo "Bem-te-vi has been completely removed. Removed $UNINSTALL_REMOVED_COUNT file(s)."
    fi
else
    printf '%b\n' "${GREEN}Installation successful!${NC}"
    echo ""
    echo "Next steps:"
    for EDITOR in "${EDITORS[@]}"; do
        case "$EDITOR" in
            claude)
                echo "  Claude Code : Type /qa and press Tab (dispatcher)"
                echo "              : Or use active commands:"
                echo "              :   /qa-cases  /qa-defect  /qa-bdd  /qa-refinement  /qa-tdd  /qa-automate  /qa-review"
                echo "              : Or use specialized rules/skills/agents:"
                echo "              :   - Rules : rules/testing-guidelines.md, rules/code-style-qa.md, accessibility-qa.md, security-qa.md"
                echo "              :   - Skills: skills/qa-plan/, skills/qa-explore/"
                echo "              :   - Agents: agents/qa-engineer.md, agents/qa-groomer.md, agents/qa-designer.md, agents/qa-writer.md"
                ;;
            cursor)
                echo "  Cursor/Trae : The rule loads automatically (alwaysApply: false — enable in settings)"
                ;;
            windsurf)
                echo "  Windsurf    : Rules are loaded from .windsurfrules / .windsurf/rules/"
                ;;
            copilot)
                echo "  Copilot     : Instructions loaded from .github/copilot-instructions.md"
                ;;
            cline)
                echo "  Cline       : Rules loaded from .clinerules"
                ;;
            antigravity)
                echo "  Antigravity : Skill loaded from .agents/skills/qa/SKILL.md"
                ;;
        esac
    done
    echo ""
    echo "Documentation:"
    echo "- Quick start: cat $SCRIPT_DIR/INSTALL.md"
    echo "- Full guide: cat $SCRIPT_DIR/README.md"
    echo "- Examples: cat $SCRIPT_DIR/examples/README.md"
fi
echo ""
echo "════════════════════════════════════════════════"
