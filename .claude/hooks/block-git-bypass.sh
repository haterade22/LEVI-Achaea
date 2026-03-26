#!/usr/bin/env bash
# block-git-bypass.sh — Prevent git safety bypasses
# Exit 2 = block, Exit 0 = allow

# Search the raw tool input directly — no need to parse JSON,
# the flags we're looking for will appear in the command string
INPUT="$TOOL_INPUT"

# Only check if input contains git
if ! echo "$INPUT" | grep -q '\bgit\b'; then
  exit 0
fi

# Check for dangerous flags
BLOCKED_FLAG=""
if echo "$INPUT" | grep -qE '\-\-no-verify'; then
  BLOCKED_FLAG="--no-verify"
elif echo "$INPUT" | grep -qE '\-\-no-gpg-sign'; then
  BLOCKED_FLAG="--no-gpg-sign"
elif echo "$INPUT" | grep -qE 'git\s+push.*\-\-force\b'; then
  BLOCKED_FLAG="--force (on push)"
elif echo "$INPUT" | grep -qE 'git\s+push.*\-\-force-with-lease'; then
  BLOCKED_FLAG="--force-with-lease (on push)"
elif echo "$INPUT" | grep -qE 'git\s+reset\s+\-\-hard'; then
  BLOCKED_FLAG="--hard (on reset)"
elif echo "$INPUT" | grep -qE 'git\s+clean\s+\-f'; then
  BLOCKED_FLAG="-f (on clean)"
fi

if [ -n "$BLOCKED_FLAG" ]; then
  echo "BLOCKED: Git command uses dangerous flag: $BLOCKED_FLAG" >&2
  echo "This flag bypasses safety checks and is not allowed." >&2
  echo "If you really need this, ask the user to run it manually." >&2
  exit 2
fi

exit 0
