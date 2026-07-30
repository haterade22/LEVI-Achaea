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

**CI/CD**: GitHub Actions (`.github/workflows/build.yml`) runs Lua syntax checks, version consistency checks, unit tests, and YAML validation on every push. Tagged releases (`v*`) trigger a full build and upload to GitHub Releases.

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
4. Push commit and tag: `git push && git push --tags`
5. CI/CD automatically builds and creates a GitHub Release with the `.mpackage`

**IMPORTANT**: When asked to rebuild the package, ALWAYS perform the full release flow: version bump → build → commit → tag → push. Do not just build locally — the user expects the new version to reach GitHub so the auto-updater can pick it up.

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

**Core Files:** `basher/001_Bashing_Functions.lua` (attack dispatch, danger levels, no-flee + own-denizen helpers; **load-time reload-safety inits** `battleRage_Timers`/`tBals`/`shape` — login-only globals that crashed the always-live path on a SYSUPDATE reload, v4.7.88; per-class battlerage rotations incl. `ataxiaBasher_magiBattlerage` which **owns culling**, and `ataxiaBasher_magiShouldBloodboil` — Magi's Bloodboil eq-slot self-cure: 3+ affs while our tree is down, or the Hot Springs boon heal at HP<60), `basher/002_Class_Bashing.lua` (20+ classes; owns the timer-free battlerage rotations for Runewarden (`RW_BR`, v4.7.163 — Bulwark 28r/45s self-mitigation first and NOT target-gated, Etch 25r/23s gated on the denizen carrying aeon/stun since it consumes one — and it was the ONE ability with no fire line, so its in-flight replay had nothing to release it: after a queued etch fired, the next two rebuilds re-queued it and the server rejected both. Captured live 2026-07-30, trigger 375: "You trace the outline of a rune in the air with <weapon>...". Trigger 329 (the BR-rejection line) now ALSO clears every owned rotation's pending hold — a rejected battlerage did not land, so replaying the held pick is exactly wrong, Onslaught 36r/23s, Collide 14r/16s filler; the real pre-existing faults were that bulwark was hidden behind a 2-target gate and etch was never wired at all -- NOT a missing-fire-line bug: collide/onslaught lines exist at 330:47/331:47 with class-agnostic bodies, corrected v4.7.164), Psion (`PSION_BR`, v4.7.128) and Golden Dragon (`GDRAGON_BR`, v4.7.129 — Deaden/Psidaze denizen aeon/amnesia control-first with rage banking) — the cure for classes whose fire lines are missing from triggers 330-332, where `battleRage_Timers` gating means the rotation never unlocks. Both rotations hold their pick PENDING ~3s and replay it verbatim across the basher's 0.3s addclearfull re-queue loop (stamping per rebuild burned the rotation phantom-style — the bloodboil command-stability rule), and both class functions compute the battlerage LAZILY so shielded/raze branches that send no battlerage can't burn a stamp unsent), `basher/005_Falcon_Cooldowns.lua` (Infernal hyena maul + Runewarden falcon rake cooldowns), `basher/007_Mob_Damage_DB.lua` (damage tracking), `basher/008_Denizen_State.lua` (per-denizen combat-state: `ataxiaTemp.denizenState[id]` + `ataxiaBasher_BR_AFFS` affliction model, PvP-inert; read by `ataxiaBasher_blademasterBattlerage` to cash reckless/feared denizens into Headstrike — Stages 1–2 of the overhaul), `genrunning/001-004` (API, targets, enable/disable, main loop)

