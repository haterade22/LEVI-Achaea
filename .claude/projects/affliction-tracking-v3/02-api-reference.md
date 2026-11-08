# V3 API Reference

## Configuration

### `affConfigV3`
Global configuration table for the V3 system.

```lua
affConfigV3 = {
    enabled = true,           -- Enable/disable V3 tracking
    minProbability = 0.01,    -- Minimum probability to keep a branch
    debugEcho = true          -- Show [V3] lines
}
affConfigV3.maxStates = 300   -- Maximum branch count before pruning (outside the table: a reload keeps the old one)
```

## Core Functions

### `resetStatesV3()`
Reset all affliction states to a single empty branch. Called when acquiring a new target.

```lua
resetStatesV3()
-- Result: afflictionStatesV3 = {{affs = {}, prob = 1.0}}
```

### `applyAffV3(aff)`
Apply an affliction to all branches.

```lua
applyAffV3("paralysis")
-- Adds paralysis = true to all existing states
```

### `removeAffV3(aff)`
Remove an affliction from all branches (when cure is certain).

```lua
removeAffV3("asthma")
-- Removes asthma from all states (e.g., tree tattoo cured it)
```

## Probability Functions

### `getAffProbabilityV3(aff)`
Get the probability (0.0 to 1.0) that target has an affliction.

```lua
local prob = getAffProbabilityV3("asthma")
if prob >= 0.9 then
    echo("Asthma is stuck!")
elseif prob >= 0.5 then
    echo("Asthma likely present")
end
```

### `getAllAffProbabilitiesV3()`
Get a table of all afflictions with their probabilities.

```lua
local allProbs = getAllAffProbabilitiesV3()
for aff, prob in pairs(allProbs) do
    if prob > 0 then
        echo(aff .. ": " .. math.floor(prob * 100) .. "%")
    end
end
```

### `haveAffV3(aff, threshold)`
True when the probability is at or above `threshold` (default 0.3).

### `isAffCertainV3(aff)`
True when every branch holds the affliction (or it is a simple-tracked one that is up). Use this for "certain". **Never compare a V3 probability with `>= 1.0`**: the cache sums the branches, and renormalising can leave the sum a few ulps under 1 (0.99999999999999978 in `test_v3_core_fixes.lua`).

### `getStateProbabilityV3(affList)`
Get the probability that ALL afflictions in the list are present simultaneously.

```lua
local lockProb = getStateProbabilityV3({"anorexia", "slickness", "asthma", "paralysis"})
if lockProb >= 0.9 then
    echo("True lock achieved!")
end
```

## Collapse Functions (Verification)

### `collapseAffPresentV3(aff)`
Collapse states based on proof that affliction IS present.
Removes all branches where the affliction is absent.

```lua
-- Target fumbled = clumsiness confirmed
collapseAffPresentV3("clumsiness")
```

### `collapseAffAbsentV3(aff)`
Collapse states based on proof that affliction is NOT present.
Removes all branches where the affliction exists.

```lua
-- Target smoked = asthma confirmed absent
collapseAffAbsentV3("asthma")
```

If every branch holds it, only that affliction is removed from every branch. The rest of the board stays.

### `proveAffAbsentV3(aff, cureType)`
An action could not have happened with this affliction: an apply proves no slickness, a tree no paralysis. Call it BEFORE erasing. With `cureType` set, nothing happens while that cure's clock runs (the line is read as an illusion). Where every branch holds the affliction, it only comes off.

```lua
if proveAffAbsentV3 then proveAffAbsentV3("slickness", "salve") end
erAff("slickness")
```

## Cure Handling

### `onHerbCureV3(herb)`
Handle target eating an herb. Creates branches for each possible cure.

```lua
-- Called by herb triggers
onHerbCureV3("kelp")    -- Branches on kelp-curable affs
onHerbCureV3("bloodroot")  -- Branches on paralysis/slickness
```

**Supported herbs**: `kelp`, `bloodroot`, `goldenseal`, `ginseng`, `ash`, `bellwort`, `lobelia`

### `onSmokeCureV3()`
Handle target smoking. Proves asthma absent and branches on smoke-curable afflictions.

```lua
-- Called by smoke trigger
onSmokeCureV3()
```

**Smoke-curable afflictions**: aeon, deadening, hellsight, tension, disloyalty, manaleech, slickness, unweavingspirit, dazed, earworm

### `onSalveCureV3(salveType)`
Handle target applying salve. Proves slickness absent and branches on salve-curable afflictions for the specified body part.

