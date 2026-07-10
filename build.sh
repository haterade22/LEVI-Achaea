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

# Resolve a valid JAVA_HOME: honor a valid pre-set one, else fall back to known local installs.
_java_ok() { [ -n "$1" ] && { [ -e "$1/bin/java.exe" ] || [ -e "$1/bin/java" ]; }; }
if ! _java_ok "$JAVA_HOME"; then
  for _cand in "E:/Java" "C:/Program Files/Java/jre1.8.0_491" "C:/Program Files/Java/jdk1.8.0_491"; do
    if _java_ok "$_cand"; then export JAVA_HOME="$_cand"; break; fi
  done
fi
if ! _java_ok "$JAVA_HOME"; then
  echo "ERROR: No valid JAVA_HOME found (need a dir containing bin/java.exe)." >&2
  echo "       Set JAVA_HOME, or add your JDK/JRE path to the candidate list in build.sh." >&2
  exit 1
fi
echo "Using JAVA_HOME=$JAVA_HOME"

MUDDLE_BAT="E:/muddle-shadow-1.1.0/muddle-shadow-1.1.0/bin/muddle.bat"
if [ ! -e "$MUDDLE_BAT" ]; then
  echo "ERROR: Muddler not found at $MUDDLE_BAT — install it or update the path in build.sh." >&2
  exit 1
fi

cd muddler_project
"$MUDDLE_BAT"

echo "=== Build complete: muddler_project/build/Levi_Ataxia.mpackage ==="
