# Tekura Offense System - Lessons from Blademaster, DWC, and DWB Runie

## Executive Summary
The three modern offense systems (Blademaster v005_CC_BM_Ice, DWC 001_Infernal_DWC_Vivisect, DWB 001_DWB_Runie_Logic) share 8 critical patterns that prevent common bugs, improve maintainability, and enable robust combat flow. Tekura should adopt these patterns.

---

## PATTERN 1: Affliction Routing (V3 → V2 → V1)

### Implementation (All Three Systems)

Blademaster (lines 120-142):
```lua
function blademaster.hasAff(aff)
  -- V3 system (highest priority - probability-based)
  if affConfigV3 and affConfigV3.enabled then
    if haveAffV3 then
      return haveAffV3(aff)  -- Uses 30% threshold by default
    end
    -- V3 enabled but not loaded - fall through to V2/V1
  end
  -- V2 system (when enabled, use ONLY V2 - no fallback)
  if ataxia and ataxia.settings and ataxia.settings.useAffTrackingV2 then
    if haveAffV2 then
      return haveAffV2(aff)
    elseif tAffsV2 and tAffsV2[aff] then
      return true
    end
    return false
  end
  -- V1 system (only when V2 is disabled)
  if tAffs and tAffs[aff] then
    return true
  end
  return false
end
```

DWC (lines 416-440):
```lua
function infernalDWC.hasAff(aff)
    -- V3 system (highest priority - probability-based)
    if affConfigV3 and affConfigV3.enabled then
        return haveAffV3(aff)  -- Uses 30% threshold by default
    end
    -- V2 system (when enabled, use ONLY V2 - no fallback)
    if ataxia and ataxia.settings and ataxia.settings.useAffTrackingV2 then
        if haveAffV2 then
            return haveAffV2(aff)
        elseif tAffsV2 and tAffsV2[aff] then
            return true
        end
        return false
    end
    -- V1 system (only when V2 is disabled)
    if tAffs and tAffs[aff] then
        return true
    end
    return false
end
```

DWB (lines 238-257):
```lua
function dwbRunie.hasAff(aff)
  -- V3 system (highest priority - probability-based)
  if affConfigV3 and affConfigV3.enabled then
    return haveAffV3(aff)
  end
  -- V2 system (when enabled, use ONLY V2 - no fallback)
  if ataxia and ataxia.settings and ataxia.settings.useAffTrackingV2 then
    if haveAffV2 then
      return haveAffV2(aff)
    elseif tAffsV2 and tAffsV2[aff] then
      return true
    end
    return false
  end
  -- V1 system (only when V2 is disabled)
  if tAffs and tAffs[aff] then
    return true
  end
  return false
end
```

