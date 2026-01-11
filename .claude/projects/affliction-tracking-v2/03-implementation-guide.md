# Implementation Guide

## Prerequisites

- Mudlet with LEVI-Ataxia installed
- Access to `src_new/scripts/` and `src_new/triggers/` directories
- Understanding of Mudlet script/trigger YAML headers

## Step 1: Create Directory Structure

```bash
mkdir -p src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_v2
```

## Step 2: Create 001_Core.lua

**File**: `src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_v2/001_Core.lua`

This is the foundation module. See [code/001_Core.lua](code/001_Core.lua) for full implementation.

**Key Components**:
- `tAffsV2` table initialization
- `affTimersV2` table initialization
- Setting toggle: `ataxia.settings.useAffTrackingV2`
- Core functions: `confirmAffV2`, `removeAffV2`, `uncertainAffV2`
- Check functions: `haveAffV2`, `haveConfirmedAffV2`
- Sync function: `syncToOldSystem`
- Event handler to catch affliction applications

## Step 3: Create 002_Herb_Cures.lua

**File**: `src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_v2/002_Herb_Cures.lua`

This handles herb cure detection with V2 logic. See [code/002_Herb_Cures.lua](code/002_Herb_Cures.lua).

**Key Components**:
- `kelpRemovalPriority` - ordered by verifiability
- `targetAteWrapper()` - routes to V2 or old system
- `targetAteV2()` - V2 cure logic with backtracking support
- Smoke disambiguation timer logic

## Step 4: Create 003_Backtracking.lua

**File**: `src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_v2/003_Backtracking.lua`

See [code/003_Backtracking.lua](code/003_Backtracking.lua).

**Key Components**:
- `lastKelpGuessV2` tracking variable
- `backtrackKelpCureV2()` function

## Step 5: Create 004_Verification.lua

**File**: `src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_v2/004_Verification.lua`

See [code/004_Verification.lua](code/004_Verification.lua).

**Key Components**:
- `onTargetFumbleV2()` - handles fumble detection
- `onTargetSmokeV2()` - handles smoke detection
- `onTargetAttackV2()` - tracks non-fumbles

## Step 6: Modify Kelp Trigger

**File**: `src_new/triggers/levi_ataxia/for_levi/leviticus/herbs/003_Kelp_(Unknown).lua`

Find the line:
```lua
targetAte("kelp")
```

Change to:
```lua
targetAteWrapper("kelp")
```

## Step 7: Add V2 Calls to Smoke Trigger

**File**: `src_new/triggers/levi_ataxia/for_levi/leviticus/369_Smoked.lua`

Add near the top of the trigger code:
```lua
if isTargeted(matches[2]) then
    onTargetSmokeV2(matches[2])
    -- ... existing code continues unchanged ...
end
```

## Step 8: Create or Modify Fumble Trigger

**Find**: Existing fumble detection trigger, or create new one.

**Pattern** (example):
```
^(\w+) fumbles .*$
```
or
```
^(\w+)'s attack fails to connect\.$
```

**Add**:
```lua
local attacker = matches[2]
if isTargeted(attacker) then
    onTargetFumbleV2(attacker)
end
```

## Step 9: Modify Other Herb Triggers (Optional)

For each herb trigger, change `targetAte("herbname")` to `targetAteWrapper("herbname")`.

Files to check:
- `006_Bloodroot_TEST.lua`
- `008_Ginseng.lua`
- Any other herb triggers that call `targetAte()`

## Step 10: Test

1. **Enable V2**:
   ```lua
   ataxia.settings.useAffTrackingV2 = true
   ```

2. **Verify in arena**:
   - Apply afflictions to target
   - Watch for `[V2]` prefix messages
   - Check `lua tAffsV2` to see certainty levels

3. **Test smoke disambiguation**:
   - Apply asthma + another kelp aff
   - Have target eat kelp
   - If they smoke → asthma should be removed
   - If no smoke in 2.5s → other aff removed, asthma kept

4. **Test fumble backtracking**:
   - Apply clumsiness + weariness
   - Target eats kelp (should remove weariness per priority)
   - Target fumbles → confirms clumsiness still there (no backtrack needed)

5. **If issues, disable V2**:
   ```lua
   ataxia.settings.useAffTrackingV2 = false
   ```

## Verification Commands

```lua
-- Check V2 state
lua tAffsV2

-- Check if V2 is enabled
lua ataxia.settings.useAffTrackingV2

-- Toggle V2 on
ataxia.settings.useAffTrackingV2 = true

-- Toggle V2 off
ataxia.settings.useAffTrackingV2 = false

-- Compare V2 to old system
lua print("V2:", tAffsV2.asthma, "Old:", tAffs.asthma)
```

## Rollback

If V2 causes issues:

1. Set `ataxia.settings.useAffTrackingV2 = false`
2. Old system immediately takes over
3. No need to revert code changes

For permanent rollback:
1. Revert trigger changes (`targetAteWrapper` → `targetAte`)
2. Delete V2 module files
3. Reload profile
