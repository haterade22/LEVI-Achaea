# Agent Instructions for LEVI-Achaea Combat System

This file contains critical instructions for AI agents working on the combat system.

---

## Before Coding Offensive Systems

**You MUST read these files first:**

1. **[classes/lock_types.md](classes/lock_types.md)** - All lock type definitions
   - Softlock, Venomlock, Truelock/Hardlock
   - Focuslock (mental affliction stacking)
   - Riftlock, Salvelock (limb-based)
   - Sleeplock, Aeonlock (timing/control-based)

2. **[classes/<target_class>.md](classes/)** - Class-specific kill routes
   - Kill route prerequisites and steps
   - Gating requirements for key afflictions
   - Class-specific lock affliction

3. **[classes/README.md](classes/README.md)** - Affliction stacking by herb
   - Which afflictions share cure balances
   - Class-specific lock affliction table

---

## Lock Types Quick Reference

| Lock | Afflictions | Escape |
|------|-------------|--------|
| **Softlock** | asthma + anorexia + slickness | Focus → eat bloodroot → eat kelp |
| **Venomlock** | + paralysis | Focus → eat bloodroot |
| **Truelock** | + impatience + class aff | None without help |
| **Focuslock** | mental aff stacking | Hope Focus cures anorexia |
| **Riftlock** | 2 broken arms + slick + asthma | Smoke valerian → mend → rift |
| **Aeonlock** | aeon + asthma + kelp stack | Must cure asthma first |

---

## Shikudo Lock System Reference

The Lock system (`203_Shikudo_Lock.lua`) uses pure affliction-based locking with Telepathy.

### Lock Progression

| Phase | Afflictions | Next Step |
|-------|-------------|-----------|
| **Softlock** | asthma + anorexia + slickness | Apply paralysis |
| **Venomlock** | + paralysis | Use Telepathy for impatience |
| **Hardlock** | + impatience | Apply weariness |
| **Truelock** | + weariness | Damage pressure to kill |

### Form Abilities for Lock Afflictions

| Form | Key Abilities | Lock Affs Available |
|------|---------------|---------------------|
| **Oak** | livestrike, nervestrike, ruku, kuro | asthma, paralysis, slickness, weariness |
| **Willow** | hiraku, hiru, dart | anorexia, dizziness |
| **Rain** | kuro, hiru, ruku | slickness, weariness, dizziness |
| **Gaital** | needle, ruku, kuro, jinzuku | slickness, weariness, addiction |
| **Maelstrom** | livestrike, ruku, jinzuku | asthma, slickness, addiction |

### Form Transitions

- **Need anorexia?** → Go to Willow (has Hiraku)
- **Have anorexia?** → Go to Oak (all lock affs)
- **Near kata limit?** → Transition to avoid stumble
- **Kill phase + prone?** → Go to Gaital (spinkick)

### Kata Limits per Form

| Form | Max Kata |
|------|----------|
| Rain | 24 |
| All others | 12 |

### Telepathy Integration

Telepathy uses EQ balance (separate from BAL for staff attacks):
1. `mindlock` - Establish first
2. `impatience` - Critical for hardlock
3. `batter` - Mental pressure (stupidity, epilepsy, dizziness)
4. `paralyse` - Backup paralysis

### Shikudo Lock Commands

- `shikudolock()` or `shikudoLock.dispatch()` - Main dispatch
- `sklstatus()` or `sklockstatus()` - Status display

---

## Shikudo Dispatch Quick Reference

### V1 System (`200_Shikudo.lua`)
- Strategy: Balanced leg prep (both legs 90%+)
- Kill: Prone + Broken leg + Broken head + Windpipe

### V2 System (`201_Shikudo_V2.lua`)
- Strategy: Focus fire one leg, clumsy first
- Key mechanic: SPINKICK on prone + damaged head = instant MANGLE
- Kill: Same as V1

### Commands

| System | Dispatch | Status |
|--------|----------|--------|
| V1 | `shikudo.dispatch()` | `skstatus()` |
| V2 | `shikudov2.dispatch()` | `skv2status()` |
| Lock | `shikudolock()` | `sklstatus()` |

---

## Before Coding Defensive Systems

Read the **attacker's class documentation** for:
- Kill routes to counter
- Gating requirements for dangerous afflictions
- Priority cure recommendations
- Class-specific lock affliction to prevent

---

## Serpent Defense Quick Reference (2024)

**CRITICAL**: Modern Serpents use **Impulse** (not SNAP) to deliver mental afflictions.

### Impulse Requirements
All three must be true for Impulse to work:
1. Victim has NO sileris/fangbarrier (quicksilver applied)
2. Victim HAS asthma
3. Victim HAS weariness

### Ekanelia Mechanics (BITE Venom Transformation)
Ekanelia allows serpent BITE attacks to deliver BONUS afflictions when specific conditionals are present.
**CRITICAL**: Only works with BITE, not DOUBLESTAB. Serpent sacrifices double venom to use it.

