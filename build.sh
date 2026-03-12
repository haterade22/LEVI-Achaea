#!/bin/bash
# Build LEVI-Achaea Mudlet package
# Usage: ./build.sh [--dry-run] [--convert-only]

set -e
cd "$(dirname "$0")"

DRY_RUN=""
CONVERT_ONLY=""

for arg in "$@"; do
  case $arg in
    --dry-run) DRY_RUN="--dry-run" ;;
    --convert-only) CONVERT_ONLY=1 ;;
  esac
done

echo "=== Converting src_new → muddler_project ==="
python tools/convert_to_muddler.py --src src_new --output muddler_project $DRY_RUN

if [ -n "$DRY_RUN" ]; then
  echo "=== Dry run complete ==="
  exit 0
fi

if [ -n "$CONVERT_ONLY" ]; then
  echo "=== Convert complete (skipping Muddler build) ==="
  exit 0
fi

echo "=== Building with Muddler ==="
export JAVA_HOME="E:/Java"
cd muddler_project
"E:/muddle-shadow-1.1.0/muddle-shadow-1.1.0/bin/muddle.bat"

echo "=== Build complete: muddler_project/build/Levi_Ataxia.mpackage ==="
