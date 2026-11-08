# V3 Architecture - Branching State Tracker

## Core Concept

The V3 system treats affliction tracking as a **probabilistic state machine**. Instead of guessing which affliction was cured, V3 maintains all possibilities simultaneously, weighted by probability.

## Data Structures

### State Table
```lua
afflictionStatesV3 = {
    {
        affs = {paralysis = true, asthma = true, clumsiness = true},
        prob = 0.33
    },
    {
        affs = {paralysis = true, clumsiness = true},
        prob = 0.33
    },
    {
        affs = {paralysis = true, asthma = true},
        prob = 0.34
    }
}
```

Each state represents one possible "world" where specific afflictions exist.

### Probability Cache
```lua
affCacheV3 = {
    paralysis = 1.0,    -- 100% certain (exists in all branches)
    asthma = 0.67,      -- 67% likely
    clumsiness = 0.66   -- 66% likely
}
```

Cache is rebuilt after every state change for O(1) probability lookups. It sums the branches, and renormalising can leave a sum a few ulps under 1, so a test for "certain" is `isAffCertainV3(aff)` (every branch holds it), never `>= 1.0`.

### Configuration
```lua
affConfigV3 = {
    enabled = true,           -- Master toggle
    minProbability = 0.01,    -- Remove branches below 1%
    debugEcho = true          -- Show [V3] lines
}
affConfigV3.maxStates = 300   -- Set outside the table: `X = X or {...}` keeps the old table on a reload
```

The cap was 50. Ten afflictions after three cures is C(10,3) = 120 branches, and the cut through ties skewed real boards (anorexia 0.90 where it was 0.70). A tree on a board at 300 took about 10 ms in Lua 5.1. A board past 300 is still cut (`007:68-78`).

## State Operations

### 1. Apply Affliction
When an affliction is applied, add it to ALL branches:

```lua
function applyAffV3(aff)
    for _, state in ipairs(afflictionStatesV3) do
        state.affs[aff] = true
    end
    rebuildCacheV3()
end
```

### 2. Herb Cure (Branching)
When target eats an herb, the cure is ambiguous. Branch into possibilities:

**Before kelp eaten** (1 state):
```lua
{affs = {asthma=true, clumsiness=true, weariness=true}, prob = 1.0}
```

