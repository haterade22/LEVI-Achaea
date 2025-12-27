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
1. Victim has NO sileris/fangbarrier
2. Victim HAS asthma
3. Victim HAS weariness

### Cure Competition
| Herb | Competing Afflictions | Priority |
|------|----------------------|----------|
| **Kelp** | asthma vs weariness | Cure ASTHMA (breaks Impulse) |
| **Bloodroot** | paralysis vs slickness | Cure PARALYSIS when asthma present |

### Fratricide Mechanic
- Delivered via Hypnosis SNAP
- Causes impulse mental afflictions (impatience) to RELAPSE after focus
- Cure with Argentum EARLY when asthma + slickness present

### Priority Swaps (029_Priority_Swaps.lua)
| Swap | Condition | Action |
|------|-----------|--------|
| `astWear` | asthma + weariness vs Serpent | Boost asthma → prio 3 |
| `paraAst` | asthma + para + slick | Boost paralysis → prio 1 |
| `fratLock` | fratricide + asthma + slick | Boost fratricide → prio 4 |

### AntiSerpent Function (299_Anti_Priorities.lua)
- **Tree trigger**: asthma + slickness + (impatience OR anorexia) = "approaching lock"
- Fires tree BEFORE paralysis locks you out

### Key Files
- `.claude/classes/serpent.md` - Full Serpent mechanics
- `.claude/classes/lock_types.md` - Serpent lock strategy section
- `src/ataxia/029_Priority_Swaps.lua` - Priority swap implementations
- `src/ataxia/299_Anti_Priorities.lua` - AntiSerpent function

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

## Key Files Reference

| Path | Purpose |
|------|---------|
| `.claude/classes/lock_types.md` | Comprehensive lock definitions |
| `.claude/classes/README.md` | Class index and combat concepts |
| `.claude/classes/<class>.md` | Per-class kill routes and mechanics |
| `.claude/classes/monk.md` | Monk/Shikudo kill routes and mechanics |
| `CLAUDE.md` | Main project documentation |
| `src/ataxia/200_Shikudo.lua` | Shikudo V1 dispatch system |
| `src/ataxia/201_Shikudo_V2.lua` | Shikudo V2 dispatch system |
| `src/ataxia/203_Shikudo_Lock.lua` | Shikudo Lock affliction system |

---

## Basher Development Reference

### Key Files

| File | Purpose |
|------|---------|
| `src/ataxiaBasher/005_Bashing_Functions.lua` | Main attack dispatch |
| `src/ataxiaBasher/006_Class_Bashing.lua` | Class-specific patterns |
| `src/ataxiaBasher/008_search_targets.lua` | Target acquisition, Stormhammer |

### Configuration Options

| Setting | Type | Purpose |
|---------|------|---------|
| `ataxiaBasher.enabled` | bool | Master on/off |
| `ataxiaBasher.fleeThreshold` | number | HP% to flee |
| `ataxiaBasher.dangerCount` | number | Max dangerous mobs |
| `ataxiaBasher.targetList` | table | Per-area targets |

### Before Modifying Basher Code

See `docs/plans/basher-review.md` for:
- Current architecture and file analysis
- Known issues and improvement plans
- System integrations
