# V3 Trigger Integration

## Overview

V3 integrates with existing triggers by adding function calls that update the branching state tracker. The V3 calls run alongside existing V2/legacy tracking for redundancy.

## Herb Triggers

### Integration Pattern
Each herb trigger should call `onHerbCureV3()` after detecting the target eating:

```lua
if isTargeted(matches[2]) then
    -- Existing code...
    targetAteWrapper("herbname")

    -- V3 integration
    if onHerbCureV3 then onHerbCureV3("herbname") end

    -- Rest of existing code...
end
```

### Integrated Herb Triggers

#### Living Herbs (`triggers/levi_ataxia/for_levi/leviticus/herbs/`)

| File | Herb | V3 Call |
|------|------|---------|
| `001_Goldenseal(U).lua` | goldenseal | `onHerbCureV3("goldenseal")` |
| `002_Goldenseal_(Madness).lua` | goldenseal | `onHerbCureV3("goldenseal")` |
| `003_Kelp_(Unknown).lua` | kelp | `onHerbCureV3("kelp")` |
| `004_Kelp_(Unknown)_2.lua` | kelp | `onHerbCureV3("kelp")` |
| `005_Goldenseal_(Mycalium).lua` | goldenseal | `onHerbCureV3("goldenseal")` |
| `006_Bloodroot_TEST.lua` | bloodroot | `onHerbCureV3("bloodroot")` |
| `007_Ash.lua` | ash | `onHerbCureV3("ash")` |
| `008_Ginseng.lua` | ginseng | `onHerbCureV3("ginseng")` |
| `009_Ginseng_with_Flushings.lua` | ginseng | `onHerbCureV3("ginseng")` |
| `010_Bellwort_Cuprum.lua` | bellwort | `onHerbCureV3("bellwort")` |
| `011_Lobelia.lua` | lobelia | `onHerbCureV3("lobelia")` |

#### Undead Herbs (`triggers/levi_ataxia/for_levi/leviticus/herbs_undead/`)

| File | Herb | V3 Call |
|------|------|---------|
| `001_Goldenseal(U).lua` | goldenseal | `onHerbCureV3("goldenseal")` |
| `002_Goldenseal_(Madness).lua` | goldenseal | `onHerbCureV3("goldenseal")` |
| `003_Kelp_(Unknown).lua` | kelp | `onHerbCureV3("kelp")` |
| `004_Goldenseal_(Mycalium).lua` | goldenseal | `onHerbCureV3("goldenseal")` |
| `005_Bloodroot_TEST.lua` | bloodroot | `onHerbCureV3("bloodroot")` |
| `006_Ash.lua` | ash | `onHerbCureV3("ash")` |
| `007_Ginseng.lua` | ginseng | `onHerbCureV3("ginseng")` |
| `008_Ginseng_with_Flushings.lua` | ginseng | `onHerbCureV3("ginseng")` |
| `009_Bellwort_Cuprum.lua` | bellwort | `onHerbCureV3("bellwort")` |
| `010_Lobelia.lua` | lobelia | `onHerbCureV3("lobelia")` |

## Smoke Trigger

### File: `369_Smoked.lua`

```lua
if isTargeted(matches[2]) then
    -- V2 integration
    if onTargetSmokeV2 then onTargetSmokeV2(matches[2]) end

    -- V3 integration: handle smoke cure (proves asthma absent AND branches on smoke-curable affs)
    if onSmokeCureV3 then onSmokeCureV3() end

    -- Rest of existing code...
end
```

The `onSmokeCureV3()` function:
1. Calls `collapseAffAbsentV3("asthma")` - proves asthma is absent
2. Branches on which smoke-curable affliction was removed

## Affliction Application Triggers

### Third-Person Hit Triggers
When we see our venom hit the target, apply the affliction:

```lua
-- Example: paralysis hit trigger
if isTargeted(matches[2]) then
    tarAffed("paralysis")

    -- V3 integration
    if applyAffV3 then applyAffV3("paralysis") end
end
```

### DWC Venom Hits
The DWC system has integrated V3 calls in venom hit handlers:

```lua
-- In 003_Infernal_DWC_Vivisect.lua
function infernalDWC.onVenomHit(venom, target)
    local aff = venomToAff[venom]
    if aff and applyAffV3 then
        applyAffV3(aff)
    end
end
```

## Verification Triggers

### Fumble Detection
When target fumbles, proves clumsiness is present:

```lua
-- Fumble trigger
if isTargeted(matches[2]) then
    if collapseAffPresentV3 then collapseAffPresentV3("clumsiness") end
end
```

### Smoke Detection (Asthma Absent)
Already handled in `onSmokeCureV3()`.

### Prone Detection
When target is prone, can collapse certain states:

```lua
if isTargeted(matches[2]) then
    if collapseAffPresentV3 then collapseAffPresentV3("prone") end
end
```

## Adding V3 to New Triggers

### Step 1: Identify the event type
- Herb cure → `onHerbCureV3(herbname)`
- Smoke cure → `onSmokeCureV3()`
- Affliction applied → `applyAffV3(affname)`
- Affliction confirmed present → `collapseAffPresentV3(affname)`
- Affliction confirmed absent → `collapseAffAbsentV3(affname)`

### Step 2: Add the call with nil check

```lua
-- Always wrap in nil check for safety
if onHerbCureV3 then onHerbCureV3("kelp") end
```

### Step 3: Place after existing tracking calls

```lua
-- Existing V2 tracking
if onTargetKelpV2 then onTargetKelpV2(matches[2]) end

-- V3 tracking (add after V2)
if onHerbCureV3 then onHerbCureV3("kelp") end
```

## Echo Output

V3 produces consolidated echo output for cure tracking:

```
(LEVI): [V3] bloodroot cured: paralysis
(LEVI): [V3] kelp eaten - branched into 3 states
(LEVI): [V3] smoke cured: slickness
```

The output is consolidated (one line per cure event, not per branch).
