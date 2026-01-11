# Problem Analysis: Affliction Tracking Bugs

## Symptom

After combat, `lua tAffs` shows incorrect affliction states:

```lua
{
  clumsiness = true,     -- WRONG: Tree tattoo cured this
  paralysis = true,      -- WRONG: Multiple magnesium chips eaten
  nausea = true,         -- WRONG: Tree tattoo cured this
  sensitivity = true,    -- WRONG: Potash doesn't cure this, but aurum should have
  haemophilia = true,    -- WRONG: Ferrum flake cured this
  anorexia = false,      -- WRONG: Applied via slike, never cured
}
```

## Root Cause Analysis

### 1. Kelp Cures are RANDOM (Not Priority-Based)

**Discovery**: The game's server-side curing picks RANDOMLY from available kelp-stack afflictions when target eats kelp/aurum.

**Impact**: The current system assumes priority-based curing and makes deterministic predictions. With random cures, these predictions are wrong ~50%+ of the time when multiple kelp affs are present.

**Current Code** (`curing/001_Herbs.lua`):
```lua
-- Assumes first in priority list is cured
local kelps = {"hypochondria", "parasite", "weariness", "healthleech", "clumsiness", "sensitivity"}
for i=1, #kelps do
    if tAffs[kelps[i]] then
        erAff(kelps[i])  -- Always removes first match
        break
    end
end
```

### 2. No Verification Signal Integration

**Problem**: Only asthma has verification (smoke detection). Other afflictions like clumsiness can be verified via fumble messages but aren't.

**Verifiable Afflictions**:
| Affliction | Verification Signal | Current Status |
|------------|---------------------|----------------|
| Asthma | Target smokes successfully | Implemented |
| Clumsiness | Target fumbles/misses attack | NOT implemented |
| Sensitivity | No reliable signal | N/A |
| Weariness | No reliable signal | N/A |

### 3. No Backtracking When Guess is Wrong

**Problem**: When we guess wrong and later see proof (e.g., fumble proves clumsiness), we don't reverse our guess.

**Example**:
1. Target has clumsiness + weariness
2. They eat kelp → we remove weariness (priority guess)
3. They fumble on next attack → proves clumsiness still there
4. **Currently**: No action taken
5. **Should**: Confirm clumsiness is still there (our guess was correct this time)

**But if we had removed clumsiness**:
1. Target has clumsiness + weariness
2. They eat kelp → we remove clumsiness (wrong guess)
3. They fumble → proves clumsiness still there!
4. **Should**: Put clumsiness back, remove weariness instead

### 4. Boolean Tracking Can't Represent Uncertainty

**Problem**: `tAffs[aff] = true/false` can't express "we applied this but it might have been cured."

**Impact**:
- Lock condition checks may announce locks that don't exist
- Offense may make decisions based on stale data
- No way to prioritize re-applying uncertain afflictions

## Evidence from Combat Log

```
CLU: You slash into Sprucebruce with Severance
pt Sprucebruce: clumsiness                    -- Applied clumsiness
Sprucebruce eats an aurum flake.              -- Could cure clumsiness
Sprucebruce touches a tree of life tattoo.    -- Could cure clumsiness
...
lua tAffs
  clumsiness = true,                          -- Still showing true!
```

The log shows:
- Clumsiness applied
- Multiple potential cures (aurum, tree)
- System still shows clumsiness = true

## Priority Order Issues

**Current kelp priority** (`002_Wide_Groups.lua`):
```lua
local kelps = {"hypochondria", "parasite", "weariness", "healthleech", "clumsiness", "sensitivity"}
```

**Problem**: This order doesn't account for verifiability.

**Better order** (unverifiable first):
```lua
local kelps = {
    "hypochondria",  -- Can't verify
    "parasite",      -- Can't verify
    "weariness",     -- Can't verify
    "healthleech",   -- Can't verify
    "clumsiness",    -- CAN verify via fumble - keep longer
    "sensitivity",   -- Hard to verify
}
```

**Rationale**: If we can verify an affliction later, we should assume it's still there and use the signal to confirm/deny. Unverifiable ones should be assumed cured first since we can never prove otherwise.

## Summary of Issues

| Issue | Impact | Solution |
|-------|--------|----------|
| Random cures assumed deterministic | Wrong 50%+ of time | Use verifiability priority + backtracking |
| No fumble detection | Miss clumsiness verification | Add fumble trigger + V2 call |
| No backtracking | Can't recover from wrong guess | Track guess, reverse when proven wrong |
| Boolean only | Can't express uncertainty | Use 0/1/2 certainty levels |
| Wrong priority order | Removes verifiable affs first | Reorder by verifiability |
