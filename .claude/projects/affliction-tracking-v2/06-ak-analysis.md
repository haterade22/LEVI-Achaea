# AK 8.6.5 Analysis and Learnings

## Overview

Analyzed the Loki 2.1.4 + AK 8.6.5 combat system (Serpent offensive + Affliction Keeper) to understand best practices for affliction tracking. This document captures key patterns and how they influenced V2 design.

**Source**: `Loki 2.1.4 + AK 8.6.5 (modified) (package install).mpackage`

## Key AK Patterns

### 1. Numeric Score Tracking (`affstrack.score`)

AK uses numeric scores instead of boolean values:

```lua
affstrack.score[aff] = 0     -- Absent
affstrack.score[aff] = 100   -- 1 confirmed instance
affstrack.score[aff] = 200   -- 2 stacked instances
```

**V2 Adaptation**: We use certainty levels with stacking support:
```lua
tAffsV2[aff] = 0   -- Absent
tAffsV2[aff] = 2   -- 1 confirmed instance
tAffsV2[aff] = 4   -- 2 stacked instances
```

The key insight: higher values = more stacks. Odd values indicate uncertainty (e.g., 3 = likely 2 stacks but 1 uncertain).

### 2. Core Affliction Functions

| AK Function | Purpose | V2 Equivalent |
|-------------|---------|---------------|
| `OppGainedAff(aff, source)` | Confirm affliction applied | `confirmAffV2(aff)` |
| `OppLostAff(aff)` | Remove affliction | `removeAffV2(aff)` |
| `OppGainedAdditive(aff, inc, cap)` | Stack affliction | `stackAffV2(aff)` |

### 3. Backtracking (`ak.thoughtIhad`)

AK's backtracking mechanism when smoke proves asthma was cured:

```lua
if affstrack.score.asthma > 0 then
    if ak.thoughtIhad then
        ak.thoughtIhad("asthma")
    else
        affstrack.score.asthma = 0
    end
end
```

**V2 Adaptation**: `backtrackKelpCureV2()` reverses incorrect guesses when verification signals arrive.

### 4. Random Cure Counter (`ak.randomaffs`)

AK tracks expected random cures (tree, focus, passive abilities):

```lua
ak.randomaffs = ak.randomaffs or 0

-- When target uses tree:
if ak.randomaffs > 0 then
    ak.randomaffs = ak.randomaffs - 1
else
    -- Unexpected tree - reduce certainty
    reduceRandomAffCertainty()
end
```

**V2 Implementation**:
```lua
randomCuresV2 = 0

function onTargetTreeV2(target)
    if randomCuresV2 > 0 then
        randomCuresV2 = randomCuresV2 - 1
    else
        reduceRandomAffCertaintyV2()
    end
end
```

### 5. Pending Cure Tracking (`ocured` tables)

AK tracks which afflictions were potentially cured by each herb:

```lua
ocured = ocured or {}
ocured.kelp = {}      -- Afflictions possibly cured by kelp
ocured.smoked = {}    -- Afflictions possibly cured by smoking
ocured.bloodroot = {} -- Afflictions possibly cured by bloodroot
```

**V2 Adaptation**: We use `pendingKelpAffsV2` for asthma disambiguation and `lastGuessV2` for backtracking.

### 6. Confirmation Signals (`ak.ProTrackingConfirmed`)

AK confirms affliction presence through behavioral signals:

```lua
-- When target fumbles, confirms clumsiness
if ocured.bloodroot.paralysis and ocured.bloodroot.slickness then
    ak.ProTrackingConfirmed("slickness")
end
```

**V2 Implementation**: `onTargetFumbleV2()` confirms clumsiness when target fumbles.

## Priority List Learnings

AK's herb priority lists are ordered by:
1. **Combat impact** - Lock-critical afflictions last (keep tracking longer)
2. **Verifiability** - Unverifiable afflictions first (assume cured first)

### AK Priority Patterns

```lua
-- From AK's ocured tables and priority handling:
kelp = {"hypochondria", "parasite", "weariness", "healthleech",
        "sensitivity", "clumsiness", "asthma"}
ginseng = {"addiction", "lethargy", "haemophilia", "darkshade",
           "nausea", "scytherus"}
goldenseal = {"depression", "shyness", "dizziness", "stupidity",
              "epilepsy", "impatience"}
```

**Rationale**:
- `hypochondria` first: Can't verify, low combat impact
- `asthma` last: Can verify via smoke, critical for locks
- `impatience` last: Critical for true lock, verify via failed focus

## Integration Insights

### Centralized Detection

AK uses centralized triggers for opponent cure detection rather than individual herb triggers. Key trigger types:

1. **Opponent Ate** - Single trigger catches all herb consumption
2. **Opponent Tree** - Detects tree tattoo usage
3. **Opponent Smoked** - Detects pipe usage
4. **Class Cures** - Handles all class-specific passive/active cures

**V2 Approach**: We integrated with existing centralized triggers:
- Tree trigger (`368_Tree(U).lua`)
- Focus triggers (`377_Focus_(UNK).lua`, `378_Focus_(known).lua`)
- Passive/Active class cures (16 files in `passive_active/`)

### Class-Specific Cure Handling

Each class cure has specific handling:

| Cure Type | Detection | Handling |
|-----------|-----------|----------|
| Known aff | Specific message | `removeAffV2("aff")` |
| Random aff | Generic message | `reduceRandomAffCertaintyV2()` |
| Multiple random | Class-specific | Multiple `reduceRandomAffCertaintyV2()` calls |
| Full reset | Phoenix-like | `resetAffsV2()` |

### Combat Flow Integration

AK integrates affliction tracking into the full combat loop:

```
Attack lands → OppGainedAff() → affstrack.score[aff] = 100
    ↓
Target cures → ocured[herb] populated → wait for confirmation
    ↓
Confirmation signal → OppLostAff() or ak.ProTrackingConfirmed()
    ↓
Random cure → ak.randomaffs decremented → reduce certainty
```

## Key Takeaways

1. **Numeric tracking is superior** - Boolean can't represent uncertainty or stacks
2. **Random cure counting matters** - Tree/focus/passives need explicit tracking
3. **Verification signals are gold** - Fumble, smoke, behavioral patterns confirm state
4. **Priority order is strategic** - Combat-critical affs should be tracked longest
5. **Backtracking is essential** - Wrong guesses happen; be ready to reverse them
6. **Centralized triggers are cleaner** - One place to integrate V2, not scattered changes

## Future Enhancements (from AK)

### Enemy Priority Tracking (`ak.enemyprio`)
AK predicts enemy cure order based on their serverside curing priorities. Could improve V2 by:
- Learning enemy cure patterns
- Adjusting priority lists per opponent
- Predicting which aff will be cured next

### Per-Herb Pending Tracking
More granular `pendingCuresV2[herb]` tables for each herb type, not just kelp:
```lua
pendingCuresV2 = {
    kelp = {},
    ginseng = {},
    goldenseal = {},
    ash = {},
    bellwort = {},
    lobelia = {},
    bloodroot = {}
}
```

### Decay System
Time-based certainty decay for afflictions that should have triggered effects:
```lua
-- If clumsiness hasn't caused a fumble in 30 seconds, reduce certainty
if getEpoch() - affTimersV2.clumsiness > 30 then
    uncertainAffV2("clumsiness")
end
```
