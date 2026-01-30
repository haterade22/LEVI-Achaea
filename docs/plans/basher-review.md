# Basher System Review & Improvement Plan

**Date:** 2024-12-18
**Files:** 12 core files in `src_new/scripts/levi_ataxia/levi/ataxia/basher/` and `src_new/scripts/levi_ataxia/levi/ataxia/genrunning/` (~2,500 lines)
**Supported Classes:** 20+ including Dragons, Elementals, and standard classes

---

## Current State

### What Works Well
- Comprehensive class-specific attack sequences
- Experience tracking database with 27+ metrics per zone
- Integration with mapper (mmp) for auto-navigation
- Battlerage ability rotation system
- Gold collection automation
- Multi-target detection (Stormhammer)
- Shield retargeting logic

### Supported Classes
- **Standard:** Alchemist, Apostate, Bard, Blademaster, Depthswalker, Infernal, Jester, Magi, Monk, Occultist, Paladin, Pariah, Priest, Psion, Runewarden, Sentinel, Serpent, Shaman, Sylvan
- **Elementals:** Air, Fire, Water, Earth
- **Dragons:** All 6 colors with type-specific summoning

---

## Critical Bugs to Fix

| Priority | Issue | File | Line |
|----------|-------|------|------|
| **CRITICAL** | Debug output left in code: `cecho("TEST TEST TEST TEST")` | 011_Bash_Stats_Functions.lua | 4 |
| **HIGH** | Null reference risk: `mmp.previousroom` not checked | 005_Bashing_Functions.lua | 53 |
| **HIGH** | Uninitialized variable: `guardianofmogcunts` | 005_Bashing_Functions.lua | 75 |
| **HIGH** | No error handling for GMCP data parsing | 002_movement.lua | 16-20 |
| **MEDIUM** | Hardcoded player name in guardian check | 012_Guardians_Of_MoG.lua | 5 |
| **MEDIUM** | Inefficient Magi loop (updates GUI every prompt) | 006_Class_Bashing.lua | 256-259 |
| **MEDIUM** | Brittle mob detection with hardcoded name | 008_search_targets.lua | 94 |

---

## Code Quality Issues

### Error Handling (None)
- No try/catch for GMCP data parsing
- No validation of table contents before iteration
- No null checks before sending commands

### Maintainability Problems
- **Massive conditionals:** 150+ line function in `ataxiaBasher_assembleBattlerage()`
- **Magic numbers:** Hardcoded timers (3.1, 4.7 sec), item IDs, room numbers
- **Duplicate code:** Class functions are 80% similar
- **Global state:** Heavy reliance on undeclared global variables
- **No documentation:** Almost no comments explaining logic

### Performance Issues
- Magi class calls `raiseEvent()`, updates room contents, shows GUI every prompt
- Stormhammer iterates full denizen list every prompt
- Path generation blocks synchronously during area discovery

---

## File-by-File Analysis

### 001_Experience_Database.lua (403 lines)
- **Purpose:** Experience tracking and historical bashing statistics
- **Key Functions:** `zData.db.zoneAdd()`, `zData.db.showData()`, `zData.db.clickback()`
- **Features:** Tracks 27+ metrics per zone, color-coded GUI, clickable sorting
- **Issue:** Max 100 result display hardcoded (line 83)

### 002_movement.lua (130 lines)
- **Purpose:** Zone-change detection and session statistics
- **Key Functions:** `zData.movement()` triggered on `gmcp.Room.Info`
- **Issue:** No error handling for malformed GMCP data (lines 16-20)

### 003_Rainbow_Script.lua (94 lines)
- **Purpose:** Decorative colorized text output
- **Note:** Not core bashing logic, utility only

### 004_buildHunter.lua (44 lines)
- **Purpose:** UI window for experience database
- **Issue:** No persistence of window size/location

### 005_Bashing_Functions.lua (381 lines) - CRITICAL
- **Purpose:** Main attack dispatch and strategy routing
- **Key Functions:** `ataxiaBasher_attack()`, `ataxiaBasher_assembleAttack()`, `ataxiaBasher_assembleBattlerage()`
- **Issues:**
  - Bug at line 75: `guardianofmogcunts` used without declaration
  - Line 53: `mmp.previousroom` not null-checked
  - Line 51-57: Hardcoded player name check
  - 150+ lines of nested conditions in battlerage

### 006_Class_Bashing.lua (735 lines) - LARGEST FILE
- **Purpose:** Class-specific attack patterns for 20+ classes
- **Architecture:** Each class has dedicated function
- **Issues:**
  - Lines 256-259 (Magi): Updates GUI every prompt - inefficient
  - Lines 384-437 (Monk): Variables never set, relies on GMCP
  - Hardcoded item IDs (staff569815, morningstar511732)
  - Duplicate Monk functions (lines 279, 366)

