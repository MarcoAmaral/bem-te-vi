#!/usr/bin/env bash
# tests/test-ts-samples.sh — every TypeScript sample the package ships type-checks (plan 055, item
# I7).
#
# The samples under .claude/ are copied into users' projects as they are. Plan 028 corrected two of
# them that could not have compiled, and plan 036 checked its new ones with tsc by hand; nothing
# checked the rest. This check extracts every ```ts, ```typescript and ```tsx block from the
# Markdown under .claude/, writes each to its own file and runs `tsc --noEmit --strict` over them.
#
# - A block whose first line is a comment naming a relative path (`// playwright/pages/BasePage.ts`)
#   is written to that path, so the blocks of one document that import each other resolve, as
#   they would in the project the document describes. Any other block is written alone.
# - A block that is intentionally partial (a fragment that uses a fixture such as `page`, a
#   template whose module under test is the user's) is skipped only when the line before it, blank
#   lines aside, is exactly `<!-- ts-check: skip (<reason>) -->`. Every skip is listed with its
#   reason; a marker that is malformed or not followed by a TypeScript block fails the check.
# - Packages with real types come from devDependencies (@playwright/test, vitest, @types/node).
#   STUBBED below lists the packages a sample imports whose types are not installed: they resolve
#   to `any`, so the code around them is still checked, but their own API is not. noImplicitThis
#   is off because a stub gives a callback no `this` type; the real Cucumber types give step
#   functions a World with an index signature, so `this.page` is `any` there too.
#
# Usage: tests/test-ts-samples.sh [repo-dir]    (default: this repository)
#        The type checker comes from this repository's node_modules (npm ci).

set -u

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SELF_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TSC="$SELF_ROOT/node_modules/.bin/tsc"
STUBBED="@axe-core/playwright @cucumber/cucumber @testing-library/jest-dom @vitejs/plugin-react dotenv @my-company/payment-sdk/client @my-company/payment-sdk/types"

if [ ! -x "$TSC" ]; then
  echo "  ✘ no type checker at $TSC: run npm ci first"
  exit 1
fi

WORK="$(mktemp -d "${TMPDIR:-/tmp}/ts-samples.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/src"
ln -s "$SELF_ROOT/node_modules" "$WORK/node_modules"
: > "$WORK/map"
: > "$WORK/skips"
: > "$WORK/problems"

