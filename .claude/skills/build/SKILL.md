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

1. Run the build script of the tree that holds your change: your worktree `lv-<name>`, not the main checkout
   (`cd LEVI-Achaea` from the session's start folder is the main checkout). The script changes to its own folder:
   ```bash
   bash <absolute path of your worktree>/build.sh [args]
   ```

2. Check the exit code. If non-zero, report the error output.

3. On success, report:
   - Build output location: `muddler_project/build/Levi_Ataxia.mpackage`
   - File size of the built package
   - Any warnings from the conversion step

4. **After a successful build, always complete the full release flow, in the order of "The release order" in `CLAUDE.md`** ("Build, Test and Release", steps 1 to 8; the incident behind each step is in `docs/ai-includes/git-and-release.md`). In short:
   - Commit THIS session's files, staged by path (version files + your code changes). Never `git add -A` or `git commit -a`: another session can have files in the same tree
   - `/c/Python314/python -B tools/ci_local.py`, and go on only at `Ready to push: YES`; then `git fetch origin && git rebase origin/main`
   - `git push origin HEAD:main` (no pull request). Do NOT tag yet
   - `/c/Python314/python -B tools/release.py tag-ready <version>`: only when the `Build & Validate` run for that commit passed does it print the tag command. Run that command (it tags that commit and pushes the ONE tag)
   - When the tag's run has built the release: `/c/Python314/python -B tools/release.py post`, and run the refresh commands it prints (the maintainer imports from `muddler_project/build/` in the main checkout)
   - This ensures the auto-updater and GitHub Releases stay current
   - **Never `git push --tags`.** It pushes every stale local tag, each of which fires the
     `v*` release workflow against that tag's OLD source. GitHub picks "Latest" by publish
     time, not semver, so the last stale release to finish hijacks
     `/releases/latest/download/Levi_Ataxia.mpackage` — the URL `sysupdate` installs from.
     Push the one tag by name. `.githooks/pre-push` refuses two `v*` tags in one push.

## Requirements
- Java 8+ (`build.sh` finds it via `JAVA_HOME` or its candidate list; on 2026-11-13 the JRE 8 at
  `C:\Program Files\Java\jre1.8.0_503`)
- Muddler 1.1.0 (`MUDDLE_BAT` or the candidate list; on 2026-11-13 `E:\muddle-shadow-1.1.0\muddle-shadow-1.1.0\`)
- Python 3 with `pyyaml` (the converter imports `yaml`)

## Important
- Only one build at a time. Nothing enforces this (no Claude Code hook runs, `docs/reference/harness-facts.md`): check that no other session is building
- No hook lints a commit or blocks `--no-verify`, `--force` or `--hard`. The gates that work: `tools/ci_local.py` before a push, `.githooks/pre-push` at the push, CI after it
- The source of truth is always `src_new/` — never edit files in `muddler_project/src/`
