# Testing Plan

## Pre-Test Setup

1. Enable V2:
   ```lua
   ataxia.settings.useAffTrackingV2 = true
   ```

2. Find a testing partner or use arena target

3. Have debug commands ready:
   ```lua
   lua tAffsV2          -- Check V2 state
   lua lastKelpGuessV2  -- Check backtrack data
   lua tAffs            -- Compare with old system
   ```

## Test Cases

### TC1: Single Kelp Affliction

**Setup**: Target has only one kelp affliction

**Steps**:
1. Apply asthma to target
2. Target eats aurum flake
3. Check `lua tAffsV2`

**Expected**:
- `tAffsV2.asthma = 0` or `nil`
- Message: affliction removed

### TC2: Multiple Kelp Afflictions - No Smoke

**Setup**: Target has asthma + another kelp aff

**Steps**:
1. Apply asthma to target
2. Apply clumsiness to target
3. Check `lua tAffsV2` (both should be 2)
4. Target eats aurum flake
5. Wait 3 seconds (no smoke)
6. Check `lua tAffsV2`

**Expected**:
- `tAffsV2.asthma = 2` (kept - no smoke proves present)
- `tAffsV2.clumsiness = 0` (removed per priority)
- Message: `[V2] No smoke: assumed clumsiness cured`

### TC3: Multiple Kelp Afflictions - With Smoke

**Setup**: Target has asthma + another kelp aff

**Steps**:
1. Apply asthma to target
2. Apply weariness to target
3. Target eats aurum flake
4. Target smokes within 2 seconds
5. Check `lua tAffsV2`

**Expected**:
- `tAffsV2.asthma = 0` (removed - smoke proves cured)
- `tAffsV2.weariness = 2` (kept)

### TC4: Fumble Verification

**Setup**: Target has clumsiness

**Steps**:
1. Apply clumsiness to target
2. Target attacks and fumbles
3. Check `lua tAffsV2`

**Expected**:
- `tAffsV2.clumsiness = 2` (confirmed via fumble)

### TC5: No Fumble Uncertainty

**Setup**: Target has clumsiness

**Steps**:
1. Apply clumsiness to target
2. Target attacks successfully 3 times (no fumble)
3. Check `lua tAffsV2`

**Expected**:
- `tAffsV2.clumsiness` reduced to 1 or 0

### TC6: Backtracking (Edge Case)

**Setup**: Test backtracking when guess is wrong

**Note**: With verifiability priority, clumsiness is removed LAST, so backtracking for it should be rare. This test requires modifying priority temporarily.

**Steps**:
1. Temporarily put clumsiness FIRST in priority list
2. Apply clumsiness + weariness to target
3. Target eats aurum (removes clumsiness per modified priority)
4. Target fumbles (proves clumsiness present!)
5. Check `lua tAffsV2`

**Expected**:
- `tAffsV2.clumsiness = 2` (put back via backtrack)
- `tAffsV2.weariness = 0` (removed instead)
- Message: `[V2] Backtracked: weariness was actually cured, not clumsiness`

### TC7: Lock Detection

**Setup**: Build toward softlock

**Steps**:
1. Apply asthma (certainty 2)
2. Apply anorexia (certainty 2)
3. Apply slickness (certainty 2)
4. Check if lock is announced
5. Have target eat something (reduces certainty on one)
6. Check if lock still announced

**Expected**:
- Lock announced when all at certainty >= 1
- Lock should persist even with uncertainty (per user preference)

### TC8: Sync to Old System

**Setup**: Verify old tAffs stays in sync

**Steps**:
1. Apply asthma
2. Check `lua tAffsV2.asthma` → should be 2
3. Check `lua tAffs.asthma` → should be true
4. Target cures asthma
5. Check both again

**Expected**:
- tAffsV2 and tAffs stay synchronized
- Old offense code works correctly

### TC9: Toggle Off Mid-Combat

**Setup**: Test fallback works

**Steps**:
1. Start combat with V2 enabled
2. Apply some afflictions
3. Disable V2: `ataxia.settings.useAffTrackingV2 = false`
4. Continue combat
5. Check that old system handles cures

**Expected**:
- No errors
- Old system takes over seamlessly
- tAffs continues to work

### TC10: Tree Tattoo Cure

**Setup**: Target uses tree tattoo

**Steps**:
1. Apply multiple afflictions including paralysis
2. Target uses tree tattoo
3. Check `lua tAffsV2`

**Expected**:
- Paralysis removed (tree always cures paralysis)
- One other aff removed based on tSingleRandom
- V2 should sync with whatever old system does

## Regression Tests

After implementing V2, verify old functionality still works:

1. **Old system still works when V2 disabled**
2. **Events still fire**: "tar afflicted", "target cured aff"
3. **Lock detection still works**
4. **Offense decisions still correct**

## Debug Commands

```lua
-- Detailed state dump
function debugAffsV2()
    echo("=== V2 State ===\n")
    echo("Enabled: " .. tostring(ataxia.settings.useAffTrackingV2) .. "\n")
    echo("\ntAffsV2:\n")
    for aff, cert in pairs(tAffsV2) do
        echo("  " .. aff .. " = " .. cert .. "\n")
    end
    echo("\nlastKelpGuessV2:\n")
    if lastKelpGuessV2 then
        echo("  removed: " .. lastKelpGuessV2.removed .. "\n")
        echo("  candidates: " .. table.concat(lastKelpGuessV2.candidates, ", ") .. "\n")
    else
        echo("  nil\n")
    end
end
```

## Known Limitations

1. **Fumble trigger needed** - Must find/create fumble pattern trigger
2. **Tree tattoo sync** - V2 relies on old tSingleRandom for tree; could diverge
3. **Other herbs** - Only kelp priority implemented; others use default
