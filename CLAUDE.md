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
│   ├── AGENTS.md           # Agent instructions for AI development
│   └── classes/            # 26 class files + lock_types.md
├── docs/
│   ├── plans/              # Project plans and reviews
│   ├── legend-deck.md      # Legend Deck card reference
│   └── artefacts-reference.md
├── src_new/                # Canonical source (YAML-header Lua files)
│   ├── aliases/            # Alias definitions
│   ├── keys/               # Key bindings
│   ├── scripts/            # Lua script modules (combat, basher, GUI, NDB, etc.)
│   ├── timers/             # Timer definitions
│   └── triggers/           # Trigger definitions
├── muddler_project/        # Muddler build project for Levi_Ataxia (generated)
│   ├── mfile               # Package metadata JSON
│   └── src/
│       ├── aliases/Levi_Ataxia/   # aliases.json + *.lua
│       ├── keys/Levi_Ataxia/      # keys.json + *.lua
│       ├── scripts/Levi_Ataxia/   # scripts.json + *.lua
│       ├── timers/Levi_Ataxia/    # timers.json + *.lua
│       ├── triggers/Levi_Ataxia/  # triggers.json + *.lua
│       └── resources/             # Static resources
├── my_package_project/     # Muddler build project for custom packages
├── levi_test_project/      # Muddler build project for Levi_Test
├── tools/
│   ├── convert_to_muddler.py  # Convert src_new → muddler project (multi-package)
│   ├── compare_builds.py      # Compare old XML vs Muddler output
│   ├── mudlet_extract.py      # Extract XML package to src_new
│   └── legacy/                # Retired build tools
│       ├── mudlet_build.py    # Old Python XML builder
│       └── mudlet_validate.py # Old validation script
├── packages/               # Compiled Mudlet packages
├── .vs/
│   └── tasks.vs.json       # VS2022 Open Folder build tasks
├── CLAUDE.md               # This file
├── GETTING_STARTED.md      # Setup and usage guide
└── README.md               # Project overview
```

### Build System (Muddler)

The project uses [Muddler](https://github.com/demonnic/muddler) to build Mudlet packages. The build pipeline is:

1. **Edit** source files in `src_new/` (YAML-header Lua format)
2. **Convert** to Muddler format: `python tools/convert_to_muddler.py --src ./src_new --output ./muddler_project`
3. **Build** with Muddler (from `muddler_project/` directory):
   ```bash
   set JAVA_HOME=E:\Java
   cd muddler_project
   E:\muddle-shadow-1.1.0\muddle-shadow-1.1.0\bin\muddle.bat
   ```
4. **Output**: `muddler_project/build/Levi_Ataxia.mpackage` and `.xml`

**Requirements**: Java 8+ (`E:\Java`), Muddler (`E:\muddle-shadow-1.1.0\muddle-shadow-1.1.0\`).

**Conversion script** (`tools/convert_to_muddler.py`):
- Strips YAML headers from Lua files, outputs pure Lua
- Builds nested JSON hierarchy from `_groups.yaml` files
- Handles name collisions by prepending parent group names
- Preserves group inline scripts
- Converts pattern types, timer formats, key codes
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

### Visual Studio 2022

Use **File > Open > Folder** and select the `LEVI-Achaea/` directory. VS2022 shows all files in the folder tree. Build tasks are in `.vs/tasks.vs.json` — right-click the root folder in Solution Explorer to run them:

- **Build Levi_Ataxia** — Full convert + Muddler pipeline
- **Build Levi_Test** — Build the test/distribution package
- **Convert Only** — Just the conversion step, no Muddler
- **Convert Only (Dry Run)** — Preview without writing
- **Clean Build Output** — Remove `muddler_project/build/`

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
| **apostate** | 2 (015+014) | **Documented** | Lock, corrupt, vivisect, sleep | `apostate/` |
| **bard** | 10 | Undocumented | Voicecraft, affliction | `bard/` |
| **blademaster** | ~10 | **Documented** | Lightning/Ice, Brokenstar | `blademaster/` |
| **depthswalker** | 1 | Undocumented | Shadow/time | `depthswalker/` |
| **dwb** | 1 | Undocumented | Breakpoint/rift | `dwb/` |
| **dwb_runie** | 1 | Undocumented | DWB + runelore | `dwb_runie/` |
| **dwc** | 3 | **Documented** | Vivisect, damage kill | `dwc/` |
| **dwc_runie** | 1 | Undocumented | DWC + runelore | `dwc_runie/` |
| **earth_lord** | 5 | Undocumented | Limb targeting | `earth_lord/` |
| **i_snb** | 1 | Undocumented | Infernal SnB | `i_snb/` |
| **mage** | 1 | Undocumented | Elemental | `mage/` |
| **pariah** | 1 | Undocumented | Plague/swarm | `pariah/` |
| **psion** | 1 | Undocumented | Mental stack | `psion/` |
| **s_n_b** | 1 | Undocumented | Sword and Board | `s_n_b/` |
| **shaman** | 27 | Undocumented | Tzantza, locks | `shaman/` |
| **shikudo** | ~5 | **Documented** | V1/V2/Lock | `shikudo/` |
| **tekura** | ~3 | Undocumented | Monk unarmed | `tekura/` |
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
- **Target Affliction Tracking**: Dual system for tracking enemy afflictions (see below)
- **Limb Tracking**: `selfLimbDamage` for damage percentages, `tLimbs` for enemy tracking
- **Fracture Management**: Two-handed combat tracking
- **Defense Management**: Automatic parrying, SSC integration
- **Basher**: `ataxiaBasher` for automated hunting (see details below)
- **Class Modules**: Pariah, Bard, Monk, Magi, Two-Handed, Infernal DWC
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

### Target Affliction Tracking System

The system uses a **dual-layer approach** for tracking afflictions applied to enemies:

**Core Files:**
- `src_new/scripts/levi_ataxia/levi/ataxia/017_Affliction_Management.lua` - Main tracking functions
- `src_new/triggers/levi_ataxia/for_levi/leviticus/439_NEW_DEADEYES.lua` - Apostate curse detection

**Dual System Design:**

| Layer | Table | Purpose |
|-------|-------|---------|
| **Core Tracking** | `tAffs` | Always tracks afflictions unconditionally (boolean) |
| **Confidence Tracking** | `tAffConfidence` | Optional enhancement with confidence levels (0.0-1.0) |

**Core Functions:**

| Function | Purpose |
|----------|---------|
| `tarAffed(...)` | Add afflictions to target (variadic - accepts multiple) |
| `tarAffedConfirmed(...)` | Add afflictions with 1.0 confidence (confirmed by game message) |
| `erAff(what)` | Remove affliction from target tracking |
| `haveAff(what)` | Check if target has affliction (core tracking) |
| `haveAffWithConfidence(aff, minConf)` | Check with minimum confidence threshold |
| `getAffConfidence(aff)` | Get current confidence level for affliction |
| `resetAffConfidence()` | Clear all confidence values (called on target change) |

**Confidence Levels:**

| Level | Value | Meaning |
|-------|-------|---------|
| Confirmed | 1.0 | Saw game confirmation message |
| Assumed | 0.7 | Assumed from venom/attack landing |
| Threshold | 0.3 | Below this, affliction considered cured |

**How It Works:**
1. Core tracking (`tAffs[aff] = true`) happens unconditionally when attacks land
2. Confidence tracking is an optional enhancement layer that doesn't affect core tracking
3. When enemy cures, `erAff()` clears both the core tracking and confidence
4. Combat logic can use either `haveAff()` (simple) or `haveAffWithConfidence()` (advanced)

**Example Usage:**
```lua
-- Simple check (core tracking)
if haveAff("paralysis") then
  -- Target has paralysis