### Key Rules:
1. **V3 → V2 → V1 priority order** - Always check V3 first, then V2, then V1
2. **No mixing systems** - When V2 is enabled, return false (don't fallback) rather than checking V1
3. **Probability vs Binary** - V3 returns probability, V2/V1 return boolean
4. **getTrackingSystem()** helper - Useful for echo/debugging to show which system is active

### Why This Matters:
- Prevents tracking inconsistencies when multiple systems are enabled
- Provides graceful fallback if a system is enabled but not loaded
- Critical for V3 probability thresholds (30% default for hasAff, configurable)

---

## PATTERN 2: wouldBreakLimb() - Treat Near-Break Limbs as Prepped

### DWC Implementation (lines 297-307)

```lua
function infernalDWC.wouldBreakLimb(limbName)
    local damage = 0
    if limbName == "left arm" then damage = infernalDWC.getLA()
    elseif limbName == "right arm" then damage = infernalDWC.getRA()
    elseif limbName == "left leg" then damage = infernalDWC.getLL()
    elseif limbName == "right leg" then damage = infernalDWC.getRL()
    end
    if damage <= 0 then return false end
    local dslDamage = 2 * infernalDWC.getSlashDamage()
    return (damage + dslDamage) >= infernalDWC.config.breakThreshold
end
```

### Usage in isLegPrepped (lines 320-325)

```lua
function infernalDWC.isLegPrepped(side)
    local damage = (side == "left") and infernalDWC.getLL() or infernalDWC.getRL()
    if damage >= infernalDWC.config.prepThreshold then return true end
    -- Treat near-break limbs as prepped to prevent accidental breaks during PREP
    return infernalDWC.wouldBreakLimb(side .. " leg")
end
```

### Blademaster Pattern (lines 270-275)

```lua
-- wouldBreak guard (DWC/DWB pattern): treat arm as prepped if a single hit would break it
function blademaster.isArmEffectivelyPrepped(side)
  local dmg = (side == "left") and blademaster.getLA() or blademaster.getRA()
  if dmg >= blademaster.config.prepThreshold then return true end
  return (dmg + blademaster.state.armPrimaryDamage) >= blademaster.config.breakThreshold
end
```

### Why This Matters:
- **Prevents accidental breaks during PREP phase** - If next single hit would break, treat as prepped
- Uses attack's actual damage value (e.g., `2 * slashDamage` for DSL, `armPrimaryDamage` for BM)
- Guards against wrong infuse type being used at the exact break moment

---

## PATTERN 3: Unified Dispatch with Shared Guards

### Blademaster Pattern (lines 669-711)

```lua
function blademaster.run()
  -- Anti-desync: block re-dispatch while previous attack hasn't resolved (DWC pattern)
  if blademaster.state.attackInFlight then return end

  -- Safe defaults (prevent nil errors on first load)
  ataxia = ataxia or {}
  ataxia.vitals = ataxia.vitals or {}
  ataxia.settings = ataxia.settings or {}
  ataxia.afflictions = ataxia.afflictions or {}
  ataxiaTemp = ataxiaTemp or {}
  tAffs = tAffs or {}

  -- Target validation
  if not target or target == "" then
    cecho("\n<red>[BM] No target set! Use: tar <name>")
    return
  end

  -- Aeon check (shared with shaman/serpent)
  if ataxia.afflictions.aeon then return end

  -- Rebound hold gate (shared system — delays attack until rebound drops)
  if reboundHold and reboundHold.gate(blademaster.run) then return end

  -- Target-change reset (DWB pattern: prevents stale Brokenstar state on new target)
  if blademaster.state.lastTarget ~= target then
    blademaster.state.lastTarget = target
    blademaster.resetBrokenstarState()
    blademaster.resetProneTimer()
  end

  -- Mode routing
  local mode = blademaster.state.mode
  if mode == "double" then
    blademaster.dispatch.runDoublePrep()
  elseif mode == "quad" then
    blademaster.dispatch.runQuadPrep()
  elseif mode == "brokenstar" then
    blademaster.dispatch.runBrokenstar()
  elseif mode == "group" then
    blademaster.dispatch.runGroup()
  end
end
```

### Key Guards (in priority order):
1. **attackInFlight** - Block re-dispatch during GMCP round-trip (prevents envenomList desync)
2. **Safe defaults** - Nil-guard globals before use
3. **Target validation** - No target = early return
4. **Aeon check** - Shared system prevents all attacks during aeon
5. **reboundHold.gate()** - Delays dispatch until rebound drops
6. **Target-change reset** - Clean per-target state on new target

### Why This Matters:
- All three systems use this pattern - it's proven robust
- Single entry point (`blademaster.run()`) ensures all guards apply uniformly
- Mode-specific logic (`runDoublePrep()`, `runQuadPrep()`, etc.) happens AFTER guards pass
- `attackInFlight` prevents desync when envenomList is updated during off-balance

---

## PATTERN 4: Rebounding/Shield V1 Fallback

### Implementation Pattern (Blademaster, DWC)

Blademaster (lines 780-784):
```lua
  -- V1 fallback: GMCP balance fires before text trigger in the same data chunk,
  -- so haveAffV3("rebounding") may return false even when rebounding is active.
  -- The tAffs fallback catches this timing gap. DO NOT remove.
  if blademaster.hasAff("shield") or blademaster.hasAff("rebounding") or (tAffs and (tAffs.shield or tAffs.rebounding)) then
```

DWC (lines 1135, 1169):
```lua
    local hasRebounding = infernalDWC.hasAff("rebounding") or (tAffs and tAffs.rebounding)
    ...
    local hasShield = infernalDWC.hasAff("shield") or (tAffs and tAffs.shield)
```

### Why This Matters:
- GMCP `Char.Vitals.bal` fires in the SAME DATA CHUNK as balance-gated triggers
- Timing gap: balance is true when trigger fires, but affliction state hasn't updated yet
- `haveAffV3()` relies on GMCP, so it returns false even when rebounding is active
- **Solution**: Use V1 fallback ONLY for rebounding/shield (not all afflictions)

---

## PATTERN 5: Limb Damage Tracking (lb[target].hits)

### Standard Access Pattern

DWC (lines 267-285):
```lua
function infernalDWC.getLA()
    if not target or not lb or not lb[target] or not lb[target].hits then return 0 end
    return tonumber(lb[target].hits["left arm"]) or 0
end

function infernalDWC.getRA()
    if not target or not lb or not lb[target] or not lb[target].hits then return 0 end
    return tonumber(lb[target].hits["right arm"]) or 0
end

function infernalDWC.getLL()
    if not target or not lb or not lb[target] or not lb[target].hits then return 0 end
    return tonumber(lb[target].hits["left leg"]) or 0
end

function infernalDWC.getRL()
    if not target or not lb or not lb[target] or not lb[target].hits then return 0 end
    return tonumber(lb[target].hits["right leg"]) or 0
end
```

DWB (lines 147-150):
```lua
function dwbRunie.getLimbDamage(limb)
  if not target or not lb or not lb[target] or not lb[target].hits then return 0 end
  return tonumber(lb[target].hits[limb]) or 0
end
```

Blademaster (lines 230-235):
```lua
function blademaster.getLimbDamage(limb)
  if not lb or not target then return 0 end
  local t = target:lower():gsub("^%l", string.upper)
  if not lb[t] or not lb[t].hits then return 0 end
  return lb[t].hits[limb] or 0
end
```

### Key Pattern:
- Always check full chain: `target` → `lb` → `lb[target]` → `lb[target].hits` → `hits[limb]`
- Convert to tonumber() (DWC/Blademaster) or use directly (DWB)
- Return 0 on any nil in chain
- Case handling: Blademaster title-cases target name (Romaen's limb counter uses title case)

---

## PATTERN 6: Smart Limb Balancing (getFocusLimb)

### DWC Pattern (lines 385-401)

```lua
function infernalDWC.getFocusArm()
    local la = infernalDWC.getLA()
    local ra = infernalDWC.getRA()
    return (la <= ra) and "left" or "right"
end

function infernalDWC.getOffArm()
    local la = infernalDWC.getLA()
    local ra = infernalDWC.getRA()
    return (la >= ra) and "left" or "right"
end

function infernalDWC.getFocusLeg()
    local ll = infernalDWC.getLL()
    local rl = infernalDWC.getRL()
    return (ll <= rl) and "left" or "right"
end
```

### Blademaster Pattern (lines 487-503)

```lua
function blademaster.getFocusLeg()
  local LL = blademaster.getLL()
  local RL = blademaster.getRL()
  local parried = blademaster.getParried()

  if LL >= blademaster.config.prepThreshold and RL >= blademaster.config.prepThreshold then
    return parried == "left leg" and "right" or "left"
  end

  local focus = (LL <= RL) and "left" or "right"

  if parried == focus .. " leg" then
    return focus == "left" and "right" or "left"
  end

  return focus
end
```

### Key Features:
1. **Hit lower damage first** - (LL <= RL) hits left leg if equal or lower
2. **Parry avoidance** - If parrying your focus limb, pick the other one
3. **Both-prepped case** - If both prepped, hit parried limb (to unblock) or any limb
4. **No hardcoded limb names** - Calculated dynamically each attack

---

## PATTERN 7: Diagnostic Echo with Debounce (0.3s Guard)

### DWB Pattern (lines 124-150)

```lua
function dwbRunie.diagnosticEcho(phase)
  local mom = dwbRunie.getMomentum()
  local ll = dwbRunie.getLimbDamage("left leg")
  local rl = dwbRunie.getLimbDamage("right leg")
  local t = dwbRunie.getLimbDamage("torso")
  local h = dwbRunie.getLimbDamage("head")
  local mode = (dwbRunie.state.mode or "torso"):upper()
  local prone = dwbRunie.isProne() and " PRONE" or ""
  local sf = (ataxiaTemp.fractures and ataxiaTemp.fractures.skullfractures or 0)
  local cr = (ataxiaTemp.fractures and ataxiaTemp.fractures.crackedribs or 0)
  local fracInfo = ""
  if sf > 0 or cr > 0 then
    fracInfo = string.format(" SF:%d CR:%d", sf, cr)
  end

  cecho(string.format("\n<yellow>[%s]<reset> <cyan>%s<reset>%s Mom:<white>%d<reset> | LL:<white>%.0f%%<reset> RL:<white>%.0f%%<reset> T:<white>%.0f%%<reset> H:<white>%.0f%%<reset>%s",
    mode, phase, prone, mom, ll, rl, t, h, fracInfo))
end
```

### Debounce Guard (lines 746-750)

```lua
  -- Debounce diagnostic echo (at most once per 0.3s to avoid spam when mashing)
  local now = getEpoch()
  if not dwbRunie.state.lastEchoTime or (now - dwbRunie.state.lastEchoTime) > 0.3 then
    dwbRunie.state.lastEchoTime = now
    dwbRunie.diagnosticEcho(phase)
  end
```

### Blademaster Echo Header (lines 862-866)

```lua
  -- Debounced echo (DWB pattern: 0.3s guard prevents spam on rapid mashing)
  if blademaster.shouldEcho() then
    cecho("\n<cyan>[BM " .. phaseLabel .. "<cyan>] Target: " .. tostring(target) .. " | HP: " .. targetHP .. "% | Track: " .. blademaster.getTrackingSystem())
    cecho("\n<cyan>[BM " .. phaseLabel .. "<cyan>] Legs: LL=" .. string.format("%.1f", blademaster.getLL()) .. "% RL=" .. string.format("%.1f", blademaster.getRL()) .. "%")
    cecho("\n<cyan>[BM " .. phaseLabel .. "<cyan>] Dmg: P=" .. string.format("%.1f", blademaster.state.legPrimaryDamage) .. "% S=" .. string.format("%.1f", blademaster.state.legSecondaryDamage) .. "%")
```

### DWC Echo Format (lines 1239-1259)

```lua
    -- Echo attack status (phase, afflictions, limbs, venoms)
    local affStr = ""
    if infernalDWC.hasAff("clumsiness") then affStr = affStr .. "clu " end
    if infernalDWC.hasAff("nausea") then affStr = affStr .. "nau " end
    ... (more affs)
    if affStr == "" then affStr = "none" end

    local la = string.format("%.0f", infernalDWC.getLA())
    local ra = string.format("%.0f", infernalDWC.getRA())
    local ll = string.format("%.0f", infernalDWC.getLL())
    local rl = string.format("%.0f", infernalDWC.getRL())
    local limbStr = "LA:" .. la .. " RA:" .. ra .. " LL:" .. ll .. " RL:" .. rl

    local venomStr = (v1 or "-") .. "/" .. (v2 or "-")
    local limbTarget = limb or "body"

    cecho("\n<cyan>[INF DWC]<reset> <yellow>" .. phase .. "<reset> | " .. limbTarget .. " | " .. venomStr .. " | [" .. affStr .. "] | " .. limbStr)
```

### Key Features:
1. **Header format**: `[CLASS MODE/LABEL] Target: X | HP: Y% | Track: SYSTEM`
2. **Phase label**: Color-coded phase names (yellow=prep, blue=break, red=execute)
3. **Per-phase details**: Show relevant state (limbs, damage, afflictions, etc.)
4. **0.3s debounce**: `shouldEcho()` or explicit `lastEchoTime` check prevents spam
5. **Tracking system display**: Shows which aff system is active (V3/V2/V1)

---

## PATTERN 8: Target Change Detection and State Reset

### Blademaster (lines 694-698)

```lua
  -- Target-change reset (DWB pattern: prevents stale Brokenstar state on new target)
  if blademaster.state.lastTarget ~= target then
    blademaster.state.lastTarget = target
    blademaster.resetBrokenstarState()
    blademaster.resetProneTimer()
  end
```

### DWB (equivalent)

```lua
  -- Target change detection
  if dwbRunie.state.lastTarget ~= target then
    dwbRunie.state.lastTarget = target
  end
```

### Why This Matters:
- Prevents stale state from previous target affecting new target
- Each mode should have reset functions:
  - `resetBrokenstarState()` - Clears impaleslash/bladetwist/bleeding state
  - `resetProneTimer()` - Clears prone attack counter
- Called AFTER target validation but BEFORE mode routing

---

## PATTERN 9: Phase System (Dynamic State Detection)

### DWC Phase System (lines 528-552)

```lua
function infernalDWC.getPhase()
    -- Riftlock mode takes priority (when target uses RESTORE)
    if infernalDWC.state.riftlockMode then
        return "RIFTLOCK"
    end

    -- Kill check: Vivisect requires broken leg + broken right arm
    if infernalDWC.isFocusLegBroken() and infernalDWC.isArmBroken("right") then
        return "KILL"
    end

    -- Execute phase case 1: all limbs prepped (starting execute)
    if infernalDWC.areBothArmsPrepped() and infernalDWC.isFocusLegPrepped() then
        return "EXECUTE"
    end

    -- Execute phase case 2: leg broken + right arm prepped (after undercut)
    if infernalDWC.isFocusLegBroken() and infernalDWC.isArmPrepped("right") then
        return "EXECUTE"
    end

    -- Default: PREP phase
    return "PREP"
end
```

### Blademaster Double-Prep (lines 721-739)

```lua
function blademaster.getPhaseDoublePrep()
  local legsPrepped = blademaster.checkBothLegsPrepped()

  -- MANGLE: If prone, stay in mangle for max damage
  if blademaster.hasAff("prone") then
    return "mangle"
  end

  if legsPrepped or blademaster.checkWillDoubleBreakLegs() then
    return "leg_break"
  end

  return "leg_prep"
end
```

### Key Pattern:
1. **Priority order** - Check special states first (riftlock, mangle, kill)
2. **Transition conditions** - Define exact conditions for phase changes
3. **Never hardcoded** - Phase computed dynamically every dispatch
4. **Prevent phase oscillation** - Use `checkWill*()` to look ahead

---

## PATTERN 10: Mounted Target Handling

### Blademaster (lines 768-770)

```lua
    -- Dismount during final prep hit if mounted + hamstrung
    -- This ensures KNEES on double-break will prone (not just dismount)
    if tmounted and blademaster.hasAff("hamstring") and blademaster.checkWillPrepBothLegs() then
      return "knees"  -- Dismount now, so KNEES on double-break will prone
    end
```

And similar in Quad (lines 1300-1301), Brokenstar (lines 1458-1459).

### Key Pattern:
- Check `tmounted` (global from Mudlet)
- Use special strike (`knees`) during final prep to dismount BEFORE breaking
- This ensures KNEES on the break attack will prone instead of just dismounting

---

## Extractable Lessons for Tekura

1. **Always use namespace.hasAff()** routing through V3→V2→V1
2. **Implement wouldBreakLimb()** as a guard for near-break limbs during PREP
3. **Use unified dispatch pattern** with shared guards (attackInFlight, aeon, reboundHold, target change)
4. **Add V1 fallback for rebounding/shield ONLY** (due to GMCP timing gap)
5. **Implement smart limb focus** (hit lower damage, avoid parried limbs)
6. **Add 0.3s echo debounce** to prevent spam on mashing
7. **Detect target changes** and reset per-target state
8. **Use dynamic phase system** with priority ordering, not state machines
9. **Handle mounted targets** with appropriate strike selection
10. **Show tracking system in echo** so user knows which aff system is active

---

## Files Analyzed

1. `/c/Users/mikew/source/repos/Achaea/LEVI-Achaea/src_new/scripts/levi_ataxia/levi/levi_scripts/blademaster/005_CC_BM_Ice.lua` (2133 lines)
2. `/c/Users/mikew/source/repos/Achaea/LEVI-Achaea/src_new/scripts/levi_ataxia/levi/levi_scripts/dwc/001_Infernal_DWC_Vivisect.lua` (1425 lines)
3. `/c/Users/mikew/source/repos/Achaea/LEVI-Achaea/src_new/scripts/levi_ataxia/levi/levi_scripts/dwb_runie/001_DWB_Runie_Logic.lua` (767 lines)

These patterns represent the "lessons learned" evolution from older systems to the current generation of offense systems.