| Venom | Conditionals | Normal + Bonus Effect |
|-------|--------------|----------------------|
| **kalmia** | clumsiness + weariness | asthma + **slickness** |
| **monkshood** | asthma + masochism + weariness | disfigurement + **impatience** |
| **curare** | hypersomnia + masochism | paralysis + **hypochondria** |
| **loki** | confusion + recklessness | random + **nausea + paralysis** |
| **scytherus** | addiction + nausea | scytherus + **camus damage** |

### Ekanelia Defense Priorities
| Danger | Block By Curing | Why |
|--------|-----------------|-----|
| kalmia setup | clumsiness OR weariness | Prevents asthma + slickness in one bite |
| monkshood setup | masochism | Blocks 2 transforms (monkshood + curare) |
| loki trap | confusion OR recklessness | Prevents predictable nausea + paralysis |

### Fratricide + Scytherus (CRITICAL)
- **Fratricide** causes Impulse-delivered afflictions to RELAPSE after cure
- **Scytherus** deals ~1200 damage on each relapse tick
- **CURE PRIORITY**: When fratricide + scytherus present, cure fratricide IMMEDIATELY
- Fratricide cured by **Argentum** (lobelia herb group)

### Cure Competition
| Herb | Competing Afflictions | Priority |
|------|----------------------|----------|
| **Kelp** | asthma vs weariness | Cure ASTHMA (breaks Impulse) |
| **Bloodroot** | paralysis vs slickness | Cure PARALYSIS when asthma present |
| **Argentum** | fratricide vs masochism | Cure FRATRICIDE when scytherus present |

### AntiSerpent Function (001_Anti_Priorities.lua)
**Priority Order**:
1. **approachingLock + tree** → TREE (asthma + slickness + mental)
2. **impulseLockThreat + tree** → TREE (asthma + weariness + no fangbarrier + mental)
3. **fratricide + impulseEnabled + tree** → TREE (stops relapse spiral)
4. **fangbarrier down + impulse conditions** → Re-apply quicksilver
5. **fratricide + scytherus** → Cure fratricide NOW (1200 damage per relapse)
6. **Ekanelia prevention** (masochism, kalmia setup, loki setup)
7. **Impulse prevention** (asthma cure when kelp stack >= 2)
8. **fratricide + impulseEnabled** → Cure fratricide
9. **Standard lock handling**

### Key Files
- `.claude/classes/serpent.md` - Full Serpent mechanics + Ekanelia
- `.claude/classes/lock_types.md` - Serpent lock strategy section
- `src_new/scripts/levi_ataxia/levi/levi_scripts/algedonic_defense_1.0/001_Anti_Priorities.lua` - AntiSerpent function
- `src_new/scripts/levi_ataxia/levi/levi_scripts/serpent/002_Ekanelia_Offense.lua` - Serpent offense system

---

## Affliction Stacking Quick Reference

Stack afflictions that share the same cure herb:

| Herb | Afflictions |
|------|-------------|
| **Kelp** | asthma, clumsiness, sensitivity, weariness, healthleech |
| **Ginseng** | addiction, haemophilia, lethargy, nausea, scytherus |
| **Goldenseal** | impatience, stupidity, dizziness, epilepsy, depression |
| **Bloodroot** | paralysis, slickness |
| **Lobelia** | recklessness, vertigo, masochism, guilt |
| **Ash** | confusion, dementia, hallucinations, paranoia |

---

## Code Header Template

When creating/modifying offensive Lua files, include:

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

---

## Class-Specific Lock Afflictions

| Classes | Lock Aff | Blocks |
|---------|----------|--------|
| Knights, Monk, Serpent, Sentinel, Blademaster, Elemental Lords | Weariness | Passive cures |
| Apostate, Pariah, Bard, Priest | Voyria | Sip healing |
| Magi, Sylvan | Haemophilia | Blood cures |
| Alchemist | Stupidity | Transmutation |
| Depthswalker | Recklessness | Shadow cures |
| Psion | Confusion | Mental cures |

---

## Target Affliction Tracking Quick Reference

The system uses a **three-tier approach** for tracking enemy afflictions:

| System | Table/Module | Purpose |
|--------|-------------|---------|
| **V1 (Core)** | `tAffs` | Boolean tracking - always present |
| **V2 (Certainty)** | `tAffsV2` / `haveAffV2()` | Certainty-based tracking with stacks |
| **V3 (Probability)** | `afflictionStatesV3` / `haveAffV3()` | Branching probability states (0.0-1.0) |

**Toggle:**
- V2: `ataxia.settings.useAffTrackingV2 = true`
- V3: `affConfigV3.enabled = true`

**Global Functions:**
- `tarAffed(...)` - Add afflictions (variadic)
- `erAff(what)` - Remove affliction
- `haveAff(what)` - Check if target has affliction (V1)
- `haveAffV2(aff)` - Check with V2 certainty
- `haveAffV3(aff, threshold)` - Check with V3 probability (default 30% threshold)
- `getAffProbabilityV3(aff)` - Get probability 0.0-1.0

**Class-Specific Routing (V3 → V2 → V1):**
- `infernalDWC.hasAff(aff)` - DWC Vivisect system
- `blademaster.hasAff(aff)` - Blademaster Ice Dispatch

