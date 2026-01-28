# Affliction Tracking V3 - Branching State Tracker

## Overview

The V3 affliction tracking system is a probability-based branching state tracker that handles uncertainty by maintaining multiple possible world states. When an ambiguous cure happens (e.g., kelp curing one of 3 possible afflictions), V3 branches into 3 separate states, each representing one possibility.

## Implementation Status: ACTIVE

| Component | Status | Description |
|-----------|--------|-------------|
| Core Branching | ✅ | Multiple state tracking with probabilities |
| Herb Cures | ✅ | All 7 herbs with branching support |
| Smoke Cures | ✅ | Smoke cure table with branching |
| Affliction Application | ✅ | `applyAffV3()` for adding afflictions |
| Affliction Collapse | ✅ | `collapseAffPresentV3()` / `collapseAffAbsentV3()` |
| Probability Queries | ✅ | `getAffProbabilityV3()`, `getAllAffProbabilitiesV3()` |
| Limb Counter Integration | ✅ | Display with probability-based coloring |
| Trigger Integration | ✅ | All herb triggers call `onHerbCureV3()` |

## Key Concepts

### Branching States
Instead of binary true/false, V3 maintains a list of possible states:

```lua
afflictionStatesV3 = {
    {affs = {paralysis=true, asthma=true}, prob = 0.5},
    {affs = {paralysis=true, slickness=true}, prob = 0.5}
}
```

### Probability Calculation
Each affliction's probability is the sum of probabilities across all branches where it exists:
- `paralysis`: 0.5 + 0.5 = 1.0 (100% certain)
- `asthma`: 0.5 (50% likely)
- `slickness`: 0.5 (50% likely)

### State Collapse
When we get verification (e.g., target smokes = asthma absent), we collapse states:
- Remove all branches where asthma exists
- Renormalize remaining branch probabilities

## Toggle

```lua
affConfigV3.enabled = true   -- Enable V3
affConfigV3.enabled = false  -- Disable V3
```

## Documentation

- [01-architecture.md](01-architecture.md) - System design and data structures
- [02-api-reference.md](02-api-reference.md) - Function reference
- [03-trigger-integration.md](03-trigger-integration.md) - How triggers integrate with V3
- [04-display-integration.md](04-display-integration.md) - Limb Counter window integration

## Deployed Files

```
src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_v3/
├── 001_Branching_State_Tracker.lua  # Core V3 system
├── 002_V3_Integration.lua           # Integration with existing systems
└── 999_Test_Scenario.lua            # Test scenarios
```

## Integrated Triggers

### Herb Triggers (Living + Undead)
All herb triggers now call `onHerbCureV3(herbname)`:

| Herb | Function Call |
|------|---------------|
| Bloodroot | `onHerbCureV3("bloodroot")` |
| Kelp | `onHerbCureV3("kelp")` |
| Goldenseal | `onHerbCureV3("goldenseal")` |
| Ginseng | `onHerbCureV3("ginseng")` |
| Ash | `onHerbCureV3("ash")` |
| Bellwort | `onHerbCureV3("bellwort")` |
| Lobelia | `onHerbCureV3("lobelia")` |

### Smoke Trigger
`369_Smoked.lua` calls `onSmokeCureV3()` which:
1. Proves asthma is absent (can't smoke with asthma)
2. Branches on which smoke-curable affliction was removed

## Cure Tables

### Herb Cure Priority Tables
```lua
herbCureTableV3 = {
    kelp = {"asthma", "clumsiness", "healthleech", "hypersomnia", ...},
    bloodroot = {"paralysis", "slickness"},
    goldenseal = {"stupidity", "dizziness", "epilepsy", ...},
    ginseng = {"clumsiness", "sensitivity", "weariness", ...},
    ash = {"impatience", "confusion", "dementia", "recklessness", ...},
    bellwort = {"pacifism", "weariness", "lethargy", ...},
    lobelia = {"anorexia", "disfigurement", "haemophilia", ...}
}
```

### Smoke Cure Priority Table
```lua
smokeCureTableV3 = {"aeon", "deadening", "hellsight", "tension",
                    "disloyalty", "manaleech", "slickness"}
```

## Quick Reference

```lua
-- Apply affliction to target
applyAffV3("paralysis")

-- Check probability of affliction
local prob = getAffProbabilityV3("asthma")  -- Returns 0.0 to 1.0

-- Get all affliction probabilities
local allProbs = getAllAffProbabilitiesV3()

-- Collapse when we KNOW aff is present
collapseAffPresentV3("clumsiness")

-- Collapse when we KNOW aff is absent
collapseAffAbsentV3("asthma")

-- Handle herb cure (called by triggers)
onHerbCureV3("kelp")

-- Handle smoke cure (called by trigger)
onSmokeCureV3()

-- Reset all states (new target)
resetStatesV3()

-- Debug: View current states
debugStatesV3()
```

## Verification Commands

```lua
-- Check if V3 is enabled
lua affConfigV3.enabled

-- View all branch states
debugStatesV3()

-- View affliction probabilities
lua getAllAffProbabilitiesV3()

-- Check specific affliction probability
lua getAffProbabilityV3("asthma")

-- View number of branches
lua #afflictionStatesV3
```
