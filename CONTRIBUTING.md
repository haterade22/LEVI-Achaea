# Contributing to LEVI-Achaea

For the full technical reference (build system, architecture, GMCP patterns, class mechanics) see [CLAUDE.md](CLAUDE.md).

## Quick-start

```bash
# Full build (convert src_new → Muddler → .mpackage)
./build.sh

# Tests only
lua5.1 src_new/tests/test_runner.lua

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
lua5.1 src_new/tests/test_runner.lua
```

Write tests for new logic where feasible. At minimum, new public functions should have a happy-path test. `mock_mudlet.lua` stubs the Mudlet API so tests run outside the client.

## Commit messages

No strict format required. Be descriptive about *why*, not just *what*:

```
Fix duplicate ataxia_promptAffs() definition in 005_Prompt_Affs.lua

The extract/convert pipeline duplicated the YAML header and function body,
causing the second definition to silently shadow the first.
```

## CI

GitHub Actions (`.github/workflows/build.yml`) runs on every push and PR:

1. Lua syntax check (all `src_new/**/*.lua`)
2. Version consistency check (version.txt / mfile / _groups.yaml)
3. Unit tests (`lua5.1 src_new/tests/test_runner.lua`)
4. YAML validation

Tagged pushes (`v*`) additionally build the `.mpackage` and create a GitHub Release.