end

-- Advanced check (confidence-based)
if haveAffWithConfidence("paralysis", 0.5) then
  -- Target probably has paralysis (50%+ confidence)
end
```

### Target Affliction Tracking V2 System

**NEW**: Advanced affliction tracking with certainty levels, stack tracking, and AK-inspired cure detection.

**Full Documentation:** `.claude/projects/affliction-tracking-v2/`

**Toggle:**
```lua
ataxia.settings.useAffTrackingV2 = true   -- Enable V2
ataxia.settings.useAffTrackingV2 = false  -- Disable, use old system (default)
```

**Key Features:**
- Certainty-based tracking (0/1/2+ levels with stacking support)
- Verifiability-based priority (unverifiable affs assumed cured first)
- Random cure counter (tracks tree/focus/passive cures like AK's `ak.randomaffs`)
- Backtracking system (reverses incorrect guesses)
- Third-party verification (fumble confirms clumsiness, smoke confirms no asthma)

**V2 Functions:**

| Function | Purpose |
|----------|---------|
| `confirmAffV2(aff)` | Set certainty to 2 (confirmed) |
| `removeAffV2(aff)` | Set certainty to 0 (cured) |
| `haveAffV2(aff)` | Check if certainty >= 1 |
| `stackAffV2(aff)` | Add a stack (+2 certainty) |
| `getStackCountV2(aff)` | Get number of stacks |
| `onTargetTreeV2(target)` | Handle tree tattoo cure |
| `onTargetFocusV2(target)` | Handle focus cure |

**V2 Files:**
```
src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_v2/
├── 001_Core.lua           # Certainty + stack + random cure tracking
├── 002_Herb_Cures.lua     # Priority lists for all 7 herbs
├── 003_Backtracking.lua   # Guess storage and reversal
└── 004_Verification.lua   # Fumble/smoke signal handlers
```

**Integrated Triggers:**
- 15 herb triggers → `targetAteWrapper()`
- Tree trigger → `onTargetTreeV2()`
- Focus triggers → `onTargetFocusV2()`
- 16 class cure triggers → `removeAffV2()` / `reduceRandomAffCertaintyV2()`

**Verification Commands:**
```lua
-- Check if V2 is enabled
lua ataxia.settings.useAffTrackingV2

-- View V2 state with stack counts
debugAffsV2()