**After kelp eaten** (3 states, branched, in the herb's cure order):
```lua
{affs = {asthma=true, clumsiness=true}, prob = 0.571},    -- weariness cured
{affs = {clumsiness=true, weariness=true}, prob = 0.286}, -- asthma cured
{affs = {asthma=true, weariness=true}, prob = 0.143}      -- clumsiness cured
```

The weights are not even. `computeCureWeightsV3` (`007:244-261`) gives the first candidate 4, the second 2, each later one 1, then normalises, because the target's curing takes the highest priority it holds.

The eat line is a fact. When the 1.3 / 2.0 / 2.5 s negative-confirm window closes, nothing is undone: `onNegativeConfirmExpiredV3` (`007:1488-1491`) only echoes "Neg-confirm timeout -- branch kept". It used to unfold the cure. The herb window is shorter than the target's fastest next eat (1.506 s), so most branched eats were undone (11 unfolds replaying `kb/raw/logs/ours/2026-11-07_164635_Saibel.log`, 0 now). A later proof settles the branches instead. A second cure action still kills the window (`killNegativeConfirmV3`).

### 3. Collapse (Verification)
When we get proof, eliminate impossible branches:

**Proof: Target smoked (asthma absent)**
```lua
function collapseAffAbsentV3(aff)
    -- Remove all branches where this aff exists
    for i = #afflictionStatesV3, 1, -1 do
        if afflictionStatesV3[i].affs[aff] then
            table.remove(afflictionStatesV3, i)
        end
    end
    -- Renormalize probabilities
end
```

If every branch holds the affliction there is a contradiction: only that affliction is removed, from every branch, and the rest of the board stays (`007:739-745`).

**`proveAffAbsentV3(aff, cureType)`** (`007:758-765`) is what a line calls when an action could not have happened with the affliction. Call it BEFORE any erase: `erAff` strips the affliction from each branch, and a branch the line has ruled out would keep its weight. Where every branch holds it, it only comes off, with no warning. With `cureType` set, a proof made while that cure's clock runs is ignored: the tracker reads the line as an illusion.

Replaying that spar, 0 rows differ from collapse-first and 68 from before. Row 2051's slickness is 0.80 (it was 0.53), and row 2057's is 0.52 (it was 0.33). `targetLocked` changed on 0 rows. An eat still strips anorexia in place (`targetAteWrapper`, `008:48-52`).

### 4. Deduplication
After branching/collapsing, merge identical states:

```lua
function deduplicateStatesV3()
    -- Hash each state by its affliction set
    -- Merge states with identical hashes, summing probabilities
end
```

### 5. Pruning
Keep branch count manageable:

```lua
function pruneStatesV3()
    -- Remove branches with prob < minProbability
    -- If EVERY branch is under the floor, keep them all (it used to fall back to the empty state)
    -- If still > affConfigV3.maxStates, keep highest probability branches
end
```

## Cure Table Design

Herbs and salves cure afflictions in priority order. V3 only considers afflictions that:
1. Are in the cure table for the given herb/salve type
2. Actually exist in the current branch

### Herb Cure Tables
`getCurableAffs` reads the global `curingTable` first (`curing/002_Wide_Groups.lua`) and then `curingTableV3` (`007:139-147`), where only the `bloodroot` row is live. See the README.

### Salve Cure Tables
Salves cure differently depending on the body part they're applied to. Slickness and bloodfire are excluded from tables because applying salve proves them absent. The lists are in the README (`007:186-191`).

### Salve Cure Branching Example
**Before body salve** (1 state):
```lua
{affs = {anorexia=true, itching=true, paralysis=true}, prob = 1.0}
```

**After body salve** (2 states, branched, weights 4 and 2):
```lua
{affs = {itching=true, paralysis=true}, prob = 0.667},  -- anorexia cured
{affs = {anorexia=true, paralysis=true}, prob = 0.333}  -- itching cured
```

## Sync to Legacy System

V3 syncs to `tAffs` for backward compatibility with offense code:

```lua
function syncToOldSystemV3()
    for aff, prob in pairs(getAllAffProbabilitiesV3()) do
        if prob >= 0.3 then
            tAffs[aff] = true
        elseif prob < 0.01 or (heldAtSyncV3[aff] or 0) >= 0.3 then
            tAffs[aff] = false   -- gone, or fell under 30% since the last sync
        end
    end
    -- Whatever V3 held at the last sync and holds nowhere now is cleared once
end
```

See `007:1071-1101`. `tAffs` keys V3 never tracks are left alone. Because V3 copies its result into `tAffs`, a V1 erase chain that runs after a V3 cure takes a SECOND affliction.

## Branch Explosion Prevention

Without limits, branches could explode exponentially:
- 1 kelp cure with 3 candidates = 3 branches
- Another kelp cure = up to 9 branches
- Another = up to 27 branches

Prevention strategies:
1. **Max branch limit** (`affConfigV3.maxStates`, 300) - prune lowest probability branches
2. **Min probability threshold** (1%) - eliminate near-impossible branches, unless that would empty the tracker
3. **Deduplication** - merge identical states
4. **Collapse on verification** - reduce branches when we get proof

## Performance Considerations

| Operation | Complexity | Notes |
|-----------|------------|-------|
| Apply aff | O(n) | n = number of branches |
| Herb cure | O(n*m) | m = candidates in cure table |
| Get probability | O(1) | Uses cached values |
| Collapse | O(n) | Single pass filter |
| Deduplicate | O(n log n) | Sort + merge |
| Rebuild cache | O(n*a) | a = unique afflictions |

With at most 300 branches and ~30 afflictions, each operation is a short loop (about 10 ms for a tree on a full board in Lua 5.1).
