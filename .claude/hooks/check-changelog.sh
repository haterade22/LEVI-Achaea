#!/usr/bin/env bash
# Stop hook: Remind to update CHANGELOG.md if real work was done

INPUT=$(cat)

# Check if any Lua source files were modified this session
MODIFIED=$(git diff --name-only 2>/dev/null | grep -c '\.lua$' || echo "0")
STAGED=$(git diff --staged --name-only 2>/dev/null | grep -c '\.lua$' || echo "0")

TOTAL=$((MODIFIED + STAGED))

if [ "$TOTAL" -gt 0 ]; then
  # Check if CHANGELOG was also modified
  CL_CHANGED=$(git diff --name-only 2>/dev/null | grep -c 'CHANGELOG' || echo "0")
  CL_STAGED=$(git diff --staged --name-only 2>/dev/null | grep -c 'CHANGELOG' || echo "0")

  if [ "$CL_CHANGED" -eq 0 ] && [ "$CL_STAGED" -eq 0 ]; then
    echo "Reminder: $TOTAL Lua file(s) changed but CHANGELOG.md has not been updated." >&2
  fi
fi

exit 0