-- View raw V2 table
lua tAffsV2

-- Check random cure counter
lua randomCuresV2

-- Compare V2 to old system
lua print("V2:", tAffsV2.asthma, "Old:", tAffs.asthma)
```

**Offense System Requirements:**
When coding offense systems, check `ataxia.settings.useAffTrackingV2`:
- If enabled: Use `haveAffV2(aff)` and `haveConfirmedAffV2(aff)` for affliction checks
- If disabled: Fall back to `haveAff(aff)` (old system)
- For stacking afflictions: Use `getStackCountV2(aff)` to check multiple stacks
- For lock detection: Use `haveAffV2()` which returns true for certainty >= 1 (likely or confirmed)

**Class Cure Integrations (16 triggers):**
| Trigger | Class | V2 Function |
|---------|-------|-------------|
| Passives | All | `removeAffV2("voyria")` or `reduceRandomAffCertaintyV2()` |
| Accelerate | Depthswalker | `removeAffV2()` + 1-2x `reduceRandomAffCertaintyV2()` |
| Alleviate | Blademaster | `removeAffV2("paralysis")` + `reduceRandomAffCertaintyV2()` |
| Dragonheal | Dragon | `removeAffV2()` + 3x `reduceRandomAffCertaintyV2()` |
| Fitness | Knights/Monk/BM | `removeAffV2("asthma")` + `removeAffV2("weariness")` |
| Phoenix | Blademaster | `resetAffsV2()` (full reset) |

### ataxiaBasher (Automated Hunting System)

The basher provides automated target selection and attack execution for PvE hunting. It supports 20+ classes, two operating modes (manual/areabash), and integrates with the mapper, GMCP, battlerage, and GUI systems.

**Core Files:**
| File | Purpose |
|------|---------|
| `src_new/scripts/.../basher/001_Bashing_Functions.lua` | Attack dispatch, flee logic, emergency checks, battlerage assembly |
| `src_new/scripts/.../basher/002_Class_Bashing.lua` | Class-specific attack builders (20+ classes) |
| `src_new/scripts/.../basher/003_Bash_Stats_Functions.lua` | Session statistics |
| `src_new/scripts/.../genrunning/001_Bashing_API.lua` | Path generation, room scanning, death recovery, flee timeout, mapper-stuck detection |
| `src_new/scripts/.../genrunning/002_search_targets.lua` | Target selection, stormhammer caching, shield retarget, ldeck rules |
| `src_new/scripts/.../genrunning/004_Autobashing_Functions.lua` | Main loop, mode control, GMCP balance tracking |
| `src_new/triggers/.../007_Mob_Shielded.lua` | Shield detection trigger (uses configurable timers) |
| `src_new/scripts/.../update_stuff/002_ataxia_Room_Update.lua` | Room change handler (invalidates stormhammer cache) |
| `src_new/scripts/.../update_stuff/003_ataxia_RoomContents_Update.lua` | Denizen list handler (invalidates stormhammer cache) |

**Key Functions:**
| Function | Purpose |
|----------|---------|
| `search_targets()` | Scans room for valid targets from `ataxiaBasher.targetList[area]` |
| `ataxiaBasher_attack()` | Assembles and sends attack command via static dispatch table |
| `ataxiaBasher_patterns()` | Main prompt loop — fires attacks when balanced, records balance samples |
| `ataxiaBasher_stormhammer()` | Populates AoE target list (dirty-flag cached, lazy recompute) |
| `ataxiaBasher_invalidateStormhammer()` | Marks stormhammer cache dirty (called by room/denizen update events) |
| `ataxiaBasher_countMobsInRoom(mobName)` | Counts specific mob types in current room |
| `ataxiaBasher_preCombatLdeck()` | Data-driven pre-combat legend deck card draws |
| `ataxiaBasher_assembleBattlerage()` | Builds battlerage commands via generic handlers with rage conservation |
| `ataxiaBasher_standardBattlerage()` | Generic battlerage handler for most classes |
| `ataxiaBasher_crowdControlBattlerage()` | Generic CC battlerage handler (Bard, Jester, etc.) |
| `ataxiaBasher_validTargets()` | Returns count of valid targets in room |
| `ataxiaBasher_shieldedTarget()` | Handles mob shield retarget with configurable timers |
| `ataxiaBasher_recordBalanceSample()` | Records inter-attack interval for GMCP-based balance tracking |
| `ataxiaBasher_getAttackCooldown()` | Returns learned attack cooldown (95% of rolling average) |
| `ataxiaBasher_onDeath()` | Death recovery — pauses basher, waits for resurrection |
| `ataxiaBasher_startFleeTimer()` | Flee circuit breaker (20s default timeout) |
| `ataxiaBasher_startStuckTimer()` | Mapper-stuck detection for speedwalk hangs |

**Key Variables:**
| Variable | Purpose |
|----------|---------|
| `ataxiaBasher.enabled` | System on/off toggle |
| `ataxiaBasher.manual` | Manual targeting mode |
| `ataxiaBasher.targetList[area]` | Table of target mob names per area |
| `ataxia.denizensHere` | Table of NPCs in current room (id → name) |
| `target` | Current target ID |
| `found_target` | Boolean — valid target exists |
| `stormhammerTargets` | List of IDs for AoE attacks |
| `ataxiaBasher_stormhammerDirty` | Dirty flag for stormhammer cache invalidation |
| `ataxiaBasher_balanceSamples` | Per-class rolling balance sample table (max 20) |
| `ataxiaBasher_lastAttackEpoch` | Timestamp of last attack for balance measurement |

**Configuration Options:**
| Setting | Type | Default | Purpose |
|---------|------|---------|---------|
| `ataxiaBasher.enabled` | bool | false | Master on/off |
| `ataxiaBasher.paused` | bool | false | Pause without disable |
| `ataxiaBasher.manual` | bool | false | Manual movement mode |
| `ataxiaBasher.areabash` | bool | false | Full automation mode |
| `ataxiaBasher.fleeThreshold` | number | varies | HP% to trigger flee |
| `ataxiaBasher.dangerCount` | number | varies | Max dangerous mobs per room |
| `ataxiaBasher.goldPack` | string | `"pack436363"` | Container ID for gold collection |
| `ataxiaBasher.attackCooldown` | number | 0.4 | Default attack cooldown (seconds) |
| `ataxiaBasher.fleeTimeout` | number | 20 | Flee circuit breaker timeout (seconds) |
| `ataxiaBasher.shieldTimers` | table | `{["a mhun knight"]=4.7}` | Per-mob shield durations |
| `ataxiaBasher.shieldTimerDefault` | number | 3.1 | Default shield duration |
| `ataxiaBasher.shieldswap` | bool | varies | Enable shield retarget swapping |
| `ataxiaBasher.targetList` | table | — | Per-area target mob lists |
| `ataxiaBasher.mobIgnore` | table | — | NPCs to skip |
| `ataxiaBasher.dangerList` | table | — | Dangerous mob names |
| `ataxiaBasher.ldeckRules` | table | see below | Data-driven legend deck draw rules |
| `ataxiaBasher_attackCooldowns` | table | — | Per-class static cooldown overrides |

**Pre-Combat Legend Deck (Data-Driven):**

The basher draws legend deck cards before attacking dangerous multi-target rooms, configured via `ataxiaBasher.ldeckRules`:

```lua
ataxiaBasher.ldeckRules = {
  { mob = "an elite mhun keeper", count = 3, cards = {"maran", "matic"} },
  { mob = "a mhun knight", count = 3, cards = {"maran"} },
  { mob = "a mhun knight", count = 4, cards = {"maran", "matic"} },
  -- Add rules for other areas/mobs here
}
```

Cards are drawn using the queue system (`queue add free ldeck draw <card>`) and only once per room entry (tracked via `ataxiaBasher.ldeckDrawnRoom`).

**GMCP-Based Balance Tracking:**

The basher learns per-class attack timing from actual balance/equilibrium recovery:
1. `ataxiaBasher_recordBalanceSample()` is called on each attack, measuring the time since the previous attack
2. Samples are stored in a rolling window of 20 per class in `ataxiaBasher_balanceSamples`
3. `ataxiaBasher_getAttackCooldown()` returns 95% of the rolling average (with 3+ samples), allowing the basher to attack slightly before balance returns for optimal throughput
4. Falls back to per-class static overrides (`ataxiaBasher_attackCooldowns`) or the global default (`ataxiaBasher.attackCooldown`, 0.4s)

**Stormhammer Dirty-Flag Caching:**

Stormhammer target list recomputation is cached via a dirty flag:
1. Room change and denizen update events call `ataxiaBasher_invalidateStormhammer()` (sets `ataxiaBasher_stormhammerDirty = true`)
2. `ataxiaBasher_stormhammer()` short-circuits if the dirty flag is false
3. When the basher logic calls `stormhammer()` during the prompt cycle, denizen data is fully up to date
4. This avoids stale-data recomputes on room entry and redundant N-per-room recomputes

**Robustness Features:**
| Feature | Description |
|---------|-------------|
| **Flee circuit breaker** | If still fleeing after 20s (configurable), disables basher and alerts player |
| **Death recovery** | Pauses basher on death, waits for resurrection/rebirth event |
| **Mapper-stuck detection** | Timer checks if speedwalk counter hasn't changed, triggers `pathFail()` |
| **Nil guards** | `mmp.previousroom`, player database, area targetList all nil-checked |
| **Rage conservation** | Skips battlerage abilities if mob is near death (< 15% HP) |

**Attack Flow:**
```
Room Entry (GMCP)
    ↓
