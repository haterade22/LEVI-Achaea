--[[mudlet
type: script
name: CC_BM_Ice
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- Blademaster
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- Blademaster Dispatch System
-- Three strategies available:
--
-- STRATEGY 1: DOUBLE-PREP (Legs only) - bmd / bmdispatch
--   1. LEG PREP (Lightning): Alternate legslash to get both legs to 90%+
--   2. LEG BREAK (Ice): Double-break legs + KNEES (prone)
--   3. MANGLE (Ice): Legslash right + STERNUM
--
-- STRATEGY 2: QUAD-PREP (Arms + Legs) - bmdq / bmdispatchquad
--   1. ARM PREP (Lightning): Alternate armslash to get both arms to 90%+
--   2. LEG PREP (Lightning): Alternate legslash to get both legs to 90%+
--   3. ARM BREAK (Ice): Double-break both arms
--   4. LEG BREAK (Ice): Double-break both legs + KNEES (prone)
--   5. MANGLE (Ice): Legslash right + STERNUM
--
-- STRATEGY 3: BROKENSTAR (Instant Kill) - bmbs / bmdispatchbs
--   1. UPPER PREP (Lightning): Centreslash up/down to get torso+head to 90%+
--      - Direction auto-selected to balance damage (like leg focus)
--      - UP: torso primary (18.1%), head secondary (12.1%)
--      - DOWN: head primary (18.1%), torso secondary (12.1%)
--   2. LEG PREP (Lightning): Legslash to get both legs to 90%+
--   3. UPPER BREAK (Ice): Centreslash up/down to break torso+head
--   4. LEG BREAK (Ice): Double-break legs + KNEES (prone)
--   5. IMPALE: Impale prone target
--   6. IMPALESLASH: Slash arteries for bleeding
--   7. BLADETWIST: Twist until 700 bleeding (discern on 3rd)
--   8. WITHDRAW: Withdraw blade (if impaled) or skip if writhed free
--   9. BROKENSTAR: Execute instant kill

blademaster = blademaster or {}
blademaster.dispatch = blademaster.dispatch or {}
blademaster.state = {
  -- Leg tracking
  focusLeg = nil,
  lastPrimaryLeg = nil,
  legPrimaryDamage = 17.3,
  legSecondaryDamage = 11.5,
  -- Arm tracking
  focusArm = nil,
  lastPrimaryArm = nil,
  armPrimaryDamage = 17.3,
  armSecondaryDamage = 11.5,
  -- Upper body tracking (centreslash up hits torso + head with different damage!)
  torsoDamage = 18.1,  -- Damage to torso from centreslash up (primary)
  headDamage = 12.1,   -- Damage to head from centreslash up (secondary)
  -- Prone timer tracking (Double-Prep mangle phase)
  proneTimerStart = nil,      -- Timestamp when salve detected
  proneAttackCount = 0,       -- Number of attacks since prone started
  proneTimerActive = false,   -- Is the 9-second window active
  -- Brokenstar tracking
  isImpaled = false,          -- Target is currently impaled
  impaleslashDone = false,    -- Impaleslash has been executed
  secondImpale = false,       -- Second impale after impaleslash done
  bleedingReady = false,      -- Bleeding at 700+ (heavy torrents)
  targetBleeding = 0,         -- Actual bleeding value from assess
  withdrawDone = false,       -- Blade withdrawn (ready for brokenstar)
  bladetwistCount = 0,        -- Number of bladetwists since impaleslash
  -- Other
  lastHamstringTime = 0,
  compassDamage = 14.9,
}

-- Configuration
blademaster.config = {
  breakThreshold = 100,
  prepThreshold = 90,
  killHealthThreshold = 30,
  hamstringDuration = 10,
  proneTimerDuration = 9,     -- Seconds from salve to stand
  balanceslashThreshold = 4,  -- Switch to balanceslash on this attack number
  brokenstarBleedThreshold = 700,  -- Bleeding level for brokenstar execution
}

--------------------------------------------------------------------------------
-- AFFLICTION TRACKING HELPERS (V3 compatible)
--------------------------------------------------------------------------------

-- Helper to check if target has an affliction (V3/V2/V1 routing)
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

-- Get affliction probability (V3 only, returns 0-1)
-- Falls back to binary (1.0 if has, 0 if not) for V2/V1
function blademaster.getAffProb(aff)
  if affConfigV3 and affConfigV3.enabled and getAffProbabilityV3 then
    return getAffProbabilityV3(aff)
  end
  return blademaster.hasAff(aff) and 1.0 or 0
end

-- Check which tracking system is active
function blademaster.getTrackingSystem()
  if affConfigV3 and affConfigV3.enabled then return "V3"
  elseif ataxia and ataxia.settings and ataxia.settings.useAffTrackingV2 then return "V2"
  end
  return "V1"
end

--------------------------------------------------------------------------------
-- LB LIMB TRACKING HELPERS
--------------------------------------------------------------------------------

function blademaster.getLimbDamage(limb)
  if not lb or not target then return 0 end
  local t = target:lower():gsub("^%l", string.upper)
  if not lb[t] or not lb[t].hits then return 0 end
  return lb[t].hits[limb] or 0
end

function blademaster.getLL()
  return blademaster.getLimbDamage("left leg")
end

function blademaster.getRL()
  return blademaster.getLimbDamage("right leg")
end

function blademaster.getLA()
  return blademaster.getLimbDamage("left arm")
end

function blademaster.getRA()
  return blademaster.getLimbDamage("right arm")
end

function blademaster.getTorso()
  return blademaster.getLimbDamage("torso")
end

function blademaster.getHead()
  return blademaster.getLimbDamage("head")
end

--------------------------------------------------------------------------------
-- CONDITION CHECKS - ARMS
--------------------------------------------------------------------------------

function blademaster.checkBothArmsPrepped()
  return blademaster.getLA() >= blademaster.config.prepThreshold and
         blademaster.getRA() >= blademaster.config.prepThreshold
end

function blademaster.checkBothArmsBroken()
  return blademaster.getLA() >= blademaster.config.breakThreshold and
         blademaster.getRA() >= blademaster.config.breakThreshold
end

function blademaster.checkAnyArmBroken()
  return blademaster.getLA() >= blademaster.config.breakThreshold or
         blademaster.getRA() >= blademaster.config.breakThreshold
end

function blademaster.checkWillDoubleBreakArms()
  local LA = blademaster.getLA()
  local RA = blademaster.getRA()
  local P = blademaster.state.armPrimaryDamage
  local S = blademaster.state.armSecondaryDamage
  local focusArm = blademaster.getFocusArm()

  if focusArm == "left" then
    return (LA + P >= 100) and (RA + S >= 100)
  else
    return (RA + P >= 100) and (LA + S >= 100)
  end
end

function blademaster.checkWillPrepBothArms()
  -- Check if the next attack will bring BOTH arms to 90%+ (prep threshold)
  local LA = blademaster.getLA()
  local RA = blademaster.getRA()
  local P = blademaster.state.armPrimaryDamage
  local S = blademaster.state.armSecondaryDamage
  local threshold = blademaster.config.prepThreshold
  local focusArm = blademaster.getFocusArm()

  -- If already both prepped, return false (we're past this point)
  if LA >= threshold and RA >= threshold then
    return false
  end

  if focusArm == "left" then
    return (LA + P >= threshold) and (RA + S >= threshold)
  else
    return (RA + P >= threshold) and (LA + S >= threshold)
  end
end

--------------------------------------------------------------------------------
-- CONDITION CHECKS - LEGS
--------------------------------------------------------------------------------

function blademaster.checkBothLegsPrepped()
  return blademaster.getLL() >= blademaster.config.prepThreshold and
         blademaster.getRL() >= blademaster.config.prepThreshold
end

function blademaster.checkBothLegsBroken()
  return blademaster.getLL() >= blademaster.config.breakThreshold and
         blademaster.getRL() >= blademaster.config.breakThreshold
end

function blademaster.checkAnyLegBroken()
  return blademaster.getLL() >= blademaster.config.breakThreshold or
         blademaster.getRL() >= blademaster.config.breakThreshold
end

function blademaster.checkWillDoubleBreakLegs()
  local LL = blademaster.getLL()
  local RL = blademaster.getRL()
  local P = blademaster.state.legPrimaryDamage
  local S = blademaster.state.legSecondaryDamage
  local focusLeg = blademaster.getFocusLeg()

  if focusLeg == "left" then
    return (LL + P >= 100) and (RL + S >= 100)
  else
    return (RL + P >= 100) and (LL + S >= 100)
  end
end

function blademaster.checkWillPrepBothLegs()
  -- Check if the next attack will bring BOTH legs to 90%+ (prep threshold)
  local LL = blademaster.getLL()
  local RL = blademaster.getRL()
  local P = blademaster.state.legPrimaryDamage
  local S = blademaster.state.legSecondaryDamage
  local threshold = blademaster.config.prepThreshold
  local focusLeg = blademaster.getFocusLeg()

  -- If already both prepped, return false (we're past this point)
  if LL >= threshold and RL >= threshold then
    return false
  end

  if focusLeg == "left" then
    return (LL + P >= threshold) and (RL + S >= threshold)
  else
    return (RL + P >= threshold) and (LL + S >= threshold)
  end
end

--------------------------------------------------------------------------------
-- CONDITION CHECKS - UPPER BODY (Torso + Head via Centreslash Up)
--------------------------------------------------------------------------------

function blademaster.checkUpperPrepped()
  -- Both torso AND head must be at 90%+ for prep
  return blademaster.getTorso() >= blademaster.config.prepThreshold and
         blademaster.getHead() >= blademaster.config.prepThreshold
end

function blademaster.checkUpperBroken()
  -- Both torso AND head must be at 100%+ for broken
  return blademaster.getTorso() >= blademaster.config.breakThreshold and
         blademaster.getHead() >= blademaster.config.breakThreshold
end

function blademaster.checkWillPrepUpper()
  -- Check if the next centreslash will bring BOTH torso and head to 90%+
  -- Uses optimal direction (hit lower limb as primary) for accurate calculation
  local torso = blademaster.getTorso()
  local head = blademaster.getHead()
  local primaryDmg = blademaster.state.torsoDamage   -- 18.1%
  local secondaryDmg = blademaster.state.headDamage  -- 12.1%
  local threshold = blademaster.config.prepThreshold

  -- If already both prepped, return false
  if torso >= threshold and head >= threshold then
    return false
  end

  -- Calculate based on which limb gets primary damage (lower limb = primary)
  if head <= torso then
    -- DOWN: head gets primary, torso gets secondary
    return (head + primaryDmg >= threshold) and (torso + secondaryDmg >= threshold)
  else
    -- UP: torso gets primary, head gets secondary
    return (torso + primaryDmg >= threshold) and (head + secondaryDmg >= threshold)
  end
end

function blademaster.checkWillBreakUpper()
  -- Check if the next centreslash will BREAK both torso and head
  -- Uses the optimal direction (up or down) based on which limb is lower
  local torso = blademaster.getTorso()
  local head = blademaster.getHead()
  local primaryDmg = blademaster.state.torsoDamage   -- 18.1%
  local secondaryDmg = blademaster.state.headDamage  -- 12.1%
  local breakThreshold = blademaster.config.breakThreshold

  -- If we hit the lower limb as primary, calculate final values
  if head <= torso then
    -- DOWN: head gets primary, torso gets secondary
    return (head + primaryDmg >= breakThreshold) and (torso + secondaryDmg >= breakThreshold)
  else
    -- UP: torso gets primary, head gets secondary
    return (torso + primaryDmg >= breakThreshold) and (head + secondaryDmg >= breakThreshold)
  end
end

function blademaster.getCentreslashDirection()
  -- Choose direction to hit the LOWER limb as primary (like getFocusLeg)
  -- UP: torso = primary (18.1%), head = secondary (12.1%)
  -- DOWN: head = primary (18.1%), torso = secondary (12.1%)
  local torso = blademaster.getTorso()
  local head = blademaster.getHead()

  if head <= torso then
    return "down"  -- Hit head as primary
  else
    return "up"    -- Hit torso as primary
  end
end

--------------------------------------------------------------------------------
-- FOCUS DIRECTION HELPERS
--------------------------------------------------------------------------------

function blademaster.getParried()
  local parried = tparrying or ataxiaTemp.parriedLimb or "none"
  if parried == false or parried == "" then
    parried = "none"
  end
  return parried
end

function blademaster.getFocusArm()
  local LA = blademaster.getLA()
  local RA = blademaster.getRA()
  local parried = blademaster.getParried()

  if LA >= blademaster.config.prepThreshold and RA >= blademaster.config.prepThreshold then
    return parried == "left arm" and "right" or "left"
  end

  local focus = (LA <= RA) and "left" or "right"

  if parried == focus .. " arm" then
    return focus == "left" and "right" or "left"
  end

  return focus
end

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

--------------------------------------------------------------------------------
-- PATH CALCULATIONS
--------------------------------------------------------------------------------

function blademaster.calculateArmPath()
  local LA = blademaster.getLA()
  local RA = blademaster.getRA()
  local P = blademaster.state.armPrimaryDamage
  local S = blademaster.state.armSecondaryDamage
  local threshold = blademaster.config.prepThreshold

  if LA >= threshold and RA >= threshold then
    return { hitsToDouble = 0, explanation = "Both arms ready for double-break!" }
  end

  local simLA, simRA = LA, RA
  local hits = 0
  local sequence = {}

  while simLA < threshold or simRA < threshold do
    hits = hits + 1
    if hits > 20 then break end

    if simLA <= simRA then
      simLA = simLA + P
      simRA = simRA + S
      table.insert(sequence, "L")
    else
      simLA = simLA + S
      simRA = simRA + P
      table.insert(sequence, "R")
    end
  end

  return {
    hitsToDouble = hits,
    explanation = string.format("%d hits to arm double-break (sequence: %s)", hits, table.concat(sequence, ""))
  }
end

function blademaster.calculateLegPath()
  local LL = blademaster.getLL()
  local RL = blademaster.getRL()
  local P = blademaster.state.legPrimaryDamage
  local S = blademaster.state.legSecondaryDamage
  local threshold = blademaster.config.prepThreshold

  if LL >= threshold and RL >= threshold then
    return { hitsToDouble = 0, explanation = "Both legs ready for double-break!" }
  end

  local simLL, simRL = LL, RL
  local hits = 0
  local sequence = {}

  while simLL < threshold or simRL < threshold do
    hits = hits + 1
    if hits > 20 then break end

    if simLL <= simRL then
      simLL = simLL + P
      simRL = simRL + S
      table.insert(sequence, "L")
    else
      simLL = simLL + S
      simRL = simRL + P
      table.insert(sequence, "R")
    end
  end

  return {
    hitsToDouble = hits,
    explanation = string.format("%d hits to leg double-break (sequence: %s)", hits, table.concat(sequence, ""))
  }
end

--------------------------------------------------------------------------------
-- SHIN & AIRFIST
--------------------------------------------------------------------------------

function blademaster.getShin()
  if gmcp and gmcp.Char and gmcp.Char.Vitals and gmcp.Char.Vitals.charstats then
    for _, stat in ipairs(gmcp.Char.Vitals.charstats) do
      local shinValue = string.match(stat, "Shin:%s*(%d+)")
      if shinValue then
        return tonumber(shinValue) or 0
      end
    end
  end
  return 0
end

function blademaster.needsAirfist(targetLimbType)
  local parried = blademaster.getParried()
  local shin = blademaster.getShin()

  if shin < 25 then
    return false, "not enough shin (" .. shin .. "/25)"
  end

  if blademaster.hasAff("airfisted") then
    return false, "already airfisted"
  end

  if targetLimbType == "arm" then
    if parried == "left arm" or parried == "right arm" then
      return true, "parrying arm (" .. parried .. ")"
    end
  elseif targetLimbType == "leg" then
    if parried == "left leg" or parried == "right leg" then
      return true, "parrying leg (" .. parried .. ")"
    end
  end

  return false, "not parrying target limb"
end

--------------------------------------------------------------------------------
-- STRIKE SELECTION (shared)
--------------------------------------------------------------------------------

function blademaster.selectPrepStrike()
  -- Prep phase strikes: Hamstring first, then afflictions
  local now = os.time()
  local hamstringExpired = (now - (blademaster.state.lastHamstringTime or 0)) >= blademaster.config.hamstringDuration
  if not blademaster.hasAff("hamstring") or hamstringExpired then
    return "hamstring"
  end

  -- Lightning prep: paralysis > hypochondria > weariness > clumsiness
  if not blademaster.hasAff("paralysis") then
    return "neck"
  end
  if not blademaster.hasAff("hypochondria") then
    return "chest"
  end
  if not blademaster.hasAff("weariness") then
    return "shoulder"
  end
  if not blademaster.hasAff("clumsiness") then
    return "ears"
  end

  return "neck"
end

function blademaster.selectIceStrike()
  -- Ice phase: clumsiness first (ice doesn't give it), then others
  if not blademaster.hasAff("clumsiness") then
    return "ears"
  end
  if not blademaster.hasAff("paralysis") then
    return "neck"
  end
  return "neck"
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  STRATEGY 1: DOUBLE-PREP (LEGS ONLY)
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function blademaster.getPhaseDoublePrep()
  -- 3-phase system for legs only:
  -- 1. leg_prep: Both legs < 90% (Lightning)
  -- 2. leg_break: Legs prepped, not broken (Ice)
  -- 3. mangle: PRONE (Ice + Sternum) - stay in mangle as long as they're down

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

function blademaster.getPhaseLabelDoublePrep()
  local phase = blademaster.getPhaseDoublePrep()
  local labels = {
    leg_prep = "<yellow>Leg Prep",
    leg_break = "<blue>Leg Break",
    mangle = "<red>Mangle",
  }
  return labels[phase] or "<grey>Unknown"
end

function blademaster.selectStrikeDoublePrep()
  local phase = blademaster.getPhaseDoublePrep()

  -- MANGLE: Always STERNUM
  if phase == "mangle" then
    return "sternum"
  end

  -- LEG BREAK: KNEES for prone
  if phase == "leg_break" then
    return "knees"
  end

  -- LEG PREP: Check if we need to dismount before double-break
  if phase == "leg_prep" then
    -- Dismount during final prep hit if mounted + hamstrung
    -- This ensures KNEES on double-break will prone (not just dismount)
    if tmounted and blademaster.hasAff("hamstring") and blademaster.checkWillPrepBothLegs() then
      return "knees"  -- Dismount now, so KNEES on double-break will prone
    end
    return blademaster.selectPrepStrike()
  end

  return blademaster.selectPrepStrike()
end

function blademaster.selectAttackDoublePrep()
  local phase = blademaster.getPhaseDoublePrep()

  -- Dual-check: belt-and-suspenders for critical defenses (matches DWC reference)
  if blademaster.hasAff("shield") or blademaster.hasAff("rebounding") or (tAffs and (tAffs.shield or tAffs.rebounding)) then
    return "raze", nil
  end

  -- Airfist is its own full-balance attack (use during prep phases)
  if phase == "leg_prep" then
    local needsAF, _ = blademaster.needsAirfist("leg")
    if needsAF then
      return "airfist", nil
    end
  end

  -- MANGLE PHASE: Check if we should use balanceslash
  if phase == "mangle" then
    -- On 4th+ attack during prone timer, use balanceslash to extend prone
    if blademaster.state.proneTimerActive and
       blademaster.state.proneAttackCount >= blademaster.config.balanceslashThreshold then
      return "balanceslash", nil
    end

    -- Hit the broken leg for mangle damage
    local LL = blademaster.getLL()
    local RL = blademaster.getRL()

    -- If both broken, hit the higher one (more mangle damage)
    if LL >= 100 and RL >= 100 then
      return "legslash", (LL >= RL) and "left" or "right"
    end

    -- If only one broken, hit that one
    if LL >= 100 then
      return "legslash", "left"
    end
    if RL >= 100 then
      return "legslash", "right"
    end

    -- Fallback (shouldn't reach here if in mangle phase)
    return "legslash", "right"
  end

  return "legslash", blademaster.getFocusLeg()
end

function blademaster.buildComboDoublePrep()
  local attack, direction = blademaster.selectAttackDoublePrep()
  local strike = blademaster.selectStrikeDoublePrep()
  local phase = blademaster.getPhaseDoublePrep()
  local combo = ""

  -- Airfist is its own full-balance attack (no infuse, no strike)
  if attack == "airfist" then
    return "airfist " .. target .. ";assess " .. target
  end

  -- Infuse: Ice for break/mangle, Lightning for prep
  -- EXCEPTION: Use Ice on final prep attack to strip caloric before break
  if phase == "leg_break" or phase == "mangle" then
    combo = "infuse ice;"
  elseif phase == "leg_prep" and blademaster.checkWillPrepBothLegs() then
    combo = "infuse ice;"
  else
    combo = "infuse lightning;"
  end

  if attack == "raze" then
    combo = combo .. "raze " .. target
    if strike then
      combo = combo .. " " .. strike
    end
  elseif attack == "balanceslash" then
    -- Balanceslash to extend prone time (no direction needed)
    combo = combo .. "balanceslash " .. target
    if strike then
      combo = combo .. " " .. strike
    end
  elseif attack == "legslash" then
    combo = combo .. "legslash " .. target .. " " .. direction
    if strike then
      combo = combo .. " " .. strike
    end
  end

  return combo
end

function blademaster.dispatch.runDoublePrep()
  ataxia = ataxia or {}
  ataxia.vitals = ataxia.vitals or {}
  ataxia.settings = ataxia.settings or {}
  ataxiaTemp = ataxiaTemp or {}
  tAffs = tAffs or {}

  if not target or target == "" then
    cecho("\n<red>[BM] No target set! Use: tar <name>")
    return
  end

  local phase = blademaster.getPhaseDoublePrep()
  local phaseLabel = blademaster.getPhaseLabelDoublePrep()
  local targetHP = tonumber(ataxiaTemp.targetHP) or 100

  -- Reset prone timer if not in mangle phase or target not prone
  if phase ~= "mangle" or not blademaster.hasAff("prone") then
    blademaster.resetProneTimer()
  end

  -- Status output
  cecho("\n<cyan>[BM " .. phaseLabel .. "<cyan>] Target: " .. tostring(target) .. " | HP: " .. targetHP .. "% | Track: " .. blademaster.getTrackingSystem())
  cecho("\n<cyan>[BM " .. phaseLabel .. "<cyan>] Legs: LL=" .. string.format("%.1f", blademaster.getLL()) .. "% RL=" .. string.format("%.1f", blademaster.getRL()) .. "%")
  cecho("\n<cyan>[BM " .. phaseLabel .. "<cyan>] Dmg: P=" .. string.format("%.1f", blademaster.state.legPrimaryDamage) .. "% S=" .. string.format("%.1f", blademaster.state.legSecondaryDamage) .. "%")

  -- Phase-specific messages
  if phase == "leg_prep" then
    local legPath = blademaster.calculateLegPath()
    if blademaster.checkWillPrepBothLegs() then
      -- Check if dismounting mounted target
      if tmounted and blademaster.hasAff("hamstring") then
        cecho("\n<magenta>*** DISMOUNT - KNEES to dismount before double-break! ***")
      else
        cecho("\n<blue>*** FINAL PREP - ICE infuse to strip caloric! ***")
      end
    elseif legPath.hitsToDouble > 0 then
      cecho("\n<yellow>" .. legPath.explanation)
    end
  elseif phase == "leg_break" then
    cecho("\n<blue>*** LEG BREAK - ICE infuse + KNEES for prone! ***")
  elseif phase == "mangle" then
    -- Show mangle info with prone timer status
    if blademaster.state.proneTimerActive then
      local attackNum = blademaster.state.proneAttackCount + 1  -- Next attack number
      local threshold = blademaster.config.balanceslashThreshold
      if attackNum >= threshold then
        cecho("\n<magenta>*** MANGLE - BALANCESLASH + STERNUM (attack #" .. attackNum .. ", extending prone) ***")
      else
        cecho("\n<red>*** MANGLE - Legslash right + STERNUM (attack #" .. attackNum .. "/" .. threshold .. ") ***")
      end
    else
      cecho("\n<red>*** MANGLE - Legslash right + STERNUM (waiting for salve) ***")
    end
  end

  -- Parry info and airfist status
  local parried = blademaster.getParried()
  local shin = blademaster.getShin()
  local attack, _ = blademaster.selectAttackDoublePrep()
  cecho("\n<cyan>[BM " .. phaseLabel .. "<cyan>] Parried: " .. parried .. " | Shin: " .. shin)
  if attack == "airfist" then
    cecho(" | <green>AIRFIST!")
  end

  -- Increment attack count in mangle phase
  if phase == "mangle" and blademaster.state.proneTimerActive then
    blademaster.state.proneAttackCount = blademaster.state.proneAttackCount + 1
  end

  -- Build and send
  local cmd = ""
  if combatQueue then
    cmd = combatQueue()
  end

  cmd = cmd .. blademaster.buildComboDoublePrep()
  cmd = cmd .. ";assess " .. target

  send("queue addclear free " .. cmd)
end

-- Aliases for Double-Prep
function bmd()
  blademaster.dispatch.runDoublePrep()
end

function bmdispatch()
  blademaster.dispatch.runDoublePrep()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  STRATEGY 2: QUAD-PREP (ARMS + LEGS)
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function blademaster.getPhaseQuadPrep()
  -- 5-phase system:
  -- 1. arm_prep: Both arms < 90% (Lightning)
  -- 2. leg_prep: Arms prepped, both legs < 90% (Lightning)
  -- 3. arm_break: Arms & legs prepped, arms not broken (Ice)
  -- 4. leg_break: Arms broken, legs prepped, legs not broken (Ice)
  -- 5. mangle: PRONE (Ice + Sternum) - stay in mangle as long as they're down

  local armsPrepped = blademaster.checkBothArmsPrepped()
  local armsBroken = blademaster.checkBothArmsBroken()
  local legsPrepped = blademaster.checkBothLegsPrepped()
  local legsBroken = blademaster.checkBothLegsBroken()

  -- Phase 5: MANGLE - If prone, stay in mangle for max damage
  if blademaster.hasAff("prone") then
    return "mangle"
  end

  -- Phase 4: LEG BREAK
  if armsBroken and legsPrepped then
    return "leg_break"
  end

  -- Phase 3: ARM BREAK
  if armsPrepped and legsPrepped and not armsBroken then
    return "arm_break"
  end

  -- Phase 2: LEG PREP
  if armsPrepped and not legsPrepped then
    return "leg_prep"
  end

  -- Phase 1: ARM PREP
  return "arm_prep"
end

function blademaster.getPhaseLabelQuadPrep()
  local phase = blademaster.getPhaseQuadPrep()
  local labels = {
    arm_prep = "<yellow>Arm Prep",
    leg_prep = "<yellow>Leg Prep",
    arm_break = "<blue>Arm Break",
    leg_break = "<blue>Leg Break",
    mangle = "<red>Mangle",
  }
  return labels[phase] or "<grey>Unknown"
end

function blademaster.selectStrikeQuadPrep()
  local phase = blademaster.getPhaseQuadPrep()

  -- MANGLE: Always STERNUM
  if phase == "mangle" then
    return "sternum"
  end

  -- LEG BREAK: KNEES for prone
  if phase == "leg_break" then
    return "knees"
  end

  -- ARM BREAK: Ice afflictions
  if phase == "arm_break" then
    return blademaster.selectIceStrike()
  end

  -- PREP PHASES: Standard prep strikes
  return blademaster.selectPrepStrike()
end

function blademaster.selectAttackQuadPrep()
  local phase = blademaster.getPhaseQuadPrep()

  -- Dual-check: belt-and-suspenders for critical defenses (matches DWC reference)
  if blademaster.hasAff("shield") or blademaster.hasAff("rebounding") or (tAffs and (tAffs.shield or tAffs.rebounding)) then
    return "raze", nil
  end

  -- Airfist is its own full-balance attack (use during prep phases)
  if phase == "arm_prep" then
    local needsAF, _ = blademaster.needsAirfist("arm")
    if needsAF then
      return "airfist", nil
    end
    return "armslash", blademaster.getFocusArm()
  end

  if phase == "leg_prep" then
    local needsAF, _ = blademaster.needsAirfist("leg")
    if needsAF then
      return "airfist", nil
    end
    return "legslash", blademaster.getFocusLeg()
  end

  if phase == "arm_break" then
    return "armslash", blademaster.getFocusArm()
  end

  if phase == "leg_break" then
    return "legslash", blademaster.getFocusLeg()
  end

  -- MANGLE PHASE: Check if we should use balanceslash
  if phase == "mangle" then
    -- On 4th+ attack during prone timer, use balanceslash to extend prone
    if blademaster.state.proneTimerActive and
       blademaster.state.proneAttackCount >= blademaster.config.balanceslashThreshold then
      return "balanceslash", nil
    end

    -- Hit the broken leg for mangle damage
    local LL = blademaster.getLL()
    local RL = blademaster.getRL()

    -- If both broken, hit the higher one (more mangle damage)
    if LL >= 100 and RL >= 100 then
      return "legslash", (LL >= RL) and "left" or "right"
    end

    -- If only one broken, hit that one
    if LL >= 100 then
      return "legslash", "left"
    end
    if RL >= 100 then
      return "legslash", "right"
    end

    -- Fallback
    return "legslash", "right"
  end

  return "legslash", blademaster.getFocusLeg()
end

function blademaster.buildComboQuadPrep()
  local attack, direction = blademaster.selectAttackQuadPrep()
  local strike = blademaster.selectStrikeQuadPrep()
  local phase = blademaster.getPhaseQuadPrep()
  local combo = ""

  -- Airfist is its own full-balance attack (no infuse, no strike)
  if attack == "airfist" then
    return "airfist " .. target .. ";assess " .. target
  end

  -- Infuse: Ice for break/mangle phases, Lightning for prep
  -- EXCEPTION: Use Ice on final prep attacks to strip caloric before break
  if phase == "arm_break" or phase == "leg_break" or phase == "mangle" then
    combo = "infuse ice;"
  elseif phase == "arm_prep" and blademaster.checkWillPrepBothArms() then
    combo = "infuse ice;"
  elseif phase == "leg_prep" and blademaster.checkWillPrepBothLegs() then
    combo = "infuse ice;"
  else
    combo = "infuse lightning;"
  end

  if attack == "raze" then
    combo = combo .. "raze " .. target
    if strike then
      combo = combo .. " " .. strike
    end
  elseif attack == "balanceslash" then
    -- Balanceslash to extend prone time (no direction needed)
    combo = combo .. "balanceslash " .. target
    if strike then
      combo = combo .. " " .. strike
    end
  elseif attack == "armslash" then
    combo = combo .. "armslash " .. target .. " " .. direction
    if strike then
      combo = combo .. " " .. strike
    end
  elseif attack == "legslash" then
    combo = combo .. "legslash " .. target .. " " .. direction
    if strike then
      combo = combo .. " " .. strike
    end
  end

  return combo
end

function blademaster.dispatch.runQuadPrep()
  ataxia = ataxia or {}
  ataxia.vitals = ataxia.vitals or {}
  ataxia.settings = ataxia.settings or {}
  ataxiaTemp = ataxiaTemp or {}
  tAffs = tAffs or {}

  if not target or target == "" then
    cecho("\n<red>[BM] No target set! Use: tar <name>")
    return
  end

  local phase = blademaster.getPhaseQuadPrep()
  local phaseLabel = blademaster.getPhaseLabelQuadPrep()
  local targetHP = tonumber(ataxiaTemp.targetHP) or 100

  -- Reset prone timer if not in mangle phase or target not prone
  if phase ~= "mangle" or not blademaster.hasAff("prone") then
    blademaster.resetProneTimer()
  end

  -- Status output
  cecho("\n<cyan>[BMQ " .. phaseLabel .. "<cyan>] Target: " .. tostring(target) .. " | HP: " .. targetHP .. "% | Track: " .. blademaster.getTrackingSystem())
  cecho("\n<cyan>[BMQ " .. phaseLabel .. "<cyan>] Arms: LA=" .. string.format("%.1f", blademaster.getLA()) .. "% RA=" .. string.format("%.1f", blademaster.getRA()) .. "%")
  cecho("\n<cyan>[BMQ " .. phaseLabel .. "<cyan>] Legs: LL=" .. string.format("%.1f", blademaster.getLL()) .. "% RL=" .. string.format("%.1f", blademaster.getRL()) .. "%")

  -- Phase-specific messages
  if phase == "arm_prep" then
    local armPath = blademaster.calculateArmPath()
    if blademaster.checkWillPrepBothArms() then
      cecho("\n<blue>*** FINAL ARM PREP - ICE infuse to strip caloric! ***")
    elseif armPath.hitsToDouble > 0 then
      cecho("\n<yellow>" .. armPath.explanation)
    else
      cecho("\n<green>*** ARMS READY ***")
    end
  elseif phase == "leg_prep" then
    local legPath = blademaster.calculateLegPath()
    if blademaster.checkWillPrepBothLegs() then
      cecho("\n<blue>*** FINAL LEG PREP - ICE infuse to strip caloric! ***")
    elseif legPath.hitsToDouble > 0 then
      cecho("\n<yellow>" .. legPath.explanation)
    else
      cecho("\n<green>*** LEGS READY ***")
    end
  elseif phase == "arm_break" then
    cecho("\n<blue>*** ARM BREAK - ICE infuse, break both arms! ***")
  elseif phase == "leg_break" then
    cecho("\n<blue>*** LEG BREAK - ICE infuse + KNEES for prone! ***")
  elseif phase == "mangle" then
    -- Show mangle info with prone timer status
    if blademaster.state.proneTimerActive then
      local attackNum = blademaster.state.proneAttackCount + 1  -- Next attack number
      local threshold = blademaster.config.balanceslashThreshold
      if attackNum >= threshold then
        cecho("\n<magenta>*** MANGLE - BALANCESLASH + STERNUM (attack #" .. attackNum .. ", extending prone) ***")
      else
        cecho("\n<red>*** MANGLE - Legslash + STERNUM (attack #" .. attackNum .. "/" .. threshold .. ") ***")
      end
    else
      cecho("\n<red>*** MANGLE - Legslash + STERNUM (waiting for salve) ***")
    end
  end

  -- Parry info and airfist status
  local parried = blademaster.getParried()
  local shin = blademaster.getShin()
  local attack, _ = blademaster.selectAttackQuadPrep()
  cecho("\n<cyan>[BMQ " .. phaseLabel .. "<cyan>] Parried: " .. parried .. " | Shin: " .. shin)
  if attack == "airfist" then
    cecho(" | <green>AIRFIST!")
  end

  -- Increment attack count in mangle phase
  if phase == "mangle" and blademaster.state.proneTimerActive then
    blademaster.state.proneAttackCount = blademaster.state.proneAttackCount + 1
  end

  -- Build and send
  local cmd = ""
  if combatQueue then
    cmd = combatQueue()
  end

  cmd = cmd .. blademaster.buildComboQuadPrep()
  cmd = cmd .. ";assess " .. target

  send("queue addclear free " .. cmd)
end

-- Aliases for Quad-Prep
function bmdq()
  blademaster.dispatch.runQuadPrep()
end

function bmdispatchquad()
  blademaster.dispatch.runQuadPrep()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  STRATEGY 3: BROKENSTAR (INSTANT KILL)
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function blademaster.resetBrokenstarState()
  blademaster.state.isImpaled = false
  blademaster.state.impaleslashDone = false
  blademaster.state.secondImpale = false
  blademaster.state.bleedingReady = false
  blademaster.state.targetBleeding = 0
  blademaster.state.withdrawDone = false
  blademaster.state.bladetwistCount = 0
end

function blademaster.getPhaseBrokenstar()
  -- 9-phase system for instant kill with upper body prep:
  -- 1. upper_prep: Centreslash up to prep torso/head (90%+)
  -- 2. leg_prep: Legslash to prep both legs (90%+)
  -- 3. upper_break: Centreslash up to break torso/head (100%+)
  -- 4. leg_break: Legslash + KNEES to break legs + prone (100%+)
  -- 5. impale: Impale the prone target
  -- 6. impaleslash: Slash arteries for bleeding
  -- 7. bladetwist: Twist until 700 bleeding
  -- 8. withdraw: Withdraw blade (if still impaled)
  -- 9. brokenstar: Execute instant kill

  local upperPrepped = blademaster.checkUpperPrepped()
  local upperBroken = blademaster.checkUpperBroken()
  local legsPrepped = blademaster.checkBothLegsPrepped()
  local legsBroken = blademaster.checkBothLegsBroken()

  -- Phase 9: BROKENSTAR (execute kill)
  -- Can brokenstar if: withdrew blade OR target not impaled (writhed free + stood up)
  if blademaster.state.bleedingReady and (blademaster.state.withdrawDone or not blademaster.state.isImpaled) then
    return "brokenstar"
  end

  -- Phase 8: WITHDRAW (pull blade out) - only if still impaled
  if blademaster.state.bleedingReady and blademaster.state.isImpaled then
    return "withdraw"
  end

  -- Phase 7: BLADETWIST (build bleeding) - requires being impaled!
  if blademaster.state.impaleslashDone and blademaster.state.isImpaled then
    return "bladetwist"
  end

  -- Phase 6: IMPALESLASH (slash arteries)
  if blademaster.state.isImpaled and not blademaster.state.impaleslashDone then
    return "impaleslash"
  end

  -- Phase 5: IMPALE (first impale or re-impale after writhe)
  -- Can impale if: both legs broken OR target is prone (from writhe while prone)
  local targetProne = blademaster.hasAff("prone")
  local canImpale = legsBroken or targetProne
  if canImpale and not blademaster.state.isImpaled then
    return "impale"
  end

  -- Phase 4: LEG BREAK (upper must be broken first!)
  if upperBroken and (legsPrepped or blademaster.checkWillDoubleBreakLegs()) then
    return "leg_break"
  end

  -- Phase 3: UPPER BREAK (legs must be prepped first!)
  if legsPrepped and (upperPrepped or blademaster.checkWillBreakUpper()) then
    return "upper_break"
  end

  -- Phase 2: LEG PREP (upper must be prepped first!)
  if upperPrepped and not legsPrepped then
    return "leg_prep"
  end

  -- Phase 1: UPPER PREP (default - prep torso/head first)
  return "upper_prep"
end

function blademaster.getPhaseLabelBrokenstar()
  local phase = blademaster.getPhaseBrokenstar()
  local labels = {
    upper_prep = "<yellow>Upper Prep",
    leg_prep = "<yellow>Leg Prep",
    upper_break = "<blue>Upper Break",
    leg_break = "<blue>Leg Break",
    impale = "<cyan>Impale",
    impaleslash = "<magenta>Impaleslash",
    bladetwist = "<red>Bladetwist",
    withdraw = "<yellow>Withdraw",
    brokenstar = "<green>BROKENSTAR",
  }
  return labels[phase] or "<grey>Unknown"
end

function blademaster.selectStrikeBrokenstar()
  local phase = blademaster.getPhaseBrokenstar()

  -- UPPER PREP: Standard prep strikes (hamstring > paralysis > etc)
  if phase == "upper_prep" then
    return blademaster.selectPrepStrike()
  end

  -- UPPER BREAK: Ice afflictions (clumsiness first since ice doesn't give it)
  if phase == "upper_break" then
    return blademaster.selectIceStrike()
  end

  -- LEG BREAK: KNEES for prone (critical - need prone for guaranteed impale!)
  if phase == "leg_break" then
    return "knees"
  end

  -- LEG PREP: Check if we need to dismount before double-break
  if phase == "leg_prep" then
    -- Dismount during final prep hit if mounted + hamstrung
    if tmounted and blademaster.hasAff("hamstring") and blademaster.checkWillPrepBothLegs() then
      return "knees"  -- Dismount now, so KNEES on double-break will prone
    end
    return blademaster.selectPrepStrike()
  end

  -- Impale phases and beyond: No strike needed
  return nil
end

function blademaster.selectAttackBrokenstar()
  local phase = blademaster.getPhaseBrokenstar()

  -- Dual-check: belt-and-suspenders for critical defenses (matches DWC reference)
  if blademaster.hasAff("shield") or blademaster.hasAff("rebounding") or (tAffs and (tAffs.shield or tAffs.rebounding)) then
    return "raze"
  end

  -- Airfist during leg prep if needed
  if phase == "leg_prep" then
    local needsAF, _ = blademaster.needsAirfist("leg")
    if needsAF then
      return "airfist"
    end
  end

  return phase  -- Return the phase name as the attack type
end

function blademaster.buildComboBrokenstar()
  local phase = blademaster.getPhaseBrokenstar()
  local attack = blademaster.selectAttackBrokenstar()
  local strike = blademaster.selectStrikeBrokenstar()
  local combo = ""

  -- Handle raze for shield/rebounding
  if attack == "raze" then
    combo = "raze " .. target
    if strike then
      combo = combo .. " " .. strike
    end
    combo = combo .. ";assess " .. target
    return combo
  end

  -- Airfist is its own full-balance attack (no infuse, no strike)
  if attack == "airfist" then
    return "airfist " .. target .. ";assess " .. target
  end

  if phase == "upper_prep" then
    -- Lightning infuse for prep, Ice on final prep (when about to prep both)
    -- Use dynamic direction to balance torso/head damage
    local direction = blademaster.getCentreslashDirection()
    if blademaster.checkWillPrepUpper() then
      combo = "infuse ice;"
    else
      combo = "infuse lightning;"
    end
    combo = combo .. "centreslash " .. target .. " " .. direction
    if strike then
      combo = combo .. " " .. strike
    end

  elseif phase == "upper_break" then
    -- Ice infuse for break, use dynamic direction
    local direction = blademaster.getCentreslashDirection()
    combo = "infuse ice;centreslash " .. target .. " " .. direction
    if strike then
      combo = combo .. " " .. strike
    end

  elseif phase == "leg_prep" then
    -- Lightning infuse for prep, Ice on final prep
    if blademaster.checkWillPrepBothLegs() then
      combo = "infuse ice;"
    else
      combo = "infuse lightning;"
    end
    local focusLeg = blademaster.getFocusLeg()
    combo = combo .. "legslash " .. target .. " " .. focusLeg
    if strike then
      combo = combo .. " " .. strike
    end

  elseif phase == "leg_break" then
    -- Ice infuse for break + KNEES to prone
    combo = "infuse ice;"
    local focusLeg = blademaster.getFocusLeg()
    combo = combo .. "legslash " .. target .. " " .. focusLeg
    if strike then
      combo = combo .. " " .. strike
    end

  elseif phase == "impale" then
    -- Impale the prone target
    combo = "impale " .. target

  elseif phase == "impaleslash" then
    -- Impaleslash to start bleeding
    combo = "impaleslash " .. target

  elseif phase == "bladetwist" then
    -- Bladetwist to build bleeding
    -- Count is incremented by trigger when bladetwist actually fires (not on button press)
    -- On 3rd+ bladetwist, add discern to check bleeding
    if blademaster.state.bladetwistCount >= 2 then
      combo = "bladetwist;discern " .. target
    else
      combo = "bladetwist;assess " .. target
    end
    return combo  -- Skip the assess at end since we already have it

  elseif phase == "withdraw" then
    -- Withdraw blade before brokenstar
    combo = "withdraw " .. target

  elseif phase == "brokenstar" then
    -- Execute the kill!
    combo = "brokenstar " .. target
  end

  -- Add assess for most phases (except bladetwist which has it built in)
  if phase ~= "bladetwist" then
    combo = combo .. ";assess " .. target
  end

  return combo
end

function blademaster.dispatch.runBrokenstar()
  ataxia = ataxia or {}
  ataxia.vitals = ataxia.vitals or {}
  ataxia.settings = ataxia.settings or {}
  ataxiaTemp = ataxiaTemp or {}
  tAffs = tAffs or {}

  if not target or target == "" then
    cecho("\n<red>[BM] No target set! Use: tar <name>")
    return
  end

  local phase = blademaster.getPhaseBrokenstar()
  local phaseLabel = blademaster.getPhaseLabelBrokenstar()
  local targetHP = tonumber(ataxiaTemp.targetHP) or 100

  -- Status output
  cecho("\n<cyan>[BMBS " .. phaseLabel .. "<cyan>] Target: " .. tostring(target) .. " | HP: " .. targetHP .. "% | Track: " .. blademaster.getTrackingSystem())
  cecho("\n<cyan>[BMBS " .. phaseLabel .. "<cyan>] Upper: T=" .. string.format("%.1f", blademaster.getTorso()) .. "% H=" .. string.format("%.1f", blademaster.getHead()) .. "%")
  cecho("\n<cyan>[BMBS " .. phaseLabel .. "<cyan>] Legs: LL=" .. string.format("%.1f", blademaster.getLL()) .. "% RL=" .. string.format("%.1f", blademaster.getRL()) .. "%")

  -- Phase-specific messages
  if phase == "upper_prep" then
    local direction = blademaster.getCentreslashDirection()
    if blademaster.checkWillPrepUpper() then
      cecho("\n<blue>*** FINAL UPPER PREP - ICE infuse + centreslash " .. direction .. "! ***")
    else
      cecho("\n<yellow>*** UPPER PREP - Centreslash " .. direction .. " (hitting " .. (direction == "up" and "torso" or "head") .. " as primary) ***")
    end
  elseif phase == "upper_break" then
    local direction = blademaster.getCentreslashDirection()
    cecho("\n<blue>*** UPPER BREAK - Centreslash " .. direction .. " to break torso/head! ***")
  elseif phase == "leg_prep" then
    local legPath = blademaster.calculateLegPath()
    if blademaster.checkWillPrepBothLegs() then
      -- Check if dismounting mounted target
      if tmounted and blademaster.hasAff("hamstring") then
        cecho("\n<magenta>*** DISMOUNT - KNEES to dismount before double-break! ***")
      else
        cecho("\n<blue>*** FINAL LEG PREP - ICE infuse to strip caloric! ***")
      end
    elseif legPath.hitsToDouble > 0 then
      cecho("\n<yellow>" .. legPath.explanation)
    end
  elseif phase == "leg_break" then
    cecho("\n<blue>*** LEG BREAK - Double-break legs + KNEES to prone! ***")
  elseif phase == "impale" then
    cecho("\n<cyan>*** IMPALE - Impale the prone target! ***")
  elseif phase == "impaleslash" then
    cecho("\n<magenta>*** IMPALESLASH - Slash arteries for bleeding! ***")
  elseif phase == "bladetwist" then
    local bleedColor = blademaster.state.targetBleeding >= 700 and "<green>" or "<yellow>"
    local twistNum = blademaster.state.bladetwistCount + 1  -- +1 because we display before increment
    local discernNote = twistNum >= 3 and " <cyan>(+discern)" or ""
    cecho("\n<red>*** BLADETWIST #" .. twistNum .. " - Building bleeding (" .. bleedColor .. blademaster.state.targetBleeding .. "/700<red>)" .. discernNote .. " ***")
  elseif phase == "withdraw" then
    cecho("\n<yellow>*** WITHDRAW - Pull blade out! ***")
  elseif phase == "brokenstar" then
    cecho("\n<green>*** BROKENSTAR - EXECUTE INSTANT KILL! ***")
  end

  -- State tracking display
  cecho("\n<cyan>[BMBS " .. phaseLabel .. "<cyan>] Impaled: " .. (blademaster.state.isImpaled and "<green>YES" or "<red>NO"))
  cecho("<cyan> | Slashed: " .. (blademaster.state.impaleslashDone and "<green>YES" or "<red>NO"))
  local bleedColor = blademaster.state.targetBleeding >= 700 and "<green>" or (blademaster.state.targetBleeding >= 300 and "<yellow>" or "<red>")
  cecho("<cyan> | Bleed: " .. bleedColor .. blademaster.state.targetBleeding)
  cecho("<cyan> | Withdrawn: " .. (blademaster.state.withdrawDone and "<green>YES" or "<red>NO"))

  -- Parry info and airfist status
  local parried = blademaster.getParried()
  local shin = blademaster.getShin()
  local attack = blademaster.selectAttackBrokenstar()
  cecho("\n<cyan>[BMBS " .. phaseLabel .. "<cyan>] Parried: " .. parried .. " | Shin: " .. shin)
  if attack == "airfist" then
    cecho(" | <green>AIRFIST!")
  end

  -- Build and send
  local cmd = ""
  if combatQueue then
    cmd = combatQueue()
  end

  cmd = cmd .. blademaster.buildComboBrokenstar()

  send("queue addclear free " .. cmd)
end

-- Aliases for Brokenstar
function bmbs()
  blademaster.dispatch.runBrokenstar()
end

function bmdispatchbs()
  blademaster.dispatch.runBrokenstar()
end

-- Reset Brokenstar state
function bmreset()
  blademaster.resetBrokenstarState()
  cecho("\n<green>[BM] Brokenstar state reset!")
end

--------------------------------------------------------------------------------
-- STATUS DISPLAYS
--------------------------------------------------------------------------------

function blademaster.dispatch.statusDoublePrep()
  tAffs = tAffs or {}
  ataxiaTemp = ataxiaTemp or {}

  local phase = blademaster.getPhaseDoublePrep()
  local phaseLabel = blademaster.getPhaseLabelDoublePrep()
  local targetHP = tonumber(ataxiaTemp.targetHP) or 100

  local function progressBar(pct, width)
    width = width or 10
    local filled = math.floor((pct / 100) * width)
    if filled > width then filled = width end
    local empty = width - filled
    return string.rep("#", filled) .. string.rep("-", empty)
  end

  local LL, RL = blademaster.getLL(), blademaster.getRL()
  local threshold = blademaster.config.prepThreshold

  cecho("\n<cyan>+============================================+")
  cecho("\n<cyan>|     <white>BLADEMASTER DOUBLE-PREP (LEGS)<cyan>        |")
  cecho("\n<cyan>+============================================+")
  cecho("\n<cyan>| <white>Target: <yellow>" .. tostring(target or "None") .. " <grey>(HP: " .. targetHP .. "%)<cyan>")
  cecho("\n<cyan>| <white>Phase: " .. phaseLabel .. " <grey>| Track: " .. blademaster.getTrackingSystem() .. "<cyan>")
  cecho("\n<cyan>+--------------------------------------------+")
  cecho("\n<cyan>| <white>LEG STATUS:<cyan>")
  cecho("\n<cyan>|   <white>L Leg: " .. (LL >= 100 and "<green>BROKEN " or (LL >= threshold and "<yellow>READY  " or "<red>       ")) .. string.format("%5.1f%%", LL) .. " [" .. progressBar(LL) .. "]")
  cecho("\n<cyan>|   <white>R Leg: " .. (RL >= 100 and "<green>BROKEN " or (RL >= threshold and "<yellow>READY  " or "<red>       ")) .. string.format("%5.1f%%", RL) .. " [" .. progressBar(RL) .. "]")
  cecho("\n<cyan>+--------------------------------------------+")
  cecho("\n<cyan>| <white>STRATEGY:<cyan>")
  cecho("\n<cyan>|   <grey>1. LEG PREP: Legslash alternating (Lightning)")
  cecho("\n<cyan>|   <grey>2. LEG BREAK: Double-break legs + KNEES (Ice)")
  cecho("\n<cyan>|   <grey>3. MANGLE: Legslash right + STERNUM (Ice)")
  cecho("\n<cyan>+============================================+\n")
end

function blademaster.dispatch.statusQuadPrep()
  tAffs = tAffs or {}
  ataxiaTemp = ataxiaTemp or {}

  local phase = blademaster.getPhaseQuadPrep()
  local phaseLabel = blademaster.getPhaseLabelQuadPrep()
  local targetHP = tonumber(ataxiaTemp.targetHP) or 100

  local function progressBar(pct, width)
    width = width or 10
    local filled = math.floor((pct / 100) * width)
    if filled > width then filled = width end
    local empty = width - filled
    return string.rep("#", filled) .. string.rep("-", empty)
  end

  local LA, RA = blademaster.getLA(), blademaster.getRA()
  local LL, RL = blademaster.getLL(), blademaster.getRL()
  local threshold = blademaster.config.prepThreshold

  cecho("\n<cyan>+============================================+")
  cecho("\n<cyan>|     <white>BLADEMASTER QUAD-PREP (ARMS+LEGS)<cyan>     |")
  cecho("\n<cyan>+============================================+")
  cecho("\n<cyan>| <white>Target: <yellow>" .. tostring(target or "None") .. " <grey>(HP: " .. targetHP .. "%)<cyan>")
  cecho("\n<cyan>| <white>Phase: " .. phaseLabel .. " <grey>| Track: " .. blademaster.getTrackingSystem() .. "<cyan>")
  cecho("\n<cyan>+--------------------------------------------+")
  cecho("\n<cyan>| <white>ARM STATUS:<cyan>")
  cecho("\n<cyan>|   <white>L Arm: " .. (LA >= 100 and "<green>BROKEN " or (LA >= threshold and "<yellow>READY  " or "<red>       ")) .. string.format("%5.1f%%", LA) .. " [" .. progressBar(LA) .. "]")
  cecho("\n<cyan>|   <white>R Arm: " .. (RA >= 100 and "<green>BROKEN " or (RA >= threshold and "<yellow>READY  " or "<red>       ")) .. string.format("%5.1f%%", RA) .. " [" .. progressBar(RA) .. "]")
  cecho("\n<cyan>+--------------------------------------------+")
  cecho("\n<cyan>| <white>LEG STATUS:<cyan>")
  cecho("\n<cyan>|   <white>L Leg: " .. (LL >= 100 and "<green>BROKEN " or (LL >= threshold and "<yellow>READY  " or "<red>       ")) .. string.format("%5.1f%%", LL) .. " [" .. progressBar(LL) .. "]")
  cecho("\n<cyan>|   <white>R Leg: " .. (RL >= 100 and "<green>BROKEN " or (RL >= threshold and "<yellow>READY  " or "<red>       ")) .. string.format("%5.1f%%", RL) .. " [" .. progressBar(RL) .. "]")
  cecho("\n<cyan>+--------------------------------------------+")
  cecho("\n<cyan>| <white>STRATEGY:<cyan>")
  cecho("\n<cyan>|   <grey>1. ARM PREP: Armslash alternating (Lightning)")
  cecho("\n<cyan>|   <grey>2. LEG PREP: Legslash alternating (Lightning)")
  cecho("\n<cyan>|   <grey>3. ARM BREAK: Double-break arms (Ice)")
  cecho("\n<cyan>|   <grey>4. LEG BREAK: Double-break legs + KNEES (Ice)")
  cecho("\n<cyan>|   <grey>5. MANGLE: Legslash right + STERNUM (Ice)")
  cecho("\n<cyan>+============================================+\n")
end

-- Status aliases
function bmstatus()
  blademaster.dispatch.statusDoublePrep()
end

function bmstatusq()
  blademaster.dispatch.statusQuadPrep()
end

--------------------------------------------------------------------------------
-- PRONE TIMER (Double-Prep balanceslash mechanic)
--------------------------------------------------------------------------------

function blademaster.resetProneTimer()
  blademaster.state.proneTimerStart = nil
  blademaster.state.proneAttackCount = 0
  blademaster.state.proneTimerActive = false
end

function blademaster.onLegSalveDetected()
  -- Only start timer if both legs broken AND target is prone
  if not blademaster.checkBothLegsBroken() then return end
  if not blademaster.hasAff("prone") then return end

  -- Only start if not already active
  if not blademaster.state.proneTimerActive then
    blademaster.state.proneTimerStart = os.time()
    blademaster.state.proneAttackCount = 0
    blademaster.state.proneTimerActive = true
    cecho("\n<magenta>[BM] Prone timer started - 9 second window, switching to BALANCESLASH on attack #4")
  end
end

--------------------------------------------------------------------------------
-- DAMAGE TRACKING
--------------------------------------------------------------------------------

blademaster.damageCapture = {
  pendingPrimary = nil,
  pendingLimb = nil,
  pendingType = nil,
  lastCaptureTime = 0,
}

function blademaster.onHamstringApplied()
  blademaster.state.lastHamstringTime = os.time()
end

function blademaster.captureLegDamage(damage, side)
  damage = tonumber(damage) or 0
  local now = os.time()

  if blademaster.damageCapture.pendingPrimary and
     blademaster.damageCapture.pendingType == "leg" and
     (now - blademaster.damageCapture.lastCaptureTime) < 2 then
    blademaster.state.legSecondaryDamage = damage
    blademaster.state.legPrimaryDamage = blademaster.damageCapture.pendingPrimary
    blademaster.state.lastPrimaryLeg = blademaster.damageCapture.pendingLimb
    blademaster.damageCapture.pendingPrimary = nil
    blademaster.damageCapture.pendingLimb = nil
    blademaster.damageCapture.pendingType = nil
  else
    blademaster.damageCapture.pendingPrimary = damage
    blademaster.damageCapture.pendingLimb = side
    blademaster.damageCapture.pendingType = "leg"
    blademaster.damageCapture.lastCaptureTime = now
  end
end

function blademaster.captureArmDamage(damage, side)
  damage = tonumber(damage) or 0
  local now = os.time()

  if blademaster.damageCapture.pendingPrimary and
     blademaster.damageCapture.pendingType == "arm" and
     (now - blademaster.damageCapture.lastCaptureTime) < 2 then
    blademaster.state.armSecondaryDamage = damage
    blademaster.state.armPrimaryDamage = blademaster.damageCapture.pendingPrimary
    blademaster.state.lastPrimaryArm = blademaster.damageCapture.pendingLimb
    blademaster.damageCapture.pendingPrimary = nil
    blademaster.damageCapture.pendingLimb = nil
    blademaster.damageCapture.pendingType = nil
  else
    blademaster.damageCapture.pendingPrimary = damage
    blademaster.damageCapture.pendingLimb = side
    blademaster.damageCapture.pendingType = "arm"
    blademaster.damageCapture.lastCaptureTime = now
  end
end

function blademaster.captureUpperDamage(damage, limb)
  -- Centreslash hits torso and head with DIFFERENT damage values
  -- Torso gets more damage (primary), head gets less (secondary)
  damage = tonumber(damage) or 0
  if limb == "torso" then
    blademaster.state.torsoDamage = damage
  elseif limb == "head" then
    blademaster.state.headDamage = damage
  end
end

-- Brokenstar trigger callbacks
function blademaster.onImpaleSuccess()
  -- ALWAYS set isImpaled = true when we impale (first, re-impale, any impale)
  local wasImpaled = blademaster.state.isImpaled
  blademaster.state.isImpaled = true

  -- Track if this is a re-impale (impaleslash already done = skip to bladetwist)
  if blademaster.state.impaleslashDone then
    cecho("\n<green>[BM] RE-IMPALE confirmed! Continuing bladetwists...")
  elseif not wasImpaled then
    cecho("\n<cyan>[BM] First impale confirmed!")
  end
end

function blademaster.onImpaleslashSuccess()
  blademaster.state.impaleslashDone = true
  blademaster.state.bladetwistCount = 0  -- Reset count for new bladetwist cycle
  cecho("\n<magenta>[BM] Impaleslash confirmed - arteries slashed!")
end

function blademaster.onBleedingReady()
  blademaster.state.bleedingReady = true
  cecho("\n<green>[BM] BLEEDING AT 700+ - BROKENSTAR READY!")
end

function blademaster.onBleedingUpdate(bleedValue)
  bleedValue = tonumber(bleedValue) or 0
  blademaster.state.targetBleeding = bleedValue
  -- Also set bleedingReady if we hit 700+
  if bleedValue >= 700 then
    blademaster.state.bleedingReady = true
  end
end

function blademaster.onTargetUnimpaled()
  -- Target escaped impale - need to re-impale before bladetwist
  -- If prone: FREE RE-IMPALE - they can't dodge while prone (regardless of leg status!)
  -- If standing + legs broken: Can re-impale
  -- If standing + legs healed: Back to leg prep

  blademaster.state.isImpaled = false
  blademaster.state.withdrawDone = false
  -- Keep bleedingReady and targetBleeding - we built that progress!
  -- Keep impaleslashDone = true so we skip impaleslash after re-impale

  local targetProne = blademaster.hasAff("prone")
  local legsBroken = blademaster.checkBothLegsBroken()

  -- Can re-impale if prone OR both legs broken
  if targetProne then
    cecho("\n<green>[BM] Target writhed free but STILL PRONE - FREE RE-IMPALE!")
    -- Phase will go to impale (canImpale = prone)
  elseif legsBroken then
    cecho("\n<red>[BM] Target writhed free and standing - RE-IMPALE! (legs still broken)")
    -- Phase will go to impale (canImpale = legsBroken)
  else
    cecho("\n<red>[BM] Target writhed free and standing - back to leg prep")
    -- Reset bleeding and impaleslash since we have to restart completely
    blademaster.state.impaleslashDone = false
    blademaster.state.bleedingReady = false
    blademaster.state.targetBleeding = 0
  end
end

function blademaster.onWithdrawSuccess()
  blademaster.state.withdrawDone = true
  blademaster.state.isImpaled = false  -- No longer impaled after withdraw
  cecho("\n<yellow>[BM] Blade withdrawn - BROKENSTAR READY!")
end

function blademaster.onBladetwistSuccess()
  -- Increment count only when bladetwist actually fires (not on button spam)
  blademaster.state.bladetwistCount = blademaster.state.bladetwistCount + 1
end

function blademaster.onTargetStandUp(who)
  -- Only care if it's our target and we were in brokenstar route
  if who == target and blademaster.state.impaleslashDone then
    local bleedColor = blademaster.state.targetBleeding >= 700 and "<green>" or "<yellow>"
    cecho("\n<yellow>[BM] Target stood up! Bleed: " .. bleedColor .. blademaster.state.targetBleeding .. "<yellow> | Twists: " .. blademaster.state.bladetwistCount)
  end
end

function blademaster.registerDamageTriggers()
  if tempRegexTrigger then
    -- Kill existing triggers
    if blademaster.legDamageTriggerID then
      killTrigger(blademaster.legDamageTriggerID)
    end
    if blademaster.armDamageTriggerID then
      killTrigger(blademaster.armDamageTriggerID)
    end
    if blademaster.upperDamageTriggerID then
      killTrigger(blademaster.upperDamageTriggerID)
    end
    if blademaster.legSalveTriggerID then
      killTrigger(blademaster.legSalveTriggerID)
    end
    if blademaster.impaleTriggerID then
      killTrigger(blademaster.impaleTriggerID)
    end
    if blademaster.impaleslashTriggerID then
      killTrigger(blademaster.impaleslashTriggerID)
    end
    if blademaster.bleedingReadyTriggerID then
      killTrigger(blademaster.bleedingReadyTriggerID)
    end
    if blademaster.withdrawTriggerID then
      killTrigger(blademaster.withdrawTriggerID)
    end
    if blademaster.writheTriggerID then
      killTrigger(blademaster.writheTriggerID)
    end
    if blademaster.bleedingUpdateTriggerID then
      killTrigger(blademaster.bleedingUpdateTriggerID)
    end
    if blademaster.standUpTriggerID then
      killTrigger(blademaster.standUpTriggerID)
    end
    if blademaster.bladetwistTriggerID then
      killTrigger(blademaster.bladetwistTriggerID)
    end

    -- Leg damage trigger
    blademaster.legDamageTriggerID = tempRegexTrigger(
      "^As you carve into .+, you perceive that you have dealt (\\d+\\.?\\d*)% damage to \\w+ (left|right) leg",
      function()
        blademaster.captureLegDamage(matches[2], matches[3])
      end
    )

    -- Arm damage trigger
    blademaster.armDamageTriggerID = tempRegexTrigger(
      "^As you carve into .+, you perceive that you have dealt (\\d+\\.?\\d*)% damage to \\w+ (left|right) arm",
      function()
        blademaster.captureArmDamage(matches[2], matches[3])
      end
    )

    -- Upper body damage trigger (torso/head from centreslash up)
    blademaster.upperDamageTriggerID = tempRegexTrigger(
      "^As you carve into .+, you perceive that you have dealt (\\d+\\.?\\d*)% damage to \\w+ (torso|head)",
      function()
        blademaster.captureUpperDamage(matches[2], matches[3])
      end
    )

    -- Leg salve trigger (starts prone timer for balanceslash mechanic)
    -- Pattern matches: "takes some salve from a vial and rubs it on his/her/faes/its legs"
    blademaster.legSalveTriggerID = tempRegexTrigger(
      "takes some salve from a vial and rubs it on \\w+ legs",
      function()
        blademaster.onLegSalveDetected()
      end
    )

    -- Brokenstar triggers
    -- Impale success: "You draw your blade back and plunge it deep into the body of <target> impaling <pronoun> to the hilt."
    blademaster.impaleTriggerID = tempRegexTrigger(
      "^You draw your blade back and plunge it deep into the body of ([\\w'\\-]+) impaling [\\w'\\-]+ to the hilt\\.$",
      function()
        blademaster.onImpaleSuccess()
      end
    )

    -- Impaleslash success: "steady in your grip, you drag its razor edge across arteries within <target>'s abdomen"
    blademaster.impaleslashTriggerID = tempRegexTrigger(
      "steady in your grip, you drag its razor edge across arteries within ([\\w'\\-]+)'s abdomen\\.$",
      function()
        blademaster.onImpaleslashSuccess()
      end
    )

    -- Bleeding ready (700+): "You observe heavy torrents of lifeblood spilling from <target>'s near-fatal wounds."
    blademaster.bleedingReadyTriggerID = tempRegexTrigger(
      "^You observe heavy torrents of lifeblood spilling from ([\\w'\\-]+)'s near-fatal wounds\\.$",
      function()
        blademaster.onBleedingReady()
      end
    )

    -- Withdraw success: Need a pattern for when blade is withdrawn
    -- TODO: Add the correct withdraw pattern when known
    blademaster.withdrawTriggerID = tempRegexTrigger(
      "^You wrench your blade free of ([\\w'\\-]+)",
      function()
        blademaster.onWithdrawSuccess()
      end
    )

    -- Writhe escape: "manages to writhe faenself free of the weapon which impaled faen"
    blademaster.writheTriggerID = tempRegexTrigger(
      "manages to writhe \\w+self free of the weapon which impaled",
      function()
        blademaster.onTargetUnimpaled()
      end
    )

    -- Bleeding update: "You observe ... [280]" - captures actual bleeding value
    -- Patterns: "sluggish bleeding" [<400], "rivers of blood" [400-699], "heavy torrents" [700-899], "shortly bleed to death" [900+]
    blademaster.bleedingUpdateTriggerID = tempRegexTrigger(
      "You observe .+ \\[(\\d+)\\]",
      function()
        blademaster.onBleedingUpdate(matches[2])
      end
    )

    -- Target stands up: "Mystor stands up." - discern to check bleeding
    blademaster.standUpTriggerID = tempRegexTrigger(
      "^([\\w]+) stands up\\.$",
      function()
        blademaster.onTargetStandUp(matches[2])
      end
    )

    -- Bladetwist success: Increment count when bladetwist actually fires
    -- Pattern: "[|] [|] [|] BLADETWIST [|] BLADETWIST [|] BLADETWIST [|] [|] [|]"
    blademaster.bladetwistTriggerID = tempRegexTrigger(
      "BLADETWIST \\[\\|\\] BLADETWIST \\[\\|\\] BLADETWIST",
      function()
        blademaster.onBladetwistSuccess()
      end
    )

    cecho("\n<green>[BM] Triggers registered (leg/arm/upper damage + leg salve + brokenstar + writhe + bleeding + standUp + bladetwist)!")
  else
    cecho("\n<yellow>[BM] tempRegexTrigger not available - create triggers manually")
  end
end

blademaster.registerDamageTriggers()
