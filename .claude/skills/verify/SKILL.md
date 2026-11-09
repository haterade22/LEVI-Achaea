---
name: verify
description: Run comprehensive build + test + git verification and produce a pass/fail report
argument-hint: "[quick|full]"
---

# Verification Report

Run the full verification suite and produce a pass/fail report.

Mode: `$ARGUMENTS` (default: `full`)

## Quick Mode

1. **Lua syntax check** — Validate all `.lua` files compile:
   ```bash
   find src_new -name '*.lua' -type f -exec luac5.1 -p {} \; 2>&1
   ```
   If `luac5.1` is not available, use the YAML-header-stripping approach from `lint-before-commit.sh`.

2. **Build** — Run the full pipeline:
   ```bash
   ./build.sh
   ```

3. **Report** — Pass/fail verdict.

## Full Mode (all of quick, plus)

4. **Unit tests** — Run the test suite:
   ```bash
   lua5.1 src_new/tests/test_runner.lua
   ```

5. **CI parity** — Run every Python step of `.github/workflows/build.yml`. A generated KB page fails CI when one of its inputs changes, and a Lua file can be an input:
   ```bash
   for c in tools/check_orphans.py tools/test_check_orphans.py tools/check_wrap.py "tools/kb_timing.py --check" tools/test_kb_timing.py "tools/kb_replay.py --check" tools/test_kb_replay.py "tools/kb_sim.py --check" tools/test_kb_sim.py "tools/kb_rules.py --check" tools/test_kb_rules.py "tools/kb_events.py --check" tools/test_kb_events.py tools/test_theorycraft.py tools/test_convert_to_muddler.py; do python -B $c > /dev/null || echo "FAIL: $c"; done
   ```
   `kb_sim.py` needs `lupa`. If a `kb_*.py --check` prints STALE, run the same tool without `--check` and read the diff (`kb_sim.py` takes about 12 minutes).

6. **Version consistency** — Verify all 3 version sources match:
   - `version.txt`
   - `muddler_project/mfile` (JSON `version` field)
   - `src_new/scripts/_groups.yaml` (`ataxiaVersion` value)

7. **Git status** — Check for uncommitted changes:
   ```bash
   git status --short
   git diff --stat
   ```

8. **CHANGELOG check** — Verify CHANGELOG.md has been updated if source files changed:
   ```bash
   git diff --name-only HEAD | grep -v CHANGELOG
   ```

9. **TODO/FIXME scan** — Count open items in source:
   ```bash
   grep -rE 'TODO|FIXME|HACK|XXX' src_new/ --include='*.lua' | wc -l
   ```

## Report Format

```
VERIFICATION REPORT
====================
Mode: [quick|full]
Date: [timestamp]

[PASS/FAIL] Lua syntax check     — N files checked, N errors
[PASS/FAIL] Build                 — build.sh exit code
[PASS/FAIL] Unit tests            — N passed, N failed
[PASS/FAIL] CI parity             — N steps, N failed
[PASS/FAIL] Version consistency   — version.txt=X, mfile=Y, yaml=Z
[PASS/FAIL] Git status            — N staged, N unstaged, N untracked
[PASS/FAIL] CHANGELOG updated     — [yes/no]
[INFO]      TODO/FIXME count      — N items

VERDICT: READY FOR COMMIT / ISSUES FOUND
```