ataxia_Room_Update() → invalidateStormhammer()
    ↓
ataxia_RoomContents_Update() → invalidateStormhammer(), raiseEvent("targets updated")
    ↓
Prompt Trigger → ataxia_promptCommands()
    ↓
ataxiaBasher_scanRoom() → need_roomCheck flag, player/danger detection
    ↓
search_targets() → Find valid target from targetList[area]
    ↓
ataxiaBasher_preCombatLdeck() → Draw cards if rules match (data-driven)
    ↓
ataxiaBasher_patterns() → Check balance/standing, recordBalanceSample()
    ↓
ataxiaBasher_attack() → Static dispatch table → class-specific function
    ↓
ataxiaBasher_assembleBattlerage() → Generic/CC handler with rage conservation
```

### GUI System (ataxiagui)
- Left panel: Players, Room info, Bash stats
- Right panel: Map display, Chat tabs
- Bottom panel: Health/Mana/Willpower/Endurance gauges
- Balance/Equilibrium indicators
- Tabbed chat (All, City, Clans, Misc, Order, Party, Tells)

### Player Database (ataxiaNDB)
- Fetches from Achaea API (`http://api.achaea.com/characters/`)
- Tracks: name, city, house, class, level, XP rank, player kills
- City-based name highlighting
- Enemy and army rank tracking

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
| **kelp** | clumsiness, healthleech, weariness, asthma, sensitivity, hypochondria, parasite |
| **ginseng** | nausea, haemophilia, addiction, darkshade, flushings, lethargy, scytherus |
| **goldenseal** | stupidity, impatience, depression, sandfever, epilepsy, dizziness, dissonance, shyness |
| **lobelia** | recklessness, vertigo, spiritburn, tenderskin, loneliness, claustrophobia, masochism, agoraphobia |
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

