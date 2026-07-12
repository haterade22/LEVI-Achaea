#!/usr/bin/env bash
# session-start.sh — Rich session context on startup

echo "=== LEVI-Achaea Session ==="
echo ""

echo "Branch: $(git branch --show-current 2>/dev/null || echo 'detached/unknown')"
echo "Version: $(cat version.txt 2>/dev/null || echo 'unknown')"
echo ""

# Warn if the current version has no pushed tag — users cannot receive it via
# sysupdate until the tag is pushed and CI publishes the release asset.
# Skipped silently when offline (ls-remote fails).
VERSION=$(cat version.txt 2>/dev/null | tr -d '[:space:]')
if [ -n "$VERSION" ]; then
  REMOTE_TAGS=$(timeout 5 git ls-remote --tags origin 2>/dev/null)
  if [ -n "$REMOTE_TAGS" ] && ! echo "$REMOTE_TAGS" | grep -q "refs/tags/v${VERSION}$"; then
    echo "!!! WARNING: v${VERSION} has no tag on origin — sysupdate still serves the previous release."
    echo "!!! Push the tag (git tag v${VERSION} && git push origin v${VERSION}) to publish it."
    echo ""
  fi
fi

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
