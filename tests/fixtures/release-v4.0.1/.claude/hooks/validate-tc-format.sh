#!/usr/bin/env bash
# .claude/hooks/validate-tc-format.sh — Automated Test Case Format Validator
# Checks that markdown test cases (*.md) conform to the TC-CODE-NNN standard.

set -euo pipefail

# Color Codes
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
NC="\033[0m"

info()    { printf "${YELLOW}[INFO]${NC}  %s\n" "$1"; }
success() { printf "${GREEN}[OK]${NC}    %s\n" "$1"; }
error()   { printf "${RED}[ERR]${NC}   %s\n" "$1" >&2; }

# Helper to check if file has frontmatter keys
# check_key <normalised-file> <key> <name-to-report> <closing-boundary-line>
# Looks only between the opening and the closing '---', never in the body.
check_key() {
  local FILE="$1"
  local KEY="$2"
  local NAME="$3"
  local END="$4"
  if ! sed -n "2,$((END - 1))p" "$FILE" | grep -qE "^${KEY}:"; then
    error "Missing required frontmatter key: '${KEY}' in $NAME"
    return 1
  fi
  return 0
}

# Prints one line per missing or empty template field, per test case.
check_case_fields() {
  awk '
    BEGIN {
      SENT = sprintf("%c", 1)
      n = split("Tags|Issue|Automation Score|ISTQB Technique|Manual Env|Precondition|Steps|Expected|data-testid needed|Source|Note", REQ, "|")
    }
    function flush(   i) {
      if (id == "") return
      for (i = 1; i <= n; i++) {
        if (!(REQ[i] in seen)) print id " is missing template field \047" REQ[i] "\047"
        else if (seen[REQ[i]] == "") print id " has an empty template field \047" REQ[i] "\047"
      }
      # Source names where the case comes from: an acceptance criterion it checks, or
      # "Added by QA (<reason>)" when QA added it beyond the ticket. Nothing vaguer.
      if (("Source" in seen) && seen["Source"] != "" &&
          seen["Source"] !~ /^ACs?[-_ #.]*[0-9]/ &&
          seen["Source"] !~ /^Added by QA \([^)]*[^) ][^)]*\)/)
        print id " has a Source that is neither an AC nor \047Added by QA (reason)\047: " seen["Source"]
    }
    /^## TC-[A-Z0-9]+-[0-9]+:/ {
      flush()
      delete seen
      id = $2
      sub(/:$/, "", id)
      next
    }
    # Any other heading closes the case: rows of a later section belong to no case.
    /^#+ / {
      flush()
      delete seen
      id = ""
      next
    }
    id != "" && /^\|/ {
      # An escaped pipe (\|) is part of the cell, not a column separator.
      line = $0
      gsub(/\\\|/, SENT, line)
      split(line, cells, "|")
      name = cells[2]
      gsub(/^[ \t]*\*\*|\*\*[ \t]*$/, "", name)
      gsub(SENT, "|", name)
      val = cells[3]
      gsub(/^[ \t]+|[ \t]+$/, "", val)
      gsub(SENT, "|", val)
      seen[name] = val
    }
    END { flush() }
  ' "$1"
}

# Writes a copy of $1 without a UTF-8 BOM and without CR line endings to stdout, so every
# check sees the same bytes whether the file came from Linux, Git for Windows (core.autocrlf)
# or PowerShell 5.1 (Out-File -Encoding utf8). printf builds the bytes: BSD sed knows neither
# \xEF nor \r. Lines inside a code fence are blanked (line numbers are kept): a template
# shown in documentation, such as .claude/commands/qa-cases.md, is not a test case file.
normalise() {
  local BOM CR
  BOM="$(printf '\357\273\277')"
  CR="$(printf '\r')"
  LC_ALL=C sed -e "1s/^${BOM}//" -e "s/${CR}\$//" "$1" |
    awk '/^[ \t]*(```|~~~)/ { fence = !fence; print ""; next } fence { print ""; next } { print }'
}