---

## Infernal DWC Vivisect Combat System

### Overview
The Infernal DWC Vivisect system provides automated combat for the Dual Wield Cutting (DWC) specialization, targeting the vivisect instant kill.

### Key Files
| File | Purpose |
|------|---------|
| `src_new/scripts/levi_ataxia/levi/levi_scripts/dwc/001_Infernal_DWC_Vivisect.lua` | 4-limb variant (`infernalDWC` namespace) |
| `src_new/scripts/levi_ataxia/levi/levi_scripts/dwc/002_Infernal_DWC_Vivisect_2L.lua` | 2-limb variant (`infernalDWC2L` namespace) |

### Vivisect Kill Requirements
```yaml
vivisect_requirement: "All 4 limbs at level 1+ break"

break_levels:
  level_1:
    sources: ["epteth venom (arms)", "epseth venom (legs)"]
    effect: "Withered state - counts for vivisect"
    cure: "Single restoration (4s salve balance)"

  level_2:
    sources: ["Physical damage 100%+", "Undercut on prepped leg"]
    effect: "Broken/crippled - also counts for vivisect"
    cure: "Restoration (4s) + Mending (4s) = 8s minimum"

key_mechanic: |
  Epteth/epseth venoms give level 1 breaks to NON-TARGETED limbs!
  DSL right arm with epteth/epseth:
    - Physically breaks right arm (level 2)
    - Epteth gives level 1 to LEFT arm
    - Epseth gives level 1 to RIGHT leg
```

### Phase Progression
| Phase | Description | Entry Condition | Priority |
|-------|-------------|-----------------|----------|
| **DAMAGE KILL** | Quash + Arc for damage kill | Health ≤40% | 1 (highest) |
| **KILL** | Vivisect | All 4 limbs at level 1+ | 2 |
| **EXECUTE** | Break limbs with undercut + DSL | Both arms + focus leg at 90%+ (or would-break) | 3 |
| **PREP** | Build limb damage to 90%+ | Default phase | 4 |
| **RIFTLOCK** | Lock mode (counter to RESTORE) | Manual: `infernalDWC.enterRiftlock()` | N/A |

**DAMAGE KILL** is checked first - if target health drops below threshold (default 40%), system switches to raw damage output with QUASH + ARC instead of continuing vivisect setup.

**Break Prevention**: `isArmPrepped()`/`isLegPrepped()` also return true when `wouldBreakLimb()` detects that the next DSL would push the limb past `breakThreshold` (i.e., `currentDamage + 2 * slashDamage >= 100`). This prevents accidental limb breaks during PREP — the system treats near-break limbs as prepped so it transitions to EXECUTE, where the break happens intentionally with epteth/epseth venoms.

### Execute Sequence (Optimized 2-Attack Kill)
```
Step 0: UNDERCUT left leg (battleaxe)
  → Breaks leg (level 2)
  → 4 second salve lock
  → Invest exploit for paranoia + weariness

Step 1: DSL right arm epteth epseth (scimitars)
  → Breaks right arm (level 2)
  → Epteth gives left arm level 1
  → Epseth gives right leg level 1
  → All 4 limbs now at level 1+

KILL: VIVISECT
```

### RIFTLOCK Mode
Activated when target uses RESTORE (heals all limbs). Counter-strategy:
- Break arms (prevents rifting herbs)
- Stick anorexia + slickness + addiction
- Maintain paralysis

### Commands
| Command | Purpose |
|---------|---------|
| `infernalDWCVivisect()` | Main dispatch function |
| `infernalDWCStatus()` | Display current state |
| `infernalDWCReset()` | Reset all state |
| `infernalDWC.enterRiftlock()` | Enter riftlock mode |
| `infernalDWC.exitRiftlock()` | Exit riftlock mode |
| `infernalDWCSetWeapons(scim1, scim2, baxe)` | Configure weapon IDs |
| `infernalDWCSetFocusLeg(leg)` | Set focus leg ("left" or "right") |

