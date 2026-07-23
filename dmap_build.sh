#!/bin/bash
# Build the standalone Dementia Mapper Mudlet package from dmap_src/.
# Usage: ./dmap_build.sh [--convert-only]
set -e
cd "$(dirname "$0")"

VERSION="$(cat dmap_version.txt 2>/dev/null || echo 0.1.0)"

echo "=== Converting dmap_src → dmap_project (v$VERSION) ==="
python tools/convert_to_muddler.py --src dmap_src --output dmap_project \
  --package-name Dementia_Mapper --package-title "Dementia Mapper (Achaea Mnemosyne)" \
  --package-version "$VERSION" --package-author Leviticus --include-roots Dementia_Mapper

if [ "$1" = "--convert-only" ]; then echo "=== Convert complete ==="; exit 0; fi

echo "=== Building with Muddler ==="
_java_ok() { [ -n "$1" ] && { [ -e "$1/bin/java.exe" ] || [ -e "$1/bin/java" ]; }; }
if ! _java_ok "$JAVA_HOME"; then
  for _cand in "E:/Java" "C:/Program Files/Java/jre1.8.0_491" "C:/Program Files/Java/jdk1.8.0_491"; do
    if _java_ok "$_cand"; then export JAVA_HOME="$_cand"; break; fi
  done
fi
if ! _java_ok "$JAVA_HOME"; then echo "ERROR: No valid JAVA_HOME found." >&2; exit 1; fi
echo "Using JAVA_HOME=$JAVA_HOME"

MUDDLE_BAT="E:/muddle-shadow-1.1.0/muddle-shadow-1.1.0/bin/muddle.bat"
if [ ! -e "$MUDDLE_BAT" ]; then echo "ERROR: Muddler not found at $MUDDLE_BAT" >&2; exit 1; fi

cd dmap_project
"$MUDDLE_BAT"
echo "=== Build complete: dmap_project/build/Dementia_Mapper.mpackage ==="
