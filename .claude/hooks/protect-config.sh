#!/usr/bin/env bash
# protect-config.sh — Block AI edits to Claude settings files
# Exit 2 = block, Exit 0 = allow

INPUT="$TOOL_INPUT"

# Extract file_path from the tool input JSON
# Try jq first, fall back to sed (grep -P not available on Windows Git Bash)
if command -v jq &>/dev/null; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.file_path // .file // empty' 2>/dev/null)
else
  FILE_PATH=$(echo "$INPUT" | sed -n 's/.*"file_path" *: *"\([^"]*\)".*/\1/p')
  if [ -z "$FILE_PATH" ]; then
    FILE_PATH=$(echo "$INPUT" | sed -n 's/.*"file" *: *"\([^"]*\)".*/\1/p')
  fi
fi

# Normalize path separators for Windows
FILE_PATH=$(echo "$FILE_PATH" | sed 's|\\\\|/|g; s|\\|/|g')

# Protected patterns — settings files at any level
case "$FILE_PATH" in
  */.claude/settings.json|*/.claude/settings.local.json)
    echo "BLOCKED: Direct modification of Claude settings files is not allowed." >&2
    echo "Settings files are protected to prevent accidental permission changes." >&2
    echo "Use the /update-config skill or ask the user to update settings manually." >&2
    exit 2
    ;;
esac

exit 0
