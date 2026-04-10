#!/usr/bin/env bash
# PermissionDenied hook: Audit log blocked tool calls

INPUT=$(cat)

if command -v jq &>/dev/null; then
  TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
  REASON=$(echo "$INPUT" | jq -r '.reason // "unspecified"')
else
  TOOL_NAME=$(echo "$INPUT" | sed -n 's/.*"tool_name" *: *"\([^"]*\)".*/\1/p')
  REASON=$(echo "$INPUT" | sed -n 's/.*"reason" *: *"\([^"]*\)".*/\1/p')
  TOOL_NAME="${TOOL_NAME:-unknown}"
  REASON="${REASON:-unspecified}"
fi

LOG_DIR=".claude/logs"
mkdir -p "$LOG_DIR" 2>/dev/null

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "[${TIMESTAMP}] DENIED: ${TOOL_NAME} — ${REASON}" >> "${LOG_DIR}/permission-denied.log"

exit 0