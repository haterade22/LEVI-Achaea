# V3 Trigger Integration

## Overview

V3 integrates with existing triggers by adding function calls that update the branching state tracker. The V3 calls run alongside existing V2/legacy tracking for redundancy.

**Not a V1 erase after a V3 cure.** V3 copies its result into `tAffs`. A V1 erase chain that runs after it reads that copy and takes a SECOND affliction. Since v4.7.479 the bloodroot trigger runs its V1 chain only with V3 off (see Bloodroot below).

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

The second table matches today's `herbs/` folder. Most of those triggers reach V3 through `targetAteWrapper` (`affliction_tracking_core/008_V3_Integration.lua:48`), which calls `onHerbCureV3` and nothing else.

#### Bloodroot (`herbs/005_Bloodroot_TEST.lua`), since v4.7.479

The 2026-11-07 Serpent spar found three faults here (`kb/raw/logs/ours/2026-11-07_164635_Saibel.log`).

- **The target's own eat never set her clocks, and anyone else's eat erased our target's afflictions.** A stray `else` closed `if matches[2] == target`. The target's eat still ran the cures above it, but the code after the `else` ran only for a bystander's eat, and it erased our target's paralysis, pyramides or slickness. So the target's eat never set `tBals.plant`, `targetIshere` or `predictBal`, and her 29 magnesium eats in the spar never stopped the TargetOutOfRoom timer. Now the match is `isTargeted(matches[2])` (`005:41`), as in the other herb triggers, so a part-name target (`t sai`) works too. The target's eat sets the plant clock, `targetIshere` and `predictBal("herb", 1.55)` (`005:120-139`). A bystander's eat only turns the line red (`005:141-144`).
- **Each eat took two afflictions.** With V3 on, the V1 erase chain still ran after `onHerbCureV3`. `tAffs.paralysis` was already false by then, so the chain erased slickness too. Now `005:66-78` runs `onHerbCureV3("bloodroot")` alone when `affConfigV3.enabled`. The V1 chain (`005:79`) runs only with V3 off.
- **A V3 cure left no `-tar` row.** The V1 erase raised "target cured aff", and `onHerbCureV3` raises nothing. Now each bloodroot affliction (`curingTable.bloodroot`, else `curingTableV3.bloodroot`) that V3 held before the eat and holds below 0.01 after it is reported through `ataxia_tarAffFaded` (`005:68-77`). That call also stops a timed clock. A cure that V3 only branched over is a guess, so it is not reported.

`onTargetBloodrootV2` still runs on every target eat (`005:55`). Tests: `src_new/tests/test_target_presence_lines.lua` (the "005:" blocks).

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

## Salve Triggers

### Integration Pattern
Each salve trigger should call `onSalveCureV3()` with the body part after detecting the target applying salve:

```lua
if isTargeted(matches[2]) then
    -- Existing V2 code...
    if onTargetSalveBodyV2 then onTargetSalveBodyV2(matches[2]) end

    -- V3 integration
    if onSalveCureV3 then onSalveCureV3("body") end

    -- Rest of existing code...
end
```

### Integrated Salve Triggers (`triggers/levi_ataxia/for_levi/leviticus/`)

| File | Body Part | V3 Call |
|------|-----------|---------|
| `370_Applied_Body_Skin.lua` | body or skin | `onSalveCureV3(matches[3])` — passes "body" or "skin" |
| `371_Applied_Head.lua` | head | `onSalveCureV3("head")` |
| `372_Applied_Torso.lua` | torso | `onSalveCureV3("torso")` |
| `374_Applied_Limbs.lua` | limbs (arms/legs) | `onSalveCureV3("limbs")` |
| `375_Salves.lua` | generic (any) | `onTargetApplySalveV3()` — slickness collapse only |

### Salve Cure Tables

| Salve Type | Curable Afflictions |
|------------|---------------------|
| body | anorexia, itching, bloodfire, selarnia, frostbite |
| skin | frozen, shivering, nocaloric, bloodfire, selarnia, frostbite |
| head | crushedthroat, damagedhead, mangledhead, blindness, scalded, epidermal, bloodfire |
| torso | hypothermia, bloodfire, selarnia, frostbite |
| limbs | bloodfire |

The `onSalveCureV3(salveType)` function:
1. Calls `collapseAffAbsentV3("slickness")` — proves slickness is absent (can't apply if slick)
2. Branches on which salve-curable affliction was removed from the body part's cure list

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
- Salve cure → `onSalveCureV3(salveType)` — salveType: "body", "skin", "head", "torso", "limbs"
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
(LEVI): [V3] body salve cured: anorexia
(LEVI): [V3] head salve - branched into 4 states
(LEVI): [V3] Collapsed 2 branches (proved slickness absent)
```

The output is consolidated (one line per cure event, not per branch).
