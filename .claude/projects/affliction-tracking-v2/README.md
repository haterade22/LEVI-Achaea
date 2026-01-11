# Affliction Tracking V2 System

## Overview

A redesigned target affliction tracking system for the LEVI-Ataxia combat system. This V2 system runs in parallel with the existing system, allowing for safe testing and instant fallback.

## Key Features

1. **Certainty-based tracking** - Uses 0/1/2 levels instead of boolean true/false
2. **Verifiability-based priority** - Assumes unverifiable afflictions cured first
3. **Backtracking system** - Reverses incorrect guesses when verification proves otherwise
4. **Third-party verification** - Uses fumble (clumsiness) and smoke (asthma) signals
5. **Full backward compatibility** - Syncs to old tAffs for existing offense code

## Toggle

```lua
ataxia.settings.useAffTrackingV2 = true   -- Enable V2
ataxia.settings.useAffTrackingV2 = false  -- Disable, use old system
```

## Documentation

- [01-problem-analysis.md](01-problem-analysis.md) - Root cause analysis of current bugs
- [02-architecture.md](02-architecture.md) - V2 system design and data structures
- [03-implementation-guide.md](03-implementation-guide.md) - Step-by-step implementation
- [04-verification-signals.md](04-verification-signals.md) - Third-party signal detection
- [05-testing-plan.md](05-testing-plan.md) - Test cases and verification

## Files to Create

```
src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_v2/
├── 001_Core.lua           # tAffsV2, confirmAffV2, removeAffV2
├── 002_Herb_Cures.lua     # targetAteV2, priority lists
├── 003_Backtracking.lua   # backtrackKelpCureV2
└── 004_Verification.lua   # onTargetFumbleV2, onTargetSmokeV2
```

## Files to Modify (Minimal)

- Herb triggers: Change `targetAte()` to `targetAteWrapper()`
- Smoke trigger: Add `onTargetSmokeV2()` call
- Fumble trigger: Add `onTargetFumbleV2()` call

## Quick Start

1. Create the 4 V2 module files
2. Update herb triggers to use wrappers
3. Set `ataxia.settings.useAffTrackingV2 = true`
4. Test in arena with `lua tAffsV2` to verify tracking
5. If issues, set to `false` to instantly fall back
