#!/usr/bin/env bash
# UserPromptSubmit hook: Set session title from branch + version

BRANCH=$(git branch --show-current 2>/dev/null)
VERSION=$(cat version.txt 2>/dev/null | tr -d '[:space:]')

TITLE="LEVI"
[ -n "$BRANCH" ] && TITLE="LEVI: $BRANCH"
[ -n "$VERSION" ] && TITLE="$TITLE (v$VERSION)"

if command -v jq &>/dev/null; then
  jq -n --arg title "$TITLE" '{"hookSpecificOutput": {"sessionTitle": $title}}'
else
  echo "{\"hookSpecificOutput\": {\"sessionTitle\": \"$TITLE\"}}"
fi

exit 0