# validate_normalised <original-path> <normalised-copy>: all checks read the copy, all messages name the original.
validate_normalised() {
  local FILE="$1"
  local NORM="$2"

  # Check if file has any test cases defined
  if ! grep -qE "^## TC-[A-Z0-9]+-[0-9]+:" "$NORM"; then
    # Not a test case file: skip, but say so when the name says it should be one
    case "$(basename "$FILE")" in
      TC-*.md) info "No '## TC-CODE-NNN:' heading found in $FILE; nothing validated" ;;
    esac
    return 0
  fi

  info "Validating Test Case format for: $FILE"
  local ERRORS=0

  # Check frontmatter boundary
  if [[ $(head -n 1 "$NORM") != "---" ]]; then
    error "File must start with '---' YAML frontmatter boundary in $FILE"
    ERRORS=$((ERRORS + 1))
  fi

  # The closing boundary must come within the first 40 lines; without it the keys are looked
  # for in lines 2-40 so one missing boundary is reported once.
  local END
  END=$(awk 'NR > 1 && /^---$/ { print NR; exit }' "$NORM")
  if [[ -z "$END" || "$END" -gt 40 ]]; then
    error "Missing closing frontmatter boundary '---' in $FILE"
    ERRORS=$((ERRORS + 1))
    END=41
  fi

  # Validate key frontmatter items
  check_key "$NORM" "feature" "$FILE" "$END" || ERRORS=$((ERRORS + 1))
  check_key "$NORM" "feature_code" "$FILE" "$END" || ERRORS=$((ERRORS + 1))
  check_key "$NORM" "tc_count" "$FILE" "$END" || ERRORS=$((ERRORS + 1))
  check_key "$NORM" "tracker_issues" "$FILE" "$END" || ERRORS=$((ERRORS + 1))
  check_key "$NORM" "risk_level" "$FILE" "$END" || ERRORS=$((ERRORS + 1))
  check_key "$NORM" "cdt" "$FILE" "$END" || ERRORS=$((ERRORS + 1))
  check_key "$NORM" "implementation_pack" "$FILE" "$END" || ERRORS=$((ERRORS + 1))
  check_key "$NORM" "spec" "$FILE" "$END" || ERRORS=$((ERRORS + 1))
  check_key "$NORM" "last_updated" "$FILE" "$END" || ERRORS=$((ERRORS + 1))

  # Every field the per-case template defines must appear in every case, with a value.
  # "N/A — <why>" is a value; an omitted row or an empty cell is not.
  local PROBLEMS line
  PROBLEMS=$(check_case_fields "$NORM")
  if [[ -n "$PROBLEMS" ]]; then
    while IFS= read -r line; do
      error "$line in $FILE"
      ERRORS=$((ERRORS + 1))
    done <<< "$PROBLEMS"
  fi

  if [[ $ERRORS -eq 0 ]]; then
    success "$FILE matches the TC-CODE-NNN template."
    return 0
  else
    error "Validation failed for $FILE with $ERRORS formatting errors."
    return 1
  fi
}

validate_file() {
  local FILE="$1"
  local NORM RC=0

  if [[ ! -f "$FILE" ]]; then
    error "No such file: $FILE"
    return 1
  fi

  NORM="$(mktemp)"
  normalise "$FILE" > "$NORM"
  validate_normalised "$FILE" "$NORM" || RC=$?
  rm -f "$NORM"
  return "$RC"
}

# --- Execution ---
if [[ $# -eq 0 ]]; then
  info "No file specified. Scanning workspace for markdown test cases..."
  FOUND_TCS=0
  FAILED_TCS=0
  
  # Scan all markdown files in the workspace (excluding adapters, dependencies, test fixtures, and configuration directories)
  while IFS= read -r -d '' file; do
    if grep -qE "^## TC-[A-Z0-9]+-[0-9]+:" "$file"; then
      FOUND_TCS=$((FOUND_TCS + 1))
      validate_file "$file" || FAILED_TCS=$((FAILED_TCS + 1))
    fi
  done < <(find . -type d \( -name "adapters" -o -name "node_modules" -o -name ".git" -o -name ".claude" -o -name "fixtures" \) -prune -o -name "*.md" -print0)

  if [[ $FOUND_TCS -eq 0 ]]; then
    info "No test case files found in the workspace."
    exit 0
  elif [[ $FAILED_TCS -gt 0 ]]; then
    error "Scan completed: $FAILED_TCS of $FOUND_TCS test case files failed validation."
    exit 1
  else
    success "Scan completed: All $FOUND_TCS test case files are perfectly formatted."
    exit 0
  fi
else
  # Validate every file passed as an argument; one bad file fails the run
  RC=0
  for file in "$@"; do
    validate_file "$file" || RC=1
  done
  exit "$RC"
fi