### Helper Functions
| Function | Purpose |
|----------|---------|
| `infernalDWC.getPhase()` | Determines current combat phase |
| `infernalDWC.shouldDamageKill()` | Checks if target health below threshold |
| `infernalDWC.selectVenoms()` | Selects venoms based on phase and stuck affs |
| `infernalDWC.selectLimbTarget()` | Chooses limb to attack (with break prevention guard) |
| `infernalDWC.wouldBreakLimb(limbName)` | Returns true if next DSL would break a limb (damage + 2*slashDamage >= breakThreshold) |
| `infernalDWC.getFocusArm()` | Returns arm with lower damage (for balancing) |
| `infernalDWC.getOffArm()` | Returns arm with higher damage |
| `infernalDWC.getFocusLeg()` | Returns focus leg for prepping |
| `infernalDWC.isArmPrepped(side)` | Checks if arm at prepThreshold OR would break from next DSL |
| `infernalDWC.isLegPrepped(side)` | Checks if leg at prepThreshold OR would break from next DSL |
| `infernalDWC.isFocusLegPrepped()` | Checks if focus leg at prepThreshold |
| `infernalDWC.hasAff(aff)` | V2-compatible affliction check |
| `infernalDWC.handleRebounding()` | Razes rebounding/shield when detected |

**Note**: The 2-limb variant uses `infernalDWC2L` namespace with the same function signatures.

### Configuration
```lua
infernalDWC.config = {
    prepThreshold = 90,         -- Limb % to consider "prepped"
    breakThreshold = 100,       -- Limb % to consider "broken"
    damageKillThreshold = 40,   -- Target health % to switch to damage kill
    weapon1 = "scimitar405403",
    weapon2 = "scimitar405398",
    battleaxe = "battleaxe590991",
    focusLeg = "left",          -- Which leg to focus prep/break
}
```

### V3/V2 Affliction Tracking Support
The system uses `infernalDWC.hasAff()` which routes through V3 → V2 → V1:
```lua
-- infernalDWC.hasAff() routes: V3 (probability) → V2 (certainty) → V1 (boolean tAffs)
-- Shield/rebounding use dual-check pattern for safety:
local hasRebounding = infernalDWC.hasAff("rebounding") or (tAffs and tAffs.rebounding)
```
The Blademaster Ice Dispatch (`005_CC_BM_Ice.lua`) follows the same pattern via `blademaster.hasAff()`.

### Documentation
See `.claude/classes/infernal.md` for complete DWC vivisect strategy documentation.

---

## Blademaster Combat System

### Strategies Available

| Strategy | Command | Description |
|----------|---------|-------------|
| **Double-Prep** | `bmd` | Legs only - prep both legs, double-break, mangle |
| **Quad-Prep** | `bmdq` | Arms + legs - prep all 4, break arms, break legs, mangle |
| **Brokenstar** | `bmbs` | Upper + legs + impale route - instant kill at 700 bleed |
| **Ice Dispatch** | `bmice` | Lightning/Ice phase - prep with lightning, damage with ice |

### Lightning/Ice Phase System (bmice)

The Ice Dispatch uses a two-phase approach based on limb state:

| Phase | Condition | Infusion | Primary Attack |
|-------|-----------|----------|----------------|
| **prep** | Legs not both broken | LIGHTNING | LEGSLASH (prep damage) |
| **ice** | Both legs broken | ICE | STERNUM (damage kill) |

**Phase Logic**:
```lua
function blademaster.getPhase()
  if blademaster.checkBothLegsBroken() then
    return "ice"   -- Both legs broken, switch to ice for damage
  else
    return "prep"  -- Still prepping legs with lightning
  end
end
```

**Key Mechanics**:
- **INFUSE LIGHTNING**: Used during prep phase for faster limb damage
- **INFUSE ICE**: Switched when both legs broken for raw damage output
- **STERNUM**: Primary attack in ice phase for damage kill
- **AIRFIST**: Reactive ability when target parries focus leg (25 shin cost)

### Brokenstar Kill Route (bmbs)

```
1. UPPER PREP: Centreslash up/down to get torso+head to 90%+
2. LEG PREP: Legslash alternating to get both legs to 90%+
3. UPPER BREAK: Centreslash up/down to break torso+head (100%+)
4. LEG BREAK: Legslash + KNEES to break legs and prone
5. IMPALE: Impale the prone target
6. IMPALESLASH: Slash arteries for bleeding
7. BLADETWIST: Twist until 700+ bleeding (discern on 3rd)
8. WITHDRAW: Withdraw blade (or skip if writhed free)
9. BROKENSTAR: Execute instant kill
```

### Dynamic Centreslash Direction

