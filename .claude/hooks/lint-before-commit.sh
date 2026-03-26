#!/usr/bin/env bash
# lint-before-commit.sh — Validate Lua syntax before git commit
# Exit 2 = block commit, Exit 0 = allow

# Search the raw tool input — no need to parse JSON for detection
INPUT="$TOOL_INPUT"

# Only gate git commit commands
if ! echo "$INPUT" | grep -qE 'git\s+commit'; then
  exit 0
fi

# Find lua checker
LUAC=""
if command -v luac5.1 &>/dev/null; then
  LUAC="luac5.1"
elif command -v luac &>/dev/null; then
  LUAC="luac"
else
  echo "WARNING: No luac found — skipping Lua syntax check" >&2
  exit 0
fi

# Get staged .lua files (added, copied, modified)
LUA_FILES=$(git diff --cached --name-only --diff-filter=ACM -- '*.lua' 2>/dev/null)

if [ -z "$LUA_FILES" ]; then
  exit 0
fi

ERRORS=0
ERROR_OUTPUT=""

while IFS= read -r file; do
  if [ -f "$file" ]; then
    # Source files have YAML front matter (--- delimited). Strip it before syntax check.
    # awk prints everything after the second --- line.
    # If no YAML header, it outputs the whole file.
    CONTENT=$(awk 'BEGIN{c=0} /^---[[:space:]]*$/{c++; next} c>=2' "$file" 2>/dev/null)
    if [ -z "$CONTENT" ]; then
      # No YAML header or file is empty after stripping — check raw file
      RESULT=$($LUAC -p "$file" 2>&1)
    else
      RESULT=$(echo "$CONTENT" | $LUAC -p - 2>&1)
    fi
    if [ $? -ne 0 ]; then
      ERRORS=$((ERRORS + 1))
      ERROR_OUTPUT="${ERROR_OUTPUT}
SYNTAX ERROR: ${file}
${RESULT}"
    fi
  fi
done <<< "$LUA_FILES"

if [ $ERRORS -gt 0 ]; then
  echo "BLOCKED: Lua syntax errors found in $ERRORS file(s):" >&2
  echo "$ERROR_OUTPUT" >&2
  echo "" >&2
  echo "Fix the syntax errors before committing." >&2
  exit 2
fi

FILE_COUNT=$(echo "$LUA_FILES" | wc -l | tr -d ' ')
echo "Lua syntax check passed ($FILE_COUNT files)" >&2
exit 0