# Write each block of one Markdown file under $WORK/src/<file>.d/ and record, per written file,
# "<generated path>\t<source>\t<line of the block's first line>".
while IFS= read -r md; do
  rel="${md#"$ROOT"/}"
  # tsc's include globs skip folders whose name starts with a dot, so .claude/ becomes claude/.
  gen="src/${rel#.}.d"
  awk -v rel="$rel" -v gen="$gen" -v out="$WORK/$gen" -v map="$WORK/map" -v skips="$WORK/skips" \
      -v problems="$WORK/problems" '
    function problem(msg) { print rel ":" NR ": " msg >> problems }
    function finish_marker_check() {
      if (marker != "") { problem("ts-check marker at line " markerline " is not followed by a TypeScript block"); marker = "" }
    }
    !inblock && !infence && /ts-check:/ {
      if (match($0, /^[ ]*<!-- ts-check: skip \(.+\) -->[ ]*$/)) {
        finish_marker_check()
        marker = $0; sub(/^[ ]*<!-- ts-check: skip \(/, "", marker); sub(/\) -->[ ]*$/, "", marker)
        markerline = NR
      } else {
        problem("malformed ts-check marker (expected <!-- ts-check: skip (<reason>) -->)")
      }
      next
    }
    !inblock && !infence && /^[ ]*```(ts|typescript|tsx)[ ]*$/ {
      indent = $0; sub(/[^ ].*$/, "", indent)
      ext = ($0 ~ /tsx/) ? "tsx" : "ts"
      start = NR + 1; inblock = 1; nlines = 0
      skipping = (marker != ""); reason = marker; marker = ""
      next
    }
    !inblock && /^[ ]*```/ { finish_marker_check(); infence = !infence; next }
    !inblock && !infence && !/^[ ]*$/ && marker != "" { finish_marker_check() }
    inblock && /^[ ]*```[ ]*$/ {
      inblock = 0
      if (skipping) { print rel ":" start - 1 "\t" reason >> skips; next }
      file = "block-L" (start - 1) "." ext
      if (match(body[1], /^\/\/ [A-Za-z0-9_.@\/-]+\.tsx?([ ]|$)/)) {
        named = body[1]; sub(/^\/\/ /, "", named); sub(/[ ].*$/, "", named)
        if (named !~ /^\// && named !~ /\.\./) file = named
      }
      if (file in written) { problem("two blocks are written to " file); next }
      written[file] = 1
      path = out "/" file
      dir = path; sub(/\/[^\/]*$/, "", dir)
      system("mkdir -p \"" dir "\"")
      for (i = 1; i <= nlines; i++) print body[i] > path
      close(path)
      print gen "/" file "\t" rel "\t" start >> map
      next
    }
    inblock {
      line = $0
      if (index(line, indent) == 1) line = substr(line, length(indent) + 1)
      body[++nlines] = line
      next
    }
    END { finish_marker_check() }
  ' "$md"
done < <(find "$ROOT/.claude" -name '*.md' -type f | LC_ALL=C sort)

checked=$(wc -l < "$WORK/map" | tr -d ' ')
skipped=$(wc -l < "$WORK/skips" | tr -d ' ')

{
  for m in $STUBBED; do printf 'declare module "%s";\n' "$m"; done
} > "$WORK/stubs.d.ts"

cat > "$WORK/tsconfig.json" <<'EOF'
{
  "compilerOptions": {
    "strict": true,
    "noImplicitThis": false,
    "noEmit": true,
    "skipLibCheck": true,
    "target": "es2022",
    "lib": ["es2022", "dom", "dom.iterable"],
    "module": "esnext",
    "moduleResolution": "bundler",
    "moduleDetection": "force",
    "esModuleInterop": true,
    "jsx": "preserve",
    "types": ["node"]
  },
  "include": ["stubs.d.ts", "src/**/*.ts", "src/**/*.tsx"]
}
EOF

FAILED=0
if [ -s "$WORK/problems" ]; then
  sed 's/^/  ✘ /' "$WORK/problems"
  FAILED=1
fi

if [ "$checked" -eq 0 ]; then
  echo "  ✘ no TypeScript block found under $ROOT/.claude; the extraction is broken"
  FAILED=1
else
  # Every extracted file must be part of the program, or a pass would mean nothing.
  listed=$( (cd "$WORK" && "$TSC" -p tsconfig.json --listFilesOnly) 2>/dev/null | grep -c '/src/')
  if [ "$listed" -ne "$checked" ]; then
    echo "  ✘ tsc would check $listed of the $checked extracted files; the generated tsconfig is wrong"
    FAILED=1
  # tsc reports "src/<source>.d/<file>(line,col): error TSnnnn: ...": map it back to the source line.
  elif (cd "$WORK" && "$TSC" -p tsconfig.json --pretty false) > "$WORK/tsc.log" 2>&1; then
    echo "  ✔ $checked TypeScript blocks under .claude/ type-check (tsc --strict)"
  else
    awk -F'\t' -v work="$WORK" '
      FILENAME == work "/map" { src[$1] = $2; start[$1] = $3; next }
      match($0, /^src\/[^(]+\([0-9]+,[0-9]+\)/) {
        loc = substr($0, 1, RLENGTH); rest = substr($0, RLENGTH + 1)
        file = loc; sub(/\(.*$/, "", file)
        pos = loc; sub(/^[^(]*\(/, "", pos); split(pos, p, ","); line = p[1] + 0
        if (file in src) { print "  ✘ " src[file] ":" start[file] + line - 1 rest; next }
      }
      /^[ ]/ { print "    " $0; next }
      { print "  ✘ " $0 }
    ' "$WORK/map" "$WORK/tsc.log"
    FAILED=1
  fi
fi

if [ "$skipped" -gt 0 ]; then
  echo "  - $skipped blocks skipped by a ts-check marker:"
  sed -e 's/\t/  (/' -e 's/$/)/' -e 's/^/      /' "$WORK/skips"
fi

if [ "$FAILED" -ne 0 ]; then
  echo "A TypeScript sample under .claude/ does not type-check, or a ts-check marker is wrong."
  exit 1
fi
echo "✔ Every TypeScript sample under .claude/ type-checks or is skipped with a stated reason."