### 007_Bashing_API.lua (115 lines)
- **Purpose:** Room scanning and path management
- **Key Functions:** `ataxiaBasher_scanRoom()`, `ataxiaBasher_generatePath()`
- **Issues:**
  - Line 88: `collectRooms` assigned without declaration
  - No handling for elite/champion mob variants

### 008_search_targets.lua (118 lines)
- **Purpose:** Target acquisition and Stormhammer
- **Key Functions:** `search_targets()`, `ataxiaBasher_stormhammer()`, `ataxiaBasher_retargetShielded()`
- **Issues:**
  - Line 94: Hardcoded mob name `"a mhun knight"`
  - Assumes `targetList[area]` exists - crashes if missing

### 009_Engaged_Disengage.lua (216 lines)
- **Purpose:** State transitions (start/stop bashing)
- **Key Functions:** `basher_engaged()`, `basher_disengaged()`
- **Issues:**
  - Lines 105-114: Hardcoded boss room IDs
  - Line 127: Moghedu-specific greeting hardcoded

### 010_Autobashing_Functions.lua (132 lines)
- **Purpose:** Attack loop and mode control
- **Key Functions:** `ataxiaBasher_patterns()`, `ataxiaBasher_nextRoom()`, `ataxiaBasher_manual()`, `ataxiaBasher_areabash()`
- **Modes:** Manual, Areabash (full auto), Harvesting

### 011_Bash_Stats_Functions.lua (17 lines)
- **Purpose:** Per-session statistics initialization
- **CRITICAL BUG:** Line 4 has debug output `cecho("TEST TEST TEST TEST")`

### 012_Guardians_Of_MoG.lua (17 lines)
- **Purpose:** Player detection (hardcoded)
- **Issues:**
  - Checks for specific player "Hikagejuunin" only
  - Offensive variable naming
  - Likely dead code

---

## Missing Features

1. **Target Priority System** - Currently uses arbitrary order
2. **Mob Difficulty Detection** - All mobs treated equally
3. **Intelligent Path Routing** - No XP-density optimization
4. **Configuration UI** - Settings scattered across files
5. **Session Export** - Can't export stats to CSV
6. **Denizen Aggro Tracking** - No tracking of mob threat
7. **Room Danger Heatmap** - No death-rate based routing

---

## Configuration Options (Inferred)

| Setting | Type | Notes |
|---------|------|-------|
| `ataxiaBasher.enabled` | bool | Master on/off |
| `ataxiaBasher.paused` | bool | Pause without disable |
| `ataxiaBasher.manual` | bool | Manual movement mode |
| `ataxiaBasher.areabash` | bool | Full automation mode |
| `ataxiaBasher.fleeThreshold` | number | HP% to trigger flee |
| `ataxiaBasher.dangerCount` | number | Max dangerous mobs per room |
| `ataxiaBasher.mobIgnore` | table | NPCs to skip |
| `ataxiaBasher.ignore` | table | Players to skip |
| `ataxiaBasher.dangerList` | table | Dangerous mob names |
| `ataxiaBasher.targetList` | table | Per-area target lists |
| `ataxiaBasher.noShieldBreak.threshold` | number | Auto-shield HP |
| `ataxiaBasher.rageraze` | bool | Use rage ability raze |
| `ataxiaBasher.nicator` | bool | Draw nicator from deck |
| `ataxiaBasher.dragonIncant` | bool | Dragon incantation mode |
| `ataxiaBasher.jabBash` | bool | Use jab vs gut (dragon) |
| `ataxiaBasher.cullingBlade` | bool | Reap on 2+ targets |
| `ataxiaBasherPaths` | table | Cached area paths |

---

## Recommended Improvements

### Phase 1: Critical Fixes
1. Remove debug output (line 4 of 011_Bash_Stats_Functions.lua)
2. Add null-checks on GMCP data access
3. Initialize all global variables properly
4. Add basic error handling to target selection

### Phase 2: Code Refactoring
1. Extract configuration to dedicated `000_config.lua` file
2. Refactor battlerage conditionals to table lookups
3. Create base class function, derive class-specific overrides
4. Replace magic numbers with named constants (`000_constants.lua`)
5. Add comments documenting complex logic

### Phase 3: Feature Additions
1. Implement target priority system (HP%, danger level)
2. Add mob difficulty tiers
3. Create configuration UI window
4. Add session statistics export
5. Implement intelligent path routing

### Phase 4: Performance Optimization
1. Cache stormhammer results (only recalc on room change)
2. Debounce GUI updates (max 1/second)
3. Make path generation async

