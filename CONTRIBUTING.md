# Contributing to LEVI-Achaea

For the full technical reference (build system, architecture, GMCP patterns, class mechanics) see [CLAUDE.md](CLAUDE.md).

## Quick-start

```bash
# Full build (convert src_new → Muddler → .mpackage)
./build.sh

# Every check that CI's validate job runs (PASS / FAIL / NOT RUN for each step)
python -B tools/ci_local.py

# The Lua suite only, or one file (lupa embeds Lua 5.1; a bare `lua` is often 5.4)
python tools/run_lua_tests.py [src_new/tests/test_x.lua]

# Convert only (skip Muddler / Java)
./build.sh --convert-only
```

VS Code: `Ctrl+Shift+B` runs the default build task. See [.vscode/tasks.json](.vscode/tasks.json) for all tasks.

## Branching & releasing

| Action | Convention |
|--------|-----------|
| Feature / fix | Work directly on `main` (solo project) |
| Release | Bump version → build → commit → `git tag v4.x.y` → push tag |
| Version bump | `/version-bump <version>` in Claude Code, or edit the 3 files manually (see below) |

## Version tracking

Version lives in **3 places** that must always match:

| File | Format |
|------|--------|
| `version.txt` | `4.7.22` |
| `muddler_project/mfile` | `"version": "4.7.22"` |
| `src_new/scripts/_groups.yaml` init script | `ataxiaVersion = "4.7.22"` |

CI will fail if they diverge. Use the `/version-bump` Claude Code skill to update all three atomically.

## Naming conventions

See [CLAUDE.md § Naming Conventions](CLAUDE.md#naming-conventions) for the full standard. Short version:

- **Public functions** — `ataxia_snake_case()`, `ataxiaBasher_snake_case()`, `ataxiaNDB_snake_case()`
- **Module-internal helpers** — declare `local`, no prefix
- **New code** follows the standard; legacy code is migrated gradually when a file is touched

## Code style

- Indent: 2 spaces (tabs in older files — match the file you're in)
- Line length: 120 columns (`stylua.toml`)
- Formatter: [StyLua](https://github.com/JohnnyMorganz/StyLua) — `stylua src_new/`
- Linter: [luacheck](https://github.com/mpeterv/luacheck) — `luacheck src_new/`

## Tests

Test files live in `src_new/tests/` and are named `test_*.lua`. The runner discovers them automatically.

```bash
python tools/run_lua_tests.py                              # the whole suite
python tools/run_lua_tests.py src_new/tests/test_x.lua     # one file
```

Use a Python that has `lupa` (`pip install lupa`). The runner exits 0 when all tests pass, 1 when a
test fails, and 2 (NOT RUN) when it has no `lupa` or finds no test file. It runs the same way on
Windows, Linux and macOS (where the `lupa` wheel has no `io.popen`, `tools/run_lua_tests.py` supplies one).

Write tests for new logic where feasible. At minimum, new public functions should have a happy-path test. `mock_mudlet.lua` stubs the Mudlet API so tests run outside the client.

Conventions the suite relies on (each learned from a real bug):

- **All test files share ONE Lua state**, and discovery order differs between Windows and CI.
  Restore every global you replace (`send`, `tempTimer`, `getEpoch`, `ataxiaEcho`, module stubs),
  ideally under `pcall` so a failing assertion cannot skip the restore. Do not depend on a flag an
  earlier file left set -- one row-latch test passed only because an earlier test left
  `inMnemosyne` true.
- **Break-back every fix**: revert it alone and confirm a test fails. A test that still passes
  against the reverted code defends nothing (sorted-pair assertions and hand-copied logic both
  survived mutation runs here).
- **Test a trigger's PATTERN, never the file text.** A text search matched the trigger's own comment
  after its pattern had been fixed. `tests/trigger_lib.lua` reads a trigger's patterns, wraps a line
  the way the server does, and evaluates each pattern per physical row (`tests/test_trigger_wrap.lua`).
- **Long game lines wrap server-side** (the author's width: 119-124 columns). Match an EARLY phrase
  of any line near or over ~110 characters; a paste in chat arrives unwrapped and is not evidence of
  length.
- **Run the real code**: dofile the real module or trigger rather than re-implementing its logic in
  the test.

## Commit messages

No strict format required. Be descriptive about *why*, not just *what*:

```
Fix duplicate ataxia_promptAffs() definition in 005_Prompt_Affs.lua

The extract/convert pipeline duplicated the YAML header and function body,
causing the second definition to silently shadow the first.
```

## CI

GitHub Actions (`.github/workflows/build.yml`) runs the `validate` job on every push to `main`, every
`v*` tag and every pull request. `main` takes direct pushes, so CI runs AFTER the push: run the same
steps before it.

```bash
python -B tools/ci_local.py          # every validate step; push only on "Ready to push: YES"
python -B tools/ci_local.py --quick  # the fast steps
python -B tools/ci_local.py --list   # each step and what it proves
```

The step list is `tools/ci_steps.json`. It is the only list: `tools/test_ci_local.py` (a CI step itself)
fails when a step of the `validate` job has no row there or a row has no step, and when a
`tools/test_*.py`, a `tools/check_*.py` or a tool with `--check` is neither a step nor listed under
`not_in_ci` with its reason.

`Ready to push: YES` needs a full run, every step PASS, and a working tree equal to `HEAD`: the run
tests the files on disk, and a push carries only what is committed. The run does not cover Linux
path behaviour, CI's own Python and Lua binaries, the live game, or the CI run on `main` itself.

### Adding a gate

- **Three results, by exit status.** 0 = pass, 1 = a finding, 2 = NOT RUN (the gate could not run or
  had nothing to check). NOT RUN is never a pass. Empty input is NOT RUN: a walk that finds no file
  must not print OK.
- **Report-only first.** Land a new check behind a `STRICT_*` flag, as `tools/check_orphans.py` did,
  and make it strict when its report is clean. A gate with false positives gets switched off.
- **Prove it where it runs.** A gate is done when it has refused one real bad input: break the thing it
  guards, see the gate fail, restore it. Try the states it will meet: a run from the wrong folder, a
  worktree, a missing tool, a wrong interpreter.
- **Wire it.** Add the tool to `build.yml` and to `tools/ci_steps.json` in the same change. A check
  that nothing runs prevents nothing.

`tools/kb_affliction_db.py` is not in CI and has no `--check`: every run rewrites `kb/afflictions/database.md` and `afflictions.json`.

Tagged pushes (`v*`) additionally build the `.mpackage` and create a GitHub Release.
