# LEVI-Achaea Combat System - AI Assistant Guide

## Project Overview

This repository contains the **"For Levi" Mudlet package**, a comprehensive combat and automation system for Achaea (an Iron Realms Entertainment MUD). The system is built in Lua for the Mudlet client and handles complex combat mechanics including affliction tracking, intelligent curing, combat offense, and defensive automation.

**Current Systems**:
- **Mudlet Mapper (mmp)** - Advanced pathfinding and navigation
- **Ataxia Combat System** - Affliction tracking, defense management, combat automation
- **ataxiaNDB** - Player database with API integration
- **ataxiagui** - Custom GUI with Geyser

**Reference System**: Orion (community combat system)

---

## Documentation-First Knowledge Base (MANDATORY)

**Goal: build a world-class, code-accurate knowledge base on Achaea and everything in it.** The docs are a first-class deliverable, not an afterthought — they must stay in lock-step with the code.

**On completing ANY task** (a feature, a fix, a research finding, a confirmed game mechanic), before considering it done, update every piece of documentation it touches:

- **Class docs** (`.claude/classes/<class>.md`) — kill routes, ability lists, cast syntax, cooldowns, bashing/basher rotations, and anything newly confirmed from AB screenshots or combat logs. If a section is a stub or is now wrong, rewrite it.
- **Cross-cutting conventions** (`this file` + `.claude/AGENTS.md`) — new patterns, invariants, pitfalls, or architectural rules that apply beyond one class (e.g. reload-safety inits, the battlerage double-call trap).
- **Memory files** (`memory/<system>.md` + `memory/MEMORY.md` index) — durable per-system knowledge and hard-won lessons.
- **CHANGELOG.md** — every shipped version.

**Rules of the knowledge base:**
1. **Code-accurate over aspirational** — document what the code actually does *now*, with `file:line` anchors. If you can't verify it against the code or a game log, mark it as unconfirmed.
2. **Capture the "why"** — game mechanics learned from AB/logs, and the reasoning behind non-obvious code, are the highest-value entries. A future reader must not have to re-derive them.
3. **No orphaned knowledge** — if you learned something this session (a fire-line, a cooldown, a boon effect, a crash class), it goes into the right doc before the task is closed.
4. **Prune what's wrong** — delete or correct stale/incorrect docs rather than leaving them to mislead.

Treat "the tests pass and it builds" as *necessary but not sufficient*. A task is complete only when the knowledge base reflects it.

---

## Technical Context

### What is Achaea?
- Text-based multiplayer game with real-time combat
- Complex affliction system (30+ different afflictions per class)
- Class-based combat with unique abilities per class (26 classes)
- Each class has at most 3 class skills; each skill has many abilities
- Requires sub-second reaction times
- Combat involves illusions that can fake afflictions
- Multiple balance types (balance, equilibrium, class-specific)
- Server-side curing (SSC) exists but custom systems provide competitive advantages

### Mudlet Platform
- Lua 5.1 based MUD client with event system
- **Triggers**: Fire on incoming game text (regex/substring/exact match)
- **Aliases**: User command shortcuts
- **Timers**: Delayed action execution
- **Scripts**: Lua code modules
- **Event system**: Named/anonymous event handlers for inter-module communication
- **GMCP**: JSON-based game data feed (Game.Core.MCP)
- **GUI components**: Gauges, labels, miniconsoles for displays

### Mudlet Package Structure (XML Format)
```xml
<MudletPackage>
  <TriggerPackage>      <!-- Trigger groups and individual triggers -->
  <TimerPackage>        <!-- Timer definitions -->
  <AliasPackage>        <!-- Command aliases -->
  <ScriptPackage>       <!-- Lua script modules -->
  <ActionPackage>       <!-- Buttons/UI actions -->
  <KeyPackage>          <!-- Keybindings -->
</MudletPackage>
```

---

## Repository Structure

```
LEVI-Achaea/
├── .claude/
│   ├── AGENTS.md              # Agent instructions for AI development
│   ├── classes/               # 26 class files + lock_types.md
│   ├── agents/                # Custom Claude Code subagents
│   │   ├── offense-system.md  # Class offense development agent
│   │   ├── build-and-version.md # Build + version management agent
│   │   └── team-class-offense.md # Parallel team development agent
│   ├── skills/                # Claude Code skills (slash commands)
│   │   ├── build/SKILL.md     # /build — full build pipeline
│   │   └── version-bump/SKILL.md # /version-bump — sync 3 version files
│   └── settings.local.json   # Project permissions + hooks
├── .github/
│   └── workflows/build.yml   # CI/CD: syntax check, version check, tests, release builds
├── .vscode/
│   ├── settings.json          # Lua 5.1 config, Mudlet globals, diagnostics
│   ├── extensions.json        # Recommended: sumneko.lua + mudlet-scripts-sdk
│   └── tasks.json             # Build, convert, test, clean tasks (Ctrl+Shift+B)
├── docs/
│   ├── plans/                 # Project plans and reviews
│   ├── legend-deck.md         # Legend Deck card reference
│   └── artefacts-reference.md
├── src_new/                   # Canonical source (YAML-header Lua files)
│   ├── aliases/               # Alias definitions
│   ├── keys/                  # Key bindings
│   ├── scripts/               # Lua script modules (combat, basher, GUI, NDB, etc.)
│   ├── timers/                # Timer definitions
│   ├── triggers/              # Trigger definitions
│   └── tests/                 # Unit tests (not included in Muddler build)
│       ├── mock_mudlet.lua    # Mudlet API mock (200+ function stubs)
│       ├── test_runner.lua    # Minimal test framework (describe/it/expect)
│       └── test_*.lua         # Test files
├── muddler_project/           # Muddler build project for Levi_Ataxia
│   └── mfile                  # Package metadata JSON (version must match version.txt)
├── tools/
│   ├── convert_to_muddler.py  # Convert src_new → muddler project (multi-package)
│   ├── compare_builds.py      # Compare old XML vs Muddler output
│   ├── mudlet_extract.py      # Extract XML package to src_new
│   ├── flatten_groups.py      # Flatten intermediate wrapper groups in _groups.yaml
│   └── legacy/                # Retired build tools
├── build.sh                   # Build script: ./build.sh [--dry-run] [--convert-only]
├── .gitignore                 # Excludes build artifacts, IDE state, caches
├── .gitattributes             # Enforces LF line endings, marks binaries
├── .editorconfig              # 2-space indent, UTF-8, LF for Lua/YAML/JSON/MD
├── .luacheckrc                # Lua 5.1 linter config with Mudlet globals
├── stylua.toml                # Lua formatter config (2-space, 120 col, Unix)
├── .claudeignore              # Excludes build output from Claude context
├── .mcp.json                  # Serena MCP server config
├── version.txt                # Package version (fetched by auto-updater)
├── CLAUDE.md                  # This file
├── GETTING_STARTED.md         # Setup and usage guide
├── README.md                  # Project overview
└── CHANGELOG.md               # Version history
```

**Note**: Build artifacts (`muddler_project/build/`, `muddler_project/src/`, `levi_test_project/`, `packages/`, `.vs/`) are gitignored and not tracked.

### Build System (Muddler)

