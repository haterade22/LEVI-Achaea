#!/usr/bin/env bash
# session-start.sh — Rich session context on startup

echo "=== LEVI-Achaea Session ==="
echo ""

echo "Branch: $(git branch --show-current 2>/dev/null || echo 'detached/unknown')"
echo "Version: $(cat version.txt 2>/dev/null || echo 'unknown')"
echo ""

echo "--- Last 5 Commits ---"
git log --oneline -5 2>/dev/null || echo "(no git history)"
echo ""

# Show uncommitted changes
DIRTY=$(git status --short 2>/dev/null)
if [ -n "$DIRTY" ]; then
  COUNT=$(echo "$DIRTY" | wc -l | tr -d ' ')
  echo "--- Uncommitted Changes ($COUNT files) ---"
  echo "$DIRTY"
else
  echo "Working tree clean."
fi

exit 0
