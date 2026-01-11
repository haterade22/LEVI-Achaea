# Verification Signals

## Overview

Verification signals are game messages that PROVE whether a target has or doesn't have an affliction. These are used to confirm our guesses or trigger backtracking.

## Implemented Signals

### Asthma - Smoke Detection

**Signal Type**: Proves ABSENCE of asthma

**How it works**:
- Target can only smoke if they don't have asthma
- Successful smoke → asthma was cured
- No smoke within 2-4 seconds → likely still has asthma

**Game Patterns**:
```
^(\w+) takes a long drag off .+\.$
^(\w+) takes a puff of .+\.$
```

**Current Implementation**: Yes (existing smoke detection)

**V2 Integration**:
```lua
function onTargetSmokeV2(smoker)
    if not ataxia.settings.useAffTrackingV2 then return end
    if not isTargeted(smoker) then return end

    removeAffV2("asthma")
    -- Clear pending kelp disambiguation
    pendingKelpAffsV2 = nil
    if kelpDisambiguateTimerV2 then
        killTimer(kelpDisambiguateTimerV2)
    end
end
```

### Clumsiness - Fumble Detection

**Signal Type**: Proves PRESENCE of clumsiness

**How it works**:
- Clumsiness causes target to fumble attacks
- Fumble message → target has clumsiness
- No fumble after 3+ attacks → uncertainty (might not have it)

**Game Patterns** (need to verify exact patterns):
```
^(\w+) fumbles .+\.$
^(\w+)'s attack .+ goes wide\.$
^(\w+) loses .+ grip .+\.$
```

**Current Implementation**: No

**V2 Integration**:
```lua
function onTargetFumbleV2(attacker)
    if not ataxia.settings.useAffTrackingV2 then return end
    if not isTargeted(attacker) then return end

    -- Check for backtracking
    if lastKelpGuessV2 and lastKelpGuessV2.removed == "clumsiness" then
        backtrackKelpCureV2("clumsiness")
    else
        confirmAffV2("clumsiness")
    end
    clumsyAttackCountV2 = 0
end
```

## Potential Future Signals

### Weariness - Restore Failure?

**Signal Type**: Would prove PRESENCE of weariness

**Theory**: Weariness might prevent certain actions or show a message when trying to use RESTORE balance.

**Status**: Needs research

### Sensitivity - Extra Damage?

**Signal Type**: Would prove PRESENCE of sensitivity

**Theory**: Sensitivity increases damage taken. If we track damage and it's higher than expected, might indicate sensitivity.

**Challenges**:
- Damage varies by many factors
- Hard to establish baseline
- Not reliable enough for tracking

**Status**: Not practical

### Healthleech - Damage on Movement?

**Signal Type**: Would prove PRESENCE of healthleech

**Theory**: Healthleech might cause damage messages on movement.

**Status**: Needs research

## Signal Priority

When multiple signals could affect the same affliction:

1. **Exact game message** (highest priority)
   - Tree tattoo with "-clumsiness" suffix
   - Focus with specific cure message

2. **Third-party verification**
   - Fumble proves clumsiness
   - Smoke proves no asthma

3. **Behavioral inference** (lowest priority)
   - No fumble after 3 attacks → maybe no clumsiness
   - No smoke after 4 seconds → maybe has asthma

## Backtracking Logic

When a verification signal contradicts our guess:

```
We guessed: clumsiness was cured
Signal: fumble (proves clumsiness present)
Action:
  1. Put clumsiness back (confirmAffV2)
  2. Remove next candidate from original list
  3. Clear the guess tracking
```

**Code**:
```lua
function backtrackKelpCureV2(provenAff)
    if not lastKelpGuessV2 then return false end
    if lastKelpGuessV2.removed ~= provenAff then return false end

    -- We were wrong! Put the aff back
    confirmAffV2(provenAff)

    -- Remove the next candidate instead
    for _, aff in ipairs(kelpRemovalPriority) do
        if aff ~= provenAff and table.contains(lastKelpGuessV2.candidates, aff) then
            removeAffV2(aff)
            ataxiaEcho("[V2] Backtracked: "..aff.." was actually cured, not "..provenAff)
            break
        end
    end

    lastKelpGuessV2 = nil
    return true
end
```

## Finding Fumble Patterns

To find the exact fumble patterns in Achaea:

1. Apply clumsiness to a test target
2. Have them attack you repeatedly
3. Log all messages when they fumble
4. Create trigger patterns from those messages

**Common fumble patterns in MUDs**:
```
^(\w+) fumbles an attack\.$
^(\w+) loses \w+ grip on .+\.$
^(\w+)'s attack goes wide\.$
^(\w+) slips and misses\.$
```
