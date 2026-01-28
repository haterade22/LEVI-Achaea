# V3 API Reference

## Configuration

### `affConfigV3`
Global configuration table for the V3 system.

```lua
affConfigV3 = {
    enabled = true,           -- Enable/disable V3 tracking
    maxBranches = 32,         -- Maximum branch count before pruning
    minProbability = 0.01,    -- Minimum probability to keep a branch
    debug = false             -- Enable debug echo messages
}
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

**Smoke-curable afflictions**: aeon, deadening, hellsight, tension, disloyalty, manaleech, slickness

## Utility Functions

### `getCurableAffs(herb)`
Get the list of afflictions a herb can cure.

```lua
local kelp_cures = getCurableAffs("kelp")
-- Returns: {"asthma", "clumsiness", "healthleech", ...}
```

### `copyAffs(affs)`
Create a deep copy of an afflictions table.

```lua
local copy = copyAffs(state.affs)
```

## Internal Functions

### `rebuildCacheV3()`
Rebuild the probability cache. Called automatically after state changes.

### `deduplicateStatesV3()`
Merge identical states (same affliction set) by summing probabilities.

### `pruneStatesV3()`
Remove low-probability branches and enforce max branch limit.

### `normalizeProbabilitiesV3()`
Ensure all branch probabilities sum to 1.0.

### `syncToOldSystemV3()`
Sync V3 state to legacy `tAffs` table for backward compatibility.

### `updateAffDisplayV3()`
Update the Limb Counter window display.

## Debug Functions

### `debugStatesV3()`
Print all current states to the console.

```lua
debugStatesV3()
-- Output:
-- [V3] Branch 1 (50%): paralysis, asthma
-- [V3] Branch 2 (50%): paralysis, slickness
```

### `v3Echo(msg)`
Echo a V3 debug message (only if debug enabled or always for important messages).

```lua
v3Echo("kelp cured: asthma")
-- Output: (LEVI): [V3] kelp cured: asthma
```

## Cure Tables Reference

### `herbCureTableV3`
```lua
herbCureTableV3 = {
    kelp = {"asthma", "clumsiness", "healthleech", "hypersomnia",
            "hypochondria", "lethargy", "recklessness", "sensitivity", "weariness"},
    bloodroot = {"paralysis", "slickness"},
    goldenseal = {"stupidity", "dizziness", "epilepsy", "impatience",
                  "dissonance", "infested"},
    ginseng = {"clumsiness", "sensitivity", "weariness", "deafblind"},
    ash = {"impatience", "confusion", "dementia", "recklessness",
           "hallucinations", "paranoia"},
    bellwort = {"pacifism", "weariness", "lethargy", "generosity",
                "justice", "peace"},
    lobelia = {"anorexia", "disfigurement", "haemophilia", "limp_veins",
               "sunallergy", "vomiting"}
}
```

### `smokeCureTableV3`
```lua
smokeCureTableV3 = {"aeon", "deadening", "hellsight", "tension",
                    "disloyalty", "manaleech", "slickness"}
```

## Event Handlers

### State Reset
V3 states are reset when a new target is acquired:
```lua
registerAnonymousEventHandler("target acquired", function()
    resetStatesV3()
    v3Echo("States reset")
end)
```

### Display Update
The Limb Counter window is updated after state changes via `updateAffDisplayV3()`.
