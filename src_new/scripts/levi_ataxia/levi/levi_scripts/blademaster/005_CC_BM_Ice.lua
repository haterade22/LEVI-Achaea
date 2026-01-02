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
-- Two strategies available:
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
  -- Prone timer tracking (Double-Prep mangle phase)
  proneTimerStart = nil,      -- Timestamp when salve detected
  proneAttackCount = 0,       -- Number of attacks since prone started
  proneTimerActive = false,   -- Is the 9-second window active
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
}

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

  if tAffs.airfisted then
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
  if not tAffs.hamstring or hamstringExpired then
    return "hamstring"
  end

  -- Lightning prep: paralysis > hypochondria > weariness > clumsiness
  if not tAffs.paralysis then
    return "neck"
  end
  if not tAffs.hypochondria then
    return "chest"
  end
  if not tAffs.weariness then
    return "shoulder"
  end
  if not tAffs.clumsiness then
    return "ears"
  end

  return "neck"
end

function blademaster.selectIceStrike()
  -- Ice phase: clumsiness first (ice doesn't give it), then others
  if not tAffs.clumsiness then
    return "ears"
  end
  if not tAffs.paralysis then
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
  if tAffs.prone then
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

  -- Airfist check for legs
  local needsAF, _ = blademaster.needsAirfist("leg")
  if needsAF then
    return "airfist"
  end

  -- MANGLE: Always STERNUM
  if phase == "mangle" then
    return "sternum"
  end

  -- LEG BREAK: KNEES for prone
  if phase == "leg_break" then
    return "knees"
  end

  -- LEG PREP: Standard prep strikes
  return blademaster.selectPrepStrike()
end

function blademaster.selectAttackDoublePrep()
  local phase = blademaster.getPhaseDoublePrep()

  if tAffs.shield or tAffs.rebounding then
    return "raze", nil
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
  if phase ~= "mangle" or not tAffs.prone then
    blademaster.resetProneTimer()
  end

  -- Status output
  cecho("\n<cyan>[BM " .. phaseLabel .. "<cyan>] Target: " .. tostring(target) .. " | HP: " .. targetHP .. "%")
  cecho("\n<cyan>[BM " .. phaseLabel .. "<cyan>] Legs: LL=" .. string.format("%.1f", blademaster.getLL()) .. "% RL=" .. string.format("%.1f", blademaster.getRL()) .. "%")
  cecho("\n<cyan>[BM " .. phaseLabel .. "<cyan>] Dmg: P=" .. string.format("%.1f", blademaster.state.legPrimaryDamage) .. "% S=" .. string.format("%.1f", blademaster.state.legSecondaryDamage) .. "%")

  -- Phase-specific messages
  if phase == "leg_prep" then
    local legPath = blademaster.calculateLegPath()
    if blademaster.checkWillPrepBothLegs() then
      cecho("\n<blue>*** FINAL PREP - ICE infuse to strip caloric! ***")
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

  -- Parry info
  local parried = blademaster.getParried()
  local shin = blademaster.getShin()
  local needsAF, _ = blademaster.needsAirfist("leg")
  cecho("\n<cyan>[BM " .. phaseLabel .. "<cyan>] Parried: " .. parried .. " | Shin: " .. shin)
  if needsAF then
    cecho(" | <green>AIRFIST READY")
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
  if tAffs.prone then
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

  -- Airfist check based on phase
  local limbType = (phase == "arm_prep" or phase == "arm_break") and "arm" or "leg"
  local needsAF, _ = blademaster.needsAirfist(limbType)
  if needsAF then
    return "airfist"
  end

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

  if tAffs.shield or tAffs.rebounding then
    return "raze", nil
  end

  if phase == "arm_prep" then
    return "armslash", blademaster.getFocusArm()
  end

  if phase == "leg_prep" then
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
  if phase ~= "mangle" or not tAffs.prone then
    blademaster.resetProneTimer()
  end

  -- Status output
  cecho("\n<cyan>[BMQ " .. phaseLabel .. "<cyan>] Target: " .. tostring(target) .. " | HP: " .. targetHP .. "%")
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

  -- Parry info
  local parried = blademaster.getParried()
  local shin = blademaster.getShin()
  local limbType = (phase == "arm_prep" or phase == "arm_break") and "arm" or "leg"
  local needsAF, _ = blademaster.needsAirfist(limbType)
  cecho("\n<cyan>[BMQ " .. phaseLabel .. "<cyan>] Parried: " .. parried .. " | Shin: " .. shin)
  if needsAF then
    cecho(" | <green>AIRFIST READY")
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
  cecho("\n<cyan>| <white>Phase: " .. phaseLabel .. "<cyan>")
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
  cecho("\n<cyan>| <white>Phase: " .. phaseLabel .. "<cyan>")
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
  if not tAffs.prone then return end

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

function blademaster.registerDamageTriggers()
  if tempRegexTrigger then
    -- Kill existing triggers
    if blademaster.legDamageTriggerID then
      killTrigger(blademaster.legDamageTriggerID)
    end
    if blademaster.armDamageTriggerID then
      killTrigger(blademaster.armDamageTriggerID)
    end
    if blademaster.legSalveTriggerID then
      killTrigger(blademaster.legSalveTriggerID)
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

    -- Leg salve trigger (starts prone timer for balanceslash mechanic)
    -- Pattern matches: "takes some salve from a vial and rubs it on his/her/faes/its legs"
    blademaster.legSalveTriggerID = tempRegexTrigger(
      "takes some salve from a vial and rubs it on \\w+ legs",
      function()
        blademaster.onLegSalveDetected()
      end
    )

    cecho("\n<green>[BM] Triggers registered (damage + leg salve)!")
  else
    cecho("\n<yellow>[BM] tempRegexTrigger not available - create triggers manually")
  end
end

blademaster.registerDamageTriggers()