**Key Config:** `ataxiaBasher.enabled`, `.paused`, `.manual`, `.areabash`, `.targetList[area]`, `.autoLearn`, `.ownDenizens`, `.inMnemosyne`, `.ldeckRules` (mob-name-driven pre-combat draws, `genrunning/002` — useless in Mnemosyne where the roster changes every ripple, hence `.mnemLdeck` below), `.mnemLdeck` (v4.7.165 — `mnem cards`, `basher/010_Mnemosyne_Legend_Deck.lua`: STATE-driven legend-deck auto-draw riding the assembled round. Morimbuul while bound / Maran at `maranAt` 20% hp / Seasone `FOR ELIXIR` at `seasoneAt` 35% / Matic at `maticAt` 3+ denizens, once per room / Covenant (plants recklessness) and Xylthus (plants stun, never on a boss — it cannot bind one) only when `ataxiaBasher_rageAfford` covers the battlerage that actually READS that aff — Blademaster Headstrike + Magi Firefall for recklessness, Runewarden Etch for stun, 25 rage each; any other class draws neither, since planting an aff nothing can spend burns a charge. Economy is the constraint — 2-3 charges regenerating ONE PER HOUR — so: one card per round, a per-card interval >= the effect duration, a hard `ldm.getCharges` check, and a skip when the denizen already carries the aff. Same in-flight replay as the owned rotations (`ataxiaTemp.mnemLdeckPending`, 4s, confirmed by `ldm.onDraw`) because `queue addclearfull` wipes the queued line every prompt. Computed BEFORE the attack gate — Morimbuul answers exactly the bindings that gate closes — and on a gated round goes out alone on the free queue ONCE per pick via `ataxiaBasher_mnemLdeckFree` (`queue add free` ACCUMULATES; an unguarded 0.3s resend would empty the card). The pre-existing global Maran check in `assembleAttack` stands down in Mnemosyne so a 2-charge card isn't double-drawn. **card -> CONFIRMED -> battlerage** (v4.7.166, live-corrected): a card's affliction is recorded on the denizen only in `ataxiaBasher_mnemLdeckConfirm`, so the exploiting battlerage fires on the FOLLOWING round — stamping it at send time was a lie whenever the draw failed, and Etch spent 25 rage on a phantom stun. Confirmation is fed by BOTH the generic charge line ("...may be used N more times...", trigger 001) and `ldm.onDraw`, since the draw-success wording is not uniform. `ldm` charge counts are NOT trustworthy — `initDeck` seeds unseen cards at max, so the game's rejection "A card depicting X currently lacks the power to invoke its stored potential" (trigger `legenddeck_cards/008`) is the ground truth: it zeroes the count, drops the replay and stamps nothing. Cards are also skipped when the payoff battlerage is on cooldown. Xylthus's bind line remains uncaptured, so its stun is recorded from the draw confirmation), `.goldPack`, `.fleeTimeout` (20s), `.shieldTimers`; battlerage: `.cullingBlade`, `.rageraze`, `.rageConserveThreshold`, `.brAlerts` (BR affliction-capture console alerts, default on), `.rageFloor` (v4.7.141 — `bash floor <n|off>`, clamped 46: spend only the SURPLUS above n so threshold gear like "+23% damage at 40+ battlerage" keeps paying; `ataxiaBasher_rageAfford(rage, cost)` gates every rotation, culling reap exempt; nil = off = pre-floor behaviour), `.rageProbe` (v4.7.141 — `bash probe on|report|bands|dump|at <n>|clear|status`, `basher/009_Rage_Probe.lua`: pairs every NON-CRIT damage line with the rage at that moment, keyed by mob+class, to MEASURE a rage-threshold bonus from live play — report gives hi/lo means + ratio with a +/-4 ambiguity band skipped since vitals are last-prompt data; bands view locates the real breakpoint)

**Safety Features:**
- **Attack gate**: Blocks attacks during disabling afflictions (paralysis, aeon, peace, transfixation, webbed, impaled, constricted, deepsleep, entangled, unconsciousness, snared)
- **No-flee areas** (`ataxiaBasher_isNoFleeArea()`): World Tree + Mnemosyne (`inMnemosyne` flag) never flee — shield on damage spike and keep attacking
- **Own denizens** (`ataxiaBasher.ownDenizens` / `bash mine`): pet/ally name keywords excluded from auto-learn and targeting without skipping the room
- **PvP auto-flee**: On `"attacker class detected"` event, disables basher and navigates to Mhaldor (`genrunning/001_Bashing_API.lua`)
- **PvE target switching**: `switchTarget()` skips all PvP state resets when basher is enabled

### Mob Damage Tracking (`mob_damage_db`)

SQLite database tracking non-critical damage per mob, keyed by class + primary stat + mob name. Crit hits are excluded via a flag set in the crit trigger and checked in the damage trigger.

**Key Files:**
| File | Purpose |
|------|---------|
| `basher/007_Mob_Damage_DB.lua` | DB schema, class-stat mapping, record/query/delete |
| `aliases/.../zdata/003_(ataxiaDmg).lua` | `ataxiadmg` alias |
| `triggers/.../334_Crits.lua` | Sets `bashStats.lastHitWasCrit` flag |
| `triggers/.../350_Damage_Dealt.lua` | Records non-crit hits to DB |
| `windows/001_Limb_Counter_Window.lua` | The `tarc` HUD — redesigned bashing panel (v4.7.90/92/94): target name, colored HP/WP/EP, DPS + Session (kills/crits/gold/time) block; renders in Mnemosyne (gated on `ataxiaBasher.enabled`, not a live game target). Mob health bar is anchored at the panel BOTTOM (v4.7.103) and always renders with a numeric target — dim `??` row when no hp reading (denizen-state `hpp` nil/negative AND no live `hpperc`); an always-`??` bar means the server target isn't set. Requires the full chain: IRE.Target module negotiated via `Core.Supports.Add` re-asserted on login/reconnect/reload (`030_GMCP_Consumers`, v4.7.107) + `IRE.Target.Set` GMCP set per basher retarget (`ataxiaBasher_setServerTarget`, v4.7.106) — only then does the server stream `IRE.Target.Info` (`hpperc`) | **Class blocks**: Shaman swiftcurse, Pariah epitaph, and (v4.7.147) **Depthswalker** -- Age (250/400/600 colour thresholds), Word balance ready/spent, and buff chips Blur/Trusad/Tsuura/Mainaas coloured green=up, grey=down, RED=down-while-Flashforward-pays-for-it.

