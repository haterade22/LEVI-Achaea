# Affliction Tracking V2 System

## Overview

A redesigned target affliction tracking system for the LEVI-Ataxia combat system. This V2 system runs in parallel with the existing system, allowing for safe testing and instant fallback.

## Implementation Status: COMPLETE ✅

All core functionality has been implemented and integrated:

| Component | Status | Description |
|-----------|--------|-------------|
| Core Module | ✅ | Certainty tracking, stack tracking, random cure counter |
| Herb Cures | ✅ | Priority lists for all 7 herbs, disambiguation |
| Backtracking | ✅ | Guess storage and reversal |
| Verification | ✅ | Fumble/smoke signal handlers |
| Herb Triggers | ✅ | 15 triggers call `targetAteWrapper()` |
| Smoke Trigger | ✅ | Calls `onTargetSmokeV2()` |
| Tree Trigger | ✅ | Calls `onTargetTreeV2()` |
| Focus Triggers | ✅ | Calls `onTargetFocusV2()` |
| Class Cures | ✅ | 16 passive/active cure triggers integrated |

### Remaining Work
- **Fumble trigger** - Need in-game patterns to detect fumbles

## Key Features

1. **Certainty-based tracking** - Uses 0/1/2+ levels instead of boolean true/false
2. **Stack tracking** - Tracks multiple instances of same affliction (2=1 stack, 4=2 stacks, etc.)
3. **Verifiability-based priority** - Assumes unverifiable afflictions cured first
4. **Random cure counter** - Tracks tree/focus/passive cures like AK's `ak.randomaffs`
5. **Backtracking system** - Reverses incorrect guesses when verification proves otherwise
6. **Third-party verification** - Uses fumble (clumsiness) and smoke (asthma) signals
7. **Full backward compatibility** - Syncs to old tAffs for existing offense code

## Toggle

```lua
ataxia.settings.useAffTrackingV2 = true   -- Enable V2
ataxia.settings.useAffTrackingV2 = false  -- Disable, use old system (default)
```

## Documentation

- [01-problem-analysis.md](01-problem-analysis.md) - Root cause analysis of current bugs
- [02-architecture.md](02-architecture.md) - V2 system design and data structures
- [03-implementation-guide.md](03-implementation-guide.md) - Step-by-step implementation
- [04-verification-signals.md](04-verification-signals.md) - Third-party signal detection
- [05-testing-plan.md](05-testing-plan.md) - Test cases and verification
- [06-ak-analysis.md](06-ak-analysis.md) - AK 8.6.5 analysis and learnings

## Deployed Files

```
src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_v2/
├── 001_Core.lua           # tAffsV2, confirmAffV2, removeAffV2, stack/random cure tracking
├── 002_Herb_Cures.lua     # targetAteV2, herbRemovalPriority for all 7 herbs
├── 003_Backtracking.lua   # backtrackKelpCureV2, pending guess tracking
└── 004_Verification.lua   # onTargetFumbleV2, onTargetSmokeV2, onTargetAttackV2
```

## Integrated Triggers

### Herb Triggers (15 files)
All herb triggers in `herbs/` and `herbs_undead/` now call `targetAteWrapper()`.

### Core Detection Triggers
- `368_Tree(U).lua` - Target tree tattoo
- `369_Smoked.lua` - Target smoking
- `377_Focus_(UNK).lua` - Target focus (unknown cure)
- `378_Focus_(known).lua` - Target focus (known cure)

### Class Passive/Active Cures (16 files in `passive_active/`)
| Trigger | Class | V2 Function |
|---------|-------|-------------|
| Passives | All | `removeAffV2("voyria")` or `reduceRandomAffCertaintyV2()` |
| Accelerate | Depthswalker | `removeAffV2()` + 1-2x `reduceRandomAffCertaintyV2()` |
| Alleviate | Blademaster | `removeAffV2("paralysis")` + `reduceRandomAffCertaintyV2()` |
| Bloodboil | Magi | `removeAffV2("haemophilia")` + `reduceRandomAffCertaintyV2()` |
| Dragonheal | Dragon | `removeAffV2()` + 3x `reduceRandomAffCertaintyV2()` |
| Expunge | Psion | `removeAffV2()` for specific mental affs |
| Fitness | Knights/Monk/BM | `removeAffV2("asthma")` + `removeAffV2("weariness")` |
| Fool | Occultist/Jester | `removeAffV2("paralysis")` + 3x `reduceRandomAffCertaintyV2()` |
| Might | Druid/Sentinel | `removeAffV2("prone")` + `reduceRandomAffCertaintyV2()` |
| Phoenix | Blademaster | `resetAffsV2()` |
| Purification | Shaman | `removeAffV2("selarnia")` + `reduceRandomAffCertaintyV2()` |
| Purify | Water Lord | `removeAffV2("weariness")` + `reduceRandomAffCertaintyV2()` |
| Rage | Knight | `removeAffV2()` for retribution/lovers/paralysis |
| Salt | Alchemist | `removeAffV2("stupidity")` + `reduceRandomAffCertaintyV2()` |
| Shrugging | Serpent | `removeAffV2("weariness")` + `reduceRandomAffCertaintyV2()` |
| Slough | Fire Lord | `reduceRandomAffCertaintyV2()` |
| Eruption | Earth Lord | `reduceRandomAffCertaintyV2()` |

## Quick Start

1. V2 modules are already deployed
2. Set `ataxia.settings.useAffTrackingV2 = true`
3. Test in arena with `debugAffsV2()` to verify tracking
4. If issues, set to `false` to instantly fall back

## Verification Commands

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
