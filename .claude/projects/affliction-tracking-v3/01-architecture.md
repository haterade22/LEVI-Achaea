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
affProbCacheV3 = {
    paralysis = 1.0,    -- 100% certain (exists in all branches)
    asthma = 0.67,      -- 67% likely
    clumsiness = 0.66   -- 66% likely
}
```

Cache is rebuilt after every state change for O(1) probability lookups.

### Configuration
```lua
affConfigV3 = {
    enabled = true,           -- Master toggle
    maxBranches = 32,         -- Prune if exceeds
    minProbability = 0.01,    -- Remove branches below 1%
    debug = false             -- Echo debug messages
}
```

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

**After kelp eaten** (3 states, branched):
```lua
{affs = {clumsiness=true, weariness=true}, prob = 0.33},  -- asthma cured
{affs = {asthma=true, weariness=true}, prob = 0.33},      -- clumsiness cured
{affs = {asthma=true, clumsiness=true}, prob = 0.34}      -- weariness cured (not kelp, stays)
-- Note: weariness is ginseng, so only 2 branches actually
```

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
    normalizeProbabilitiesV3()
end
```

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
    -- If still > maxBranches, keep highest probability branches
end
```

## Cure Table Design

Herbs cure afflictions in priority order. V3 only considers afflictions that:
1. Are in the herb's cure table
2. Actually exist in the current branch

```lua
herbCureTableV3 = {
    kelp = {
        "asthma", "clumsiness", "healthleech", "hypersomnia",
        "hypochondria", "lethargy", "recklessness", "sensitivity",
        "weariness"  -- Note: some overlap with ginseng
    },
    bloodroot = {"paralysis", "slickness"},
    -- etc.
}
```

## Sync to Legacy System

V3 syncs to `tAffs` for backward compatibility with offense code:

```lua
function syncToOldSystemV3()
    -- Clear old tAffs
    for aff in pairs(tAffs) do
        if type(tAffs[aff]) == "boolean" then
            tAffs[aff] = false
        end
    end

    -- Set affs with probability >= 0.5 as true
    for aff, prob in pairs(affProbCacheV3) do
        if prob >= 0.5 then
            tAffs[aff] = true
        end
    end
end
```

## Branch Explosion Prevention

Without limits, branches could explode exponentially:
- 1 kelp cure with 3 candidates = 3 branches
- Another kelp cure = up to 9 branches
- Another = up to 27 branches

Prevention strategies:
1. **Max branch limit** (32) - prune lowest probability branches
2. **Min probability threshold** (1%) - eliminate near-impossible branches
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

With max 32 branches and ~30 afflictions, all operations are effectively O(1).
