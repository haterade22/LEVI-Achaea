#!/usr/bin/env bash
# pre-compact.sh — Save working context before compaction
# All output to stderr so it survives compaction and gets injected into post-compact context

exec >&2

echo "=== PRE-COMPACT CONTEXT SNAPSHOT ==="
echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC' 2>/dev/null || date '+%Y-%m-%d %H:%M:%S')"
echo ""

echo "--- Branch ---"
git branch --show-current 2>/dev/null || echo "(not in a git repo)"

echo ""
echo "--- Version ---"
cat version.txt 2>/dev/null || echo "(no version.txt)"

echo ""
echo "--- Uncommitted Changes ---"
git status --short 2>/dev/null || echo "(no git)"

echo ""
echo "--- Staged Changes ---"
git diff --cached --stat 2>/dev/null

echo ""
echo "--- Changed File Stats ---"
git diff --stat 2>/dev/null

echo ""
echo "--- WIP Markers in Changed Files ---"
changed_files=$(git diff --name-only 2>/dev/null; git diff --cached --name-only 2>/dev/null)
if [ -n "$changed_files" ]; then
  echo "$changed_files" | sort -u | while read -r f; do
    if [ -f "$f" ]; then
      markers=$(grep -n -E '(WIP|TODO|FIXME|HACK|XXX|INCOMPLETE)' "$f" 2>/dev/null | head -5)
      if [ -n "$markers" ]; then
        echo "  $f:"
        echo "$markers" | sed 's/^/    /'
      fi
    fi
  done
else
  echo "  (no changed files)"
fi

echo ""
echo "--- Recent Commits ---"
git log --oneline -5 2>/dev/null

echo "=== END SNAPSHOT ==="
exit 0
