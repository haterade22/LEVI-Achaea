---
name: version-bump
description: Bump the version across all 3 tracked locations and verify consistency
user_invocable: true
---

# Version Bump

Update the package version in all 3 locations that must stay in sync.

## Arguments
- Required: the new version string (e.g., `4.4.0`)

## Steps

1. **Read current versions** from all 3 locations:
   - `version.txt` — plain text
   - `muddler_project/mfile` — JSON `"version"` field
   - `src_new/scripts/_groups.yaml` — Lua line containing `ataxiaVersion = "X.Y.Z"`

2. **Report current state**: show the version found in each file. If they are already out of sync, warn the user before proceeding.

3. **Update all 3 files** with the new version:
   - `version.txt`: replace entire content with the new version string
   - `muddler_project/mfile`: update the `"version"` JSON field
   - `src_new/scripts/_groups.yaml`: update the `ataxiaVersion = "..."` value in the inline Lua init script

4. **Verify**: re-read all 3 files and confirm they now match the target version.

5. **Report**: list the changes made and suggest next steps (build + commit + push).

## Important
- The `mfile` is JSON — preserve all other fields (package, title, author)
- The `_groups.yaml` version is inside an inline Lua script block — match the existing format exactly
- Do NOT automatically build or commit — just update the version files