**DB Schema** (`mob_damage_db.hits`): `class`, `stat` (e.g., "str 16"), `mob`, `area`, `min_damage`, `max_damage`, `hit_count`, `when`

**Class-Stat Mapping** (`ataxia.data.classPrimaryStat`): Maps each class to its primary bashing stat (str/dex/int). Multi-stat classes (Monk, Psion, Dragon) use highest priority stat.

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
| `gearaudit scrap` | Scrap recommendations + copy-paste GEAR SCRAP commands |
| `gearaudit scrap <set>` | Scrap recommendations for a specific set |
| `gearaudit save/load` | Manual save/load |

**BiS Scoring Weights** (configurable via `gearAudit.config.bisWeights`):
| Stat | Weight | Priority |
|------|--------|----------|
| Additional Damage % | 10.0 | Highest |
| Celerity | 8.0 | Very High |
| Burst Damage (normalized) | 7.0 | High |
| Ignore Denizen Resistance | 6.0 | High |
| HP Increase | 3.0 | Moderate |
| HP Regen | 2.5 | Moderate |
| Damage Reduction | 2.0 | Low |
| Resistance | 1.5 | Low |
| WP Regen / Blackout Reduction | 1.0 | Lowest |

Conditional gear (location-locked) discounted 50%; battlerage-conditional 30%.
Burst damage normalized to per-attack value: `effectivePct = burstPct / (cooldown / 3)`.
Scrap threshold: items scoring below 50% of set BiS (`gearAudit.config.scrapThreshold`).

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

**Flow:** `GO!` → capture the mob spawn line (the line directly above `GO!`, positional — spawn wording varies per mob) → auto `WADE STATUS` → `/ripple_level`, `/boss` (from the `Objective: defeat <boss>` line), `/effects`; buffered monsters flush after `/ripple_level`. Serial queue enforces ordering (ripple_level first; boons_offered before boons_selected). `_auto()` gates run-start/GO/ripple; `_inRun()` gates monsters/effects/boons/boss/death so generic phrases can't report outside a tracked run. **`/boons_offered` posts IMMEDIATELY** with the offer-screen name+description (v4.7.91) — it is no longer gated behind the slow per-boon `BOON CONTEMPLATE` enrichment chain, which raced the next ripple's captures for the single `_capturing` slot and, on a lost race, stalled and silently dropped the entire boon report (rarity/echoes are still learned locally). The line-capture (`_captureLines`) **force-finishes** a wedged prior capture rather than dropping the new one (v4.7.93). **Pause/resume (v4.7.88):** `WHISPER … beseech that it grow still` pauses the run without ending it server-side; the next wade **resumes via `/run_exists`** (no new `/run_start`), and `M.run.paused` is cleared unconditionally on a confirmed run-end.

**Commands:** `mnem status|token <t>|on|off|contemplate|debug|quiet [on|off]|test|start|end|check|ripple <n>|boss <name>|monsters <text>|death [killer]|map [on|off|status]|boons|affixes|library|explore [on|off|status]|cards [on|off|maran <hp%>|seasone <hp%>|matic <n>]`. Also `ataxia setup reporting`.

**Persistence:** `ataxia.settings.reporting` (`enabled`, `contemplate`, `token`, `url`, `mapEnabled`, `quiet`) — saved inside the main `ataxia` file / `_ataxia_backup.ataxia`. Run state is in-memory (re-synced via `/run_exists` on load). The **local history** (`ataxia.mnemosyne.history`) is the one thing on its own disk file, `<profile>/mnemosyne_history.lua`.