Each class's `hasAff()` routes: V3 (if enabled) → V2 (if enabled) → V1 (fallback).
Shield/rebounding use dual-check pattern: `hasAff("rebounding") or (tAffs and tAffs.rebounding)`

**Files:**
- `src_new/scripts/.../017_Affliction_Management.lua` - V1 core tracking
- `src_new/scripts/.../affliction_tracking_v2/` - V2 certainty system
- `src_new/scripts/.../affliction_tracking_v3/` - V3 branching states
- `src_new/scripts/.../dwc/003_Infernal_DWC_Vivisect.lua` - DWC V3 integration
- `src_new/scripts/.../blademaster/005_CC_BM_Ice.lua` - BM V3 integration

---

## Key Files Reference

| Path | Purpose |
|------|---------|
| `.claude/classes/lock_types.md` | Comprehensive lock definitions |
| `.claude/classes/README.md` | Class index and combat concepts |
| `.claude/classes/<class>.md` | Per-class kill routes and mechanics |
| `.claude/classes/monk.md` | Monk/Shikudo kill routes and mechanics |
| `CLAUDE.md` | Main project documentation |
| `src_new/scripts/levi_ataxia/levi/levi_scripts/shikudo/001_Shikudo.lua` | Shikudo V1 dispatch system |
| `src_new/scripts/levi_ataxia/levi/levi_scripts/shikudo/002_Shikudo_R2.lua` | Shikudo V2 dispatch system |
| `src_new/scripts/levi_ataxia/levi/levi_scripts/shikudo/007_CC_Shikudo_Lock.lua` | Shikudo Lock affliction system |
| `src_new/scripts/.../017_Affliction_Management.lua` | Target affliction tracking |

---

## Basher Development Reference

### Key Files

| File | Purpose |
|------|---------|
| `src_new/scripts/.../basher/001_Bashing_Functions.lua` | Attack dispatch, flee logic, battlerage assembly |
| `src_new/scripts/.../basher/002_Class_Bashing.lua` | Class-specific attack builders (20+ classes) |
| `src_new/scripts/.../basher/003_Bash_Stats_Functions.lua` | Session statistics |
| `src_new/scripts/.../genrunning/001_Bashing_API.lua` | Path generation, room scanning, death recovery, flee timeout, mapper-stuck detection |
| `src_new/scripts/.../genrunning/002_search_targets.lua` | Target selection, stormhammer caching, shield retarget, ldeck rules |
| `src_new/scripts/.../genrunning/004_Autobashing_Functions.lua` | Main loop, mode control, GMCP balance tracking |
| `src_new/triggers/.../007_Mob_Shielded.lua` | Shield detection trigger (uses configurable timers) |
| `src_new/scripts/.../update_stuff/002_ataxia_Room_Update.lua` | Room change handler (invalidates stormhammer cache) |
| `src_new/scripts/.../update_stuff/003_ataxia_RoomContents_Update.lua` | Denizen list handler (invalidates stormhammer cache) |

### Configuration Options

| Setting | Type | Default | Purpose |
|---------|------|---------|---------|
| `ataxiaBasher.enabled` | bool | false | Master on/off |
| `ataxiaBasher.paused` | bool | false | Pause without disable |
| `ataxiaBasher.fleeThreshold` | number | varies | HP% to flee |
| `ataxiaBasher.dangerCount` | number | varies | Max dangerous mobs |
| `ataxiaBasher.targetList` | table | — | Per-area targets |
| `ataxiaBasher.goldPack` | string | `"pack436363"` | Container ID for gold collection |
| `ataxiaBasher.attackCooldown` | number | 0.4 | Default attack cooldown (seconds) |
| `ataxiaBasher.fleeTimeout` | number | 20 | Flee circuit breaker timeout (seconds) |
| `ataxiaBasher.shieldTimers` | table | `{["a mhun knight"]=4.7}` | Per-mob shield durations |
| `ataxiaBasher.shieldTimerDefault` | number | 3.1 | Default shield duration |
| `ataxiaBasher.ldeckRules` | table | see CLAUDE.md | Data-driven legend deck draw rules |
| `ataxiaBasher_attackCooldowns` | table | — | Per-class static cooldown overrides |

### Architecture Notes

- **Dispatch table** is built once at load time (not per-attack). Maps class name to function name via `_G[]` lookup.
- **Battlerage** uses generic handlers (`standardBattlerage`, `crowdControlBattlerage`) with only 4 special-cased classes.
- **Stormhammer caching**: Update events call `invalidateStormhammer()` (sets dirty flag). Recompute happens lazily during prompt cycle.
- **GMCP balance tracking**: `recordBalanceSample()` measures inter-attack intervals in a rolling window of 20 per class. `getAttackCooldown()` returns 95% of the average.
- **Knight classes** have separate standalone functions with 4 specs each.
- **Monk** has `monkBashing2()` handling both Tekura and Shikudo specs.

### Before Modifying Basher Code

See `docs/plans/basher-review.md` for:
- Current architecture and file analysis
- Known issues and improvement history
- System integrations