```lua
-- Called by salve triggers
onSalveCureV3("body")    -- Body salve (mending)
onSalveCureV3("skin")    -- Skin salve (mending)
onSalveCureV3("head")    -- Head salve (restoration)
onSalveCureV3("torso")   -- Torso salve (mending/restoration)
onSalveCureV3("limbs")   -- Limbs salve (restoration)
```

**salveType parameter**: `"body"`, `"skin"`, `"head"`, `"torso"`, `"limbs"`

**Behavior**:
1. Collapses slickness absent (applying salve proves no slickness)
2. Closes a guess an earlier eat or smoke left open (`killNegativeConfirmV3`)
3. Checks each branch for salve-curable afflictions
4. If 1 candidate → cures it definitively
5. If multiple candidates → branches into possibilities
6. Stamps `salveChargedAtV3`, so 396's `onTargetApplySalveV3` on the same line does nothing
7. Consolidated echo output (one line per cure event)

### `onTargetTreeV3()`, `onTargetFocusV3()`, `onPassiveCureV3(numCures)` (`008`)
A tree (`:329-380`) drops the branches that hold paralysis (`proveAffAbsentV3`; where every branch holds it, it only comes off), then branches over `treeCurableAffsV3`. A focus (`:383-438`) needs impatience absent, then branches over `focusCurableAffsV3`. A passive (`:473-581`) branches over `passiveCurableAffsV3`. One tree or passive reports only afflictions the tracker held: in `tAffs` or at 30% or more before the cure. `curing/002`'s `ataxia_targetTreeV3` (`:206-243`) is the tree's entry point.

### `onTargetApplySalveV3()` (`008:141-150`)
Generic apply (trigger 396). Slickness proof and salve clock, unless 391-395 charged this application under 0.1 s ago.

### `ataxia_randomCureV3(kind, who, cure)` and `ataxia_knownCureV3(kind, who, aff)` (`ataxia/001_Miscellaneous_Aff_Tracking_Methods.lua:384`, `:401`)
A cure that prints a second line naming what it took. `randomCure` runs `cure()` and keeps the branches from before and after. `knownCure` puts "before" back, applies what the action itself proved (anorexia for an eat, asthma for a smoke, impatience for a focus), takes out `aff`, and drops the pending guess. It returns false, doing nothing, unless the random cure was `who`'s, of this `kind`, under `ataxia_KNOWN_CURE_WINDOW` (0.5 s) ago, and nothing else changed the branches. See [03-trigger-integration.md](03-trigger-integration.md).

## Utility Functions

### `getCurableAffs(herb)`
Get the list of afflictions a herb can cure.

```lua
local kelp_cures = getCurableAffs("kelp")
-- Returns: {"asthma", "clumsiness", "healthleech", ...}
```

## Internal Functions

### `rebuildCacheV3()`
Rebuild the probability cache. Called automatically after state changes.

### `deduplicateStatesV3()`
Merge identical states (same affliction set) by summing probabilities.

### `pruneStatesV3()`
Remove low-probability branches and enforce max branch limit. When every branch is under the floor it keeps them all.

### `syncToOldSystemV3()`
Sync V3 state to legacy `tAffs`: 30% or more is true; under 1%, or fallen under 30% since the last sync, is false.

### `onNegativeConfirmExpiredV3(guess)`
Only echoes "Neg-confirm timeout -- branch kept". It no longer unfolds a cure (see 01-architecture).

### `updateAffDisplayV3()`
Update the Limb Counter window display.

## Debug Functions

### `showBranchesV3()` and `showAffProbsV3()` (`007:1115`, `:1139`)
Print all current states, and every affliction's probability, to the console. `v3status()` and `v3probs()` (`008:249`, `:262`) do the same as a short report. A refused cure prints `[V3] ILLUSION: ...` under `debugEcho` (`008:76-80`).

```lua
showBranchesV3()
```

### `v3Echo(msg)`
Echo a V3 debug message (only if debug enabled or always for important messages).

```lua
v3Echo("kelp cured: asthma")
-- Output: (LEVI): [V3] kelp cured: asthma
```

## Cure Tables Reference

### Herb, smoke and salve tables
The current lists are in the [README](README.md) ("Cure Tables"). `getCurableAffs` reads the global `curingTable` first. `herbCureTableV3` no longer exists.

## Event Handlers

### State Reset
V3 states are reset when the target changes (`007:1525-1529`):
```lua
registerAnonymousEventHandler("changed target", function()
    resetStatesV3()
    resetCureBalancesV3()
    killNegativeConfirmV3()
end)
```

### Display Update
The Limb Counter window is updated after state changes via `updateAffDisplayV3()`.