**Run end:** `/run_end` fires on `"The Mnemosyne releases its hold, weaving N shimmering threads into your possession."` — but only after a **confirmation** (`onRunEndMaybe` waits ~2s for `"You just received message #N from Achaea."`), because that reward line also prints on a mid-run message re-read. The Mnemosyne boon flags (`bardWarmarch` / `bmShatteredStar` / `magiKkractle` / `magiHotSprings` / `mnemHammerAnvil` / `bmBladedReflexes` / `mnemSleuth` / `mnemRollHide` / `mnemReaper` / `mnemBloodscent` / `mnemKaiUnleashed` / `mnemSenselessFlurry` / `psionPanoply` / `dragonMightSycaerunax` / `dragonRampage` / `dwFlashforward` / `infArmyOfDead` / `infDaemonJaws` / `infIndiscriminate` / `infNecroticAura` / `infFuryOfAges` / `mnemWintersHeart` / `mnemResourceful` / `mnemFalconersTactics` / `mnemHomebound` / `mnemHammerAndNail` — Hammer and Anvil is class-agnostic: attacks bypass denizen shields, so `336_Mob_Shielded` skips the raze path AND the shield-swap while it's up; Bladed Reflexes makes the BM basher keep `SHIN AUGMENT <n>` up (spend `ataxiaBasher.bmAugmentAmount`, default 3 — a 1-shin augment dissipates in ~12ms per live log) — 20% DR while the `bodyaugment` defence holds; Sleuth arms the swarm module's fullsense-on-GO recon; Roll Hide arms the swarm panic tumble; Kai Unleashed makes the Shikudo basher PREPEND `KAI CHOKE <target>` to the round's combo in RAIN form when 2+ denizens share the room (the boon bursts magic damage on ALL of them — live captures 8472 → **25560 + 17931** magical (it SCALES, likely with the Reaper stack/coalescence empowerment; one burst killed the primary outright); per AB Kaichoke the ability spends 4s of EQUILIBRIUM — idle during balance combos, so both land — and against a DENIZEN consumes NO kai, only 50 mana, hence a 250-mana floor instead of a kai gate; the 30s cooldown starts from the CONFIRMED burst line "Your surroundings ripple like a lake's surface struck..." via trigger 031 → `ataxiaBasher_kaiUnleashedBurst` into `ataxiaTemp.kaiUnleashedAt`, with a 6s retry guard (`kaiChokePendingAt`) so an eaten choke re-fires instead of locking the burst out; shield-break rounds skip it — `ataxiaBasher_kaiUnleashedChoke`, basher/002); Senseless Flurry (balance 30% faster while the numbness defence is up) makes the Shikudo basher keep `NUMB` up in Rain form (AB Numbness 894: self-only, 3s eq, defers damage −40% into one later blow; defence-gated on GMCP `ataxia.defences.numbness` + 5s attempt-hold, fires even on shielded rounds; ONE eq spender per round — the choke outranks the numb refresh; **CROWD-GATED** (review HIGH): numb pins HP while damage defers, blinding the rate watchdog/danger levels/escape ladder until the lump lands as one −40% blow — so never numb at >= the swarm threshold or while a swarm tactic runs — `ataxiaBasher_senselessFlurryNumb`); Panoply makes the Psion basher swap `weave deathblow` → `weave flurry` (AB Flurry 2704: 2.6s balance; the boon scales its damage 60–200% per strike landed — straight verb swap, cleave keeps shield-break, psi shatter keeps the transcendence slot — `ataxiaBasher_psionBashing`); Might of Sycaerunax (dragon: BLAST +25% damage AND the breath weapon PERSISTS through use — AB Blast: 4s eq, strips shield/lyre, "Requires summoned breath") makes `ataxiaBasher_dragonBashing` drop the `;summon <ele>` from both the blast weave and the shielded reblast while it's up (trigger 035 + claim intercept; breath-down still summons once); Draconic Rampage (dragon: TRAMPLE — AB 1564, room, 2.75s balance — deals a large cutting nuke to ALL denizens on a 40s proc) makes the dragon basher spend the balance swing on `trample` at 2+ denizens (Mnemosyne `_denizenCount`, the Kai Choke gate) whenever the proc is ready — send-side 40s stamp + the v4.7.129 in-flight hold, shield-break rounds skip it, the eq blast weave still rides beside it (`ataxiaBasher_dragonRampagePick`, trigger 036 + claim intercept); Flashforward (Depthswalker: +20% damage while the `chrono blur` defence is up) makes the DW basher keep CHRONO BLUR up as an EQUILIBRIUM rider paid in AGE (not the word balance, so it never competes with nakail/the Terminus buffs) -- defence-gated on GMCP `blur`, 8s attempt-hold, capped by `ataxiaBasher.dwAgeCap` (400) so bashing cannot price out the chrono kit, and it rides shielded rounds too (`ataxiaBasher_dwFlashforward`, trigger 038 + claim intercept); Army of the Dead (Infernal: `summon hands of the grave` also damages every denizen in the room) makes the Infernal basher cast it at 2+ denizens ahead of the swing, on a provisional 20s stamp since the real cooldown is uncaptured (`ataxiaBasher_infGravehands`, trigger 039); Daemon Jaws (hyena maul cooldown -66%) shrinks the maul SAFETY timer 30s -> ~10.2s -- the game already sends its ready-line sooner, but basher/005 previously had NO backstop at all, so a missed line stranded the maul forever (trigger 040); Indiscriminate (ARC becomes denizen-effective) makes the Infernal basher swing the UNTARGETED room-wide `arc` INSTEAD of its single-target attack at 2+ denizens — arc spends 4.75s of balance vs a ~2s dsl, so the crowd gate is what makes it pay (`ataxiaBasher_infArc`, `infArcAt`, trigger 041); Necrotic Aura (attacks inhibit denizen healing while the DEATHAURA defence is up) makes the Infernal basher keep that defence raised — defence-gated, 10s attempt-hold, prefixed to every round incl. shielded (`ataxiaBasher_infDeathaura`, trigger 042), and its proc line records `inhibit` on the denizen (trigger `denizen_attacks_misc_lines/024`, the same state Monk Ripplestrike applies); Fury of Ages (FURY becomes near-permanent: +8 strength and 20% faster balance for 45 of every 60 minutes, but QUADRUPLED endurance) makes the Infernal basher hold `fury on` while EP >= 60% and drop it under 25%, with a 30s floor between toggles since each activation may cost 500 willpower, and a run-end `fury off` so it never drains EP after the boon expires (`ataxiaBasher_infFury`, trigger 043); Winter's Heart (DEEPFREEZE works on denizens and deals cold to ALL of them in the room) casts it at 2+ denizens — class-agnostic on purpose, since the Bracers of Frost grant deepfreeze outside Elementalism, and it is an EQUILIBRIUM cast so it rides FREE beside a balance swing while taking the eq slot for Magi (`ataxiaBasher_winterDeepfreeze`, `deepfreezeAt`, trigger 044); Resourceful (-10% endurance/willpower costs; each denizen kill restores 10% of the CLASS RESOURCE — life essence for Infernal) held together with Army of the Dead makes Tyranny effectively free, so its crowd gate drops to 1 denizen (gravehands in every occupied room) and its essence floor 20% → 10% (trigger 045); Falconer's Tactics (falcon rake cd -66%, the Runewarden twin of Daemon Jaws) shrinks the missed-line safety timer 30s → ~10.2s (trigger 046); Homebound (returning to your raido cures + full-heals, but not in the same location) makes the explorer `sketch raido on ground` in the HOLDING room right before the descent, once per ripple (trigger 047); Hammer and NAIL — **not** Anvil — (attacks splash to a second denizen while a sowulu rune is present) makes the Runewarden basher `sketch sowulu on ground` at 2+ denizens, once per room, on the free queue so it costs no balance (`ataxiaBasher_rwSowulu`, `sowuluAt`, trigger 048); Bloodscent auto-recons every ripple entry ("You sense <mob> (#id) at <room>." per denizen — trigger 028 parses the rows into `swarm.recon` with per-room counts and a crowded-room callout, the parsed format Sleuth's raw capture waited for); Reaper (legendary, +1% damage per denizen kill for the run) is COUNTED — the per-kill tithe line ("You reap a tithe of power from your fallen foe.", trigger 023, its own proof of the boon) increments `ataxiaTemp.reaperKills` (survives SYSUPDATE reload) and echoes the running "+N% damage total") are cleared only on the confirmed end (and reset on run start). **Boss tactics** live beside the affix safeties in 004_Parsers: `reserveTreeForBoss` (`TREE_RESERVE_BOSSES`, extensible) holds `curing tree off` from a reserve-boss's `Objective:` line; the instant Seasone's phial truelock lands (trigger 032) the counter **touches tree DIRECTLY** (v4.7.138 — bounded 3/6/10s re-touches while asthma+anorexia persist; reserve-independent, since a missed Objective line once made the burst a no-op and `curing tree on` alone left SSC too slow to tree out of a 25s+ lock) and releases the reserve when armed — telemetry-independent like Splinterbark, whose taint always wins (never touch a tainted tree); released on ripple change/run end. `startRun` also self-recovers: its `onError` resets `run.active` if `/run_start` 500s or times out. All events auto-report; manual `mnem` overrides remain.

**Ripple mini-map (`ataxia.mnemosyne.map`, files 005/006):** draggable per-ripple grid widget (`Adjustable.Container`, position auto-persists). Builds a room graph from `gmcp.Room` arrivals in Mnemosyne. **Coordinates come from `MAP.relayout()`** — on every arrival it rebuilds a bidirectional adjacency from all rooms' known exits (`dir → neighbour-num`, coerced with `tonumber`; gmcp reports them as strings and `0` for unknown dests) and BFS-assigns coordinates from the origin. Re-deriving from the full accumulated graph each step is what makes it robust: a room unplaceable on arrival is placed on a later pass once either side of a link is known (per-arrival placement couldn't bootstrap). Anchored on the origin, falling back to the current room so it's always shown. Walked edges (for click-to-walk `MAP.path` BFS → `queue add free`) are recorded separately. Render (006) draws a **fixed 4×4 grid** (every ripple is a 4×4): visited rooms coloured (current green, un-walked-exit gold `?`, else grey), unvisited positions as dim placeholders. Wipes each ripple and re-seeds the current room from `gmcp.Room.Info` (`onRipple → MAP.onRipple`). Toggle `mnem map on|off` (`ataxia.settings.reporting.mapEnabled`, default on); `mnem map status` prints diagnostics incl. per-exit state. GUI (006) needs Geyser/`main` so it's not unit-tested; the pure graph in 005 is (`test_mnemosyne.lua`).

**Local history (`ataxia.mnemosyne.history`, file 007):** a persisted local mirror of what each run parses — `offers`/`claims`/`affixes` per run plus an all-time `library` of affixes — recorded at the parser hooks (`_recordOffers`/`_recordClaim`/`_recordAffixes`) whenever a tracked run is on. `mnem boons` / `mnem affixes` / `mnem library` review this run's claims, its affixes, and the catalogue; `mnem quiet` silences the auto per-claim/affix echoes (still records). Bootstrapped runs (missed start line) get their own bucket via `onRipple` bumping the counter. Persistence (`table.save`/`load` to `mnemosyne_history.lua`) is guarded so a bare/test env never errors.

**Swarm tactics (`ataxia.mnemosyne.swarm`, file 009, v4.7.111-120):** deep ripples pack 3-4+ ROAMING denizens per room (they move between rooms; cleared rooms can repopulate). The explorer delegates every decidable tick to `swarm.onTick()` (consumed tick = no navigation). At `>= threshold` killable mobs (`mnem swarm assess <n>`, default 3; `mnem swarm deep <r> <n>` depth-scales) with a VALIDATED back-route (planar + adjacency vs the reported-exit graph — never "up" out of the first grid room), the pull fires: a one-shot decorator (`ataxiaTemp.swarmPullDir`, consumed in `ataxiaBasher_assembleAttack`) turns the next attack into `"<attack>;<backdir>"` — swing + step-out as ONE queued line (the manual ragepull shape). Consumption arms `ataxiaTemp.swarmHold` (gates BOTH `ataxiaBasher_attack` — several triggers call it directly — and `ataxiaBasher_tryAttack`; 8s self-clear matched to the pull's tactical timeout + load-time clear — it would otherwise survive SYSUPDATE and silently kill the basher), clears `found_target`, kills `mobshieldtimer`. Funnel: fight followers where we chose the ground; 2s window refreshed by combat (v4.7.157, 4 -> 3 -> 2: chasers arrive quickly, so a longer wait only idles on mobs that were never coming; combat refreshes the window, so a real fight still holds us there); empty window → re-enter and re-assess; `MAX_PULLS=3`/room then fight in place — but **progress REFUNDS the budget** (v4.7.117, Putoran-wildcat log: non-chasing mobs make every cycle a free swing): each pull snapshots count + focused-target hp (`entrySnap`, HUD mob-bar data chain), and a re-entry with fewer denizens or the same target chipped lower resets pulls to 0 — hit-and-run continues until the room is cleared or below threshold; only unproductive cycles (mobs regen while we funnel — "tending his wounds") spend budget. **Tactical moves NEVER write `explore.failed`** (`M._tacticalArm` + `explore.tacticalMove` guards all three condemn paths). Resets: boon screen, `_exploreStop`, `basher disabled`, sysLoad (flight landed on every reset). LIVE branches: indoors icewall+leap (first escape suffix `;point bracers417868 <LONG back>;leap <back>` one queue entry; the wall then STAYS — v4.7.119: re-entry is a single eq-gated `leap <fwd>`, follow-up escapes go leap-only via `S.wallRaised[room]` (a balance-round faster), and the wall is melted via `bracers151113` only when the room empties, on a consumed tick so the explorer's own queued move can't wipe the melt — an intact wall silently fails normal walks and would condemn the backtrack edge), outdoors fly-kite (`land;<attack>;fly` wrap while `swarm.flying`; lands below threshold; FLY-needs-balance degrades to grounded, never wedges), Roll Hide panic-tumble (`swarm.panic`, `panicAt`% default 40, non-swarm exit, 10s cooldown; lands first mid-kite, free-queued + hold-protected so the next attack's addclearfull can't wipe it — v4.7.112-113). **Low-HP escape ladder** (v4.7.114-115, `swarm.escape` on, `escapeAt` 35%, HP-gated ONLY — a 2-mob chip-down killed below the swarm threshold, and shield-in-place fails with broken arms): outdoors → fly + hover (state `recovering`, attacks hold-gated, 60s cap) landing only FULLY healed (`recoverAt` 95% AND aff-free; kept defences blindness/deafness/curseward/insomnia never hold it); indoors → plain retreat to the cleared room; no route → shield fallback; SLC bothArmsFlee is inert in the tower; **landing SETTLES, never decides** (v4.7.125 live catch: airborne gmcp Char.Items reflects the SKY so denizensHere is empty — the landing tick is consumed and the arrival settle window opened, else the explorer reads a mob-filled ground room as "clear" and walks out on touchdown). Ladder live-validated end-to-end 2026-07-27 (19% → fly → hover-heal to 99% → land → resume; Blazing affix smokes hovering flyers ~511 asphyx/5s but the hover out-heals it). **Live-validated** (2026-07-26): icewall chain drains across balance (point) + eq (leap), ~7s, inside the 8s hold; **denizens WALK THROUGH icewalls without Maklak's Promise** (wall = pacing, not barrier); kite fly line = the ring of flying. **Emergency hardening after the Pinnacle death** (v4.7.116 — 3 angelic razers + a roamed-in inquisitor, ~3k HP/s incoming, razer psychic applies STUPIDITY which EATS queued commands): (1) `S.onVitals` on `gmcp.Char.Vitals` runs the panic/escape gates EVERY prompt (fresh gmcp read, hp<=0 = blackout-unknown, 2s cooldown, acts even mid-pull via `M._disarmMove()` — the tick path is event-starved in a stationary fight and its one look landed on a potash bounce); (2) a lost pull move RESTORES the route anchor from `S.funnelRoom`/`S.fwdShort` and re-pulls (was: `_tacticalArm`'s fromRoom clobber → "no valid pull route" → permanent noTactics latch); (3) `S.flightConfirmed` fed by trigger 022_Flight_Lines — the hover re-sends fly each 2s tick until the up-line confirms (an eaten fly = grounded-but-gated); (4) hovers self-tick from birth. **Wall-leap navigation** (v4.7.119, user-directed): "A wall blocks your way." / "A wall bars your path." during ANY in-flight explorer move → trigger 025 → `M.onWallBlocked()` replaces the walk with `stand;leap <dir>` — never condemns (real exit), shares the ice-slip budget; ALL swarm tactical moves also leap (`_tacticalGo` — a plain walk into our own wall livelocked the escape ladder, review CRITICAL); the melt is hold-armed, cleared only on the melt-confirm line (trigger 026 → `onWallMelted`), re-sent while unconfirmed, capped at 4 tries; wall memory survives mid-ripple `mnem explore off/on` (wiped only on genuine ripple change) and the panic tumble avoids the walled edge; legacy `766_Wall` manual branches are gated off during explore. **Deluge affix** (v4.7.140, trigger 037 → `onDelugeSeen`, same shape): "All rooms are underwater" makes FLY impossible — `S._canFly()` gates the escape ladder's outdoor fly+hover (falls through to the grounded retreat / shield fallback) and the fly-kite entry, so neither wedges on a silently-rejected queued fly. **Haemophiliac affix pacing** (v4.7.119-120, trigger 029 → `onHaemophiliacSeen`, Splinterbark's telemetry-independent shape): kills bleed THOUSANDS + mana costs +20% — post-clear navigation holds until the bleed is CLOTTED (`ataxia.vitals.bleed < 50`; SSC `curing clotat 30` does the clotting) AND `hpp >= 90` (`M._haemoHold`, missing reading = 0 so it never wedges). The dmap standalone package mirrors the pull/funnel core (`dmap swarm <n|off>`, default off — no basher there, so the funnel waits on the user/attack-hook). Recon: **Bloodscent** (boon) auto-senses every denizen per ripple entry — trigger 028 parses `You sense <mob> (#id) at <room>.` rows into `swarm.recon` ({name,id,room} + per-room counts + crowded-room callout echo); Sleuth's `mnemSleuth` → fullsense on GO (raw capture; same-shape rows feed the parser); `mnem sense` manual. Tests `test_swarm_tactics.lua`. Full doc: `.claude/projects/mnemosyne/07-explorer.md` swarm section.

**Auto-explorer (`ataxia.mnemosyne.explore`, file 008):** `mnem explore on` auto-sweeps the ripple's 4×4 — it drives the **basher in manual mode** (combat + no-flee, never mapper-moving) and handles *navigation* itself: room clear (`ataxia.denizensHere` empty) → step through a usable unexplored exit or backtrack via `MAP.path` to the nearest room with one, moving with `queue addclear free stand;<dir>` (stands first — you're often prone post-fight). `usableUnexplored` keeps **planar** unwalked exits, plus **only `down`** from a room with no planar exit at all — the entry **holding room's `down`** into the grid. `up`/`in`/`out` are never used (there is no `up` in Mnemosyne), and a 4×4 room's deeper `down` isn't taken. Event-driven (`gmcp.Room` + `"targets updated"` → debounced tick, `moving` guard); it echoes each step (`room clear → moving <dir>`) and once per room `clearing this room (N denizen(s))`. When the grid is fully swept it does **not** stop — on a **boss ripple** (every 5th) the boss spawns at the end in any already-cleared room, so it **patrols** (`_nextPatrolStep`, round-robin re-visit) to find + kill it, capped at `MAX_PATROL_LOOPS` fruitless loops. **Pauses** at the boon screen (`onBoonScreen` — sets `explore.pausedAtBoon`, halts navigation but **keeps the basher on** in explore mode; **auto-resumes on `GO!`** via `exploreOnGo` — a `look` to lock in the holding room's `down` exit, then `_exploreResume()` — or `mnem explore on` manually). It **stops** (restoring the saved basher state) on leaving Mnemosyne (strict `ataxiaBasher.inMnemosyne`, still detected during the pause), on `mnem explore off`, or the patrol cap. Safety: start-guard (`area==""`), stall watchdog, basher save/restore, `sysLoadEvent` reset, and **ice handling** — icy rooms print "You slip and fall on the ice as you try to leave" (move fails, but the exit is fine), so trigger `011_Ice_Slip.lua` → `onIceSlip` re-sends the move (no failed-exit charge) until you leave, capped at `MAX_ICE_SLIPS`. Pure logic (`_nextExploreStep`/`_roomHasDenizens`) is unit-tested; the timer/event machine is validated in-game.

### Data Persistence & Profile Backup

All system state is saved to disk files in `getMudletHomeDir()` via `table.save()`/`table.load()`. A profile backup system provides redundancy by also storing data in the `_ataxia_backup` global (Mudlet saved variable).

**Save flow**: Every save rotates a `.bak`, writes to disk, AND copies into `_ataxia_backup`. `ataxia` is
passed through `sanitizeForSave()` first — it strips **live GUI/runtime objects** (Geyser windows, Mudlet
`db` proxies) so they never hit disk. Detection is `getmetatable`/`rawget` only — **never index
`.hide`/`.show`** (a `db` proxy's `__index` errors "access sheet 'hide'"). This matters because GUI objects
are — as a known TODO — stored under the saved `ataxia` namespace (`ataxia.mnemosyne.map.window`,
`ataxia.data.hunter.window`, vital bars, chat).

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

**Namespace:** `selfLimbDamage` (global). **Alias:** `slc`. **Files:** `self_limb_tracking/002-005`, `triggers/.../highlighting/027_Parry_Success.lua`, `aliases/.../slc/005_SLC_Toggle.lua`. PvE predictive layer (005, v4.7.109): `selfLimbDamage.denizenPatterns[name]` holds fixed swing cycles (e.g. the Mnemosyne axe-wielding revenant: right leg x2 → left leg x2 → torso x2) or, since v4.7.111, `{ fixed = "<limb>" }` for mobs with exactly one parryable attack (a steel-encased Death Knight = left leg, a ravager of the Infernal Legion = torso); `ataxia_denizenParryPredict()` parries the NEXT swing's limb, including the cycle opener before the first hit lands. Lives inside the **`bashing` parry mode** (v4.7.110), which auto-engages on `basher enabled` (saving the prior mode) and restores on `basher disabled` — ladder: pattern/fixed prediction → focus-follow (`lasthit`, 12s-fresh via `lasthitAt`, fed by perceive lines AND confirmed parries through `ataxia_parrySuccess`) → head default (head → right leg → left leg → torso); `manual` never hijacked, opt-out `slc bashparry off`. The parry-success line ("You parry the assault to your <limb> with a deft maneouvre." — game spells it "eo"; trigger tolerates both spellings) is highlighted bold spring_green and feeds the tracker; parried swings emit no perceive line, so without that feed the system went blind exactly while the parry worked.

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

**Last Updated**: 2026-07-27
**Project Lead**: Michael
**Development Environment**: VS Code + Mudlet + Claude Code
**Reference Systems**: Orion, Ataxia