The system auto-selects UP or DOWN to balance torso/head damage:
- **UP**: Torso = primary (18.1%), Head = secondary (12.1%)
- **DOWN**: Head = primary (18.1%), Torso = secondary (12.1%)
- Always hits the **LOWER** limb as primary (like `getFocusLeg()` for legs)

### Helper Functions

| Function | Purpose |
|----------|---------|
| `blademaster.getFocusLeg()` | Returns "left" or "right" based on lower leg damage |
| `blademaster.getCentreslashDirection()` | Returns "up" or "down" based on lower limb |
| `blademaster.checkWillPrepBothLegs()` | True if next hit preps both legs to 90%+ |
| `blademaster.checkWillPrepUpper()` | True if next centreslash preps both torso/head |
| `blademaster.getPhase()` | Returns current phase ("prep" or "ice") |
| `blademaster.getShin()` | Returns current shin resource |
| `blademaster.checkDoubleBreakReady()` | True if both legs at prepThreshold |
| `blademaster.checkBothLegsBroken()` | True if both legs at breakThreshold |
| `blademaster.needsAirfist()` | Checks if airfist should be used (parry + cooldown) |
| `blademaster.calculateOptimalPath()` | Returns optimal attack sequence to reach 90% |
| `blademaster.recordLegDamage(leg, pct)` | Records leg damage from hits |
| `blademaster.recordLegslashDamage(leg, pct)` | Records legslash-specific damage |
| `blademaster.hasAff(aff)` | Check affliction via V3 → V2 → V1 routing |
| `blademaster.getAffProb(aff)` | Get affliction probability (V3: 0.0-1.0, V2/V1: binary) |
| `blademaster.getTrackingSystem()` | Returns "V3", "V2", or "V1" |

### Configuration
```lua
blademaster.config = {
    legBreakThreshold = 100,    -- % to consider leg "broken"
    legPrepThreshold = 90,      -- % to consider leg "prepped"
    killHealthThreshold = 30,   -- Target health % for damage kill
    airfistCooldown = 8,        -- Seconds between airfist uses
}
```

### Documentation
See `.claude/classes/blademaster.md` for complete documentation.

---

## Apostate Combat System

### Overview
The Apostate offensive system (`CC_Apostate`) provides automated curse delivery via DEADEYES, with kill routes for true locking, corrupt burst damage, vivisect, and sleep. Consolidated from 14 legacy files into a single namespace-based system with V3 affliction tracker integration.

### Key Files
| File | Purpose |
|------|---------|
| `src_new/scripts/.../apostate/015_CC_Apostate.lua` | Complete unified system with `apostate` namespace |
| `src_new/scripts/.../apostate/014_Levi_Apostate.lua` | Backward-compat wrappers + daemon utility functions |
| `src_new/scripts/.../apostate/001-013_*.lua` | Legacy files (all disabled, `isActive: 'no'`) |
| `src_new/triggers/.../439_NEW_DEADEYES.lua` | Curse detection → `tarAffed()` |
| `src_new/triggers/.../apostate/007_CORRUPT.lua` | Corrupt cooldown tracking |

### Kill Routes (4 Modes)
| Mode | Command | Description |
|------|---------|-------------|
| **lock** | `apostate.setMode("lock")` | DEADEYES curse delivery building toward truelock + class lock |
| **corrupt** | `apostate.setMode("corrupt")` | Stack afflictions → `demon corrupt` for damage / catharsis setup |
| **vivisect** | `apostate.setMode("vivisect")` | Truelock → prone → shrivel 4 limbs → vivisect |
| **sleep** | `apostate.setMode("sleep")` | Build asthma + impatience + hypersomnia → sleep curse |

### Dual-Slot Curse Priority Engine
DEADEYES delivers 2 curses per action (2.3s balance). Each slot has an independent priority chain:

**Curse 1 (`selectPrimaryCurse`)** — Direct affliction stacking:
```
clumsiness → asthma → manaleech → impatience → slickness → anorexia
→ sleep mode / nightmare synergy / sensitivity → fillers → class lock aff
```

**Curse 2 (`selectSecondaryCurse(c1)`)** — Sicken cascade + lock support:
```
sicken (delivers paralysis) → impatience → asthma
→ sicken again (delivers manaleech/slickness when asthma protects smoke cure)
→ anorexia → slickness → manaleech → fillers → class lock aff
```

Curse 2 never duplicates curse 1 (`c1` passed as parameter to avoid overlap).

**Orchestrator (`selectCurses`):**
- Curseward detected → breach + secondary
- Truelock >= 70% → class lock aff + secondary
- Otherwise → primary + secondary

### Sicken Cascade Mechanics
Sicken delivers afflictions in order: `paralysis → manaleech → slickness`. It is used at two points in the Curse 2 chain:
1. **First use** (top priority): Delivers paralysis for tree block
2. **Second use** (after asthma secured): Delivers manaleech/slickness — asthma blocks smoke cure, protecting both

### Lock Progression
```
softlock  = asthma + anorexia + slickness
hardlock  = softlock + impatience
truelock  = hardlock + paralysis
classlock = truelock + voyria (class lock aff)
```