---

## Files to Modify

| File | Changes |
|------|---------|
| `011_Bash_Stats_Functions.lua` | Remove debug line |
| `005_Bashing_Functions.lua` | Add null checks, fix variables |
| `002_movement.lua` | Add GMCP error handling |
| `006_Class_Bashing.lua` | Optimize Magi, refactor duplicates |
| `008_search_targets.lua` | Fix hardcoded mob names |
| `012_Guardians_Of_MoG.lua` | Remove or generalize |
| NEW: `000_config.lua` | Centralized configuration |
| NEW: `000_constants.lua` | Named constants for magic numbers |

---

## System Integrations

```
ataxiaBasher
├── ataxia.combat (vitals, balance, afflictions)
├── ataxia.settings (config persistence)
├── mmp.mapper (navigation, room locking)
├── GMCP (room info, denizen list, vitals, target info, balance timing)
├── ataxia.harvester (shares path generation)
├── zData.experience (database for statistics)
├── Ataxia GUI (basherBar windows)
└── Triggers (Denizen Attacks, Gold Dropped, Mob Shielded)
```

---

## Completed Improvements (2026-01-29)

A comprehensive review was performed with 27 items identified across 5 priority categories. The following items were implemented (items marked with [KEPT] were the user's choice to keep; [REVERTED] were rejected and reverted; [SKIPPED] were deferred):

### Bug Fixes (All Completed)
- [KEPT] 1.1 Removed debug output `cecho("TEST TEST TEST TEST")`
- [KEPT] 1.2 Fixed pause typo (`.pause` → `.paused`)
- [KEPT] 1.3 Added nil guard for `mmp.previousroom`
- [KEPT] 1.4 Added nil check for player database access
- [KEPT] 1.5 Removed hardcoded player name check

### Performance Improvements
- [KEPT] 2.1 Dispatch table built once at load time (not per-attack)
- [KEPT] 2.2 Battlerage refactored to generic handlers (`standardBattlerage`, `crowdControlBattlerage`) — reduced ~300 lines to ~50
- [SKIPPED] 2.3 `mobhealth` variable left in place (used elsewhere)
- [KEPT] 2.4 Magi GUI spam gated behind `ataxiaBasher_stormhammerDirty` flag
- [KEPT] 2.5 Stormhammer caching with dirty-flag invalidation — room/denizen events call `invalidateStormhammer()`, lazy recompute on prompt
- [KEPT] 2.6 `validTargets()` double-count fix

### Effectiveness Improvements
- [REVERTED] 3.1 Flee loop prevention — user prefers to keep attacking same mob
- [REVERTED] 3.2 Path cycling — respawns take long enough, current behavior is fine
- [KEPT] 3.3 Death recovery handler (pauses basher, waits for resurrection)
- [KEPT] 3.4 GMCP-based balance tracking — measures inter-attack intervals in rolling window of 20, returns 95% of average for optimal throughput
- [KEPT] 3.5 Data-driven legend deck rules via `ataxiaBasher.ldeckRules` table
- [KEPT] 3.6 Configurable shield timers via `ataxiaBasher.shieldTimers` table (both trigger and retarget function use same config)
- [KEPT] 3.7 Gold pack ID configurable via `ataxiaBasher.goldPack`
- [KEPT] 3.8 Rage conservation — skips battlerage if mob HP < 15%
- [REVERTED] 3.9 PvP flee — user decided not to implement this

### Code Maintainability
- [REVERTED] 4.1 Knight consolidation — user wants 4 separate functions (one per knight class, each with 4 specs)
- [NOTE] 4.2 Monk — `monkBashing()` was deleted but cannot be restored (no git history). `monkBashing2()` handles both Tekura and Shikudo.
- [KEPT] 4.3 Serpent double battlerage fix (uses cached `brage` variable)
- [SKIPPED] 4.4 Global namespacing — deferred as too large a change

### Robustness & Safety
- [KEPT] 5.1 Flee circuit breaker with 20-second timeout (configurable via `ataxiaBasher.fleeTimeout`)
- [KEPT] 5.2 Mapper-stuck detection with `ataxiaBasher_startStuckTimer()`
- [KEPT] 5.3 Area targetList nil check in `search_targets()`

### Trigger Changes (Follow-up)
- Updated `007_Mob_Shielded.lua` to use `ataxiaBasher.shieldTimers` config table (was hardcoded 4.5/3.1)
- Replaced `ataxiaBasher_stormhammer()` calls with `ataxiaBasher_invalidateStormhammer()` in `002_ataxia_Room_Update.lua` and `003_ataxia_RoomContents_Update.lua` (4 locations)
