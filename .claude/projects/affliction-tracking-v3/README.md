# Affliction Tracking V3 - Branching State Tracker

## Overview

The V3 affliction tracking system is a probability-based branching state tracker that handles uncertainty by maintaining multiple possible world states. When an ambiguous cure happens (e.g., kelp curing one of 3 possible afflictions), V3 branches into 3 separate states, each representing one possibility.

## Implementation Status: ACTIVE

| Component | Status | Description |
|-----------|--------|-------------|
| Core Branching | ✅ | Multiple state tracking with probabilities |
| Herb Cures | ✅ | All 7 herbs with branching support |
| Smoke Cures | ✅ | Smoke cure table with branching |
| Salve Cures | ✅ | All 5 salve types (body/skin/head/torso/limbs) with branching |
| Affliction Application | ✅ | `applyAffV3()` for adding afflictions |
| Affliction Collapse | ✅ | `collapseAffPresentV3()` / `collapseAffAbsentV3()` |
| Probability Queries | ✅ | `getAffProbabilityV3()`, `getAllAffProbabilitiesV3()` |
| Limb Counter Integration | ✅ | Display with probability-based coloring |
| Trigger Integration | ✅ | All herb + salve triggers integrated |

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
- [00-reference-from-claude-md.md](00-reference-from-claude-md.md) - The V3 section of `CLAUDE.md` until 2026-11-13, moved verbatim. Not yet reconciled with the files above: where they disagree, check the code

## Integrated Combat Classes

| Class | File | Helper Function | Status |
|-------|------|-----------------|--------|
| **Infernal DWC** | `dwc/001_Infernal_DWC_Vivisect.lua` | `infernalDWC.hasAff()` | V3 ready |
| **Blademaster Ice** | `blademaster/005_CC_BM_Ice.lua` | `blademaster.hasAff()` | V3 ready (2026-01-29) |

Each class uses the same routing pattern: V3 (probability, 30% threshold) → V2 (certainty) → V1 (boolean tAffs).
Shield/rebounding checks use dual-check pattern for safety (hasAff + raw tAffs fallback).

## Deployed Files

```
src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/
├── 007_Branching_State_Tracker.lua  # Core V3 system
├── 008_V3_Integration.lua           # Integration with existing systems
└── 009_Test_Scenario.lua            # Test scenarios
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

Bloodroot (`herbs/005_Bloodroot_TEST.lua`) calls `onHerbCureV3` itself. Since v4.7.479 it skips its V1 erase chain while V3 is on, because that chain took a second affliction per eat. It reports a cure that V3 made certain through `ataxia_tarAffFaded`. See [03-trigger-integration.md](03-trigger-integration.md) ("Bloodroot").

Kelp (`herbs/003`), ginseng (`herbs/007`, `008`) and goldenseal (`herbs/002`) run `onHerbCureV3` through `ataxia_randomCureV3`, so a following line that names the cure can replace the random cure. See [03-trigger-integration.md](03-trigger-integration.md) ("Known-cure lines").

### Smoke Trigger
`390_Smoked.lua` calls `onSmokeCureV3()` (through `ataxia_randomCureV3`) which:
1. Proves asthma is absent (can't smoke with asthma)
2. Branches on which smoke-curable affliction was removed

### Salve Triggers
The salve triggers call `onSalveCureV3(salveType)`, which:
1. Proves slickness is absent (can't apply salve while slick)
2. Closes a pending guess from an earlier eat or smoke (`killNegativeConfirmV3`)
3. Branches on which salve-curable affliction was removed

| File | Salve Type | V3 Call |
|------|------------|---------|
| `391_Applied_Body_Skin.lua` | body/skin | `onSalveCureV3("body")` or `("skin")` |
| `392_Applied_Head.lua` | head | `onSalveCureV3("head")` |
| `393_Applied_Torso.lua` | torso | no cure call: it proves slickness only, and its restoration is delayed |
| `395_Applied_Limbs.lua` | limbs | `onSalveCureV3("limbs")` |
| `396_Salves.lua` | generic | `onTargetApplySalveV3()` (slickness only; a no-op when 391-395 charged this line) |

## Cure Tables

### Herb Cure Tables
`getCurableAffs` reads the global `curingTable` first (`curing/002_Wide_Groups.lua`, pinned to the game's WHATCURES) and only then `curingTableV3` (`007:139-147`). Today only that table's `bloodroot` row is read. An old `herbCureTableV3` is gone. Fratricide is a cure-last entry (`herbCureLastV3`, `007:158`): an eat takes it only when nothing else that herb cures is there.

### Smoke Cure Priority Table
One table for both pipes, because the smoke line does not name the herb (`007:168`).
```lua
smokeCureTableV3 = {"aeon", "deadening", "hellsight", "tension", "disloyalty", "manaleech",
                    "slickness", "unweavingspirit", "dazed", "earworm"}
```

### Salve Cure Tables (by body part, `007:186-191`)
The line names the spot and not the salve, so each list is every affliction a salve at that spot cures, sorted by our curing priority. Torso has no list. Slickness and bloodfire are proofs and are not listed.
```lua
salveCureTableV3 = {
    body = {"heartseed", "anorexia", "itching", "internalbleeding", "burning",
            "mildtrauma", "serioustrauma", "selarnia"},
    skin = {"frostbite", "frozen", "shivering", "nocaloric"},
    head = {"calcifiedskull", "dazzled", "concussion", "tonguetied", "stuttering",
            "laceratedthroat", "slashedthroat"},
    limbs = {},
}
```

### Tree, focus and passive pools (`008`)
`treeCurableAffsV3` (`:278-308`), `focusCurableAffsV3` (`:319-324`) and `passiveCurableAffsV3` (`:452-470`: voyria, then the tree pool, 77 entries). `tools/kb_affliction_db.py` parses the passive pool from the file's text, so it stays a literal.

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

-- An action that could not happen with it. Call this BEFORE any erase
proveAffAbsentV3("slickness", "salve")   -- the second argument is optional, the action's cure clock

-- Is it in every branch? Never compare a probability with >= 1.0: a sum can be a few ulps under 1
isAffCertainV3("paralysis")

-- Handle herb cure (called by triggers)
onHerbCureV3("kelp")

-- Handle smoke cure (called by trigger)
onSmokeCureV3()

-- Handle salve cure (called by salve triggers)
onSalveCureV3("body")   -- body, skin, head, torso, or limbs

-- Reset all states (new target; the "changed target" event does this, 007:1525-1529)
resetStatesV3()

-- Debug: view current states
showBranchesV3()
showAffProbsV3()
```

## Verification Commands

```lua
-- Check if V3 is enabled
lua affConfigV3.enabled

-- View all branch states
lua showBranchesV3()

-- View affliction probabilities
lua showAffProbsV3()
lua getAllAffProbabilitiesV3()

-- Check specific affliction probability
lua getAffProbabilityV3("asthma")

-- View number of branches
lua #afflictionStatesV3
```
