---
name: build
description: Build the Levi_Ataxia Mudlet package from src_new sources
user_invocable: true
---

# Build LEVI-Achaea Package

Run the full build pipeline for the Levi_Ataxia Mudlet package.

## Arguments
- No args: full build (convert + Muddler)
- `--dry-run`: preview conversion without writing files
- `--convert-only`: convert src_new to Muddler format but skip Muddler build

## Steps

1. Run the build script from the LEVI-Achaea directory:
   ```bash
   cd LEVI-Achaea && bash build.sh [args]
   ```

2. Check the exit code. If non-zero, report the error output.

3. On success, report:
   - Build output location: `muddler_project/build/Levi_Ataxia.mpackage`
   - File size of the built package
   - Any warnings from the conversion step

4. **After a successful build, always complete the full release flow:**
   - Commit all pending changes (version files + any code changes)
   - Tag the commit: `git tag v<version>` (read version from `version.txt`)
   - Push commit and tag: `git push && git push --tags`
   - This ensures the auto-updater and GitHub Releases stay current

## Requirements
- Java 8+ at `E:\Java`
- Muddler at `E:\muddle-shadow-1.1.0\muddle-shadow-1.1.0\`
- Python 3 with no extra dependencies

## Important
- Only one build may run at a time
- The source of truth is always `src_new/` — never edit files in `muddler_project/src/`