The project uses [Muddler](https://github.com/demonnic/muddler) to build Mudlet packages.

**Quick build** (recommended):
```bash
./build.sh                 # Full convert + Muddler build
./build.sh --convert-only  # Convert only, skip Muddler
./build.sh --dry-run       # Preview without writing
```

**VS Code**: Press `Ctrl+Shift+B` to run the default build task. See `.vscode/tasks.json` for all tasks.

**Claude Code**: Use `/build` skill or invoke the `build-and-version` subagent.

**CI/CD**: GitHub Actions (`.github/workflows/build.yml`) runs Lua syntax checks, **an orphaned-call check**, version consistency checks, unit tests, and YAML validation on every push. Tagged releases (`v*`) trigger a full build and upload to GitHub Releases.

**`tools/check_orphans.py` — a script switched off must take its callers with it (v4.7.261).**
`isActive: 'no'` on a script does NOT disable the triggers that call into it. They stay live, call
a nil global, and throw once per matching line — and where the pattern is `^.*$`, that is *every
line of game output*. **108 such call sites existed across four superseded scripts** (the old SLC,
the pre-V3 affliction core, a retired Shaman `ATTACK`), producing dozens of errors a second in the
user's client. Every gate in the pipeline was blind to it by construction: the syntax check passes
(the code is valid, the callee merely does not exist), the tests never load triggers, and the build
succeeds because a disabled script still ships. The only symptom was an error window nobody reads.

The fix has **two shapes, and choosing between them is the point** — a trigger that does *nothing
but* call dead code is disabled to match its script; a trigger that does live work and merely
contains one dead call has that **call guarded** (`if NAME then NAME(...) end`, the idiom those
files already use for their V3 calls), never disabled, or real logic goes with it. 27 of 62 were
the second kind.

**Verify which interpreter before blaming the syntax.** Local `luac` may be 5.4, which rejects
unknown escapes like `[\[`; **Mudlet runs Lua 5.1, which silently maps them to the bare
character**, and CI's own `luac5.1 -p` passes over them. When a tool reports an error the runtime
does not, check the tool's version against the runtime's before acting on it.

**Manual pipeline**:
1. **Edit** source files in `src_new/` (YAML-header Lua format)
2. **Convert** to Muddler format: `python tools/convert_to_muddler.py --src ./src_new --output ./muddler_project`
3. **Build** with Muddler (from `muddler_project/` directory):
   ```bash
   set JAVA_HOME=E:\Java
   cd muddler_project
   E:\muddle-shadow-1.1.0\muddle-shadow-1.1.0\bin\muddle.bat
   ```
4. **Output**: `muddler_project/build/Levi_Ataxia.mpackage` and `.xml`

**Requirements**: Java 8+ (`E:\Java`), Muddler (`E:\muddle-shadow-1.1.0\muddle-shadow-1.1.0\`), Python 3.

**Testing**: Run `lua5.1 src_new/tests/test_runner.lua` or use the "Run Tests" VS Code task. Tests use `mock_mudlet.lua` to stub the Mudlet API.

### Versioning & Auto-Update

**Version is tracked in 3 places** (must stay in sync):

| Location | Format | Purpose |
|----------|--------|---------|
| `version.txt` | Plain text (`4.3.2`) | Remote check — fetched by clients on login |
| `muddler_project/mfile` | JSON (`"version": "4.3.2"`) | Build metadata — muddler reads this |
| `_groups.yaml` init script | Lua (`ataxiaVersion = "4.3.2"`) | Runtime global — compared against remote |

**Version bump workflow** (for every release):
1. Use `/version-bump <new_version>` in Claude Code, OR manually update all 3 files
2. Build with `/build` (or `./build.sh`)
3. Commit all changes (version files + any code changes), tag with `v<new_version>`
4. Push commit and tag: `git push && git push origin v<new_version>` — **push the ONE tag by name; never `git push --tags`** (see below)
5. CI/CD automatically builds and creates a GitHub Release with the `.mpackage`

**IMPORTANT**: When asked to rebuild the package, ALWAYS perform the full release flow: version bump → build → commit → tag → push. Do not just build locally — the user expects the new version to reach GitHub so the auto-updater can pick it up.

**NEVER `git push --tags` (2026-08-03, learned the hard way).** It pushes every local tag the
remote lacks, and this clone carries stale ones. Each stale tag fires the `v*` release workflow,
which builds **that tag's old source** and publishes it as a release. GitHub then picks "Latest"
by **publish time, not semver**, so the last stale release to finish becomes
`/releases/latest` — the exact URL `sysupdate` downloads from
(`releases/latest/download/Levi_Ataxia.mpackage`). Pushing `v4.7.208` this way re-pointed Latest
at a two-week-old `v4.7.46` build while `version.txt` on raw `main` still advertised 4.7.208:
`sysupdate` would have installed the old package and only the `onInstalled` version cross-check
would have caught it. **The version CHECK (raw `main`) and the version DOWNLOAD
(`releases/latest`) read different sources and can disagree.** Repair without losing history:
`gh release edit v<version> --latest`, then `gh release delete <stray> --yes --cleanup-tag=false`.

**Auto-update system** (`ataxia.updater` namespace, `misc_scripts/021_Auto_Update.lua`):
- On `sysLoadEvent` (5s delay): downloads `version.txt` from GitHub raw, compares against `ataxiaVersion`
- If newer: shows notification, prompts user to type `SYSUPDATE`
- `sysupdate` alias: downloads `.mpackage` → `uninstallPackage` → `installPackage` → cleanup
- Uses `sysDownloadDone`/`sysDownloadError` events (same pattern as mudlet-mapper), not `tempTimer`
- **Install triggers a load**: `sysInstallPackage` → `ataxia_updateApplied` → `ataxia_loadSettings()` (when not already loaded), so an install/self-update loads settings immediately — no reconnect required

**Conversion script** (`tools/convert_to_muddler.py`):
- Strips YAML headers from Lua files, outputs pure Lua
- Builds nested JSON hierarchy from `_groups.yaml` files
- Handles name collisions by prepending parent group names
- Preserves group inline scripts
- Converts pattern types, timer formats, key codes
- Rewrites stale file `hierarchy:` headers using per-type dissolved group sets (strips intermediate wrapper names)
- Unwraps root groups in JSON output (emits children directly into array, preventing extra nesting level from Muddler)
- Supports multi-package builds via CLI arguments:
  - `--package-name` — Package identifier (default: `Levi_Ataxia`)
  - `--package-title` — Human-readable title
  - `--package-version` — Version string
  - `--package-author` — Author name
  - `--include-roots` — Root group names to include from `_groups.yaml`
  - `--include-dirs` — Source subdirectory names to scan (default: derived from roots)

**Building a custom package**:
```bash
python tools/convert_to_muddler.py --src ./src_new --output ./my_package_project \
  --package-name My_Package --include-roots My_Package
```

**Comparison tool** (`tools/compare_builds.py`):
- Compares old Python-built XML against Muddler project source
- Verifies item counts, names, hierarchy, and code content

### VS Code (Primary IDE)

Open the `LEVI-Achaea/` folder in VS Code. Recommended extensions are in `.vscode/extensions.json` (sumneko Lua + Mudlet Scripts SDK).

**Build tasks** (`.vscode/tasks.json` — press `Ctrl+Shift+B`):
- **Build Levi_Ataxia** (default) — Full convert + Muddler pipeline
- **Convert Only** — Just the conversion step, no Muddler
- **Convert Dry Run** — Preview without writing
- **Clean Build Output** — Remove `muddler_project/build/`
- **Run Tests** (default test task) — Execute unit tests
- **Build Levi_Test** — Build the test/distribution package

**Hooks** (`.claude/settings.local.json`):

| Hook | Event | Purpose |
|------|-------|---------|
| `session-start.sh` | SessionStart | Prints version, branch, recent commits on startup |
| `lint-before-commit.sh` | PreToolUse (Bash) | Blocks `git commit` if Lua syntax errors exist |
| `block-git-bypass.sh` | PreToolUse (Bash) | Prevents `--no-verify`, `--force`, `--hard` flags |
| `protect-config.sh` | PreToolUse (Edit\|Write) | Blocks edits to `.claude/settings*.json` |
| `pre-compact.sh` | Notification (compact) | Saves working context before compaction |
| `check-changelog.sh` | Stop | Reminds to update CHANGELOG.md if Lua files changed |
| `log-permission-denied.sh` | PermissionDenied | Audit logs blocked tool calls to `.claude/logs/` |
| `set-session-title.sh` | UserPromptSubmit | Auto-sets session title to `LEVI: <branch> (v<version>)` |

**Claude Code skills**:

| Command | Purpose |
|---------|---------|
| `/build` | Run the full build pipeline |
| `/version-bump <version>` | Sync version across all 3 tracked locations |
| `/verify [quick\|full]` | Build + test + version check + git status report |
| `/build-fix` | Fix build/lint errors one at a time, minimal diffs |
| `/deep-review [system]` | Launch 4 parallel agents: Lua quality, combat correctness, triggers, completeness |
| `/codex-verify [system]` | Dispatch independent Codex verification in background |
| `/review-codex` | Auto-detect changes, write Codex prompt, dispatch, verify results |
| `/deslop [path]` | Regression-safe Lua bloat cleanup: deletion-first, tests-first |
| `/scope-check [change]` | Assess whether a proposed change fits current work context |
| `/commit-split` | Group changed files by concern and commit each group atomically |
| `/issue [bug\|feature\|crash] [desc]` | Create GitHub issue with structured sections |
| `/new-adr [name]` | Scaffold a new Architecture Decision Record |
| `/tooling-review` | Review last 2 weeks of Claude Code + VS Code updates for improvements |

Use `/reload-plugins` to pick up new or modified skills without restarting Claude Code.

**Custom subagents** (`.claude/agents/`):
- `offense-system` — Enforces project patterns when creating class offense systems
- `build-and-version` — Handles version bumps and builds with validation
- `team-class-offense` — Team agent for parallel class development

### Visual Studio 2022 (Legacy)

Build tasks are in `.vs/tasks.vs.json` — right-click the root folder in Solution Explorer to run them.

### Source Code Organization

Files are organized in `src_new/` by Mudlet item type (aliases, keys, scripts, timers, triggers). Each `.lua` file has a YAML metadata header and uses numbered prefixes (001_, 002_, etc.) for ordering:
- **scripts/levi_ataxia/levi/ataxia/** - Combat system (afflictions, defense, basher, curing)
- **scripts/levi_ataxia/levi/levi_scripts/** - Class-specific offenses (shikudo, dwc, blademaster, etc.)
- **triggers/levi_ataxia/** - Game text pattern matching
- **aliases/levi_ataxia/** - User command shortcuts
- **timers/levi_ataxia/** - Delayed action definitions
- **keys/levi_ataxia/** - Key bindings

### Combat Systems Index

All combat systems in `src_new/scripts/levi_ataxia/levi/levi_scripts/`:

| System | Files | Status | Kill Route | Location |
|--------|-------|--------|------------|----------|
| **apostate** | 1 (015) | **Documented** | Lock, corrupt, vivisect, sleep, mental | `apostate/` |
| **bard** | 10 | **Documented** | Voyria lock; Composition/Bladedance affliction; PvE footwork bashing | `bard/` |
| **blademaster** | ~10 | **Documented** | Lightning/Ice, Brokenstar | `blademaster/` |
| **depthswalker** | 1 | **Documented** | Shadow/time; PvE = owned battlerage (all 6 abilities denizen-legal) + Terminus word-balance keepers | `depthswalker/` |

**DEPTHSWALKER AEONIC CASH-IN (v4.7.265, NOT boon-gated).** `CHRONO DETERIORATE <t>` (AB 2425,
**300 age**) deals significant magical damage to a MIND-ADDLED denizen -- recklessness, charm,
fear, aeon, amnesia -- and `CHRONO DEGENERATE <t>` (AB 2423, **700 age**) to a PHYSICALLY-PLAGUED
one -- inhibit, weakness, sensitivity, clumsiness. Herald of Infirmity only adds 25% on top, so the
coordination is worth doing without it. **All nine were already modelled** by
`basher/008_Denizen_State.lua` (`ataxiaBasher_BR_AFFS`), and the loop FEEDS ITSELF: DW battlerage
applies two of the five mental triggers (`chrono curse` -> aeon, `intone boinad` -> charm), so the
rotation plants and `ataxiaBasher_dwAeonicCashIn` collects a round later -- the Blademaster
Headstrike shape. **Never boosted** (both ABs say denizens cannot be). **REPLACES the swing**: the
balance type is unstated in both ABs, and if they are balance abilities an appended swing would be
REJECTED after the age was already spent, whereas if they are equilibrium we merely lose one
`shadow reap` -- the recoverable error. Deteriorate is preferred (300 vs 700 age); **amnesia sorts
LAST** because `chrono erasure` consumes weakness/amnesia and the two cash-ins would otherwise
fight over the same affliction. Age-capped on `dwAgeCap` like chrono blur, 4s in-flight hold,
PvE-only (`type(target) == "number"`), `bash dwaeonic off` to disable.
| **dwb** | 1 | Undocumented | Breakpoint/rift | `dwb/` |
| **dwb_runie** | 1 | Undocumented | DWB + runelore | `dwb_runie/` |
| **dwc** | 3 | **Documented** | Vivisect, damage kill | `dwc/` |
| **dwc_runie** | 1 | Undocumented | DWC + runelore | `dwc_runie/` |
| **earth_lord** | 5 | Undocumented | Limb targeting | `earth_lord/` |
| **i_snb** | 1 | Undocumented | Infernal SnB | `i_snb/` |
| **mage** | 4 | **Documented** | Elementalism: salve push, fire burns, water freeze, lock, group, stormhammer | `mage/` |
| **pariah** | 1 | Undocumented | Plague/swarm | `pariah/` |
| **psion** | 1 | **Documented** | Mana kill, deconstruct, flurry burst | `psion/` |
| **s_n_b** | 1 | Undocumented | Sword and Board | `s_n_b/` |
| **serpent** | 1 (002) | **Documented** | Ekanelia lock, darkshade, scytherus | `serpent/` |
| **shaman** | 1 (028) | **Documented** | Tzantza, locks, bleed | `shaman/` |
| **snipe** | 1 | **Documented** | Class-agnostic snipe system | `snipe/` |
| **shikudo** | ~5 | **Documented** | V1/V2/Lock | `shikudo/` |
| **tekura** | ~3 | **Documented** | 6-limb backbreaker (TK6), 3-limb legacy (TKD) | `tekura/` |
| **two_handed** | 1 | Undocumented | 2H knight | `two_handed/` |
| **wildwalker** | 8 | Undocumented | Navigation/utility | `wildwalker/` |

**Project Folders** for undocumented systems: `.claude/projects/<system>/README.md`

---

## Current System Components

### Mudlet Mapper (mmp)
- `mmp.gotoRoom(roomID)` - Navigate to a specific room
- `mmp.gotoArea(areaName)` - Navigate to area entrance
- `mmp.gotoFeature(featureName)` - Navigate to map features
- `mmp.getPath(from, to)` - Calculate and cache paths
- `mmp.fixPath()` - Optimize paths for sprint/dash/gallop
- Fast travel integration (wings, tarot, harness, pebble)
- Balance-aware movement with GMCP integration
- Multi-game support (Achaea, Aetolia, Lusternia, Imperian)

### Ataxia Combat System
- **Affliction Tracking**: 100+ afflictions with color-coded display
- **Target Affliction Tracking**: V3 branching probability engine — single source of truth (see below)
- **Limb Tracking**: `selfLimbDamage` for own limb damage, `lb` for target limb tracking (per-target, event-driven, trigger-fed from actual game damage)
- **Fracture Management**: Two-handed combat tracking
- **Defense Management**: Automatic parrying, SSC integration
- **Basher**: `ataxiaBasher` for automated hunting (see details below)
- **Class Modules**: Serpent, Shaman, Blademaster, Infernal DWC, Apostate, Monk, and 12+ more
- **Shikudo Dispatch System**: Full auto-combat for Monk/Shikudo spec
  - `200_Shikudo.lua` (V1) - Balanced leg prep, both legs 90%+
  - `201_Shikudo_V2.lua` (V2) - Focus fire one leg with SPINKICK kill route
  - `203_Shikudo_Lock.lua` (Lock) - Pure affliction-based locking with Telepathy
  - V1/V2 Commands: `shikudo.dispatch()`, `shikudov2.dispatch()`, `skstatus()`, `skv2status()`
  - Lock Commands: `shikudolock()`, `sklstatus()`, `sklockstatus()`
  - **V2 SPINKICK**: If target is prone + head at level 2 damage → instant MANGLE kill
  - **Kai Surge**: `canKaiSurge()` requires 31 kai, burst ability
  - **Max Kata per Form**: Tykonos/Oak/Willow=12, Rain=24, Gaital=12, Maelstrom=12
  - **Lock Telepathy**: `mindlocked` global tracks if target's mind is connected
- **Infernal DWC Vivisect System**: Full auto-combat for Infernal DWC spec
  - `003_Infernal_DWC_Vivisect.lua` - Undercut + DSL vivisect strategy
  - Commands: `infernalDWCVivisect()`, `infernalDWCStatus()`, `infernalDWCReset()`
  - Phases: DAMAGE KILL (highest) → KILL → EXECUTE → PREP
  - Kill routes: Vivisect (all 4 limbs broken) or Damage Kill (health ≤40%)
  - RIFTLOCK mode: Counter to RESTORE ability (anorexia + slickness + addiction lock)
  - V2-compatible: Uses `infernalDWC.hasAff()` for certainty-based tracking when enabled

### Target Affliction Tracking System (V3 Branching Probability Engine)

V3 is the **single source of truth** for target affliction tracking. It models multiple possible world states simultaneously with probability weights, resolving ambiguous cures via branching and collapsing branches via verification signals.

**Full documentation**: See `memory/affliction-tracking.md` (API, data structure, algorithm, verification signals, performance, commands)

**Quick API reference:**
- `tarAffed(...)` — Add afflictions (sets tAffs + V3 + raises event)
- `erAff(what)` — Remove affliction (clears tAffs + V3 + raises event)
- `haveAff(what)` — Query (routes to V3 at 30% threshold, fallback tAffs during load)
- `getAffProbabilityV3(aff)` — Exact probability 0.0–1.0
- Always use the public API — never call `applyAffV3()`/`removeAffV3()` directly

### ataxiaBasher (Automated Hunting System)

Automated target selection and attack execution for PvE hunting. Supports 20+ classes, manual/areabash modes, integrates with mapper, GMCP, battlerage, and GUI.

**Full documentation**: See `memory/basher.md` and the `.claude/projects/basher/` doc set (dispatch chain, gates, danger levels, flee logic, no-flee areas, own-denizen exclusion, room arrival flow, attack gate affliction checks, PvP auto-flee, stormhammer caching). Ongoing **better-Blademaster-basher overhaul**: Stages 1–2 **DONE** (v4.7.62–65 — per-denizen combat-state + rage-rotation fix so Blademaster owns its battlerage, affliction capture, in-game BR alerts); Stage 4 first-hit auto-parry **DONE** (v4.7.109–111 — cycle prediction, fixed-parry entries, parry-success feed, head default; see the SLC section); only charm-swap targeting (Stage 3) remains. Docs: `.claude/projects/basher/battlerage-pve.md` (Blademaster rotation), line/regex + BR spec in `.claude/projects/basher/denizen-lines-catalog.md`, plan in `~/.claude/plans/i-was-given-this-refactored-sunbeam.md`, and `memory/basher-overhaul.md`.

**Battlerage cooldown feed (v4.7.167):** the game names the ability coming off cooldown -- `You can use <X> again.` and `Your <X> ability could be used again but you lack the necessary Rage.` (the same event through an empty rage bar). `basher/011_Battlerage_Ready_Lines.lua` + trigger 328 clear that verb's stamp in whichever owned rotation holds it (`rwBrAt`/`gdragonBrAt`/`psionBrAt`/`dwBrAt`), release a replay holding the same verb, and route Cullingblade to `ataxiaTemp.bladeCooldown`; unknown verbs are ignored. Together with trigger 329 (the "must wait" rejection) this brackets the true cooldown window from the SERVER instead of the hardcoded `cd` guess -- which was wrong in both directions (too slow when a boon shortens the real cooldown, too fast when a stamped pick never executed).

**One resource spender per assembled round (v4.7.193):** `send("queue addclearfull freestand stand;<a>;<b>;<c>")` is ONE queue entry -- when it fires, every command in the chain executes back to back in the same instant. So a helper gating on "do I have equilibrium / word balance / shin RIGHT NOW?" is answering about a moment before the earlier elements of its own chain ran: both pass their own gate, only the first can pay, and the second is REJECTED after already stamping a cooldown, arming an in-flight replay, arming the global battlerage cooldown, and possibly spending a Rage-Fuelled charge. Three live instances, three classes, shipped weeks apart, each helper correct in isolation: **Blademaster** `shin augment` + `shin thunderstorm` (both eq, both shin -- and the storm's `shin >= 30` gate reads the pool BEFORE the augment spends from it, so 32 shin clears both gates and pays for one), **Depthswalker** `intone <keeper>` + `intone boinad` (one word balance). The fix is to thread a flag from the caller (`shinSpent`, `wordUsed`) -- no current-state read can substitute -- and to **skip the CALL, not the result**, wherever the cooldown stamp lives inside the helper. Corollary: **a helper that STAMPS must refuse on exactly the conditions its caller refuses on** -- `ataxiaBasher_infGravehands` latched `infTyrannyRoom` and was then discarded by the shielded branch dozens of lines away, and because that latch is only overwritten by a DIFFERENT room and never reset, one shielded first contact killed Tyranny in that room for the whole session (its four sibling helpers all self-guarded; the exception is what broke).

**Battlerage replay records store the ROTATION KEY (v4.7.193):** `basher/011` releases a held pick with `pend.verb == field` where `field` is the `BR_READY_MAP` key, so the canonical record is `{ verb = ab.key, cmd = <full command>, at = nowT }`. Psion stored `verb = ab.cmd` (`"weave barbedblade"` vs key `barbedblade`) and was therefore **never** released by a ready line for any of its four abilities; Golden Dragon uses the same shape and is correct only by the coincidence that its commands equal its keys. Also v4.7.193: culling reap has **eight** gates, not the seven v4.7.179 swept -- the eighth is the SHARED branch in `assembleBattlerage` that every class without an owned rotation actually runs, and it was missed because it compares raw rage instead of calling `rageAfford`.

**Clearing the state does not retract the COMMAND (v4.7.197).** When a denizen's shield comes down, setting `ataxiaBasher.shielded = false` only decides what the NEXT rebuild looks like -- the raze already sent is sitting in the SERVER-SIDE queue waiting on balance and will execute into a shield that is gone (a wasted swing, plus 17+ rage for the rage-raze classes). Because the rebuild is PROMPT-driven, that stale raze gets a full balance round to fire. `ataxiaBasher_shieldDropped()` (called from trigger 335, which owns all ~25 shield-down lines) re-sends the round immediately: only another `queue addclearfull` can replace a queued command. It routes through `ataxiaBasher_attack` rather than `assembleAttack` so it inherits the gates -- swarm hold (a pull chain is ONE queue entry that addclearfull would wipe), danger level, player-flee -- is PvE-only, off while paused, and throttled to 1/sec since one shield can match several of 335's patterns in a round. It also kills 336's `removeShield` expiry timer, which 336 overwrites without killing, so a survivor would clear `shielded` during a LATER shield and swing us into a live one. **The general rule: anywhere the basher pre-queues a conditional action (raze, shield-swap, card draw), the condition changing mid-flight needs an explicit re-send, not just a flag write.**

**Control-first denizens (v4.7.198, `bash control`).** Some mobs hit hard enough that a battlerage spent on THEIR balance beats the same rage spent on our damage. `ataxiaBasher.controlMobs` (seeded `manifested nightmare`; seeded ONCE behind `controlMobsSeeded`, because `deepMerge` copies a saved table into the live one and can never delete a key, so a plain default would resurrect a removed entry every load) + `ataxiaBasher_controlFirst()` -- case-insensitive substring on `secondTarget`, numeric-target-gated so it is inert in PvP. It **reorders abilities each class already owns and never adds one**: Blademaster promotes Daze (stun) AND Nerveslash (weakness); Magi Dilation (aeon -- "the mob attacks slower"); Depthswalker Chrono Curse (aeon); Golden Dragon Deaden/Psidaze. **Runewarden has NO denizen-slowing battlerage** (etch CONSUMES aeon/stun; onslaught/collide are damage), so Bulwark's 25% damage negation is flagged as the nearest equivalent -- which also stops the Rage-Fuelled dearest-first rule displacing it with onslaught. Psion and Monk gain nothing. **The flag is `slows`, NOT `control`:** `control` already means "BANK rage until affordable" in `dwBattlerage`/`goldenDragonBattlerage`, and v4.7.145 deliberately removed that from chrono curse after measuring aeon at ~5.6s against a 35s cooldown (~16% uptime) -- reusing the key silently restored a measured-and-rejected behaviour, and the existing Depthswalker test caught it in one run. Composes with Rage-Fuelled: the free charge sorts descending-by-cost, then `slows` floats to the front preserving that order within each group.

**Core Files:** `basher/001_Bashing_Functions.lua` (attack dispatch, danger levels, no-flee + own-denizen helpers; **load-time reload-safety inits** `battleRage_Timers`/`tBals`/`shape` — login-only globals that crashed the always-live path on a SYSUPDATE reload, v4.7.88; per-class battlerage rotations incl. `ataxiaBasher_magiBattlerage` which **owns culling**, and `ataxiaBasher_magiShouldBloodboil` — Magi's Bloodboil eq-slot self-cure: 3+ affs while our tree is down, or the Hot Springs boon heal at HP<60), `basher/002_Class_Bashing.lua` (20+ classes; owns the timer-free battlerage rotations for Runewarden (`RW_BR`, v4.7.163 — Bulwark 28r/45s self-mitigation first and NOT target-gated, Etch 25r/23s gated on the denizen carrying aeon/stun since it consumes one — and it was the ONE ability with no fire line, so its in-flight replay had nothing to release it: after a queued etch fired, the next two rebuilds re-queued it and the server rejected both. Captured live 2026-07-30, trigger 375: "You trace the outline of a rune in the air with <weapon>...". Trigger 329 (the BR-rejection line) now ALSO clears every owned rotation's pending hold — a rejected battlerage did not land, so replaying the held pick is exactly wrong, Onslaught 36r/23s, Collide 14r/16s filler; the real pre-existing faults were that bulwark was hidden behind a 2-target gate and etch was never wired at all -- NOT a missing-fire-line bug: collide/onslaught lines exist at 330:47/331:47 with class-agnostic bodies, corrected v4.7.164), Psion (`PSION_BR`, v4.7.128) and Golden Dragon (`GDRAGON_BR`, v4.7.129 — Deaden/Psidaze denizen aeon/amnesia control-first with rage banking) — the cure for classes whose fire lines are missing from triggers 330-332, where `battleRage_Timers` gating means the rotation never unlocks. Both rotations hold their pick PENDING ~3s and replay it verbatim across the basher's 0.3s addclearfull re-queue loop (stamping per rebuild burned the rotation phantom-style — the bloodboil command-stability rule), and both class functions compute the battlerage LAZILY so shielded/raze branches that send no battlerage can't burn a stamp unsent), `basher/005_Falcon_Cooldowns.lua` (Infernal hyena maul + Runewarden falcon rake cooldowns), `basher/007_Mob_Damage_DB.lua` (damage tracking), `basher/010_Mnemosyne_Legend_Deck.lua` (v4.7.165-167 state-driven card auto-draw, see Key Config), `basher/011_Battlerage_Ready_Lines.lua` (v4.7.167 authoritative per-ability cooldown feed), `basher/008_Denizen_State.lua` (per-denizen combat-state: `ataxiaTemp.denizenState[id]` + `ataxiaBasher_BR_AFFS` affliction model, PvP-inert; read by `ataxiaBasher_blademasterBattlerage` to cash reckless/feared denizens into Headstrike — Stages 1–2 of the overhaul), `genrunning/001-004` (API, targets, enable/disable, main loop)

**Key Config:** `ataxiaBasher.enabled`, `.paused`, `.manual`, `.areabash`, `.targetList[area]`, `.autoLearn`, `.ownDenizens`, `.inMnemosyne`, `.ldeckRules` (mob-name-driven pre-combat draws, `genrunning/002` — useless in Mnemosyne where the roster changes every ripple, hence `.mnemLdeck` below), `.mnemLdeck` (v4.7.165 — `mnem cards`, `basher/010_Mnemosyne_Legend_Deck.lua`: STATE-driven legend-deck auto-draw riding the assembled round. Morimbuul while bound / Maran at `maranAt` 20% hp / Seasone `FOR ELIXIR` at `seasoneAt` 35% / Matic at `maticAt` 3+ denizens, once per room / Covenant (plants recklessness) and Xylthus (plants stun, never on a boss — it cannot bind one) only when `ataxiaBasher_rageAfford` covers the battlerage that actually READS that aff — Blademaster Headstrike + Magi Firefall for recklessness, Runewarden Etch for stun, 25 rage each; any other class draws neither, since planting an aff nothing can spend burns a charge. Economy is the constraint — 2-3 charges regenerating ONE PER HOUR — so: one card per round, a per-card interval >= the effect duration, a hard `ldm.getCharges` check, and a skip when the denizen already carries the aff. Same in-flight replay as the owned rotations (`ataxiaTemp.mnemLdeckPending`, 4s, confirmed by `ldm.onDraw`) because `queue addclearfull` wipes the queued line every prompt. Computed BEFORE the attack gate — Morimbuul answers exactly the bindings that gate closes — and on a gated round goes out alone on the free queue ONCE per pick via `ataxiaBasher_mnemLdeckFree` (`queue add free` ACCUMULATES; an unguarded 0.3s resend would empty the card). The pre-existing global Maran check in `assembleAttack` stands down in Mnemosyne so a 2-charge card isn't double-drawn. **card -> CONFIRMED -> battlerage** (v4.7.166, live-corrected): a card's affliction is recorded on the denizen only in `ataxiaBasher_mnemLdeckConfirm`, so the exploiting battlerage fires on the FOLLOWING round — stamping it at send time was a lie whenever the draw failed, and Etch spent 25 rage on a phantom stun. Confirmation is fed by BOTH the generic charge line ("...may be used N more times...", trigger 001) and `ldm.onDraw`, since the draw-success wording is not uniform. `ldm` charge counts are NOT trustworthy — `initDeck` seeds unseen cards at max, so the game's rejection "A card depicting X currently lacks the power to invoke its stored potential" (trigger `legenddeck_cards/008`) is the ground truth: it zeroes the count, drops the replay and stamps nothing. Cards are also skipped when the payoff battlerage is on cooldown. Xylthus's bind line remains uncaptured, so its stun is recorded from the draw confirmation), `.goldPack`, `.fleeTimeout` (20s), `.shieldTimers`; battlerage: `.cullingBlade`, `.rageraze`, `.rageConserveThreshold`, `.brAlerts` (BR affliction-capture console alerts, default on), `.rageFloor` (v4.7.141 — `bash floor <n|off>`, clamped 46: spend only the SURPLUS above n so threshold gear like "+23% damage at 40+ battlerage" keeps paying; `ataxiaBasher_rageAfford(rage, cost)` gates every rotation, culling reap exempt; nil = off = pre-floor behaviour), `.rageProbe` (v4.7.141 — `bash probe on|report|bands|dump|at <n>|clear|status`, `basher/009_Rage_Probe.lua`: pairs every NON-CRIT damage line with the rage at that moment, keyed by mob+class, to MEASURE a rage-threshold bonus from live play — report gives hi/lo means + ratio with a +/-4 ambiguity band skipped since vitals are last-prompt data; bands view locates the real breakpoint)

**The danger alarm was structurally unable to fire (rewritten v4.7.243).**
`ataxiaBasher_isDamageRateExtreme` tested `net HP delta over 5s >= maxhp * 0.6`, which failed
three separate ways in the fight that killed us (~2,150 HP/s against an ~18,700 pool): healing
subtracted from its own samples (a prompt that took 2000 and sipped 1500 recorded 500; a
net-positive prompt recorded nothing), the bar was an absolute fraction of a large pool, and it
was only ever evaluated INSIDE `ataxiaBasher_attack` below the holds -- so it fell silent exactly
while an escape was in flight. It is now fed by `bashStats_recordIncoming` (trigger
`351_Health_Lost_By_Type` -- the damage BEFORE any healing) in its own window beside the old
net-delta feed, whichever reports MORE winning so the net feed remains a floor where the game
does not print the type line, divided by the elapsed span **clamped UP to
`ataxiaBasher_dmgMinSpan` (3s)** -- v4.7.243 clamped it DOWN to 1s so a young fight would not
read low, which turned every burst into a false alarm (blows landing together were reported at
several times the sustained rate: a live round of 925+1384 at one instant read 2,309 HP/s and
tripped, where the 3s floor reads 770 HP/s and does not). Sustained damage is untouched because
its samples really do span the window. **Both alarms are throttled** (v4.7.253): `DYING FAST`
sat ABOVE the emergency cooldown so it printed whenever the condition held rather than when we
acted -- dozens of duplicate lines per fight -- and the no-flee `DANGER ... fighting on` echo is
capped at 5s because it is evaluated on the attack path. An alarm nobody can read past is not an
alarm. It judges **time to death** (`hp / incoming-per-second` vs
`ataxiaBasher.dangerTTL`, default 6s), the only figure that means the same thing at every pool
size -- tripping at ~12,000 HP instead of never. Also called from `S.onVitals`, which runs every
prompt and reads none of the holds. **A no-flee area had NO HP branch at all**: `hpp <= fleePct`
lived only in the non-no-flee `else`, so at 5% HP in the tower `dangerLevel()` returned
`"attack"`. It now asks the swarm to leave the ROOM (the AREA is what cannot be fled) and returns
`"wait"` only if it can -- a refusal falls through to shield/attack deliberately. `canShield()` is
dropped from the alarm condition: it returns false whenever a room denizen is on the area target
list, i.e. every real tower fight, which made the branch unreachable; it now gates only the
shielding.

**Safety Features:**
- **Attack gate**: Blocks attacks during disabling afflictions (paralysis, aeon, peace, transfixation, webbed, impaled, constricted, deepsleep, entangled, unconsciousness, snared)
- **No-flee areas** (`ataxiaBasher_isNoFleeArea()`): World Tree + Mnemosyne (`inMnemosyne` flag) never flee — shield on damage spike and keep attacking. **The flag could never self-clear in a real area whose name CONTAINS "Mnemosyne" (v4.7.260)** — which is precisely "Ruins of Seleucar West of River Mnemosyne", the riverbank you wade in from. Trigger 351 matched `^You are in .*Mnemosyne` and 352 (the only clearing path) bailed on `find("Mnemosyne")`, so stepping out of the tower closed all three exits from the flag at once. The collateral was worse than the tower being wrong: `isNoFleeArea()` returned true **everywhere**, so the basher would not flee in the open world; `areaKey()` pinned to `""`, so real denizens were auto-learned into the tower's target list; and `mnem explore on` would happily start a 4×4 sweep in open Achaea. `ataxiaBasher_mnemSurveySaysTower(where)` is now the single owner, matching the full phrase with a **plain** find (an area name is not a Lua pattern). It lives in the script, not the trigger — the first cut of the fix put the check inside trigger 352, where a unit test calling `mnemLeftFor` directly sailed straight past it and a deliberate break went unnoticed. **A guard inside a trigger is a guard the test suite cannot see.**
- **Own denizens** (`ataxiaBasher.ownDenizens` / `bash mine`): pet/ally name keywords excluded from auto-learn and targeting without skipping the room. Matched by case-insensitive SUBSTRING, which cuts both ways: `ataxiaBasher.notOwnDenizens` / `bash notmine` (v4.7.169) exempts a REAL denizen whose name merely contains a pet's word and WINS over the keyword -- "a slope-backed hyena" was shielded by the `hyena` keyword seeded for the Infernal pet. In Mnemosyne the consequence is that the SWEEP WALKS AWAY FROM A LIVE MOB: `_roomHasDenizens`/`_denizenCount` (008_Explorer:97,108) filter own denizens too, so a room holding only the shadowed mob reads as CLEAR and the explorer navigates out, trailing an aggressive denizen (v4.7.169 called this a stall; corrected v4.7.170 -- it is silent, not stuck). Seeded by backfill, since existing saves already carry the bare keyword. The user's five MOUNTS are on the list too (v4.7.174) and are keyed on their FULL descriptive name — `lean grizzly bear`, never `bear` — for exactly the same reason: a bare creature noun would shadow half the bestiary
- **PvP auto-flee**: On `"attacker class detected"` event, disables basher and navigates to Mhaldor (`genrunning/001_Bashing_API.lua`)
- **PvE target switching**: `switchTarget()` skips all PvP state resets when basher is enabled

**Defence tables: three of them, different meanings (v4.7.209).** `ataxiaTables.classDefences` is class MEMBERSHIP (only its keys are read; values are raising commands). `ataxiaTables.defenceWords` is what `ashow defs` DISPLAYS beside a defence, via `ataxia_defenceWord()` -- list a defence here only when its command differs from its name (bard: `acrobatics on`, `blade tune`, `dance harrying`). `ataxiaTables.defences` (inline in `_groups.yaml`) maps client-side name -> **SERVER-SIDE NAME** and is read as `csd, ssd` by `supportedDefence()` -- its values are NOT commands, and changing one to a command breaks every `ataxia.defences[actual]` lookup. Defences are raised by SSC (`curing priority defence <def> 25`), never by sending the ability command, so these tables are membership and documentation. **Before changing any table's values, find who reads them.**

### Bashing DPS & damage-taken tracking (`bashStats`, v4.7.207)

`bashStats_getDPS()` returns **Now** and **Avg**, both reworked because each was misleading. *Avg* was `totalDamage / wall clock since reset` -- idle time (walking, resting, hovering, the boon screen) divided it down, so it measured how long the client had been open rather than how hard we hit; it now divides by `bashStats.combatTime`, which accumulates only gaps between hits shorter than `bashStats_COMBAT_GAP` (10s). *Now* was a SINGLE balance's damage over that balance -- a crit spiked it, a miss zeroed it; it is now a rolling `bashStats_DPS_WINDOW` (10s), reusing the `ataxiaBasher_dmgSamples` shape from the incoming-damage watchdog, and divides by the whole window so it decays to 0 rather than showing the last burst forever. Fed by `bashStats_recordDamage()` from trigger 350.

**Stun** (v4.7.219, `ataxiaBasher_stunStart`/`stunEnd`, triggers 722/723): the dispatch off
`You are no longer stunned.` was never the slow part -- 723 calls `ataxiaBasher_attack()`
directly. Two things around it were. (1) **The re-queue cooldown outlived the stun**:
`ataxiaBasher_atk` (0.3s) is armed by the last dispatch BEFORE the stun latched and its
clearing timer runs through it while `affed("stun")` blocks every `tryAttack`, so nothing
consumes it -- the follow-up prompt dispatch then served out a window armed for an unrelated
reason. Now dropped, timer and all, on the way out. (2) **The flag had one way out and no
failsafe**: two of 722's three patterns are Vertani-specific, so the real setter is the REFUSAL
line ("You are too stunned to be able to do anything"), which fires for ANY stun source because
it only appears when we tried to act -- and exactly one line cleared it. A missed clear latched
the flag TRUE and blocked the basher until the next stun happened to print it: a STALL,
indistinguishable from lag at the keyboard. It now self-expires after
`ataxiaBasher_STUN_FAILSAFE` (5s) and dispatches on the way out. **Not done:** pre-queuing
during the stun would beat the client round-trip, but the refusal line exists and is GAGGED in
`011_GAG2`, so queued commands are attempted and burned mid-stun rather than held -- re-queuing
to compensate would re-run the whole round assembly and spend battlerage/deck/cooldown stamps
on refused rounds. Needs the server's queue-during-stun behaviour confirmed first.

**Damage taken by type**: `Health lost: 1488 (physical cutting).` -> trigger `351_Health_Lost_By_Type` -> `bashStats_recordIncoming()`. Stored in `incomingByType`/`incomingTotal`/`incomingHits`, **deliberately separate from `bashStats.damageByType`, which is our OUTGOING damage**. The type is kept whole (category + subtype are different answers) and case-normalised. `bashStats_topIncoming()` gives type/amount/share and `bashStats_incomingRanked()` gives all of them, biggest first with stable alphabetical tie-breaking. The `tarc` HUD shows **every type** (v4.7.216, user: "expand that all of the way"), rows coloured BY DAMAGE TYPE (`TAKEN_COLOUR`, 18 ordered substring rules) so the table is scanned by colour rather than read. The top-10 cap it replaced was the wrong default: the leaders are unremarkable (a Bard bashing physical denizens takes physical cutting) and the TAIL is where the surprises live -- a 1% type that has no business being there means something is hitting us we did not know was in the room, which `+N more` hid. The list is self-limiting (only types actually dealt to us; Achaea has under twenty). `ataxiaBasher.takenTop` survives as an opt-in cap, 0 = all = default. `bashstats` still prints the full ranking.

### Mob Damage Tracking (`mob_damage_db`)

SQLite database tracking non-critical damage per mob, keyed by class + primary stat + mob name. Crit hits are excluded via a flag set in the crit trigger and checked in the damage trigger.

**Key Files:**
| File | Purpose |
|------|---------|
| `basher/007_Mob_Damage_DB.lua` | DB schema, class-stat mapping, record/query/delete |
| `aliases/.../zdata/003_(ataxiaDmg).lua` | `ataxiadmg` alias |
| `triggers/.../334_Crits.lua` | Sets `bashStats.lastHitWasCrit` flag |
| `triggers/.../350_Damage_Dealt.lua` | Records non-crit hits to DB |
| `windows/001_Limb_Counter_Window.lua` | The `tarc` HUD — redesigned bashing panel (v4.7.90/92/94): target name, colored HP/**MP**/WP/EP (MP added v4.7.177, directly under HP in conventional vitals order; it keeps the same health-style colour ramp rather than a flat mana-blue because running out of mana is a kill condition for us -- Psion excise, the Kai Choke 250-mana floor -- so the useful signal is the warning, not the number), DPS + Session (kills/crits/gold/time) block; renders in Mnemosyne (gated on `ataxiaBasher.enabled`, not a live game target). Mob health bar is anchored at the panel BOTTOM (v4.7.103) and always renders with a numeric target — dim `??` row when no hp reading (denizen-state `hpp` nil/negative AND no live `hpperc`); an always-`??` bar means the server target isn't set. Requires the full chain: IRE.Target module negotiated via `Core.Supports.Add` re-asserted on login/reconnect/reload (`030_GMCP_Consumers`, v4.7.107) + `IRE.Target.Set` GMCP set per basher retarget (`ataxiaBasher_setServerTarget`, v4.7.106) — only then does the server stream `IRE.Target.Info` (`hpperc`) | **Class blocks**: Shaman swiftcurse, Pariah epitaph, and (v4.7.147) **Depthswalker** -- Age (250/400/600 colour thresholds), Word balance ready/spent, and buff chips Blur/Trusad/Tsuura/Mainaas coloured green=up, grey=down, RED=down-while-Flashforward-pays-for-it.

**DB Schema** (`mob_damage_db.hits`): `class`, `stat` (e.g., "str 16"), `mob`, `area`, `min_damage`, `max_damage`, `hit_count`, `when`

**Class-Stat Mapping** (`ataxia.data.classPrimaryStat`): Maps each class to its primary bashing stat (str/dex/int). Multi-stat classes (Monk, Psion, Dragon) use highest priority stat.

**A LIST value means "whichever of these is currently higher" (v4.7.259).** Jester's
GALLOWSHUMOUR (AB 2680) "deals damage based on whichever stat is higher between your intelligence
or strength", so the class has no single primary stat -- the answer depends on the character.
`["jester"] = { "int", "str" }` is resolved against the live character at record time; keying
every Jester hit under `str` made the per-stat comparison meaningless for an int build. The
filter-recognition test (`classPrimaryStat[filter] ~= nil`) is unaffected -- a table value is
non-nil like any other. Also confirmed from that AB: gallowshumour needs **no puppet**, deals
PSYCHIC damage, takes a target, spends 2.10s of balance, and "the closer they are to death, the
sharper your wit cuts" -- increased damage under 50% health and *further* under 25%, so the
existing 50% bop->gallowshumour switch is exactly the documented breakpoint and the second tier
needs no code.

**Commands:**
| Command | Purpose |
|---------|---------|
| `ataxiadmg` | Show all records |
| `ataxiadmg <class>` | Filter by class |
| `ataxiadmg <mob/area>` | Filter by mob name or area |
| `ataxiadmg delete <filter>` | Delete matching records |
| `ataxiadmg reset` | Clear all records |

### GUI System (ataxiagui)

~20 windows using `Adjustable.Container`. Tabbed chat, map, bash stats, afflictions, vital bars, SLC, and more.

**Full documentation**: See `memory/gui-windows.md` (Adjustable.Container patterns, namespace migration status, vital bars, ANSI color handling)

### Gear Audit & BiS Analysis (`gearAudit`)
Automated gear inventory and PvE Best-in-Slot scoring system. Collects all gear via GEAR LIST ALL + GEAR PROBE, then scores items for PvE damage output.

**Key File:** `src_new/scripts/.../gear_system/001_Gear_Audit.lua`
**Alias:** `src_new/aliases/.../gear_system/001_Gear_Audit.lua` (`gearaudit`)

**Commands:**
| Command | Purpose |
|---------|---------|
| `gearaudit` | Start new gear audit (GEAR LIST ALL + GEAR PROBE all items) |
| `gearaudit show` | Display all collected gear |
| `gearaudit detail <id>` | Full details for a gear ID |
| `gearaudit set/slot/effect <filter>` | Filter by set, slot, or effect keyword |
| `gearaudit bis` | PvE Best-in-Slot analysis (all slots, per-set + overall) |
| `gearaudit bis <slot>` | BiS analysis for a specific slot |
| `gearaudit score <id>` | Detailed score breakdown with weights |
| `gearaudit scrap` | Scrap recommendations -- **AUTO-SENDS** `GEAR SCRAP <id> CONFIRM`, one per balance, unprompted |
| `gearaudit scrap <set>` | Scrap recommendations for a specific set |
| `gearaudit save/load` | Manual save/load |

**BiS Scoring Weights** (configurable via `gearAudit.config.bisWeights`):
| Stat | Weight | Priority |
|------|--------|----------|
| Additional Damage % / Bonus Damage % | 10.0 | Highest |
| Celerity | 8.0 | Very High |
| Burst Damage (normalized) | 7.0 | High |
| Ignore Denizen Resistance | 6.0 | High |
| Crit Chance | 5.0 | High |
| Crit Damage | 4.0 | Moderate |
| HP Increase / Battlerage Damage | 3.0 | Moderate |
| HP Regen | 2.5 | Moderate |
| Damage Reduction / Rage Gen / BR Rage Gen / Bleed Damage | 2.0 | Low |
| Resistance | 1.5 | Low |
| WP Regen / Blackout Reduction | 1.0 | Lowest |

Conditional gear (location-locked) discounted 50%; battlerage-conditional 30%.
Burst damage normalized to per-attack value: `effectivePct = burstPct / (cooldown / 3)`.
Scrap threshold: items scoring below 50% of set BiS (`gearAudit.config.scrapThreshold`).

**Display never truncates (v4.7.208).** `display()` auto-sizes ID/Set/Slot to their widest
actual value and gives the remainder of the console to Effects, wrapping long text onto
indented continuation rows -- via `gearAudit.consoleWidth()` (pcall-guarded `getColumnCount`),
`wrapText`, `tableRule`, `tableRow`, configured by `gearAudit.config.display`
(`width` pins it, `maxWidth`/`fallback`/`minEffects`). `displayBis` reuses the same helpers.
**The old 40-char Effects cut was not the real problem** -- `summarizeEffect`'s *fallback*
(`effects[1]:sub(1,30)`) was, because roughly half a real 147-item inventory had **no matching
pattern at all** and was printing raw sentence fragments. `scoreEffect` missed the same
families, so `bis`/`score`/`scrap` valued crit damage, crit chance, rage generation and bonus
denizen damage at zero. Both now cover them; the fallback returns the **full** raw text, which
is what a new pattern gets written from. Every added pattern is **safe-fail** -- a wrong guess
about a sentence's tail simply doesn't match and falls through to that raw text. Order matters
in one place: `generate (%d+)%% less` must be tested before `attacks will generate (%d+)%%`, or
a rage penalty is scored as a bonus.

**`gearaudit scrap` is destructive and unprompted** -- `displayScrap` queues
`GEAR SCRAP <id> CONFIRM` for every recommendation and auto-sends it, one per balance. Any
change to `scoreEffect`/`bisWeights` changes what gets destroyed.

**Persistence:** `gearaudit` file via `table.save/load` with `_ataxia_backup` fallback.

### Armour & Paragon Management (`ataxia.armour`)
Configurable profile system for armour paragon slots, traits, and morphing. Auto-swaps on basher enable/disable.

**Key Files:**
| File | Purpose |
|------|---------|
| `src_new/scripts/.../gear_system/002_Armour_Paragons.lua` | Main system (`ataxia.armour` namespace) |
| `src_new/aliases/.../gear_system/002_Armour_Paragons.lua` | `armour` alias dispatcher |
| `src_new/triggers/.../gear_system/001_Paragon_Inventory.lua` | Auto-detect paragons from `ii paragon` |
| `src_new/triggers/.../gear_system/002_Armour_Probe.lua` | Detect current embrasures from `probe armour` |

**Profile Structure:**
```lua
ataxia.armour.config.profiles["bash"] = {
  slots = {"paragon361796", "paragon343178", "paragon514466"},
  traits = {"quick-witted", "fully fit", "marksman", ...},
  armourType = nil,  -- nil/string/"auto"
}
```

**Auto-swap:** `armour auto on` + `armour bash <profile>` + `armour pvp <profile>` — hooks into `"basher enabled"` / `"basher disabled"` events.

**Morph:** Sends `MORPHARMOUR armour INTO <type>`. Tracks cooldown (10min). `armourType = "auto"` resolves via `gmcp.Char.Status.class` → `classArmourType` lookup. Auto-detects current armour type from class on init if unknown.

**Paragons are NAME-addressable (game change 2026-08-03, v4.7.205).** `INSERT CRUCIOUS INTO FULLPLATE` works without knowing the ID, so a profile slot may hold either a registered id (`paragon514466`) or a bare type keyword (`crucious`). `ataxia.armour.paragonName` resolves in that order -- registered id (proven to exist on this character) -> known type keyword -> raw string -- and `isBorrowedRedundant` inherits it, so name-slotted profiles behave exactly like id-slotted ones. **`armour scan` is now a convenience, not a prerequisite:** Borrowed Power used to be entirely inert on a character that had never scanned, because it could not name a replacement paragon; it now falls back to the type keyword. Not explored: the announcement's example targets the armour ITEM (`INTO FULLPLATE`) with no embrasure number, while the package still sends `insert <ref> into armour embrasure <n>` -- proven to work, and the announcement concerns the identifier rather than the target syntax.

**Paragon Lookup:** `PARAGON_TYPES` table maps 24 paragon type keywords to clean display names with effects. `registerParagon()` resolves raw game names (e.g., "an aeneaous paragon") to display names (e.g., "aeneaous (absorption)"). Stale names re-resolved on load.

**Persistence:** Self-contained `table.save/load` to `getMudletHomeDir()/armourconfig` with `_ataxia_backup` fallback.

**Commands:** `armour`, `armour <name>`, `armour add/remove/set/show/auto/bash/pvp/morph/scan/paragons/types/help`

### Item Catalog (`itemCatalog`)
Catalogs artefacts, talismans, promo items, and special equipment. Cross-references against a knowledge base to identify what each item does. Auto-probes unknowns and flags them for review.

**Key Files:**
| File | Purpose |
|------|---------|
| `src_new/scripts/.../item_catalog/001_Item_Catalog_Init.lua` | Namespace, config, state machine, echo helpers, skip patterns |
| `src_new/scripts/.../item_catalog/002_Item_Catalog_DB.lua` | Knowledge base (200+ artefacts, all talisman sets) |
| `src_new/scripts/.../item_catalog/003_Item_Catalog_Functions.lua` | Scan orchestration, KB matching, display, search, command dispatch |
| `src_new/scripts/.../item_catalog/004_Item_Catalog_Save_Load.lua` | Persistence (save/load/backup) |
| `src_new/aliases/.../item_catalog/001_Item_Catalog.lua` | `catalog` alias dispatcher |

**Namespace:** `itemCatalog` (global). **Alias:** `catalog`.

**Data Structures:**
- `itemCatalog.kb` — Knowledge base keyed by normalized item name (type, category, power, effect, credits, tier)
- `itemCatalog.talismanKB` — Talisman keyword lookup (set, effect)
- `itemCatalog.items` — Discovered items keyed by ID (name, location, source, kbKey, probeText, userNote, etc.)

**Scan Flow:** ARTEFACT LIST → TALISMAN LIST → Auto-probe unknowns (0.7s delay). Uses `tempRegexTrigger` with timer-based end-of-output detection and MORE pagination handling.

**Commands:**
| Command | Purpose |
|---------|---------|
| `catalog scan` | Full scan (ARTEFACT LIST + TALISMAN LIST + auto-probe) |
| `catalog quick` | Quick scan (no probing) |
| `catalog show [artefacts\|talismans\|promo\|unknown]` | Display by type/category |
| `catalog search <keyword>` | Search name, power, effect, set, category |
| `catalog info <id>` | Full item details |
| `catalog note <id> <text>` | Add manual annotation |
| `catalog unknowns` | List unidentified items |
| `catalog save` / `catalog load` | Manual save/load |
| `catalog help` | Command reference |

**Persistence:** `table.save/load` to `getMudletHomeDir()/itemcatalog` with `_ataxia_backup.itemcatalog` fallback. Integrated into `ataxia_saveSettings()`/`ataxia_loadSettings()`.

### Player Database (ataxiaNDB)
- Fetches from Achaea API (`http://api.achaea.com/characters/`)
- Tracks: name, city, house, class, level, XP rank, player kills, mark, army rank, dauntless
- City-based name highlighting with per-city colours
- Enemy and army rank tracking
- Auto-honours hidden-city players (queued with 2s spacing after API batch)
- `an refresh [city]` — bulk `honours` to update mark/army/dauntless (honours-only data)
- Threat queries: `an marks`, `an army`, `an dauntless`, `an threats` (all support optional city filter)
- Player notes: `an noteadd/noteshow/noteremove`

### Setup Wizard (leviSetup)
In-game configuration wizard accessed via `ataxia setup`.

**Key File**: `src_new/scripts/levi_ataxia/levi/ataxia/misc_scripts/020_Setup_Wizard.lua`

**Namespace**: `leviSetup` — all functions under this table, dispatched via `leviSetup.dispatch(cmd, rest)`. Note: the internal Lua namespace was intentionally kept as `leviSetup` (internal only); only the user-facing alias changed from `levi setup` to `ataxia setup`.

**Commands**:
| Command | Purpose |
|---------|---------|
| `ataxia setup` | Main menu |
| `ataxia setup class` | Set/auto-detect class |
| `ataxia setup separator` | Command separator |
| `ataxia setup weapons` | Weapon IDs |
| `ataxia setup basher` | Basher settings (flee, gold pack, shield swap) |
| `ataxia setup sipping` | Health/mana sip thresholds |
| `ataxia setup tracking` | Affliction tracking mode (V1/V2) |
| `ataxia setup combat` | Party relay, auto-loot, gag clot |
| `ataxia setup gui` | Toggle GUI on/off |
| `ataxia setup ndb` | NDB highlight colours |
| `ataxia setup install` | Guided install walkthrough (atinstall/abinstall/aninstall) |
| `ataxia setup status` | One-page settings overview |
| `ataxia setup guide` | Configuration guides (ataxia/basher/ndb) |
| `ataxia setup reporting` | Mnemosyne run tracker (token, auto on/off, test) |

### Mnemosyne Run Tracker (`ataxia.mnemosyne`)

Reports Mnemosyne (tides-of-memory) run progress to an external REST tracker as you play. HTTP POST with the token in the JSON body (no auth header). This is the *telemetry* system — distinct from the in-game Mnemosyne bashing area no-flee rules.

**Full documentation**: See the `.claude/projects/mnemosyne/` doc set (architecture, reporting/endpoints, parsing & triggers, ripple map, commands, local history, auto-explorer) and `memory/mnemosyne.md` (concise index).

**Namespace:** `ataxia.mnemosyne`. **Aliases:** `mnem` (+ `mnemosyne`), plus an intercept of `BOON CLAIM <name>`.

**Key files:** `scripts/.../mnemosyne/001_HTTP_Client.lua` (serial POST queue + error recovery), `002_Reporter_API.lua` (per-endpoint fns + run state), `003_Commands.lua` (`mnem` dispatch), `004_Parsers.lua` (effects/boons parsers, monster buffering), `005_Ripple_Map.lua` + `006_Ripple_Map_Window.lua` (per-ripple room mini-map), `007_History.lua` (local run history + reports), `008_Explorer.lua` (auto-sweep the 4×4), `009_Swarm_Tactics.lua` (multi-mob pull & funnel — see below). Triggers `triggers/.../mnemosyne/001-021` (incl. `006_Go` → `exploreOnGo` + `swarm.onGo`, `013_Boons_List_Row`, boon-flag triggers `014_Aspect_Of_Kkractle`/`015_Hot_Springs`/`018_Hammer_And_Anvil`/`019_Bladed_Reflexes`/`020_Sleuth`/`021_Roll_Hide`, `016_Run_Pause`, `017_Splinterbark`). Aliases `aliases/.../mnemosyne/001-002`.

**Flow:** `GO!` → capture the mob spawn line (the line directly above `GO!`, positional — spawn wording varies per mob) → auto `WADE STATUS` → `/ripple_level`, `/boss` (from the `Objective: defeat <boss>` line), `/effects`; buffered monsters flush after `/ripple_level`. Serial queue enforces ordering (ripple_level first; boons_offered before boons_selected). `_auto()` gates run-start/GO/ripple; `_inRun()` gates monsters/effects/boons/boss/death so generic phrases can't report outside a tracked run. **`/boons_offered` posts IMMEDIATELY** with the offer-screen name+description (v4.7.91) — it is no longer gated behind the slow per-boon `BOON CONTEMPLATE` enrichment chain, which raced the next ripple's captures for the single `_capturing` slot and, on a lost race, stalled and silently dropped the entire boon report (rarity/echoes are still learned locally). The line-capture (`_captureLines`) **force-finishes** a wedged prior capture rather than dropping the new one (v4.7.93). **`/boons_offered` also carries `class` and `race`** (v4.7.220, tracker-side request) -- top-level optional strings on `BoonsOfferedRequest`, NOT members of `BoonInfo` where the names suggest; verified against the live schema at `http://104.128.56.238:8000/openapi.json`, which is how to settle any question about this API's shape rather than inferring from prose. `M._charInfo()` reads `gmcp.Char.Status.class`/`.race` and makes two deliberate calls: **class is normalised** (the basher's `:title():gsub(" Lady",""):gsub(" Lord","")` -- Lord/Lady is a gender suffix on one class and leaving them distinct halves every per-class count) while **race is passed through raw** (no known distortion, and normalising against an unverified vocabulary corrupts data more quietly than leaving it alone); and a missing/empty read **omits the key** rather than sending `"unknown"`, which would become its own cohort in the queries. Both branches of `_reportBoonsOfferedEnriched` route through `reportBoonsOffered`, so the tagging lands on the real path. **Pause/resume (v4.7.88):** `WHISPER … beseech that it grow still` pauses the run without ending it server-side; the next wade **resumes via `/run_exists`** (no new `/run_start`), and `M.run.paused` is cleared unconditionally on a confirmed run-end.

**Commands:** `mnem status|token <t>|on|off|contemplate|debug|quiet [on|off]|test|start|end|check|ripple <n>|boss <name>|monsters <text>|death [killer]|map [on|off|status]|boons|affixes|library|explore [on|off|status]|cards [on|off|maran <hp%>|seasone <hp%>|matic <n>]`. Also `ataxia setup reporting`.

**Persistence:** `ataxia.settings.reporting` (`enabled`, `contemplate`, `token`, `url`, `mapEnabled`, `quiet`) — saved inside the main `ataxia` file / `_ataxia_backup.ataxia`. Run state is in-memory (re-synced via `/run_exists` on load). The **local history** (`ataxia.mnemosyne.history`) is the one thing on its own disk file, `<profile>/mnemosyne_history.lua`.

**Run end:** `/run_end` fires on `"The Mnemosyne releases its hold, weaving N shimmering threads into your possession."` — but only after a **confirmation** (`onRunEndMaybe` waits ~2s for `"You just received message #N from Achaea."`), because that reward line also prints on a mid-run message re-read. The Mnemosyne boon flags (`bardWarmarch` / `bmShatteredStar` / `magiKkractle` / `magiHotSprings` / `mnemHammerAnvil` / `bmBladedReflexes` / `mnemSleuth` / `mnemRollHide` / `mnemReaper` / `mnemBloodscent` / `mnemKaiUnleashed` / `mnemSenselessFlurry` / `psionPanoply` / `dragonMightSycaerunax` / `dragonRampage` / `dwFlashforward` / `infArmyOfDead` / `infDaemonJaws` / `infIndiscriminate` / `infNecroticAura` / `infFuryOfAges` / `mnemWintersHeart` / `mnemResourceful` / `mnemFalconersTactics` / `mnemHomebound` / `mnemHammerAndNail` — Hammer and Anvil is class-agnostic: attacks bypass denizen shields, so `336_Mob_Shielded` skips the raze path AND the shield-swap while it's up; Bladed Reflexes makes the BM basher keep `SHIN AUGMENT <n>` up (spend `ataxiaBasher.bmAugmentAmount`, default 3 — a 1-shin augment dissipates in ~12ms per live log) — 20% DR while the `bodyaugment` defence holds; Sleuth arms the swarm module's fullsense-on-GO recon; Roll Hide arms the swarm panic tumble; Kai Unleashed makes the Shikudo basher PREPEND `KAI CHOKE <target>` to the round's combo in RAIN form when 2+ denizens share the room (the boon bursts magic damage on ALL of them — live captures 8472 → **25560 + 17931** magical (it SCALES, likely with the Reaper stack/coalescence empowerment; one burst killed the primary outright); per AB Kaichoke the ability spends 4s of EQUILIBRIUM — idle during balance combos, so both land — and against a DENIZEN consumes NO kai, only 50 mana, hence a 250-mana floor instead of a kai gate; the 30s cooldown starts from the CONFIRMED burst line "Your surroundings ripple like a lake's surface struck..." via trigger 031 → `ataxiaBasher_kaiUnleashedBurst` into `ataxiaTemp.kaiUnleashedAt`, with a 6s retry guard (`kaiChokePendingAt`) so an eaten choke re-fires instead of locking the burst out; shield-break rounds skip it — `ataxiaBasher_kaiUnleashedChoke`, basher/002); Senseless Flurry (balance 30% faster while the numbness defence is up) makes the Shikudo basher keep `NUMB` up in Rain form (AB Numbness 894: self-only, 3s eq, defers damage −40% into one later blow; defence-gated on GMCP `ataxia.defences.numbness` + 5s attempt-hold, fires even on shielded rounds; ONE eq spender per round — the choke outranks the numb refresh; **CROWD-GATED** (review HIGH): numb pins HP while damage defers, blinding the rate watchdog/danger levels/escape ladder until the lump lands as one −40% blow — so never numb at >= the swarm threshold or while a swarm tactic runs — `ataxiaBasher_senselessFlurryNumb`); Panoply makes the Psion basher swap `weave deathblow` → `weave flurry` (AB Flurry 2704: 2.6s balance; the boon scales its damage 60–200% per strike landed — straight verb swap, cleave keeps shield-break, psi shatter keeps the transcendence slot — `ataxiaBasher_psionBashing`); Might of Sycaerunax (dragon: BLAST +25% damage AND the breath weapon PERSISTS through use — AB Blast: 4s eq, strips shield/lyre, "Requires summoned breath") makes `ataxiaBasher_dragonBashing` drop the `;summon <ele>` from both the blast weave and the shielded reblast while it's up (trigger 035 + claim intercept; breath-down still summons once); Draconic Rampage (dragon: TRAMPLE — AB 1564, room, 2.75s balance — deals a large cutting nuke to ALL denizens on a 40s proc) makes the dragon basher spend the balance swing on `trample` at 2+ denizens (Mnemosyne `_denizenCount`, the Kai Choke gate) whenever the proc is ready — send-side 40s stamp + the v4.7.129 in-flight hold, shield-break rounds skip it, the eq blast weave still rides beside it (`ataxiaBasher_dragonRampagePick`, trigger 036 + claim intercept); Flashforward (Depthswalker: +20% damage while the `chrono blur` defence is up) makes the DW basher keep CHRONO BLUR up as an EQUILIBRIUM rider paid in AGE (not the word balance, so it never competes with nakail/the Terminus buffs) -- defence-gated on GMCP `blur`, 8s attempt-hold, capped by `ataxiaBasher.dwAgeCap` (400) so bashing cannot price out the chrono kit, and it rides shielded rounds too (`ataxiaBasher_dwFlashforward`, trigger 038 + claim intercept); Army of the Dead (Infernal: `summon hands of the grave` also damages every denizen in the room) makes the Infernal basher cast it at 2+ denizens ahead of the swing, on a provisional 20s stamp since the real cooldown is uncaptured (`ataxiaBasher_infGravehands`, trigger 039); Daemon Jaws (hyena maul cooldown -66%) shrinks the maul SAFETY timer 30s -> ~10.2s -- the game already sends its ready-line sooner, but basher/005 previously had NO backstop at all, so a missed line stranded the maul forever (trigger 040); Indiscriminate (ARC becomes denizen-effective) makes **every KNIGHT** basher swing the UNTARGETED room-wide `arc` INSTEAD of its single-target attack at **3+** denizens (`ataxiaBasher_knightArc`, `ataxiaBasher.arcAt`, trigger 041). Arc is **Weaponmastery**, so Infernal, Paladin, Runewarden and Unnamable all have it across all four specs — it shipped Infernal-only in v4.7.145 only because that was the class in the tower when the boon was captured, leaving three knights holding a dead boon (corrected v4.7.244, user-directed). The threshold is 3 rather than 2 because arc spends 4.75s of balance against a ~2s dsl — 2.375 normal swings — so at TWO denizens it lands 2 hits where focused swinging lands ~2.4; three is where it starts paying, and the margin widens per extra mob. The legacy `infArcAt` key is still read as a fallback (neither key is ever written, so the default change needs no migration). Its fire lines are captured (v4.7.245, `highlighting/046`, chartreuse bold): `You swing your weapon in a wide arc to hit everyone within your reach.` and `Your weapon carves through the air with deadly accuracy, slicing open all it touches as its keen edge passes by.` -- **only the FIRST is used as confirmation**, because "its keen edge" is edged-weapon wording a blunt spec will not print, and treating the effect line as proof would warn every blunt knight that arc is broken (rule: when a line names a weapon PROPERTY, assume the other specs word it differently until seen). It feeds a PROOF OF LIFE: arc has no cooldown and no in-flight replay, so nothing knew whether it had ever fired -- three attempts with no fire line warns once, counting ATTEMPTS not calls (a 4s gate collapses each round's 0.3s rebuilds into one, the phantom-stamp trap), and it WARNS rather than disabling. **For Runewarden a Thunderclap BISECT outranks it** — both are crowd-gated BALANCE swaps so only one can land, and bisect buys the same room-wide reach for the price of an ordinary swing. The boon FLAG keeps its legacy `infIndiscriminate` name deliberately: it is reset in three places and a missed rename would leave arc armed outside the tower; Necrotic Aura (attacks inhibit denizen healing while the DEATHAURA defence is up) makes the Infernal basher keep that defence raised — defence-gated, 10s attempt-hold, prefixed to every round incl. shielded (`ataxiaBasher_infDeathaura`, trigger 042), and its proc line records `inhibit` on the denizen (trigger `denizen_attacks_misc_lines/024`, the same state Monk Ripplestrike applies); Fury of Ages (FURY becomes near-permanent: +8 strength and 20% faster balance for 45 of every 60 minutes, but QUADRUPLED endurance) makes the Infernal basher hold `fury on` while EP >= 60% and drop it under 25%, with a 30s floor between toggles since each activation may cost 500 willpower, and a run-end `fury off` so it never drains EP after the boon expires (`ataxiaBasher_infFury`, trigger 043); Winter's Heart (DEEPFREEZE works on denizens and deals cold to ALL of them in the room) casts it at 2+ denizens — class-agnostic on purpose, since the Bracers of Frost grant deepfreeze outside Elementalism, and it is an EQUILIBRIUM cast so it rides FREE beside a balance swing while taking the eq slot for Magi (`ataxiaBasher_winterDeepfreeze`, `deepfreezeAt`, trigger 044); Resourceful (-10% endurance/willpower costs; each denizen kill restores 10% of the CLASS RESOURCE — life essence for Infernal) held together with Army of the Dead makes Tyranny effectively free, so its crowd gate drops to 1 denizen (gravehands in every occupied room) and its essence floor 20% → 10% (trigger 045); Falconer's Tactics (falcon rake cd -66%, the Runewarden twin of Daemon Jaws) shrinks the missed-line safety timer 30s → ~10.2s (trigger 046); Homebound (returning to your raido cures + full-heals, but not in the same location) makes the explorer `sketch raido on ground` in the HOLDING room right before the descent, once per ripple (trigger 047); Hammer and NAIL — **not** Anvil — (attacks splash to a second denizen while a sowulu rune is present) makes the Runewarden basher `sketch sowulu on ground` at 2+ denizens, once per room, on the free queue so it costs no balance (`ataxiaBasher_rwSowulu`, `sowuluAt`, trigger 048). **URUZ** is its non-boon sibling (v4.7.248, user-directed): `sketch uruz on ground` at **3+** denizens (`ataxiaBasher.uruzAt`), once per room, laid FIRST in the round -- ahead of sowulu, the battlerage and the swing. The rune is HP REGEN, corroborated in-tree by the rune identification tables (triggers 738/740, totem/001, "like a lightning bolt"). Three deliberate divergences from sowulu: not boon-gated (base Runelore), **rides a SHIELDED round** (sowulu skips one because splash is pointless while razing -- uruz heals US, so the target's shield is irrelevant, and a crowded room opening on a raze is exactly when we want it down), and its threshold is a DEFAULT not a clamped rule (unlike bisect's floor of 2, there is no count at which regeneration is *wrong*, only counts where it is not worth the prefix); Bloodscent auto-recons every ripple entry ("You sense <mob> (#id) at <room>." per denizen — trigger 028 parses the rows into `swarm.recon` with per-room counts and a crowded-room callout, the parsed format Sleuth's raw capture waited for); Reaper (legendary, +1% damage per denizen kill for the run) is COUNTED — the per-kill tithe line ("You reap a tithe of power from your fallen foe.", trigger 023, its own proof of the boon) increments `ataxiaTemp.reaperKills` (survives SYSUPDATE reload) and echoes the running "+N% damage total") and `mnemRageFuelled` — **Rage-Fuelled** (v4.7.179: "When slaying a denizen, your next battlerage attack will cost no resource") banks ONE free battlerage per kill. It is a STATE, not a timer: `ataxiaTemp.brFreeCharge` is armed by the kill trigger (`340_Slain`, already denizen-gated on a numeric target so it cannot arm off a player kill) and sits until a battlerage actually goes out. The entire payoff routes through **`ataxiaBasher_rageAfford`** — the single gate all **37** rotation affordability checks already use — so one bypass lands the boon on EVERY class at once, and it short-circuits the **rage floor** too (a free ability has no surplus to preserve). **Culling reap needs it explicitly** (`rage >= 36 or ataxiaBasher_brFree()`, 7 sites) because it deliberately bypasses `rageAfford` to stay floor-exempt, and a free AoE execute is the best possible use of a charge. The charge is spent by **`ataxiaBasher_brSent()`**, which consolidated the six scattered `ataxiaTemp.brGlobalReadyAt = ... + 1` assignments — arming the ~1s global cooldown and spending the charge MUST stay in lockstep, and a seventh call site remembering one but forgetting the other would leak a free battlerage silently. Spent on SEND rather than a confirmed fire line because several battlerage abilities have no fire line at all; the error directions are asymmetric (believing it spent costs one missed cast and self-corrects next kill, believing it banked costs a rejected command)) and `mnemStormcleaver` -- **Stormcleaver** (v4.7.246: "Your bisect attack now executes denizens with less than 20% of their maximum health") which switches on a clause bisect ALREADY HAD: AB 3107's "if your target is an ADVENTURER and at 20% of their health or lower ... slain outright" was always present and always worthless in PvE, so `ataxiaBasher_rwBisect` carried a note saying there was no low-hp branch. **The two bisect boons pull OPPOSITE ways and are independent** -- Thunderclap wants 2+ denizens (splash), Stormcleaver wants ONE under the threshold (a kill has nothing to splash) -- so the old `if not mnemThunderclap` head-gate had to go or Stormcleaver would have been silently inert when held alone. The execute is checked BEFORE the crowd gate, is not crowd-gated itself, and outranks Arc (both spend balance; a guaranteed kill beats spread damage, and it denies self-healing denizens the chance to climb back out). `bisectTargetHp()` prefers `gmcp.IRE.Target.Info.hpperc` and falls back to denizen state; **a missing reading means NO execute** -- the opposite default from the legend deck's `targetNearlyDead`, because there a wrong guess withholds a card while here it spends 4s of balance on a finisher that cannot finish. `<=` on `ataxiaBasher.bisectExecuteAt` (20): the boon says "less than 20%" and the AB "at 20% or lower", and since `hpperc` is LAST-PROMPT data on a mob we are hitting, the real figure when the cutting damage lands is already lower -- so the boundary errs safely. Trigger `mnemosyne/062` -- and `mnemThunderclap` -- **Thunderclap** (v4.7.181: "Your bisect ability now strikes a third time, dealing bonus electric damage to all denizens in your location") turns BISECT from a single-target finisher into a ROOM hit, so `ataxiaBasher_rwBisect` (basher/002, `ataxiaBasher.bisectAt` default 2) swings it INSTEAD of the normal attack at 2+ denizens. Crowd-gated because of the AoE, with the balance cost only setting where the crossover falls: over a 4s window combination lands 2 swings on ONE mob while bisect lands 1 empowered strike on the target PLUS electric on EVERY denizen -- twice the balance for room-wide coverage. At 1 denizen there is nothing to splash to (the only case the gate excludes); from 2 upward bisect reaches what combination cannot, widening with each extra mob, and in the tower the objective is CLEARING THE ROOM rather than killing one thing fastest. `ataxiaBasher.bisectAt` tunes it upward only: **2 is a clamped floor, not a default** (user rule) -- at one denizen the third strike has nothing to splash to, so no configuration makes it correct. (The Infernal Arc trade exactly.) It REPLACES the swing (both spend balance) but the free falcon rake still rides. Two AB facts deliberately absent from the logic: the "slain outright at <=20% health" execute is **adventurers only** (no PvE value), and bisect bypasses rebounding/reflections while leaving them intact, so it needs and gives no raze handling -- a denizen shield must still be broken first. **Unmanaged prerequisite (user decision):** bisect needs an edged runeblade with the HUGALAZ rune on the blade; nothing in the package knows hugalaz and the blade-sketch syntax was never captured, so keeping it on the weapon is the user's setup. Fire line captured live: "Lightning follows the path of <weapon> as you sweep it at <target>, a clap of thunder heralding your strike." (highlighting/035, chartreuse bold -- the attack-landing colour)) are cleared only on the confirmed end (and reset on run start). **Boss tactics** live beside the affix safeties in 004_Parsers: `reserveTreeForBoss` (`TREE_RESERVE_BOSSES`, extensible) holds `curing tree off` from a reserve-boss's `Objective:` line; Seasone's phial burst (trigger 032) **BANKS** the tattoo rather than spending it (v4.7.213: burst one is survivable and SSC often wins it, so spending there left nothing for burst two, which killed us) and releases the reserve when armed. Three later corrections, all from death logs: **burst two DISENGAGES** (v4.7.215 — rationing one charge only ever buys one extra burst; `ataxia.mnemosyne.phialDisengage`, default 2, +1 while `mnemFontOfLife` is held since a tattoo that cures two halves what the lock costs); the **FULL lock is a different event** and fires `M._phialLockResponse()` (v4.7.235 — stop swinging via `ataxiaTemp.phialHold`, `touch tree`, `touch shield`, in that order because every attack sends `queue addclearfull` and would throw the rest away; shield skipped while paralysed or already up); and **an affliction we are IMMUNE to counts as present** (v4.7.241 — `Coarse Flesh` grants slickness immunity and `Kevadrin's Patience` impatience, so requiring all four actively-on-us made the response unreachable against the exact fight it was written for) — telemetry-independent like Splinterbark, whose taint always wins (never touch a tainted tree); released on ripple change/run end. `startRun` also self-recovers: its `onError` resets `run.active` if `/run_start` 500s or times out. All events auto-report; manual `mnem` overrides remain.

**Ripple mini-map (`ataxia.mnemosyne.map`, files 005/006):** draggable per-ripple grid widget (`Adjustable.Container`, position auto-persists). Builds a room graph from `gmcp.Room` arrivals in Mnemosyne. **DEAD RECKONING -- THE ROOM ID IS ALSO A LIE (v4.7.250).** User: "the gmcp room id will be changed every time we look because of dementia that we cannot cure". Keying the graph by `gmcp.Room.Info.num` is then broken at the root: every look mints a NEW room record, `MAP.current` changes without us moving (so the explorer's `MAP.current ~= explore.fromRoom` arrival test reads TRUE for a plain `ql` and never FALSE), and exit destination ids never match any key we hold so `relayout` links nothing. Creville's Legacy is INCURABLE, so it cannot be waited out. **Track what dementia cannot touch: our own movement.** Position is dead-reckoned from the directions WE sent (failure has its own lines -- `Room.WrongDir`, the wall line, the ice slip, the move timeout -- so a failed move is known), and the room KEY becomes that position (`dr:2,1`). Deliberately a KEY SWAP, not a parallel map: `MAP.rooms`/`room.edges`/`MAP.path`/`unexploredExits`/the whole sweep treat the key as opaque and keep working unchanged. `MAP.drActive()` (dementia + in tower, `MAP.drForce` for tests), `MAP.drArrive(exits)` (advance + record, the single owner -- it runs from 005's gmcp.Room handler which is registered BEFORE the explorer's, so it still sees `explore.moving`; advancing in both would double-step, advancing only in the explorer would miss the swarm's tumbles and pulls). Exit DIRECTIONS are kept and destination ids discarded (the direction set is the fingerprint, the id is noise); `relayout` parses coordinates back out of the key instead of BFS; `MAP.reset` restarts the reckoning per ripple; `up`/`down` carry no 2-D step so the holding room's descent does not move us on the grid.
**TRACK BY EXITS, AND ARM THE STEP (v4.7.251).** `MAP.drArm(dir)`/`drDisarm()` arm the reckoning
for EXACTLY ONE step when a move is sent, consumed by the first event after it: v4.7.250's "any
room event while moving is the arrival" was the same bug in a new hat, because several room
events land inside one move's window -- so the move ended early AND the reckoning advanced again
each time (live log: `room clear -> moving e` eight times in five seconds). A token that gets
SPENT distinguishes the first event from the rest; a predicate over current state cannot.
`MAP.parseExitsLine`/`onExitsLine` read `You see exits leading north and west.` -- the only
honest exit source under dementia, since gmcp pairs directions with invented DESTINATIONS while
this line carries directions alone. It REPLACES the exit set (a direction that stopped being
reported is one the room does not have; merging is what walks the sweep into a wall), trigger
`mnemosyne/063` is a one-line adapter so the parse stays testable.

**BOTH WORDINGS, AND THE EXITS LINE IS NOT DEMENTIA-ONLY (v4.7.260).** The game prints
`a single exit leading northeast` for one and `exits leading ...` for two or more, and the
plural-only pattern is why a sweep stopped dead in a room whose description plainly listed an
exit. `353_Real_Exits` had captured both since v4.7.75 into `ataxiaTemp.realExits` -- which
**nothing ever read**, and the CHANGELOG entry that added it listed wiring the explorer to it as
the next step. Dead output is indistinguishable from a missing feature. The "gmcp is richer"
reasoning survives as a REPLACE/BACKFILL split: under dead reckoning the ids are inventions so the
text replaces; outside it `relayout` needs the real destinations, so the text only backfills
directions gmcp did not give (stored `0` = exit exists, destination unknown).

**A ROOM NUMBER IS NOT A PLACE (v4.7.260).** The tower draws each ripple's 4x4 from a POOL OF REAL
ROOMS, so the same gmcp id returns on a later level with a different layout and different affixes.
`lavaRooms`, `lavaEdges`, `failed` and the boss-chase counter are all keyed by room number and
were cleared only on a package RELOAD -- so lava learned on one level condemned that id for the
rest of the session (live: `north -> 65420 REFUSED: leads into lava` on an exit never glanced at).
`M.onRippleReset()` now hangs off `MAP.reset()`, which already draws that line.

**A GLANCE PRINTS SOMEONE ELSE'S ROOM (v4.7.262).** `Glancing to the northwest, you see:` is
followed by the NEIGHBOUR's exits line, and 063 has no notion of whose room a line describes -- so
the neighbour's exits were grafted onto ours (observed: 67777 holding four exits where its own
description lists two). Not cosmetic: text exits store as destination `0`, which reads as an
unwalked door, so the sweep would step through a door that does not exist. Trigger
`mnemosyne/071` arms a **one-shot token** (not a time window -- the glanced block prints
immediately, and a token that gets SPENT distinguishes the first line from the rest, the same
reasoning as `MAP.drArm`); both `onExitsLine` and `onNoExits` spend it. This was the missing half
of v4.7.260's ungating: **widening what a parser accepts obliges you to say what it must still
refuse.**

**ZERO IS AN ANSWER (v4.7.263, trigger `mnemosyne/072`).** Nothing parsed
`There are no obvious exits.` -- so an empty `room.exits` meant both "none" and "not told", and
the explorer re-asked forever. `room.exitsTextZero` is deliberately **inert**: it never writes
`room.exits` and no consumer of the exit graph reads it, because **"no OBVIOUS exits" is not "no
exits"** -- the holding room prints that line and still has the `down` the sweep descends by.
Zeroing the table would run `usableUnexplored` -> nil -> `_exploreStop` ->
`raiseEvent("basher disabled")`, i.e. combat off in a no-flee instance while the user reads a
menu. Its only job is to stop the asking, and a told-zero room **holds** (bounded) rather than
stopping, since `_exploreStop` clears `explore.on` and `exploreOnGo` only un-pauses.

**THE EMPTY PUSH IS SILENCE, NOT A DENIAL (v4.7.263).** `MAP.onRoom` rebuilt `room.exits` from the
gmcp table on EVERY push, and 005's handler runs before the explorer's -- so in the tower, where
that table is empty, each push erased whatever the prose had just supplied, **including the push
our own `ql` caused**. That closed the boon-screen loop: ask -> wipe -> find nothing -> ask again,
~15 room descriptions in half a second. The wipe's purpose is retained (a non-empty push replaces
exactly as before, so a direction gmcp stops naming is still dropped and a demented push still
overrides); an empty or absent table now changes nothing. **Capping the asker would have been a
cap on a live engine.**

**`gmcp.Room` IS A PREFIX EVENT (v4.7.263).** `Room.Players`, `Room.AddPlayer`,
`Room.RemovePlayer` and `Room.WrongDir` all raise it, and 005 acted on all of them off a stale
`Room.Info`: another player entering rebuilt our exits, and **`Room.WrongDir` spent
`MAP._drArmed` and credited a dead-reckoning step for a move the server had just REFUSED**. 005
and 008 both register on `gmcp.Room.Info` now, in the same change (008 is where the arrival
decision is made, so 005 declining alone changes nothing); a two-liner stays on the prefix for
`MAP.autoShow()`. **The obvious guard is a trap:** `if not gmcp.Room.Info then return end` (as at
`update_stuff/002_ataxia_Room_Update.lua:39`) tests whether the TABLE EXISTS, not whether THIS
EVENT was an Info -- and the table persists after the first room push, so it is dead code from the
second room onward.

**THE WITNESS, NOT THE INTENT (v4.7.262).** `explore.fromRoom`/`fromDir` record the move we
**ARMED**; nothing on any arrival path corrects them, and `onLava`'s `from ~= cur` guard is not an
adjacency check (every other room on the grid satisfies it). So any unarmed room change -- panic
tumble, drag, forced move, the lava escape itself -- left them naming a room we are not next to,
and the next lava tick condemned an edge out of THAT room permanently. `MAP.onRoom` already
resolved the true traversed direction for every arrival however caused (it survives a tumble
because `MAP._lastMoveDir` comes from `sysDataSendRequest`, which sees `...;tumble ne` as readily
as `...;nw`) and proved adjacency by writing the edge -- it simply never published it. It now
publishes `MAP._lastArrival`, and `M._inbound()` is the single owner of "how did we get here":
prefer the witness, accept the armed pair only where the map corroborates it, and return the
REASON when it cannot.

**THE 4x4 IS EVIDENCE (v4.7.249).** DEMENTIA (Creville's Legacy) hallucinates the room wholesale -- a real Achaea room name, a real room NUMBER, an NPC that is not there and invented exits ("You see exits leading north and west"), all arriving through the SAME gmcp channel the map trusts. `MAP.onRoom` recorded whatever it was handed and `relayout` placed rooms wherever those exits implied, so one demented room stretched the layout across the map. The 4x4 is the one thing dementia cannot fake and it was known ONLY to the renderer (`006`'s `LEVEL = 4`). `MAP.GRID = 4` + `MAP.exitFitsGrid(num, dir)`: an exit whose destination would push the bounding box past 4 cells on either axis cannot be real. It rejects ONLY provable overflow -- unplaced room, unknown room, non-planar `up`/`down` (the holding room's descent) and a still-small box all pass, so it never rejects on ignorance and tightens as the ripple is explored. Consumed by `relayout`'s BFS (a placement that would burst the box is refused, so the room stays unplaced rather than corrupting its neighbours) and by `usableUnexplored` (never spend a move + MOVE_TIMEOUT + retry on an exit the geometry already rules out). `MAP.GRID` is a field, not a literal, so a non-4x4 ripple relaxes it with one assignment. **Coordinates come from `MAP.relayout()`** — on every arrival it rebuilds a bidirectional adjacency from all rooms' known exits (`dir → neighbour-num`, coerced with `tonumber`; gmcp reports them as strings and `0` for unknown dests) and BFS-assigns coordinates from the origin. Re-deriving from the full accumulated graph each step is what makes it robust: a room unplaceable on arrival is placed on a later pass once either side of a link is known (per-arrival placement couldn't bootstrap). Anchored on the origin, falling back to the current room so it's always shown. Walked edges (for click-to-walk `MAP.path` BFS → `queue add free`) are recorded separately. Render (006) draws a **fixed 4×4 grid** (every ripple is a 4×4): visited rooms coloured (current green, un-walked-exit gold `?`, else grey), unvisited positions as dim placeholders. Wipes each ripple and re-seeds the current room from `gmcp.Room.Info` (`onRipple → MAP.onRipple`). Toggle `mnem map on|off` (`ataxia.settings.reporting.mapEnabled`, default on); `mnem map status` prints diagnostics incl. per-exit state. GUI (006) needs Geyser/`main` so it's not unit-tested; the pure graph in 005 is (`test_mnemosyne.lua`).

**Local history (`ataxia.mnemosyne.history`, file 007):** a persisted local mirror of what each run parses — `offers`/`claims`/`affixes` per run plus an all-time `library` of affixes — recorded at the parser hooks (`_recordOffers`/`_recordClaim`/`_recordAffixes`) whenever a tracked run is on. `mnem boons` / `mnem affixes` / `mnem library` review this run's claims, its affixes, and the catalogue; `mnem quiet` silences the auto per-claim/affix echoes (still records). Bootstrapped runs (missed start line) get their own bucket via `onRipple` bumping the counter. Persistence (`table.save`/`load` to `mnemosyne_history.lua`) is guarded so a bare/test env never errors.

**Swarm tactics (`ataxia.mnemosyne.swarm`, file 009, v4.7.111-120):** deep ripples pack 3-4+ ROAMING denizens per room (they move between rooms; cleared rooms can repopulate). The explorer delegates every decidable tick to `swarm.onTick()` (consumed tick = no navigation). At `>= threshold` killable mobs (`mnem swarm assess <n>`, default 3; `mnem swarm deep <r> <n>` depth-scales) with a VALIDATED back-route (planar + adjacency vs the reported-exit graph — never "up" out of the first grid room), the pull fires: a one-shot decorator (`ataxiaTemp.swarmPullDir`, consumed in `ataxiaBasher_assembleAttack`) turns the next attack into `"<attack>;<backdir>"` — swing + step-out as ONE queued line (the manual ragepull shape). Consumption arms `ataxiaTemp.swarmHold` (gates BOTH `ataxiaBasher_attack` — several triggers call it directly — and `ataxiaBasher_tryAttack`; 8s self-clear matched to the pull's tactical timeout + load-time clear — it would otherwise survive SYSUPDATE and silently kill the basher), clears `found_target`, kills `mobshieldtimer`. Funnel: fight followers where we chose the ground; 2s window refreshed by combat (v4.7.157, 4 -> 3 -> 2: chasers arrive quickly, so a longer wait only idles on mobs that were never coming; combat refreshes the window, so a real fight still holds us there); empty window → re-enter and re-assess -- but **only if we are FIT to** (v4.7.242): `S._reenterReady()` requires `recoverAt`% AND affliction-free, the same gate the hover uses, because `_beginReenter` used to decide on one question ("did anything follow?") and **"nothing followed" is not the same fact as "we are ready"** -- a death log has it walking back onto Seasone two seconds after a successful disengage, at 28% HP and still soft-locked. Not ready → enter `recovering` (ground recovery) rather than inventing a second wait. Nothing else caught it because the low-HP ladder runs BEFORE the funnel branch and `_beginEscape` needs a back-route we were already standing in, so it returned false and fell through; `MAX_PULLS=3`/room then fight in place — but **progress REFUNDS the budget** (v4.7.117, Putoran-wildcat log: non-chasing mobs make every cycle a free swing): each pull snapshots count + focused-target hp (`entrySnap`, HUD mob-bar data chain), and a re-entry with fewer denizens or the same target chipped lower resets pulls to 0 — hit-and-run continues until the room is cleared or below threshold; only unproductive cycles (mobs regen while we funnel — "tending his wounds") spend budget. **Tactical moves NEVER write `explore.failed`** (`M._tacticalArm` + `explore.tacticalMove` guards all three condemn paths). Resets: boon screen, `_exploreStop`, `basher disabled`, sysLoad (flight landed on every reset). LIVE branches: indoors icewall+leap (first escape suffix `;point bracers417868 <LONG back>;leap <back>` one queue entry; the wall then STAYS — v4.7.119: re-entry is a single eq-gated `leap <fwd>`, follow-up escapes go leap-only via `S.wallRaised[room]` (a balance-round faster), and the wall is melted via `bracers151113` only when the room empties, on a consumed tick so the explorer's own queued move can't wipe the melt — an intact wall silently fails normal walks and would condemn the backtrack edge), outdoors fly-kite (`land;<attack>;fly` wrap while `swarm.flying`; lands below threshold; FLY-needs-balance degrades to grounded, never wedges), Roll Hide panic-tumble (`swarm.panic`, `panicAt`% default **35** (v4.7.218; the old 40 is migrated ONCE behind a persisted `panicAt35` marker, so `mnem swarm panic 40` stays typeable -- an unconditional rewrite would drag it back every tick) **OR** the absolute floor `panicHp` default 3000 -- whichever is crossed first, v4.7.202, `mnem swarm panichp`; tumbles back into the room we just CLEARED via the validated `S._backDir()` -- the one square known empty, and Roll Hide sheds every pursuer so we arrive alone -- unless that edge carries our own icewall, in which case it falls through to a non-swarm exit; 10s cooldown; lands first mid-kite, free-queued + hold-protected so the next attack's addclearfull can't wipe it — v4.7.112-113). **The tumble then HEALS WHERE IT LANDED (v4.7.218)** rather than dropping to `idle`: it used to hand straight back to the explorer and the 8s `swarmHold` self-cleared, so we navigated back into the room we had just fled at panic HP -- the boon's whole value spent on an immediate return. It now enters `recovering` with `S.recoverGround`, held until `recoverAt`% AND aff-free, then hands back for the next run-in (user: "the denizens wont follow so we can use this to our advantage to heal up and then do hit and run tactics"). A GROUND recovery is not a hover: a denizen arriving ENDS it (standing attack-gated at panic HP while something hits us is worse than fighting it) and it never sends `land`. `_maybePanic` also refuses while `state == "recovering"` -- Roll Hide already shed them, so a repeat tumble only walks us off the sweep. **Forced disengage** (`S.disengage(reason)`, v4.7.215): leave on a TACTICAL judgement, not an HP reading. The ladder below is entirely reactive, which is useless against an enemy whose kill pattern is "apply an unsurvivable lock, then wait" -- by the time HP crosses `escapeAt` we are locked, and a locked character cannot be relied on to execute an escape at all. Drives the same proven ladder and the same recovery gate, so we do not return until the lock is gone. Returns FALSE rather than pretending (disabled / 10s cooldown / no validated route), and a FAILED attempt does not stamp the cooldown -- the caller that read the fight as lethal retries the moment a route exists. First consumer: Seasone's second phial burst. **Low-HP escape ladder** (v4.7.114-115, `swarm.escape` on, `escapeAt` 35%, HP-gated ONLY — a 2-mob chip-down killed below the swarm threshold, and shield-in-place fails with broken arms): outdoors → fly + hover (state `recovering`, attacks hold-gated, 60s cap) landing only FULLY healed (`recoverAt` 95% AND aff-free; kept defences blindness/deafness/curseward/insomnia never hold it); indoors → plain retreat to the cleared room; no route → shield fallback; SLC bothArmsFlee is inert in the tower; **landing SETTLES, never decides** (v4.7.125 live catch: airborne gmcp Char.Items reflects the SKY so denizensHere is empty — the landing tick is consumed and the arrival settle window opened, else the explorer reads a mob-filled ground room as "clear" and walks out on touchdown). Ladder live-validated end-to-end 2026-07-27 (19% → fly → hover-heal to 99% → land → resume; Blazing affix smokes hovering flyers ~511 asphyx/5s but the hover out-heals it). **Live-validated** (2026-07-26): icewall chain drains across balance (point) + eq (leap), ~7s, inside the 8s hold; **denizens WALK THROUGH icewalls without Maklak's Promise** (wall = pacing, not barrier); kite fly line = the ring of flying. **Emergency hardening after the Pinnacle death** (v4.7.116 — 3 angelic razers + a roamed-in inquisitor, ~3k HP/s incoming, razer psychic applies STUPIDITY which EATS queued commands): (1) `S.onVitals` on `gmcp.Char.Vitals` runs the panic/escape gates EVERY prompt (fresh gmcp read, hp<=0 = blackout-unknown, 2s cooldown, acts even mid-pull via `M._disarmMove()` — the tick path is event-starved in a stationary fight and its one look landed on a potash bounce); (2) a lost pull move RESTORES the route anchor from `S.funnelRoom`/`S.fwdShort` and **RETRIES immediately** (v4.7.235, bounded by `S.PULL_RETRIES`, hold re-armed each time — going idle relied on the next tick, and the tick is EVENT-driven, so in a stationary slugfest the gap measured FOURTEEN seconds) (was: `_tacticalArm`'s fromRoom clobber → "no valid pull route" → permanent noTactics latch); (3) `S.flightConfirmed` fed by trigger 022_Flight_Lines — the hover re-sends fly each 2s tick until the up-line confirms (an eaten fly = grounded-but-gated); (4) hovers self-tick from birth. **Wall-leap navigation** (v4.7.119, user-directed): "A wall blocks your way." / "A wall bars your path." during ANY in-flight explorer move → trigger 025 → `M.onWallBlocked()` replaces the walk with `stand;leap <dir>` — never condemns (real exit), shares the ice-slip budget; ALL swarm tactical moves also JUMP (`_tacticalGo` — a plain walk into our own wall livelocked the escape ladder, review CRITICAL). **A TUMBLE IN FLIGHT IS NOT "NOWHERE TO GO"** (v4.7.252): the mid-recovery re-tumble `and`-ed
four conditions into one `dir`, and the fall-through read a falsy `dir` as "we cannot leave" --
so while a tumble was MID-AIR the move lock made it falsy and the recovery was ABANDONED, the
attack hold cleared and the basher released with the escape still resolving (log: tumble at
13.736, "nowhere to go -- handing back" at 14.841, two attack rounds, then the tumble landed).
"Already leaving" means WAIT, "no route" means GIVE UP; the lock now holds the tick and only a
genuine dead end hands back. **MANALEECH must not hold a recovery** (v4.7.252): a real
affliction at PvP priority 13, under the PARKED floor, so `S._afflicted()` was permanently TRUE
while it was up and every hover burned its full 60s cap -- and in the tower it is re-applied
faster than it is cured. Now in `AFF_IGNORE`, and the rule generalises: blindness or a broken
limb is a state WAITING FIXES, a leech is a state waiting PAYS FOR, and only the first belongs
in a gate whose action is "stand still longer". **THE MOVEMENT LOCK** (v4.7.243, user: "If we tumble and then leap or walk in a direction it
cancels the tumble"): a tumble is ~4s between "You begin to tumble agilely to the <dir>." and
"You tumble out of the room.", and anything else we send inside that window cancels it -- and
FIVE of our own paths did. `S.moveLocked()` reads the state that already exists
(`ataxiaTemp.tumbleDir`, armed by `onTumbleStart`, released by `onTumbleDone`), so there is no
second lifecycle. Guarded: `_tacticalGo`, `_beginPull`'s arm-timeout fallback, `_maybePanic`,
`_beginEscape`'s hover, `_beginReenter`'s wall branch, the mid-recovery tumble, and the
explorer's `_exploreMove`/`onIceSlip`/`onWallBlocked`. **`S.onVitals` was the worst**: a Roll
Hide pull tumble leaves `state == "pulling"`, whose only early return is the `recovering` one,
so two seconds into a four-second tumble it fired `cq all` + `_beginEscape`. `_maybeTincture`
is deliberately OUTSIDE the lock -- healing is not movement, and mid-tumble at crash HP is when
it is worth most. **ESCAPE MODE** (v4.7.243, user: "We should've stopped attacking here and put
a priority on leaving the room"): `ataxiaTemp.escapeMode`, the single authoritative "are we
trying to get out?", read by both `ataxiaBasher_attack` and `ataxiaBasher_tryAttack` (which was
also missing `bardComposeHold`/`phialHold` entirely). Armed at `_tacticalGo` -- the choke point
every tactical move passes -- plus the panic tumble, the no-swing pull fallback and
`_onPullSent`; cleared when the room number ACTUALLY CHANGES, on reset, and at
`ESCAPE_MODE_MAX` (12s). **It arms at `_onPullSent`, never `_beginPull`**: a pull's escape RIDES
the next attack (the `swarmPullDir` decorator makes the round `<attack>;<backdir>`), so gating
at arm time starves the swing carrying the step-out. `_beginEscape` clears it again when there
is no route back -- fighting in place is then the best answer and muting the basher would be
lethal. **The ice-slip recovery re-sent the WRONG COMMAND** (v4.7.243): `M.onIceSlip` called
`_exploreMove`, which sends a bare `stand;<dir>` WALK -- discarding the leap/backflip the
retreat was, and a walk into our own icewall silently fails. With `MAX_ICE_SLIPS = 15` that
cost thirteen seconds in the room that killed us. Tactical slips now hand back to
`S.onMoveFailed()` (which re-sends the swarm's own verb, anchor restored, hold re-armed) under
a separate `MAX_TACTICAL_ICE_SLIPS = 3`. **The escape pull HOLDS the attack dispatcher** (v4.7.235): the hover branch always armed the hold, the indoor pull branch did not, so the next attack's `queue addclearfull` — which clears the FULL queue — threw the queued escape away. A Seasone log shows THREE complete attack rounds between the disengage and "pull move lost". General rule: **anything we queue that is not an attack must hold the dispatcher.** **The tumble CHAIN** (v4.7.245): `_roomHasDenizens()` reads `ataxia.denizensHere` (gmcp `Char.Items`), which LAGS the room change -- so the recovery tick firing on arrival reads the PREVIOUS room's company and tumbles again. A live log shows four tumbles in nineteen seconds through rooms whose descriptions named no denizens at all, while the Ablaze affix took ~1,200 per tick: HP 31% -> 14% and stuck, because a recovery that keeps moving never recovers. Same class as v4.7.125 (airborne `Char.Items` reflects the sky) with the sign flipped. `S.ARRIVE_SETTLE` (1.5s from the tumble RESOLVING, stamped in `onTumbleDone`) consumes and re-schedules the tick rather than deciding on stale data, and `S.RECOVER_TUMBLES` (2, per recovery) caps the chain -- Roll Hide sheds pursuers, so a third tumble means our reading of the room is wrong, and every extra hop pays the affix damage again. A future-dated stamp cannot wedge the settle (`since >= 0`): the failure direction that hurts is silently disabling the re-tumble. **"You cease your tumbling." was never wired** (v4.7.245): `misc_alerts/003` printed a banner and `cq all`-ed for years without telling the swarm, so a cancelled tumble sat on `tumbleDir` until the `TUMBLE_CONFIRM` fallback expired -- and v4.7.243 made that state a MOVEMENT LOCK, so those were seconds in which nothing could move. The log measures it at 4.5s at 14% HP in a burning room. `S.onTumbleCanceled()` retries immediately, sharing `_tumbleRetry()` with the timer path; ordered AFTER the trigger's `cq all` so the flush cannot wipe the retry. **A fallback timer is for when the game says NOTHING -- when it names the failure, use it.** **Tumble confirmation** (v4.7.233/234): the "begin to tumble" line is the START of a two-stage action — paralysis or prone between the halves cancels it and killed us once. "You tumble out of the room." is the completion line (`misc_alerts/005`); the room-change fallback waits `S.TUMBLE_CONFIRM` = 5s because a real tumble takes 4.0s and a 2s window would re-send one that was working — *a retry window must outlast the action it guards*. **Vitalising Tincture** (v4.7.241, boon-gated): 33% max health / 20s, fired at `escapeAt` from `onVitals` BEFORE the flee decision; `ataxia.mnemosyne.tinctureCmd` is nil by default because the command is unconfirmed. **Which jump: `S.moveVerb(dir)` (v4.7.217)** -- **`backflip`** for a Bard (faster balance; user, 2026-08-06) and **`leap`** for everyone else. The normal sweep already WALKS (`_exploreMove` sends a bare direction), so there was never balance to save there. LEAP is KEPT wherever a wall is known to stand (`_escapeSuffix` wall-mode both branches, the wall-mode re-entry, the explorer's wall-blocked reflex): those jumps exist to clear our OWN icewall and greaves-LEAP is the ability confirmed to do that in both directions, whereas whether BACKFLIP crosses an icewall is NOT confirmed -- and guessing wrong is not a slow move, it is a silent no-op in the indoor low-HP escape, i.e. the anti-death ladder livelocking at crash HP. `moveVerb` disambiguates from `wallRaised[room]` and falls back to LEAP when the wall state cannot be resolved; the melt is hold-armed, cleared only on the melt-confirm line (trigger 026 → `onWallMelted`), re-sent while unconfirmed, capped at 4 tries; wall memory survives mid-ripple `mnem explore off/on` (wiped only on genuine ripple change) and the panic tumble avoids the walled edge; legacy `766_Wall` manual branches are gated off during explore. **Damage-suppression affixes** (v4.7.186, trigger `mnemosyne/053` -> `M.onDamageNulled`/`M.damageNulled`): the Ongoing-effects block can carry `Null Magic: All magic damage you deal is reduced by 33%.` -- one member of a family whose other affix NAMES are unknown, so the trigger parses the SENTENCE, which always names the type itself. Covers every present and future sibling without a name table that goes stale. Stored on `ataxiaTemp.mnemNulled` (NOT under the saved `ataxia` namespace -- a run-scoped fact must not persist across sessions), cleared on RIPPLE CHANGE as well as run start/end since the effects block is re-read from each ripple's WADE STATUS. First consumer: **`ataxiaBasher_bmInfuse`** -- Shindo INFUSE chooses our damage type, so unlike most affixes this one can be stepped around. `fire`->fire, `void`->MAGIC, `lightning`->ELECTRICITY, `ice`->COLD; note the two that do NOT match their own name, so a Null Magic ripple must move us off VOID rather than some element called magic. Preference `fire`->lightning->ice->void (`ataxiaBasher.bmInfusePrefs`), fire first so a clean ripple behaves exactly as the hardcoded `infuse fire` it replaced; never returns nil, since an empty infuse would break the attack string. **Deluge affix** (v4.7.140, trigger 037 → `onDelugeSeen`, same shape): "All rooms are underwater" makes FLY impossible — `S._canFly()` gates the escape ladder's outdoor fly+hover (falls through to the grounded retreat / shield fallback) and the fly-kite entry, so neither wedges on a silently-rejected queued fly. **Dragged out of the sky** (v4.7.168, trigger `mnemosyne/050` → `S.onDraggedDown`): "A tentacle shoots up from the ground, wraps itself around you, and drags you back to earth." — a DENIZEN can pull us out of the air. Third way flight fails after Deluge and an eaten FLY, and the worst, because it is SILENT to the state machine: the hover keeps `S.flying` optimistically true until a flight line confirms (the guard that exists because stupidity eats queued commands), and after a drag that confirmation never comes — so the hover re-sends `fly` EVERY TICK while the tentacle yanks us back, holding us attack-GATED at crash HP until `RECOVER_MAX` expires. Latches `S.grounded` (honoured by `S._canFly` and hence `S._canHover`), corrects the flight state, and converts an in-progress hover into the grounded retreat. **Per-RIPPLE** — `S.onRipple` clears it. **BOILING LAVA -- the only unconditional "leave now"** (v4.7.254, hardened v4.7.256, trigger `mnemosyne/064` → `M.onLava`/`M.roomLava`): `You splash into boiling lava!` / `You continue to struggle in the boiling grasp of the lava as it eats away at your body.` -- **5,890 UNBLOCKABLE per tick** against a 10,939 pool, i.e. 54% of the pool, two ticks is a death, and unblockable means no shield, barrier or resistance helps. Every other hazard here can be fought through (Ablaze is ~1,200 and only gates the hover), so this is **the exception to the validated-route rule**: the escape ladder refuses unvalidated exits by user decision, but staying costs half the pool per tick, so ANY door beats the floor. Exit order: back the way we came (provably safe -- we just stood there) → any planar exit not into a known lava room → any planar → `down`; holds the attack dispatcher, resets any swarm tactic, re-sends every tick (an eaten move must be retried), and on no known exit sends `ql` and says **MOVE MANUALLY**. Both lines are used: the splash is entry, the struggle is the tick, and the tick fires without an entry line when we were already standing in it. **v4.7.256 was a DEATH**: marking the room caught one code path and three others still led back in -- the sweep BACKTRACK (once the room was walked its exits stopped counting as unexplored, but the unexplored exit BEYOND it made lava the shortest path, and `MAP.path` has no hazard filter), `S._backDir` (the room we came from is normally the safest square) and `S._panicDir`. **Remember the EDGE, not just the room**: room-keyed marking is unusable from the room next door, because `_exitTarget` returns nil when gmcp has not filled a destination id -- exactly the case for an unvisited neighbour. `M.explore.lavaEdges[from][dir]`, recorded at the moment we splash, needs no id from anyone; shared predicates `M.roomIsLava`/`M.edgeIsLava` feed all four consumers. The backtrack checks only the FIRST step (every step is re-decided on arrival, so a route we never enter is one we never traverse), and `_backDir` returning nil drops the ladder to shield-in-place -- bad, not fatal. **"We walked through it" is not the same fact as "it is survivable."** Two guards found while testing: a stale `explore.fromRoom` (current only after a sweep step, not a tumble or chase) would mark an edge out of a non-adjacent room and refuse a good exit forever, so recording requires `from ~= cur`; and both exit scans are SORTED, because an unordered choice makes the log unreadable and made the guards untestable.

**A BOSS THAT RUNS AWAY** (v4.7.255, triggers `mnemosyne/065`+`066`): `Lyaeus, the travelling bard flails in panic.` then `... a satyri bard strolls out to the southeast, ...`. **The two lines name him differently** -- proper name on the panic, generic denizen description on the departure -- so neither suffices alone: the panic says WHO, the departure says WHERE, paired within a 6s window. A boss ripple only ends when the boss dies, so a boss that leaves is not a fight we can decline. `M._chaseRefusal(dir)` is split from the send so every refusal is named and testable (nothing panicked / escaping / recovering / lava / too hurt / budget spent / basher off); **never chase while leaving** -- adding a pursuit to a retreat is how a retreat becomes a death -- and the budget is 4 per ripple since a boss kiting us across the grid is its own hazard. The HP guard is DEFAULTED (35) rather than conditional: a guard that evaporates on a missing config key would chase at crash HP on a fresh profile. Trigger 066 matches the FRAGMENT `out to the <direction>` with directions enumerated, not the whole sentence -- every denizen words its exit differently ("strolls"/"prowls"/"stomps"), and enumerating verbs is how you get a trigger that works for one boss and silently misses the next; safe because it decides nothing alone.

**Burning rooms** (v4.7.167, trigger `mnemosyne/049` → `M.onAblazeBurn`/`M.roomAblaze`): "The area is ablaze!" + "The roaring inferno engulfs you as you fight to find a way out." for ~800 every few seconds, indefinitely. Latched on the BURN LINE not the room description, so it self-expires when we leave (no "fire goes out" line has ever been captured); gates `S._canHover` — flying up to heal is a bad plan over a fire that follows you. The KITE is deliberately not gated: it lands for every swing anyway. General rule: **an optimistic flag cleared only by a CONFIRMATION line becomes a livelock the moment something makes that confirmation impossible** — such a flag needs a third input, the line that says the thing can never happen. **Haemophiliac affix pacing** (v4.7.119-120, trigger 029 → `onHaemophiliacSeen`, Splinterbark's telemetry-independent shape): kills bleed THOUSANDS + mana costs +20% — post-clear navigation holds until the bleed is CLOTTED (`ataxia.vitals.bleed < 50`; SSC `curing clotat 30` does the clotting) AND `hpp >= 90` (`M._haemoHold`, missing reading = 0 so it never wedges). The dmap standalone package mirrors the pull/funnel core (`dmap swarm <n|off>`, default off — no basher there, so the funnel waits on the user/attack-hook). Recon: **Bloodscent** (boon) auto-senses every denizen per ripple entry — trigger 028 parses `You sense <mob> (#id) at <room>.` rows into `swarm.recon` ({name,id,room} + per-room counts + crowded-room callout echo); Sleuth's `mnemSleuth` → fullsense on GO (raw capture; same-shape rows feed the parser); `mnem sense` manual. Tests `test_swarm_tactics.lua`. Full doc: `.claude/projects/mnemosyne/07-explorer.md` swarm section.

**Borrowed Power changes our GEAR (v4.7.204).** "Critical hits reach plane-razing level without requiring paragons or the Psion class -- this does NOT stack." The non-stacking clause makes the crit-TIER paragon (`crucious`) dead weight, so `ataxia.armour.borrowedPower(true)` builds a `borrowed` profile from the bash one with that slot replaced by the shifting-damage or willpower paragon and hands it to the existing `ataxia.armour.swap` (which owns the pry/insert sequencing, morph handling and swap guard). `icosagon` is deliberately kept -- it buys crit CHANCE, which the boon does not grant. **The revert is the risky half:** the boon is per-RUN, so a swap left in place costs the crit paragon everywhere OUTSIDE the tower indefinitely -- reverted on the confirmed run end, with `armour borrowed off` as the manual escape hatch for a run that ends without one. Swapping runs from the `BOON CLAIM` intercept as well as the BOONS row, because claiming happens at the boon screen: out of combat, explorer paused, the only safe moment to pry armour apart. **General rule: a per-run boon that mutates persistent state needs its revert designed before its effect.**

**Bard PERFORMANCE probe (v4.7.204).** Every other thing that tracks the bash performance is REACTIVE -- the fade line, the not-performing error, the already-performing refusal -- and each needs something to go wrong first. `M._bardPerformanceCheck` (explorer 008, both entry points, beside `_wearArmour`) ASKS instead: sends `performance`, stamps `ataxiaTemp.bardPerfProbe`, and trigger 001 clears it on the "shall last another N minutes" reply. Nothing clears it in 2s -> not performing -> recompose. Handles a reply wording we have never captured without inventing one.

**A dance is a STATE, not a rider (Songstep, v4.7.200).** Every other Mnemosyne rider in this package spends EQUILIBRIUM, so it rides free beside the swing and can be re-asserted whenever its defence drops. The Bard's Bladedance dances spend **BALANCE** (AB Hawkstep 3193: 3.00s) and are mutually exclusive ("you can only dance one thing at a time"), so a dance costs the attack and can only be SWITCHED. `ataxiaBasher_bardDance` therefore returns `""` on almost every round -- it fires only when the wanted dance differs from what is up, then holds 8s so an unconfirmed dance cannot cost every balance. On a switching round the dance REPLACES the swing (the battlerage still rides -- rage, not balance). Choice: boss -> **wavedance** (ignore 75% resistance), 2+ denizens or ripple >= `bardHawkstepRipple` (**25** -- the user's number for where the tower's difficulty steps up; an earlier guess of 5 anchored on the boss cadence, which is not the same thing) -> **hawkstep** (25% DR), else **harrying** (+50% damage); boss beats crowd. One knowingly-unverified bit: `hawkstep`/`wavedance` as GMCP defence names are inferred from `harrying`, which IS tracked -- the attempt-hold is what makes that safe to ship, since a wrong name costs one dance per 8s rather than one per round. **Rule for any new ability: check the RESOURCE first -- equilibrium/word/rage ride, balance replaces, and a mutually-exclusive balance ability is a state machine, not a keeper.**

**Bravado REMOVES answers rather than adding a threat (v4.7.206)** -- "perpetually reckless and unable to benefit from shields, prismatic barriers, or blood barriers". Three defensive responses become no-ops while it is up, and each keeps costing us: `touch shield` (the danger-level response AND the escape ladder's fallback), **Maran** (the emergency 5000hp PRISMATIC barrier, charges regenerating ONE PER HOUR -- gated in both the out-of-tower path and the Mnemosyne card layer) and `activate bloodshield` (the cloak's BLOOD barrier, one charge per five kills). All gated on `ataxiaBasher_bravado()`. The shield case is a CORRECTION rather than a saving: the round bought nothing *and* the basher then believed it was mitigated, so `danger == "shield"` now falls through to attacking. Hit-and-run clamps to `swarm.bravadoThreshold` (default 2, user rule), **clamping DOWN only** and covering the deep-ripple threshold too. User's framing, worth keeping: *"we will never know our health pool"* -- with every mitigation off the prompt number is all there is. **General rule: an affix that DISABLES a defence is more dangerous than one that adds damage, because the code keeps paying for the dead defence and keeps believing it worked -- when a new affix names a mechanic, grep every site that spends on it.**

**Pacing affixes (v4.7.196).** Two affixes make the instant a room goes quiet the worst instant to walk, so the auto-explorer carries two post-clear holds, both gated on 90% HP and both re-checking at 1.5s: **Haemophiliac** (`M._haemoHold`, also waits for the bleed to be CLOTTED, since SSC's `curing clotat` is doing real work while we stand still) and **Last Word** -- "Denizens explode on death!" (`M._lastWordHold`, HP only: an explosion is instantaneous, so there is nothing to clot and waiting on a bleed reading would just idle the sweep). Either holding is sufficient. Affix flags are now three (`mnemHaemophiliac`, `mnemDeluge`, `mnemLastWord`) plus the damage-suppression family on `ataxiaTemp.mnemNulled`, so the run-start reset block is **30 boons + 3 affixes = 33 lines** -- never read a boon count off that block. Captured in the same screenshot but deliberately UNHANDLED pending observation: **Necromantic** ("Denizens may revive as mindless thralls" -- potentially significant, since a room that clears then repopulates from its own corpses is exactly what `_roomHasDenizens` is trusted for) and **Iceblood** ("Taking damage causes your blood to freeze").

**Boon re-latch** (v4.7.188, corrected v4.7.192): every boon flag latches from the `BOON CLAIM` alias or a BOONS-list row, so a boon owned BEFORE its handling shipped -- or claimed outside the alias -- stays inert silently. `M._relatchBoons()` sends **`BOON CLAIMED`** once per run to re-latch all 33 at once (**corrected v4.7.203** -- it sent bare `BOONS` from v4.7.188, which is NOT a command: the game answers it with its syntax help, so the re-latch never re-latched anything and printed a syntax block into combat. Three passes touched the function reasoning about WHEN to send and never WHAT, and its test pinned the string `"boons"` without checking it was a real command. Unexplained syntax help in a combat log is always one of our commands being rejected), called from `M.onRipple` (every mode) AND both explorer entry points. Its guard lives on **`ataxiaTemp`**, not `ataxia.mnemosyne`: `ataxia` is serialized wholesale and `deepMerge` lets a disk value win, so a guard stored there would come back TRUE after a reload while the bare-global boon flags came back nil -- defeating the function on exactly the path it exists for. Deliberately NOT latched from boon DESCRIPTIONS (unlike the damage affixes): a boon description also appears on the OFFER screen, listing boons we declined.

**Auto-explorer (`ataxia.mnemosyne.explore`, file 008):** `mnem explore on` auto-sweeps the ripple's 4×4 — it drives the **basher in manual mode** (combat + no-flee, never mapper-moving) and handles *navigation* itself: room clear (`ataxia.denizensHere` empty) → step through a usable unexplored exit or backtrack via `MAP.path` to the nearest room with one, moving with `queue addclear free stand;<dir>` (stands first — you're often prone post-fight). `usableUnexplored` keeps **planar** unwalked exits, plus **only `down`** from a room with no planar exit at all — the entry **holding room's `down`** into the grid. `up`/`in`/`out` are never used (there is no `up` in Mnemosyne), and a 4×4 room's deeper `down` isn't taken. Event-driven (`gmcp.Room` + `"targets updated"` → debounced tick, `moving` guard); it echoes each step (`room clear → moving <dir>`) and once per room `clearing this room (N denizen(s))`. When the grid is fully swept it does **not** stop — on a **boss ripple** (every 5th) the boss spawns at the end in any already-cleared room, so it **patrols** (`_nextPatrolStep`, round-robin re-visit) to find + kill it, capped at `MAX_PATROL_LOOPS` fruitless loops. **Pauses** at the boon screen (`onBoonScreen` — sets `explore.pausedAtBoon`, halts navigation but **keeps the basher on** in explore mode; **auto-resumes on `GO!`** via `exploreOnGo` — a `look` to lock in the holding room's `down` exit, then `_exploreResume()` — or `mnem explore on` manually).

**A PAUSE IS THREE QUESTIONS, NOT ONE (v4.7.263).** `pausedAtBoon` was consulted in **2 of the 8
paths that could still act**, two of which send movement. `M._navRefusal()` (008, reason-string
form like `_stepRefusal`/`_chaseRefusal`) is now the single owner, and every site is classified:
**INITIATION** (sweep, patrol, pull, re-entry, boss chase, map upkeep, wall melt) suspends;
**COMPLETION** (a move in flight landing, failing, slipping, retrying) never does, because
suspending it strands `moving`/`swarmHold`/`S.state`; **SELF-PRESERVATION** (lava, escape ladder,
panic tumble, recovery loop, tincture, disengage) never does. Two traps, both of which this code
fell into: **(1) `S._enabled()` must stay pause-blind** -- it gates `S.onVitals`, `S.disengage`
AND `S.onTick` together, so the obvious one-line fix would kill the escape ladder, the panic
tumble, the tincture and the forced disengage at a stroke (the bug with its sign flipped); the
gate belongs on the *idle assess* inside `onTick`, at its single call site, never inside
`_beginPull`, which stamps. **(2) The old gate was in the wrong PLACE** -- third line of
`_exploreTick`, above the swarm delegation -- and every swarm state machine self-ticks through
`M._scheduleTick`, so pausing froze the recovery loop: the ladder fired ONCE and then disabled
itself (`S.onVitals` returns early while `recovering`, and only the tick can leave that state),
until GO, which needs the user at the keyboard. It now sits BELOW the delegation. The arrival tick
is still re-armed while paused, deliberately -- `_beginEscape`'s indoor branch does not
self-schedule and has no other clock -- while the watchdog, being navigation-only, does not. It **stops** (restoring the saved basher state) on leaving Mnemosyne (strict `ataxiaBasher.inMnemosyne`, still detected during the pause), on `mnem explore off`, or the patrol cap. Safety: start-guard (`area==""`), stall watchdog, basher save/restore, `sysLoadEvent` reset, and **ice handling** — icy rooms print "You slip and fall on the ice as you try to leave" (move fails, but the exit is fine), so trigger `011_Ice_Slip.lua` → `onIceSlip` re-sends the move (no failed-exit charge) until you leave, capped at `MAX_ICE_SLIPS`. **Wears armour before sweeping** (v4.7.175): `M._wearArmour()` fires from BOTH `exploreOn()` and `_exploreResume()` — the latter is the PER-RIPPLE entry (GO calls it after every boon screen), so armour is re-asserted before each dive, not only the first `explore on`. Sent DIRECTLY, not queued, because `queue addclearfull` wipes queued lines; deliberately ungated on a worn-check since there is no reliable worn-state to read and the failure mode of guessing wrong is exactly what it exists to prevent. Pure logic (`_nextExploreStep`/`_roomHasDenizens`) is unit-tested; the timer/event machine is validated in-game.

### Data Persistence & Profile Backup

All system state is saved to disk files in `getMudletHomeDir()` via `table.save()`/`table.load()`. A profile backup system provides redundancy by also storing data in the `_ataxia_backup` global (Mudlet saved variable).

**Save flow**: Every save rotates a `.bak`, writes to disk, AND copies into `_ataxia_backup`. `ataxia` is
passed through `sanitizeForSave()` first — it strips **live GUI/runtime objects** (Geyser windows, Mudlet
`db` proxies) so they never hit disk. Detection is `getmetatable`/`rawget` only — **never index
`.hide`/`.show`** (a `db` proxy's `__index` errors "access sheet 'hide'"). This matters because GUI objects
are — as a known TODO — stored under the saved `ataxia` namespace (`ataxia.mnemosyne.map.window`,
`ataxia.data.hunter.window`, vital bars, chat).

**Transient state must NOT ride the saved namespace (v4.7.192/193/194).** Because the save is
wholesale and `deepMerge` ends in an unconditional `dst[k] = v`, any flag that is *set true on
use and cleared only by a `tempTimer`* comes back from disk stuck ON -- the timer that would
clear it does not survive a relog or SYSUPDATE. The feature is then permanently disabled,
silently. Four were built this way and are now reload-safe TIMESTAMPS on `ataxiaTemp`: the
emergency wand of reflection (`wandReflectAt`, **1 hour** -- at that length an interrupted
cooldown is the normal case), the Maran barrier (`maranAt`, 65s), the vulture talon
(`vultureTalonAt`, 180s) and the darkshade auto-prioritise (`darkshadeTimer` /
`darkshadePrioritized`). A missing stamp reads READY, so the failure direction is one early
re-use rather than a lockout. Never serialize a `tempTimer` **id** either -- after a reload it
names whatever timer inherited that integer, and `killTimer` cancels a stranger's. CONFIG
(thresholds, durations, ids) does belong on `ataxia`; only the transient half moves.

**Load flow** (`ataxia_loadSettings`, on `sysLoadEvent` **and** `sysInstallPackage`): fault-isolated — the
main-settings load and each sub-load (basher/paths/extraction/NDB/SLC/itemCatalog/ldm) are `pcall`-wrapped
so one corrupt file can't strand the rest; `ataxia.loaded` is set only at the end (an interrupted load
retries); and `deepMerge` is **cycle-safe** (`seen` set) and **GUI-safe** (`stripGui(loaded)` recursively
drops serialized GUI snapshots before merge, and it never merges into a live runtime object). Each file
falls back primary → `.bak` → `_ataxia_backup`.

**Disk Files** (all relative to `getMudletHomeDir()`):

| File | Variable | Data | Save Source |
|------|----------|------|-------------|
| `ataxia` | `ataxia` | Main settings, vitals, curing priorities | `001_Save_Load_Settings.lua` |
| `basher` | `ataxiaBasher` | Basher state, targets, shield timers | `001_Save_Load_Settings.lua` |
| `basherpaths` | `ataxiaBasherPaths` | Hunting route paths | `001_Save_Load_Settings.lua` |
| `andb` | `ataxiaNDB` | Player database | `001_Save_Load_Settings.lua` |
| `extractLocations` | `ataxiaExtraction` | Extraction zones | `001_Save_Load_Settings.lua` |
| `slcconfig` | `selfLimbDamage.config` | Self-Limb Tracking config | `001_Save_Load_Settings.lua` |
| `shaman_profile.lua` | `shaman` | Shaman offense config | `shaman_system/002_Save_Load_functions.lua` |
| `legenddeck` | `ldm.deck` | Card charges/timers | `legend_deck/004_Legend_Deck_Save_Load.lua` |
| `legenddeck_config` | `ldm.config/favorites/enabled` | Card config | `legend_deck/004_Legend_Deck_Save_Load.lua` |
| `classDetect_config.lua` | `classDetect.config/curingsetMap` | Class detection settings | `class_detect/001_Class_Detect_Engine.lua` |
| `gearaudit` | `gearAudit.data` | Gear inventory | `gear_system/001_Gear_Audit.lua` |
| `armourconfig` | `ataxia.armour.config` | Armour profiles, paragons, morph state | `gear_system/002_Armour_Paragons.lua` |
| `itemcatalog` | `itemCatalog.items/config` | Cataloged items, user notes, config | `item_catalog/004_Item_Catalog_Save_Load.lua` |
| `ataxia_bars_config.lua` | `ataxia.bars.config` | Vital bar toggles | `build_windows/016_buildVitalBars.lua` |
| `mapper.options.lua` | `mmp.locked/settings` | Mapper options | `mudlet-mapper` (no profile backup) |

**Profile Backup Keys** (in `_ataxia_backup`):
`ataxia`, `basher`, `basherpaths`, `ndb`, `extraction`, `slcconfig`, `shaman`, `legenddeck`, `legenddeck_config`, `classDetect`, `gearaudit`, `armourconfig`, `itemcatalog`, `bars_config`

**Other Storage**: SQLite `exp_db` (hunting stats via Mudlet `db` API), SQLite `mob_damage_db` (per-mob non-crit damage tracking via `db` API), `ataxiaNDB/*.json` (temp API downloads).

**Event Hooks**: `sysDisconnectionEvent` → `ataxia_saveSettings()`, `sysLoadEvent` → `ataxia_loadSettings()`, and `sysInstallPackage` → `ataxia_updateApplied()` which calls `ataxia_loadSettings()` when not already loaded (so install/self-update loads settings without needing a reconnect). `ataxia_loadSettings()` is fault-isolated: the main-settings load and each sub-load (basher/paths/extraction/NDB/SLC/itemCatalog/ldm) are `pcall`-wrapped, its `deepMerge` is cycle-safe, and `ataxia.loaded` is set only at the very end.

**Setup**: User must add `_ataxia_backup` as a saved variable in Mudlet's Variables panel (one-time, type: table).

---

## Achaea Classes Reference

Achaea has **26 classes** total: 21 base classes + 4 Elemental Lords + Dragon.

Each class has:
- At most 3 class skills with many abilities each
- Unique bashing (hunting) attacks
- Unique battlerage attacks

### Class Progression
1. **Fledgling** - Initial stage, only 2 of 3 skills, capped at Skilled level
2. **Journeyman** - Level 20+, skills capped at Fabled level
3. **Full Member** - After `EMBRACE CLASS` (Level 30 + House rank 2, or Level 50 without house), gains 3rd skill, no learning limits

**Getting a Class**: Visit Certimene in Delos: `ASK CERTIMENE BECOME <class>`

**Changing Class**:
- **Multiclass**: Can have multiple classes (`HELP MULTICLASS`)
- **Quit Class**: Use `QUIT CLASS` to leave (98% lesson refund before full member, 50% after)

### Base Classes (21)

| Class | Description | Skills |
|-------|-------------|--------|
| Alchemist | Enigmatic figures wielding the power of the ether | Alchemy, Physiology, Formulation/Sublimation |
| Apostate | Evil, necromantic daemon summoners | Evileye, Necromancy, Apostasy |
| Bard | Sword, Song, and Story at the disposal of the Virtuoso | Composition, Bladedance, Sagas (or Woe for Cyrene) |
| Blademaster | Masters of the legendary Two Arts | TwoArts, Striking, Shindo |
| Depthswalker | Fearless manipulators of shadow and time | Aeonics, Shadowmancy, Terminus |
| Druid | Forest-loving metamorphs | Groves, Metamorphosis, Reclamation |
| Infernal | Evil warriors employing necromantic methods (Knight) | Malignity, Oppression, Weaponmastery |
| Jester | Happy-go-lucky pranksters and roguish entertainers | Puppetry, Pranks, Tarot |

**JESTER PvE (v4.7.258).** **BADJOKE TAKES NO TARGET** -- AB 681 is `Syntax: BADJOKE`, "Works
on: Adventurers, denizens, and room", 3.00s equilibrium, 100 mana, and it strips rebounding and
shield from everyone who hears it. The basher sent `badjoke <target>` for its entire existence,
so every shield-break was a malformed command; a rejected command is silent here, which is why
nothing surfaced it. Three boons now handled in `ataxiaBasher_jesterBashing`: **Tough Crowd**
(badjoke also deals psychic damage to all denizens, but stuns AND stupefies US -- so it rides
the eq slot at 2+ denizens on a 12s cooldown behind a 300 mana floor, and `jesterJokeSafe`
refuses while escaping / recovering / in lava / already stunned / at or below `escapeAt`, because
stun blocks every action and stupidity EATS QUEUED COMMANDS; a shielded round where the joke is
unsafe falls back to the rage raze); **Elusive Foolery** (keeps the `slippery` defence up -- the
standard keeper shape, and shrugging off webs/ropes matters in the tower because entanglement is
what strands an escape); **Apostatic** (`fling priestess at <target>` -- syntax confirmed in-tree
from the lock-breakers' `fling fool at me`, NOT guessed -- on a deliberately generous 20s
cooldown because whether a fling consumes an INSCRIBED CARD is unconfirmed, and it is appended
rather than replacing the swing because its balance type is unconfirmed too).
| Magi | Masters of the four elements and crystalline vibrations | Crystalism, Elementalism, Artificing |
| Monk | Forges mind, body, and spirit into a unified whole | Tekura/Shikudo, Kaido, Telepathy |
| Occultist | Chaos-loving summoners of extra-planar entities | Domination, Tarot, Occultism |
| Paladin | Valorous warriors with eagle companion (Knight) | Excision, Valour, Weaponmastery |
| Pariah | Cheaters of Death and bringers of plagues | Memorium, Pestilence, Charnel |
| Priest | Holy warriors with a fearsome guardian angel | Spirituality, Devotion, Zeal |
| Psion | Weavers of Aldar magic | Weaving, Psionics, Emulation |
| Runewarden | Mystic warriors who employ runic lore (Knight) | Runelore, Discipline, Weaponmastery |
| Sentinel | Metamorphing forest rangers with animal companions | Woodlore, Metamorphosis, Skirmishing |
| Serpent | Masters of venoms and subterfuge (see Ekanelia below) | Subterfuge, Venom, Hypnosis |
| Shaman | Mystical users of Vodun dolls, curses, and bound spirits | Vodun, Curses, Spiritlore |
| Sylvan | Forest-lovers who blend mastery of three elements | Propagation, Groves, Weatherweaving |
| Unnamable | Frenzied mutant warriors for Chaos (Knight) | Dominion, Anathema, Weaponmastery |

### Elemental Lords (4 separate classes)
- Airlord, Earthlord, Firelord, Waterlord

### Dragon (End-Game Class)

**RED DRAGON SCORCH applies INHIBIT (v4.7.266).** AB 2299: `SCORCH <target>`, 18 rage, 25.00s
cooldown, denizens only, "Gives denizen affliction: Inhibit". Trigger
`denizen_attacks_misc_lines/027` records it into the denizen-state model (`BR_AFFS.inhibit`, the
same state Monk Ripplestrike and the Infernal Necrotic Aura proc apply) and announces it on PT
when `ataxia.settings.raid.enabled`. Recording matters twice over: it stops a second inhibit being
spent on a mob that already has one, and inhibit is one of the four PHYSICAL triggers for
Depthswalker's `chrono degenerate` (v4.7.265) -- so a scorching dragon sets up an aeonic cash-in
for a Depthswalker in the party. **Not in any rotation**: `GDRAGON_BR` is Golden-specific, so
there is no red-dragon rotation to add it to and it remains a manual cast.

- Unlocked at level 99
- 6 color variants: Red, Black, Silver, Gold, Blue, Green
- Each color has unique breath weapon and battlerage

### Class Specializations

**Knight Classes** (Infernal, Paladin, Runewarden, Unnamable) - Weaponmastery specs:
- **DWC (Dual Wield Cutting)** - Double venom application, fast attacks
- **DWB (Dual Wield Blunt)** - Double breaks, best limb prep
- **SnB (Sword and Board)** - Impale/stun, shield abilities, damage mitigation
- **2H (Two-Handed)** - Best damage, passive paralysis curing, strip rebounding/shield

**Monk**:
- **Tekura** - Unarmed martial arts (default)
- **Shikudo** - Staff-based combat (requires Trans Tekura to unlock)

**Alchemist**:
- **Formulation** - Default alchemical field
- **Sublimation** - Alternative field using Hashan's Wellspring

**Metamorphosis** (Druid/Sentinel):
- **Druid-exclusive morphs**: Hydra, Wyvern
- **Sentinel-exclusive morphs**: Jaguar, Basilisk

**Bard**:
- **Sagas** - Default third skill
- **Woe** - Exclusive to Cyrene

---

## Key Concepts

### Afflictions
- Negative status effects applied during combat (~55+ different afflictions)
- Must be cured in correct order (priority-based)
- Some afflictions hide or fake others (diagnosis required)
- GMCP provides: `gmcp.Char.Afflictions.List`, `.Add`, `.Remove`

**TRUTHSEEKER makes the `?` markers phantoms (v4.7.257).** The boon (uncommon) reads "The God
of Darkness allows your eyes to perceive the truth of all hidden afflictions that may befall
you" -- so while it is held there are no hidden afflictions and every `?` in the prompt is
false. **The prompt is the least of it**: `ataxia.afflictions.unknown` is a counter that only
ever goes UP in `gotUnknownAff` (nothing decrements it), and the Mnemosyne recovery gate reads
`unknown > 0` as a real affliction -- so a phantom count makes `S._afflicted()` permanently
true, `S._reenterReady()` can never pass, and every hover burns its full 60s cap. A live
screenshot showed ~20 banked. It also spammed `diagnose` via the `>= 2` branch. Refused at the
SOURCE (`gotUnknownAff` returns before even arming the next-line capture) rather than filtered
at each reader, because the boon means the INPUT is wrong; and the flag-setting paths (trigger
`mnemosyne/067`, the `BOON CLAIM` intercept) also CLEAR what is already banked, since they are
how the flag returns after a reload or mid-run re-latch -- by then the phantoms exist and
stopping new ones would leave the old ones forever.

#### Cure Types
| Action | Description | Examples |
|--------|-------------|----------|
| **Eat** | Consume herb or mineral | Bloodroot (paralysis), Kelp (asthma) |
| **Apply** | Apply salve to body part | Epidermal (anorexia), Mending (crippled) |
| **Smoke** | Smoke from pipe | Elm (aeon), Valerian (slickness) |
| **Sip** | Drink elixir | Immunity (voyria) |
| **Writhe** | Escape bindings | Entangled, Transfixed, Webbed |
| **Clot** | Stop bleeding | Bleeding |
| **Focus** | Mental cure | Breaks some locks |
| **Tree** | Tree tattoo | Cures random affliction |

#### Herb/Mineral Groupings
Each herb has an alchemical mineral equivalent (same cure balance):
- **Ginseng/Ferrum**: Addiction, Haemophilia, Lethargy, Nausea
- **Kelp/Aurum**: Asthma, Clumsiness, Sensitivity, Weariness
- **Goldenseal/Plumbum**: Epilepsy, Impatience, Stupidity, Dizziness
- **Bloodroot/Magnesium**: Paralysis, Slickness (alt)
- **Lobelia/Argentum**: Agoraphobia, Recklessness, Vertigo
- **Bellwort/Cuprum**: Generosity, Pacifism, Peace
- **Prickly Ash/Stannum**: Confusion, Dementia, Paranoia

#### Complete Cure Herb Reference
**Sources:** [Venom (Skill)](https://wiki.achaea.com/Venom_(Skill)), [Oppression](https://wiki.achaea.com/Oppression)

| Herb | Afflictions Cured |
|------|-------------------|
| **kelp** | clumsiness, healthleech, weariness, asthma, sensitivity, parasite |
| **ginseng** | nausea, haemophilia, addiction, darkshade, flushings, lethargy, scytherus |
| **goldenseal** | stupidity, impatience, depression, sandfever, epilepsy, dizziness, dissonance, shyness |
| **lobelia** | recklessness, vertigo, spiritburn, tenderskin, loneliness, claustrophobia, masochism, agoraphobia, hypochondria |
| **ash** | confusion, hypersomnia, hallucinations, paranoia, dementia, crescendo |
| **bellwort** | timeloop, justice, lovers, peace, pacified, generosity, indifference, diminished |
| **bloodroot** | paralysis |

#### Venom → Affliction → Cure Reference
| Venom | Affliction | Cure | Combat Use |
|-------|------------|------|------------|
| **curare** | paralysis | bloodroot | Venomlock, prevent tree |
| **kalmia** | asthma | kelp | Softlock, block smoking |
| **xentio** | clumsiness | kelp | Kelp stack, 33% miss chance |
| **euphorbia** | nausea | ginseng | Block parry, enable limb prep |
| **gecko** | slickness | kelp | Softlock, block salves (also cured by smoking valerian if no asthma!) |
| **slike** | anorexia | kelp | Softlock, block eating |
| **prefarar** | sensitivity (or removes deafness) | kelp | Damage amplification |
| **vardrax** | addiction | ginseng | Riftlock helper, eating triggers cooldown |
| **delphinium** | sleep | wake/insomnia | Sleeplock, prone via leg break |
| **epseth** | crippled leg (level 1) | mending | Limb pressure |
| **epteth** | crippled arm (level 1) | mending | Limb pressure |
| **voyria** | voyria (sip damage) | antidote | Lock aff for healers |
| **eurypteria** | recklessness | lobelia | Lock aff for Depthswalker |
| **digitalis** | shyness | goldenseal | Mental stack |
| **larkspur** | dizziness | goldenseal | Mental stack |
| **monkshood** | disloyalty | lobelia | Hinder loyalty-based abilities |
| **aconite** | stupidity | goldenseal | Mental stack, focus bait |
| **darkshade** | darkshade (light allergy) | ginseng | Hinder targeting |
| **notechis** | haemophilia | ginseng | Lock aff for Magi/Sylvan, Agony synergy |
| **sumac** | impatience | goldenseal | Truelock completion |
| **vernalius** | weakness | kelp | Hinder physical actions |
| **oleander** | blindness | smoke | Hinder targeting |
| **colocasia** | blindness + deafness | smoke + deafness | Full sensory denial |
| **loki** | random affliction | varies | Unpredictable pressure |

#### Hellforge Investments (Infernal Only)
| Investment | Affliction | Cure | Notes |
|------------|------------|------|-------|
| **INVEST TORTURE** | haemophilia | ginseng | Enables Agony passive healing |
| **INVEST EXPLOIT** | weariness + paranoia | kelp + ash | Two affs at once, blocks Fitness |
| **INVEST TORMENT** | healthleech | kelp | Sustained damage, confusion if already has healthleech |
| **INVEST PUNISHMENT** | scaling damage | n/a | More damage on wounded targets |

#### Affliction Locks

**See also**: `.claude/classes/lock_types.md` for comprehensive documentation.

##### Softlock (3 affs)
```yaml
afflictions:
  asthma: "Prevents smoking pipes - cured by eating Kelp"
  anorexia: "Prevents eating herbs - cured by applying Epidermal or Focus"
  slickness: "Prevents applying salves - cured by eating Bloodroot or smoking Valerian"
escape: "FOCUS to cure anorexia, then eat bloodroot, then eat kelp"
```

##### Venomlock (4 affs)
```yaml
afflictions: [paralysis, asthma, anorexia, slickness]
paralysis: "Prevents Tree tattoo - cured by eating Bloodroot"
escape: "FOCUS to cure anorexia, then eat bloodroot (cures para OR slick)"
```

##### Truelock / Hardlock (5 affs)
```yaml
afflictions: [paralysis, asthma, anorexia, slickness, impatience]
impatience: "Prevents using Focus - cured by eating Goldenseal"
escape: "None without external help"
requires: "Class-specific affliction to block passive cures"
```

##### Focuslock (Alternative to Truelock)
```yaml
afflictions: [paralysis, asthma, anorexia, slickness]
strategy: "Stack mental afflictions (goldenseal cures) instead of impatience"
mental_affs: [stupidity, dizziness, epilepsy, shyness, depression]
escape: "Focus may randomly cure anorexia instead of mental aff"
```

##### Riftlock (Limb-based)
```yaml
afflictions:
  broken_arms: "2 broken arms - prevents rifting herbs"
  slickness: "Prevents applying mending salve"
  asthma: "Prevents smoking valerian"
helper: "Addiction (Vardrax) forces eating held items"
escape: "Smoke valerian → mend arms → rift herbs"
```

##### Salvelock (Enhanced Riftlock)
```yaml
afflictions:
  mangled_arms: "Level 2+ breaks - prevents Restore ability"
  slickness: "Prevents applying mending"
  asthma: "Prevents smoking"
escape: "Very difficult - requires multiple mending applications"
```

##### Sleeplock (Timing-based)
```yaml
steps:
  1: "First Sleep/Delphinium strips Insomnia defence"
  2: "Second strips Gypsum/Kola defence"
  3: "Third puts opponent to sleep"
timing: "All three must hit in rapid succession"
```

##### Aeonlock (Time-manipulation)
```yaml
afflictions:
  aeon: "Only one action at a time on lengthy balance"
  asthma: "Prevents smoking Elm to cure aeon"
strategy: "Stack kelp affs to keep asthma stuck"
kelp_stack: [asthma, clumsiness, sensitivity, weariness, healthleech]
```

#### Class-Specific Lock Afflictions
| Classes | Extra Affliction | Blocks |
|---------|-----------------|--------|
| Knights, Monk, Serpent, Sentinel, Druid, Blademaster, Elemental Lords | Weariness | Various passive cures |
| Apostate, Pariah, Bard, Priest | Voyria | Sip-based healing |
| Magi, Sylvan | Haemophilia | Blood-based cures |
| Alchemist | Stupidity | Transmutation cures |
| Depthswalker | Recklessness | Shadow cures |
| Psion | Confusion | Mental cures |
| Jester, Occultist, Shaman | Paralysis | Already in base lock |

#### Server-Side Curing (SSC)
Achaea provides built-in curing that simulates average latency. Custom systems can integrate with or replace it.

**Core Commands:**
| Command | Description |
|---------|-------------|
| `CURING ON/OFF` | Enable/disable the system |
| `CURING STATUS` | Show current curing status |
| `CURING AFFLICTIONS ON/OFF` | Toggle affliction curing |
| `CURING DEFENCES ON/OFF` | Toggle defence upkeep |
| `CURING SIPPING ON/OFF` | Toggle health/mana sipping |
| `CURING SIPHEALTH/SIPMANA <percent>` | Set sip thresholds |
| `CURING FOCUS ON/OFF` | Toggle FOCUS ability usage |
| `CURING TREE ON/OFF` | Toggle TREE tattoo usage |
| `CURING BATCH ON/OFF` | Send multiple cures at once |

**Priority Management:**
| Command | Description |
|---------|-------------|
| `CURING PRIORITY LIST` | List affliction cure priority |
| `CURING PRIORITY <aff> <priority>` | Move affliction priority |
| `CURING PRIORITY RESET` | Reset to default priority |
| `CURING PRIORITY DEFENCE LIST` | List defence upkeep priority |

**Curingsets** (save/load priority configurations):
| Command | Description |
|---------|-------------|
| `CURINGSET NEW <name>` | Create new curingset |
| `CURINGSET SWITCH <name>` | Switch to a curingset |
| `CURINGSET LIST` | List all curingsets |
| `CURINGSET CLONE <from>` | Clone into current setup |

**KNOW WHAT SETS EXIST BEFORE TOUCHING THEM (v4.7.247).** `ataxia/009_Curingset_State.lua`
parses `CURINGSET LIST` into `ataxia.curingsets` (ordered list, per-name COUNTS so duplicates
stay visible, the `(current)` marker, used/allowed) via TEMP triggers armed only when we asked
-- a set-name row is a bare lowercase word and would be a catastrophic permanent trigger.
Queries answer **nil = unknown** as a third state; a caller reading unknown as "no" creates a
set that already exists (burning one of a hard-capped 22) or refuses one that does. This exists
because `ataxia_bashProfileInstall` used to send `curingset new`/`switch` and then write ~55
`curing priority` commands on timers ASSUMING both worked -- at the cap (live capture: 22 of 22)
both fail, the PVP set stays active, and those writes rewrote it, while `installed = true` was
set regardless. It is the one path that bypasses `ataxia_sendCuringPriority`'s guard by calling
`send()` directly. Now: `ataxia_bashInstallDecide` (pure, tested) returns proceed/create/abort,
**an unreadable list ABORTS rather than falling through to create**, `create` re-reads the list
to VERIFY the set appeared before writing, `bashProfileOn` refuses a set proven absent, and
`aconfig bashcuring status` reports what the GAME says instead of the old `installed` flag
(which only ever meant "we ran the installer"). `classDetect.setup()` was equally blind --
`curingsetMap` names 27 sets against a cap of 22 and it sent every `curingset new` silently
(`send(..., false)`), so it could never succeed and never said so; it now plans against free
slots (`classDetect.planCuringsets`, pure + sorted so drops are deterministic) and reports what
it could not create. Command: `curingsets`.

**CRITICAL: `CURING PRIORITY <aff> <n>` writes a STORED priority into whichever curingset is
ACTIVE.** Any code path that writes priorities while a non-default set is selected mutates
that set permanently — and `ataxia_restorePrio()` will then write the *default* table's value
into the *other* set, rotting it one affliction at a time. Route every priority write through
`ataxia_sendCuringPriority()` (`ataxia/ataxia/002_Prio_Management.lua`), which throttles to
4/sec (server limit 5/sec, Announce #5450) **and** drops stored affliction writes while the
PvE bash set is active. `CURING PRIOAFF <aff>` is a *temporary* prioritisation, writes nothing
stored, and is always safe.

**PvE bashing curing profile** (`ataxia/ataxia/008_Bash_Curing_Profile.lua`, v4.7.172): the
default table (`001_Default_Curing_Prios.lua`) is tuned entirely for PvP, which loses bashers.
Two balances are contended and the PvP ordering spends both on afflictions that do nothing to
a denizen: **potash/moss shares the EATING balance with every cure-mineral**, and **mending/
restoration shares the SALVE balance with crackedribs/fractures/traumas**. So the PvE table
inverts it — cure-channel blockers (anorexia/slickness/paralysis) > limbs at 4-6 (arms gate
the attack, legs gate every escape) > damage math > salve competitors parked at 20 > junk
mental spray parked at 25. Held in a server-side `bash` curingset so the swap is ONE command
rather than ~55 throttled pushes (~15s). Switched on `"basher enabled"` / `"basher disabled"`;
opt-in via `aconfig bashcuring install`. A priority at/above `ataxiaBashProfile.PARKED` (20)
means SSC will not cure it, so it stays up for the whole fight — **anything testing
"affliction-free" must treat a parked aff as not-an-affliction** (see `S._afflicted` in
mnemosyne/009, whose recovery hover would otherwise never land). Full detail in
`memory/curing.md`.

**Manual Queue:**
| Command | Description |
|---------|-------------|
| `CURING QUEUE ADD <cure>` | Add manual cure to queue |
| `CURING QUEUE LIST` | List queue contents |
| `CURING PREDICT <aff>` | Tell system you have an affliction |
| `CURING PRIOAFF <aff>` | Temporarily prioritise an affliction |

**Example Pattern (Ataxia style):**
```lua
ataxia.afflictions = ataxia.afflictions or {}

local function affsAdd()
  local aff = gmcp.Char.Afflictions.Add.name
  ataxia.afflictions[aff] = true
  raiseEvent("aff gained", aff)

  -- Special handling
  if aff == "amnesia" then
    send("touch flaws")
  elseif aff == "aeon" then
    send("curing batch off")
  end
end

registerAnonymousEventHandler("gmcp.Char.Afflictions.Add", affsAdd)
```

### Combat Strategies
Classes generally focus on one of two kill paths:

**Affliction-Based**: Stack afflictions to achieve a lock or kill condition
- Build toward Soft Lock → Tree Lock → True Lock
- Use class-specific affliction to complete the lock
- Examples: Serpent, Shaman, Apostate

### Serpent Combat System (Ekanelia + Impulse)

Modern Serpent combat revolves around two key mechanics:

**Impulse** - Instant mental affliction delivery when:
- Target has asthma AND weariness AND no fangbarrier
- Delivers impatience or anorexia instantly (no SNAP timing needed)

**Ekanelia** - BITE venom transformation that ADDS bonus afflictions:
| Venom | Conditionals Required | Normal + Bonus Effect |
|-------|----------------------|----------------------|
| kalmia | clumsiness + weariness | asthma + **slickness** |
| monkshood | asthma + masochism + weariness | disfigurement + **impatience** |
| curare | hypersomnia + masochism | paralysis + **hypochondria** |
| loki | confusion + recklessness | random + **nausea + paralysis** |
| scytherus | addiction + nausea | scytherus + **camus damage** |

**Fratricide** - Causes Impulse-delivered afflictions to RELAPSE after cure
- Combined with scytherus = ~1200 damage per relapse tick
- CRITICAL to cure early when fighting serpents

**Kill Routes**:
1. **True Lock**: asthma + slickness + paralysis + impatience + anorexia + weariness
2. **Darkshade Kill**: Keep darkshade stuck for 26 seconds (protected by ginseng stack)

**Defense Priority vs Serpent**:
1. Tree when Impulse enabled + mental affliction present
2. Re-apply fangbarrier (quicksilver) when stripped
3. Cure fratricide IMMEDIATELY when scytherus present
4. Block Ekanelia setups by curing masochism, clumsiness, or confusion early

**Key Files**: `.claude/classes/serpent.md`, `src_new/scripts/.../serpent/002_Ekanelia_Offense.lua`

**Limb Damage-Based**: Break limbs to enable killing blows
- Limbs track damage as percentage (0-200%+)
- **Level 1 break**: Limb reaches ~33% (damaged)
- **Level 2 break**: Limb reaches 100% (crippled/broken)
- **Level 3 break**: Limb reaches 200% before victim can apply restoration+mending (mangled)
- Cured with: Restoration salve (damage), Mending salve (breaks)
- Examples: Knights (2H spec), Monk, Blademaster

**Limbs**: Head, Torso, Left Arm, Right Arm, Left Leg, Right Leg

### Offensive System Development Guidelines

**CRITICAL**: Before coding ANY offensive combat system, agents MUST read:
1. `.claude/classes/lock_types.md` - Lock definitions and escape routes
2. `.claude/classes/<class>.md` - Target class kill routes and vulnerabilities
3. `.claude/classes/README.md` - Affliction stacking reference

**Lock knowledge is essential for:**
- Building toward softlock → venomlock → truelock
- Understanding which afflictions to prioritize
- Knowing gating requirements for key afflictions (e.g., paralysis needs nausea + weariness + asthma for Waterlord)
- Anticipating defender cure priorities and escape routes

**When creating offensive Lua files, include this header:**
```lua
--[[
  OFFENSIVE SYSTEM - <Class Name>

  REQUIRED READING before modifying:
  - .claude/classes/lock_types.md (lock definitions)
  - .claude/classes/<class>.md (class mechanics)

  Lock progression: Softlock → Venomlock → Truelock
  See lock_types.md for affliction requirements and escape routes.
]]--
```

### Balances
- **Balance**: Physical action cooldown (~2-4 seconds)
- **Equilibrium**: Mental action cooldown (~2-4 seconds)
- **Cure balances**: herb, salve, mineral, smoke, focus, tree, sip, moss
- **Class-specific**: kai (Monk), blood (Praenomen), devotion (Priest), etc.
- Tracked via GMCP (`gmcp.Char.Vitals.bal/eq`) and text triggers

**Example Pattern:**
```lua
ataxia.balance = ataxia.balance or {}
ataxia.balance.stopwatches = ataxia.balance.stopwatches or {}

function ataxia.balance.lost(bal)
  if not ataxia.balance.stopwatches[bal] then
    ataxia.balance.stopwatches[bal] = createStopWatch()
  end
  ataxia.bals[bal] = false
  startStopWatch(ataxia.balance.stopwatches[bal], true)
end

function ataxia.balance.regained(bal)
  ataxia.bals[bal] = true
  if ataxia.balance.stopwatches[bal] then
    local time = stopStopWatch(ataxia.balance.stopwatches[bal])
    cecho(" <dark_turquoise>(<plum>"..(math.floor(time*100)/100).."<dark_turquoise>)")
  end
end
```

### Server-Side Curing (SSC)
- Built-in Achaea curing system
- Configurable via `CURING` commands
- Can be integrated with custom systems

```lua
-- Initialize with custom curingset
send("curingset new ataxia", false)
send("curingset switch ataxia", false)
send("curing priority defence list reset", false)
```

### Queue System
- Achaea has built-in ability queuing
- Commands: `QUEUE ADD`, `QUEUE INSERT`, `QUEUE PREPEND`
- Executes on balance recovery
- Multiple queue types (bal, eq, eqbal, free)

---

## Development Guidelines

### Naming Conventions

**Functions** — use `snake_case` with the owning namespace as a prefix:

| Namespace | Prefix | Example |
|-----------|--------|---------|
| Core system | `ataxia_` | `ataxia_saveSettings()`, `ataxia_promptAffs()` |
| Basher | `ataxiaBasher_` | `ataxiaBasher_getTarget()` |
| NDB | `ataxiaNDB_` | `ataxiaNDB_getClass()` |
| GUI | `ataxiagui_` | `ataxiagui_buildWindow()` |
| MMP | `mmp.*` | `mmp.gotoRoom()` |

**Module tables** — `camelCase` no underscore: `ataxia`, `ataxiaNDB`, `ataxiaBasher`, `ataxiaTables`, `mmp`.

**Private / module-internal helpers** — declare `local`, no prefix required.

**Files** — `NNN_Descriptive_Name.lua` (three-digit numeric prefix for load order).

**Directories** — `snake_case`.

**What to avoid**:
- camelCase public functions (`ataxiaCheckForMissing` → prefer `ataxia_checkForMissing`)
- Unprefixed globals (`haveDef`, `needToSalt`) — make `local` or add namespace prefix
- Mixed conventions within a single file

Migration is gradual: apply the standard to new code and any file touched significantly.

### Namespace Pattern
```lua
-- All system code under namespaces
ataxia = ataxia or {}
ataxia.afflictions = ataxia.afflictions or {}
ataxia.balance = ataxia.balance or {}
ataxia.defense = ataxia.defense or {}

mmp = mmp or {}
mmp.settings = mmp.settings or {}

ataxiagui = ataxiagui or {}
ataxiaNDB = ataxiaNDB or {}
```

### Initialization Pattern
```lua
function ataxia.initialize()
  -- Setup file paths
  ataxia.filepath = getMudletHomeDir() .. "/AtaxiaSaves"
  if not io.exists(ataxia.filepath) then
    lfs.mkdir(ataxia.filepath)
  end

  -- Request GMCP data
  sendGMCP([[ Core.Supports.Add [ "Comm.Channel 1" ] ]])
  sendGMCP([[ Core.Supports.Add ["IRE.Target 1"] ]])
  sendGMCP("IRE.Rift.Request")
  sendGMCP("Char.Items.Inv")

  -- Initialize subsystems
  ataxia.loadSettings()
  ataxia.balance.reset()

  raiseEvent("ataxia system loaded")
end

registerAnonymousEventHandler("gmcp.Char.Name", "ataxia.initialize")
```

### Event-Driven Architecture
```lua
-- Raise custom events for inter-module communication
raiseEvent("aff gained", "paralysis")
raiseEvent("aff lost", "paralysis")
raiseEvent("ataxia system loaded")

-- Other modules listen
registerAnonymousEventHandler("aff gained", "updateUI")
```

### Echo/Debug Pattern
```lua
function ataxia.echo(text)
  cecho("\n<dark_orchid>[<light_slate_blue>Ataxia<dark_orchid>]<lavender>: <plum>" .. text)
end

function ataxia.decho(text)
  if ataxia.debug then
    ataxia.echo(text)
  end
end

-- Quiet commands (no echo)
function ataxia.quietSend(command)
  send(command, false)
end
```

**Echo strings must be pure ASCII** (2026-07-26): typographic characters (em-dashes `—`,
arrows `→`, ellipses `…`, curly quotes) mojibake through the packaging/display pipeline
(`—` rendered as `â€"` in-game). Use `--`, `->`, `...`, `'` in any string passed to
echo/cecho/send. Decorative box-drawing borders in status screens are currently
tolerated; never add new non-ASCII to user-visible strings.

---

## Testing Approach

### Mock GMCP Data
```lua
gmcp = gmcp or {}
gmcp.Char = gmcp.Char or {}
gmcp.Char.Vitals = {bal="1", eq="1", hp=5000, maxhp=5000}
gmcp.Char.Afflictions = {List = {}}
```

### Performance Considerations
- **Sub-second response times critical**
- Optimize trigger patterns (use specific strings over wildcards)
- Cache frequently accessed data
- Minimize table creation in hot paths (balance/prompt triggers)
- Use stopwatches for precise timing
- Avoid expensive operations in prompt triggers

---

## Common Pitfalls & Solutions

### Pitfall: Trusting Combat Messages
```lua
-- BAD: Assuming affliction was applied
if matches[1]:find("You jab") then
  target.affs.paralysis = true  -- They might have shrugging!
end

-- GOOD: Track attempts, confirm with diagnose/death messages
if matches[1]:find("You jab") then
  target.affAttempts.paralysis = true
end
```

### Pitfall: Not Handling Blackout
```lua
-- BAD: Assuming vitals are accurate
if ataxia.vitals.hp < 1000 then
  sip health
end

-- GOOD: Check for blackout first
if not ataxia.afflictions.blackout and ataxia.vitals.hp < 1000 then
  sip health
end
```

### Pitfall: Hardcoded Timing
```lua
-- BAD: Assuming 2s balance
tempTimer(2.0, function() doNextAttack() end)

-- GOOD: Use stopwatches and balance regain events
function ataxia.balance.regained("bal")
  doNextAttack()
end
```

---

## GMCP Data Reference

### Vitals (fires on prompt)
```lua
gmcp.Char.Vitals = {
  hp = "5000",
  maxhp = "5000",
  mp = "4500",
  maxmp = "4500",
  bal = "1",  -- "1" = have balance, "0" = don't have
  eq = "1",
  charstats = {"Endurance: 18500/18500", "Willpower: 18500/18500", ...}
}
```

### Afflictions
```lua
gmcp.Char.Afflictions.List = {
  {name = "asthma", cure = "kelp"},
  {name = "clumsiness", cure = "kelp"}
}
gmcp.Char.Afflictions.Add = {name = "paralysis", cure = "bloodroot"}
gmcp.Char.Afflictions.Remove = {"asthma"}
```

### Room Info
```lua
gmcp.Room.Info = {
  num = 12345,
  name = "A dark alley",
  area = "Ashtan"
}
```

---

## Important Considerations

### Things to Remember
- Achaea has 26 classes (21 base + 4 Elemental Lords + Dragon) with unique mechanics
- Server-side curing exists but custom systems provide advantages
- Illusions and hidden afflictions are common (use diagnosis)
- Combat logs can be several hundred lines per second
- System must handle disconnections/reconnections gracefully
- Blackout hides all vitals and afflictions (special handling required)
- Aeon/retardation slow down actions (disable batching)
- Some afflictions prevent certain actions (paralysis, stun, etc.)

### Things to Avoid
- Hardcoded delays (server-side timing varies by ping)
- Assuming affliction order from attacks
- Trusting all game output without verification (illusions exist)
- Over-automating (ToS compliance concerns)
- Blocking the main thread with heavy processing
- Creating tables in hot paths (prompt/vitals triggers)
- Using wildcards excessively in triggers
- Global variable pollution (use namespaces)

---

## Resources & References

- **Achaea Wiki**: https://wiki.achaea.com/
- **Mudlet Documentation**: https://wiki.mudlet.org/
- **Lua 5.1 Reference**: https://www.lua.org/manual/5.1/
- **Achaea API**: http://api.achaea.com
- **IRE Mapping Script Wiki**: http://wiki.mudlet.org/w/IRE_mapping_script
- **Achaea Forums**: https://forums.achaea.com/
- **Agent Teams Guide**: `docs/ai-includes/agent-teams.md` - Multi-agent team coordination for parallel development

---

## Questions to Ask When Developing

### Correctness
- Does this handle illusions correctly?
- What happens during blackout?
- How does aeon/retardation affect this?
- Does it work when stunned/asleep/dead?

### Performance
- Is this timing-sensitive code optimized?
- Are we creating unnecessary tables?
- Should this be cached?
- Can triggers be more specific?

### Compatibility
- Does this work for all classes or just one?
- Are there class-specific edge cases?
- How does this behave with different artifacts?

### Reliability
- How does this behave when offline/reconnecting?
- What if GMCP data is delayed?
- Is there graceful degradation?
- Are errors handled properly?

---

## Defense Systems

### Core Defense Files
```
src_new/scripts/levi_ataxia/levi/ataxia/deffing/001_Defence_API.lua        # Main defense tracking API
src_new/scripts/levi_ataxia/levi/ataxia/deffing/003_Defence_Reporting.lua  # Defense status display
src_new/scripts/levi_ataxia/levi/ataxia/deffing/004_Defence_Sorting_-_Cleaner.lua  # Defense priority management
```

### Defence API (`ataxia.defense`)
The defense system tracks active defenses and manages automatic rekeeping.

**Key Functions:**
| Function | Purpose |
|----------|---------|
| `ataxia.defense.add(def)` | Mark defense as active |
| `ataxia.defense.remove(def)` | Mark defense as lost |
| `ataxia.defense.has(def)` | Check if defense is active |
| `ataxia.defense.list()` | Return all active defenses |

### Anti-Serpent Defenses
Located in `algedonic_defense_1.0/001_Anti_Priorities.lua`

**Serpent Defense Priority Adjustments:**
When fighting a serpent, automatically adjusts curing priorities:
- Metawake high priority (vs hypnosis)
- Insomnia high priority (vs sleep lock)
- Kola/Gypsum for deafness cycling

**Usage:**
```lua
ataxia.defense.antiSerpent(true)   -- Enable anti-serpent priorities
ataxia.defense.antiSerpent(false)  -- Restore normal priorities
```

### Self Limb Counter (SLC) — Defensive Limb Tracking

Tracks exact limb damage percentages from combat text with automated defensive responses (auto-parry, auto-shield, party callouts, SSC priority).

**Full documentation**: See `memory/slc.md` (thresholds, events, parry modes, defensive reactions, config)

**Namespace:** `selfLimbDamage` (global). **Alias:** `slc`. **Files:** `self_limb_tracking/002-005`, `triggers/.../highlighting/027_Parry_Success.lua`, `aliases/.../slc/005_SLC_Toggle.lua`. PvE predictive layer (005, v4.7.109): `selfLimbDamage.denizenPatterns[name]` holds fixed swing cycles (e.g. the Mnemosyne axe-wielding revenant: right leg x2 → left leg x2 → torso x2) or, since v4.7.111, `{ fixed = "<limb>" }` for mobs with exactly one parryable attack (a steel-encased Death Knight = left leg, a ravager of the Infernal Legion = torso, an unbound frost elemental = torso, and v4.7.167 **an iron malagma = right arm** / **an invar malagma = right leg** — the iron malagma has two arm attacks to one head attack and broken arms REFUSE the SnB combination outright, so arms are the limbs gating the whole offence; `fixed` not `cycle` because neither arm line names a SIDE, so an unsynchronised cycle would guard the wrong arm half the time); `ataxia_denizenParryPredict()` parries the NEXT swing's limb, including the cycle opener before the first hit lands. Lives inside the **`bashing` parry mode** (v4.7.110), which auto-engages on `basher enabled` (saving the prior mode) and restores on `basher disabled` — ladder: pattern/fixed prediction → focus-follow (`lasthit`, 12s-fresh via `lasthitAt`, fed by perceive lines AND confirmed parries through `ataxia_parrySuccess`) → head default (head → right leg → left leg → torso); `manual` never hijacked, opt-out `slc bashparry off`. **The level-1 break line had NO handler until v4.7.167** (trigger `038_Limb_Broken_L1`, `^Your (left arm|right arm|left leg|right leg) breaks with a loud crack\.$`) — SLC captured both ends of the trio (`036_Limb_healed` → `ataxia_clearLimbDamage`, `037_mangled` → `SLC_broke`) but not the most common of the three. Because `ataxia_brokenLimbFound` only branches on the `damaged*`/`mangled*` families, a level-1 break never reset the accumulator: `selfLimbDamage[limb].damage` climbed past the real break, `ataxia_selfHitsToBreak` pinned at 0, the threshold latched `critical` forever, and every one-shot reaction latch (SSC priority, party callout, auto-shield cooldown) stayed set and never re-armed — and `computeThreshold` never returns `"broken"` for a limb at all (torso only), making `004_Defensive_Reactions`' `if threshold ~= "broken" then return end` unreachable for arms. The fix uses the GAME'S OWN FIRE TEXT, which names limb AND side, sidestepping the unresolved `crippled*` vs `broken*` vs `damaged*` naming split the codebase is genuinely inconsistent about. **Two refusal lines** are also wired (v4.7.167): `344_Broken_Arms` (which previously fired an unthrottled `diag` that nothing parses) and the new `345_Broken_Legs_Block` both roll back every owned rotation's in-flight replay, and the legs one also calls `M._disarmMove()` — its expensive victim is not a lost swing but the swarm escape ladder's `leap`, whose refusal was otherwise silent. The parry-success line ("You parry the assault to your <limb> with a deft maneouvre." — game spells it "eo"; trigger tolerates both spellings) is highlighted bold spring_green and feeds the tracker; parried swings emit no perceive line, so without that feed the system went blind exactly while the parry worked.

---

## Infernal DWC Vivisect Combat System

4-limb and 2-limb vivisect offense. Phases: DAMAGE KILL → KILL → EXECUTE → PREP → RIFTLOCK. Optimized 2-attack execute sequence using epteth/epseth cross-limb breaks.

**Full documentation**: See `memory/dwc.md` (phase progression, execute sequence, break prevention, riftlock, helper functions, config)

**Key files:** `dwc/001_Infernal_DWC_Vivisect.lua` (4-limb), `dwc/002_Infernal_DWC_Vivisect_2L.lua` (2-limb). **Namespace:** `infernalDWC` / `infernalDWC2L`. **Class docs:** `.claude/classes/infernal.md`

---

## Blademaster Combat System

3 modes: double-prep (`bmd`), quad-prep (`bmdq`), brokenstar (`bmbs`). Lightning/Ice phase system for damage kills.

**Full documentation**: See `memory/blademaster.md` (strategies, phase system, helper functions, config, brokenstar kill route)

**Key file:** `blademaster/005_CC_BM_Ice.lua`. **Namespace:** `blademaster`. **Class docs:** `.claude/classes/blademaster.md`

---

## Apostate Combat System

Dual-slot curse engine via DEADEYES. 6 modes: lock (default), mental, group, corrupt, vivisect, sleep. Consolidated from 14 legacy files into `apostate` namespace with V3 integration.

**Full documentation**: See `memory/apostate.md` (curse priority engine, lock progression, corrupt calculator, kill routes, config)

**Key file:** `apostate/015_CC_Apostate.lua`. **Namespace:** `apostate`. **Class docs:** `.claude/classes/apostate.md`

---

## Tekura Monk Combat System

Two Tekura systems: TK6 (6-limb backbreaker, primary) and TKD (3-limb legacy). Both use `combo target <kick> <punch1> <punch2>` format with break-guarded prep phases.

**Full documentation**: See `memory/tekura.md` (phases, break guards, kai modes, candidate pools, limb attack mapping, config)

**Key files:** `tekura/002_Tekura_6Limb_Offense.lua` (TK6), `tekura/001_Tekura_Offense.lua` (TKD). **Namespace:** `tekura6` / `tekura`.

**Aliases:** `zz` = TK6 with kai surge, `xx` = legacy TKD, `vv` = TK6 with kai cripple.

**Kill route (TK6):** Prep all 6 limbs to 86%+ → Break arms+torso (Horse stance) → Wrench torso + break legs (Bear stance) → Backbreaker.

**Kai modes:** `tekura6.config.kaiMode` — `"surge"` (31 kai, 3.2s eq, dismount) or `"cripple"` (41 kai, 4s eq, dismount + L1 breaks all limbs).

---

## Psion Combat System

Weave-based combat with 2 modes (mind/flurry) and 3 simultaneous kill routes: Psi Excise (mana kill), Deconstruct (unweave execute), Flurry (damage burst). Unified `psion` namespace with V3 integration and rebounding handling.

**Full documentation**: See `memory/psion.md` (kill routes, weave selection priority, rebounding bypass rules, V3 integration, config)

**Key file:** `psion/001_Levi_Psion_Logic.lua`. **Namespace:** `psion`. **Class docs:** `.claude/classes/psion.md`

---

## Lessons Learned (Combat System Development)

### Mudlet Trigger Patterns

**Problem**: Strict regex anchors (`^` and `$`) can fail in Mudlet due to line processing quirks.

```lua
-- BAD: May not match due to anchors
"^You observe .+ \\[(\\d+)\\]$"

-- GOOD: More flexible, still specific
"You observe .+ \\[(\\d+)\\]"
```

**Best Practices**:
- Avoid `^` and `$` unless absolutely necessary
- Use `.+` (one or more) instead of `.*` (zero or more) when content is expected
- Test patterns against actual game output before deploying

### Counter Incrementing (Button Spam Issue)

**Problem**: Incrementing counters in dispatch/combo builder functions causes them to increment on every button press, not just when the action fires.

```lua
-- BAD: In buildComboBrokenstar() - called every button press
blademaster.state.bladetwistCount = blademaster.state.bladetwistCount + 1
combo = "bladetwist;discern " .. target

-- GOOD: Use trigger to increment when action actually fires
blademaster.bladetwistTriggerID = tempRegexTrigger(
  "BLADETWIST \\[\\|\\] BLADETWIST \\[\\|\\] BLADETWIST",
  function()
    blademaster.state.bladetwistCount = blademaster.state.bladetwistCount + 1
  end
)
```

### Limb Balancing Strategy

**Problem**: When attacking two limbs with asymmetric damage, one limb reaches threshold before the other.

**Solution**: Always hit the **LOWER damage limb as primary** to balance progression.

```lua
function blademaster.getFocusLeg()
  local LL = blademaster.getLL()
  local RL = blademaster.getRL()
  return (LL <= RL) and "left" or "right"
end

function blademaster.getCentreslashDirection()
  local torso = blademaster.getTorso()
  local head = blademaster.getHead()
  return (head <= torso) and "down" or "up"
end
```

### Mounted Target Handling

**Problem**: KNEES on a mounted target DISMOUNTS instead of PRONING.

**Solution**: Dismount on the final prep hit (before double-break), then KNEES on double-break will properly prone.

```lua
if phase == "leg_prep" then
  -- Dismount during final prep hit if mounted + hamstrung
  if tmounted and blademaster.hasAff("hamstring") and blademaster.checkWillPrepBothLegs() then
    return "knees"  -- Dismount now
  end
  return blademaster.selectPrepStrike()
end
```

### Phase Transition Triggers

**Problem**: State-based phase transitions fail when triggers don't capture values correctly.

**Best Practices**:
1. Use simple, robust trigger patterns for critical state updates
2. Log trigger fires during debugging to verify they're matching
3. Have fallback phase logic when triggers miss
4. Always update both state flags and values (e.g., `bleedingReady = true` AND `targetBleeding = value`)

### Writhe/Escape Handling

**Problem**: Target escaping (writhe from impale, standing from prone) should preserve progress.

**Best Practices**:
1. On writhe: Keep `bleedingReady` and `targetBleeding` - don't reset progress
2. Check if target is still prone after writhe (free re-impale!)
3. If bleeding >= 700 and not impaled, can go directly to brokenstar

```lua
function blademaster.onTargetUnimpaled()
  blademaster.state.isImpaled = false
  -- Keep bleedingReady and targetBleeding - we built that progress!

  if blademaster.hasAff("prone") then
    cecho("[BM] Target writhed free but STILL PRONE - FREE RE-IMPALE!")
  elseif blademaster.state.bleedingReady then
    -- Go to brokenstar phase (checked in getPhaseBrokenstar)
  end
end
```

---

## Agent Teams

Claude Code agent teams enable parallel development across isolated combat subsystems. See `docs/ai-includes/agent-teams.md` for the full guide.

### Quick Reference

**When to use**:
- Parallel class system development (e.g., shaman + blademaster simultaneously)
- Cross-system feature rollouts (e.g., adding V3 tracking to multiple classes)
- Parallel code review of independent subsystems
- Documentation sprints across multiple class files

**When NOT to use**:
- Single class edits, threshold tweaks, trigger fixes
- Sequential debugging (cause-and-effect tracing)
- Changes to shared `ataxia/` core files (serialize through lead)

**File ownership rule**: Each teammate owns a class directory under `levi_scripts/`. The `ataxia/` core (affliction tracking, curing, balance) is shared -- coordinate through the team lead before modifying.

**Build contention**: Only one agent may run `convert_to_muddler.py` or `muddle.bat` at a time.

### Porting Foreign Combat Scripts

**Problem**: When porting logic from another player's combat system, global table names may look identical but have completely different write sources in our codebase.

**Root cause (2026-04-14 Shikudo God Mode)**: Pharaus' script reads `tLimbs.LL` for limb damage. Our codebase has `tLimbs` as a table, but no trigger ever writes to it — our canonical limb data lives in `lb[target].hits["left leg"]`. The ported code silently ran on permanent zeros.

**Prevention checklist for ported code:**
1. For every global table the foreign code READS, grep for WRITE sites in `src_new/triggers/`: `grep -r "tableName\s*=" src_new/triggers/`
2. If no writes found, the table is dead — map to the canonical source (usually `lb[target].hits` for limb data, `tAffs` for afflictions)
3. For file-scope `local` state tables, verify they are reset at the top of the per-tick entry point — stale sentinels from prior ticks cause phantom actions
4. When two functions must agree on a threshold (e.g., `executeReady` and form transition `allPrepped`), verify they use identical flags — don't mix conventions from the source and destination systems
5. Never write a new offense file (>200 lines) in a single pass — write namespace + calc first, build, then add each form's logic incrementally

```lua
-- BAD: Assumed tLimbs was populated (it wasn't)
local tl = tLimbs
gm.llFLASH = (tl.LL + ld.shikFlashheel >= 100)

-- GOOD: Read from canonical trigger-fed source
local function getLimb(key)
  if not target or not lb or not lb[target] or not lb[target].hits then return 0 end
  return lb[target].hits[LIMB_NAMES[key]] or 0
end
gm.LL = getLimb("LL")
gm.llFLASH = (gm.LL + ld.shikFlashheel >= 100)
```

---

## Model Routing Guidance

Different tasks benefit from different model tiers. The `build-and-version` agent already routes to Haiku for efficiency.

| Task Type | Recommended Model | Rationale |
|-----------|------------------|-----------|
| Architecture design, complex offense systems, lock strategy | Opus | Deep combat mechanic reasoning, multi-file coordination |
| Standard development (features, bug fixes, triggers) | Sonnet | Good balance of speed and capability for typical coding |
| Builds, version bumps, syntax checks | Haiku | Mechanical tasks with clear steps, speed over reasoning |
| Code review, documentation updates | Sonnet | Benefits from context understanding without deep planning |
| Multi-class parallel development (team agent) | Sonnet per worker, Opus for lead | Workers follow patterns; lead coordinates strategy |

**Current agent model assignments:**
- `build-and-version`: `haiku` (configured)
- `offense-system`: default (Sonnet recommended)
- `team-class-offense`: default (Sonnet for workers)

**When to escalate to Opus:**
- Designing new combat system architecture from scratch
- Debugging subtle cross-system interactions (e.g., V3 affliction tracking + class offense)
- Refactoring shared `ataxia/` core modules
- Planning multi-session development arcs

---

## Hooks

The project uses Claude Code hooks for automated quality gates and context preservation. All hook scripts live in `.claude/hooks/`.

| Hook | Event | Purpose |
|------|-------|---------|
| `session-start.sh` | SessionStart | Shows branch, version, recent commits, uncommitted changes |
| `pre-compact.sh` | Notification (compact) | Dumps working state to stderr before context compaction |
| `protect-config.sh` | PreToolUse (Write/Edit) | Blocks AI edits to `.claude/settings*.json` files |
| `block-git-bypass.sh` | PreToolUse (Bash) | Blocks `--no-verify`, `--force`, `--hard` on git commands |
| `lint-before-commit.sh` | PreToolUse (Bash) | Validates Lua syntax on staged files before `git commit` |
| *(inline)* | PreToolUse (Bash) | Prevents concurrent build processes |

**Exit codes:** 0 = allow, 2 = block tool use. All hooks have jq-with-grep fallbacks for portability.

---

## Documentation Requirements

**MANDATORY**: After every code change, you MUST update all relevant documentation before considering the task complete. This is not optional.

### CHANGELOG.md
- **Update `CHANGELOG.md` after every change** — bug fixes, new features, refactors, anything that modifies behavior
- Group entries by date, with newest at the top
- Each entry must include: **what changed** (files), **why** (root cause / motivation), and **how** (what the fix/feature does)
- Use the existing format in `CHANGELOG.md` as a template

### Other Documentation
- **CLAUDE.md**: Update if you add new systems, change architecture, modify build processes, or add new conventions
- **Memory files** (`~/.claude/projects/.../memory/`): Update with stable patterns, conventions, and lessons learned
- **Class docs** (`.claude/classes/*.md`): Update if combat mechanics or class-specific logic changes
- **Plan files** (`.claude/plans/`, `docs/plans/`): Mark completed items, update status, note deviations from plan
- **README.md / GETTING_STARTED.md**: Update if setup steps, dependencies, or usage instructions change

### Checklist (run mentally after every task)
1. Did I change code? → Update `CHANGELOG.md`
2. Did I add/remove files? → Update `CHANGELOG.md`, verify build includes them
3. Did I change system architecture? → Update `CLAUDE.md`
4. Did I learn something reusable? → Update memory files
5. Did I change class combat logic? → Update relevant `.claude/classes/*.md`

---

**Last Updated**: 2026-08-12
**Project Lead**: Michael
**Development Environment**: VS Code + Mudlet + Claude Code
**Reference Systems**: Orion, Ataxia