### Attack Builder Priority
The main attack builder checks kill conditions in this order:
1. `needVivisect()` — All 4 limbs broken → vivisect
2. `needShieldStrip()` — Catharsis/corrupt ready but target shielded
3. `needTrample()` — Truelocked + target prone → trample
4. `needCatharsis()` — Target mana below threshold → catharsis
5. `needCorrupt()` — Corrupt damage >= assessed health, or pushes mana to catharsis range
6. Corrupt followup — Corrupt already fired → catharsis
7. `needShrivel()` — Vivisect mode, truelocked, prone, limbs remaining
8. Default: DEADEYES dual-curse delivery

### Corrupt Damage Calculator
```lua
function apostate.corruptDmg()
  -- Physical affs × 7 + Mental affs × 8 + Smoke affs × 9
  -- V3 mode: weights each affliction by probability (0.0-1.0)
  -- V1/V2 mode: binary 1.0 or 0 per affliction
end
```

### V3/V2/V1 Tracking Integration
Same routing pattern as Blademaster:
| Helper | Purpose |
|--------|---------|
| `apostate.hasAff(aff)` | Check affliction via V3 → V2 → V1 routing |
| `apostate.getAffProb(aff)` | Get affliction probability (V3: 0.0-1.0, V2/V1: binary) |
| `apostate.getTrackingSystem()` | Returns "V3", "V2", or "V1" |
| `apostate.getLocks()` | Returns `{softlock, hardlock, truelock}` probabilities |

### Commands
| Alias | Regex | Action |
|-------|-------|--------|
| `cath` | `^cath$` | `apostate.dispatch()` (lock mode) |
| `KELP STACK` | `^kel$` | `apostate.dispatch()` (lock mode, class-conditional) |
| `Group Attack` | `^yy$` | `apostate.dispatch()` (group mode, currently disabled) |
| `Levi Lock Apo` | `^ll$` | `apostate.dispatch()` (lock mode) |
| `Vivisect` | `^viv$` | `apostate.dispatch()` (vivisect mode) |
| `SLEEP` | `^slee$` | `apostate.dispatch()` (sleep mode) |
| `Corrupt` | `^corr$` | `apostate.dispatch()` (corrupt mode) |

### Backward Compatibility (014_Levi_Apostate.lua)
| Legacy Function | Mode Set |
|-----------------|----------|
| `leviclumsapo()` | lock |
| `leviweariapo()` | lock |
| `levisleepapo()` | sleep |
| `apostate_lock()` | lock |
| `apostate_lockattack()` | (current mode) |
| `apostate_lockImpale()` | lock |
| `apostate_sleepattack()` | sleep |
| `apostate_clumsy()` | lock |
| `apostate_vivisect()` | vivisect |
| `apostate_weari()` | lock |
| `apostate_mental()` | lock |
| `apostate_kelp()` | lock |
| `apostate_group()` | group |
| `apostate_clumsyillusion()` | lock |

Legacy wrappers kept: `corruptDmg()`, `corruptKill()`, `cathCorrupt()`

### Daemon Utilities (014_Levi_Apostate.lua)
| Function | Purpose |
|----------|---------|
| `bloodPact()` | Bloodpact setup (fresh blood + no pentagram) |
| `bloodworm()` | Summon bloodworms |
| `baalzadeen()` | Ensure Baalzadeen summoned |
| `apopentagram()` | Pentagram setup |
| `demon()` / `daemonite()` / `fiend()` / `nightmare()` | Entity management |

### Pre/Post Attack Actions
**Pre-attack:**
- Bloodpact setup (fresh blood + no pentagram active)
- Daegger summon when catharsis/prone situations require it

**Post-attack:**
- Bloodworm summon (when fresh blood available)
- Daemon resummon (when wrong daemon type present)
- Disfigure for disloyalty (when asthma is held)

Note: Daegger hunt was intentionally removed from commands — it slows offense when seconds matter.

### Configuration
```lua
apostate.state = {
  mode = "lock",            -- "lock", "corrupt", "vivisect", "sleep", "group"
  corrupted = false,        -- corrupt has been fired (awaiting catharsis)
  lastCorruptTime = 0,      -- corrupt cooldown tracking
  daeggerhere = false,      -- daegger summoned
  freshblood = false,       -- fresh blood available for bloodpact
  fiendthing = "nightmare", -- preferred lesser daemon
  wantDisloyalty = false,   -- disfigure toggle
  partyrelay = true,        -- relay to party
}

apostate.config = {
  corruptThreshold = 0.7,   -- V3 probability threshold for corrupt consideration
  lockThreshold = 0.3,      -- V3 threshold for "has affliction"
  catharsisThreshold = 50,  -- mana % for catharsis execute
  sapThreshold = 60,        -- mana % for sap consideration
  debugEcho = false,        -- enable debug output
}
```

### Documentation
See `.claude/classes/apostate.md` for complete class mechanics and implementation documentation.

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

---

**Last Updated**: 2026-02-10
**Project Lead**: Michael
**Development Environment**: VS Code + Mudlet + Claude Code
**Reference Systems**: Orion, Ataxia
