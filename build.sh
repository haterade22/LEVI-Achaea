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
  # GLOB, do not pin versions. This list held jre1.8.0_491 and broke the moment Java
  # auto-updated to _501 mid-session (2026-08-04) -- an exact version in a path is a build
  # that expires on someone else's release schedule. "C:/Program Files/Java/latest" is
  # Oracle's own stable alias and is tried first; the globs then catch any JDK/JRE present.
  for _cand in "E:/Java"                "C:/Program Files/Java/latest"                "C:/Program Files/Java"/jdk*                "C:/Program Files/Java"/jre*                "C:/Program Files/Eclipse Adoptium"/jdk*                "C:/Program Files/Microsoft"/jdk*; do
    if _java_ok "$_cand"; then export JAVA_HOME="$_cand"; break; fi
  done
fi
if ! _java_ok "$JAVA_HOME"; then
  echo "ERROR: No valid JAVA_HOME found (need a dir containing bin/java.exe)." >&2
  echo "       Set JAVA_HOME, or add your JDK/JRE path to the candidate list in build.sh." >&2
  exit 1
fi
echo "Using JAVA_HOME=$JAVA_HOME"

# Resolve Muddler: honor a valid pre-set MUDDLE_BAT, else try the known install locations
# (C:/Tools is where this machine keeps it; E: is the original dev box).
if [ -z "$MUDDLE_BAT" ] || [ ! -e "$MUDDLE_BAT" ]; then
  MUDDLE_BAT=""
  for _cand in "C:/Tools/muddle-shadow-1.1.0/muddle-shadow-1.1.0/bin/muddle.bat"                "E:/muddle-shadow-1.1.0/muddle-shadow-1.1.0/bin/muddle.bat"; do
    if [ -e "$_cand" ]; then MUDDLE_BAT="$_cand"; break; fi
  done
fi
if [ -z "$MUDDLE_BAT" ]; then
  echo "ERROR: Muddler not found. Set MUDDLE_BAT, or add its path to the candidate list in build.sh." >&2
  exit 1
fi
echo "Using MUDDLE_BAT=$MUDDLE_BAT"

cd muddler_project
"$MUDDLE_BAT"

echo "=== Build complete: muddler_project/build/Levi_Ataxia.mpackage ==="
