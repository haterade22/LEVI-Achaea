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

-- Blademaster Double-Prep Dispatch System
-- Kill Route: Lightning prep -> double-break both legs -> Ice damage phase
--
-- KEY MECHANICS:
-- 1. DOUBLE-PREP: Alternate legs to keep both roughly equal until 90%+
-- 2. INFUSE LIGHTNING during prep (clumsy from strikes)
-- 3. AIRFIST when target parries our leg (requires 25 shin: 20 + 5 infuse)
-- 4. When BOTH legs 90%+: legslash + KNEES = double-break + prone
-- 5. INFUSE ICE + STERNUM after both legs broken (max damage)
-- 6. Frozen + broken legs = massive damage output

blademaster = blademaster or {}
blademaster.dispatch = blademaster.dispatch or {}
blademaster.state = {
  focusLeg = nil,         -- "left" or "right"
  lastHamstringTime = 0,  -- Timestamp of last hamstring application
  -- Damage tracking (updated from combat)
  primaryDamage = 17.3,   -- Damage to focused leg (default, updated dynamically)
  secondaryDamage = 11.5, -- Damage to off-leg (default, updated dynamically)
  compassDamage = 14.9,   -- Compassslash damage (single leg)
  lastPrimaryLeg = nil,   -- Which leg received primary damage last hit
}

-- Configuration
blademaster.config = {
  legBreakThreshold = 100,      -- % damage for broken leg
  legPrepThreshold = 90,        -- % damage to consider "prepped" for double-break
  killHealthThreshold = 30,     -- HP% to start kill phase
  -- NOTE: Airfist has NO cooldown, only shin requirement (25 shin)
  hamstringDuration = 10,       -- Seconds hamstring lasts
}

--------------------------------------------------------------------------------
-- LB LIMB TRACKING HELPERS
-- Use lb[target].hits instead of tLimbs for accurate limb damage tracking
--------------------------------------------------------------------------------

function blademaster.getLimbDamage(limb)
  -- limb should be "left leg" or "right leg"
  if not lb or not target then return 0 end
  local t = target:lower():gsub("^%l", string.upper) -- Title case
  if not lb[t] or not lb[t].hits then return 0 end
  return lb[t].hits[limb] or 0
end

function blademaster.getLL()
  return blademaster.getLimbDamage("left leg")
end

function blademaster.getRL()
  return blademaster.getLimbDamage("right leg")
end

-- Callback for when hamstring is applied (call from trigger)
function blademaster.onHamstringApplied()
  blademaster.state.lastHamstringTime = os.time()
end

--------------------------------------------------------------------------------
-- DAMAGE TRACKING (Call from triggers when you see damage)
--------------------------------------------------------------------------------

-- Call this when you see: "you have dealt X% damage to his left/right leg"
-- Example trigger pattern: ^As you carve into .+, you perceive that you have dealt (\d+\.?\d*)% damage to (?:his|her) (left|right) leg
function blademaster.recordLegDamage(damage, leg, isPrimary)
  damage = tonumber(damage) or 0
  if isPrimary then
    blademaster.state.primaryDamage = damage
    blademaster.state.lastPrimaryLeg = leg
  else
    blademaster.state.secondaryDamage = damage
  end
end

-- Convenience function to record both damages from a legslash
-- Call with primary damage first, then secondary
function blademaster.recordLegslashDamage(primaryDmg, primaryLeg, secondaryDmg)
  blademaster.state.primaryDamage = tonumber(primaryDmg) or blademaster.state.primaryDamage
  blademaster.state.secondaryDamage = tonumber(secondaryDmg) or blademaster.state.secondaryDamage
  blademaster.state.lastPrimaryLeg = primaryLeg
end

--------------------------------------------------------------------------------
-- OPTIMAL PATH CALCULATION
--------------------------------------------------------------------------------

function blademaster.calculateOptimalPath()
  -- Calculate the optimal sequence of attacks to get both legs to 90%+
  -- Returns: { attack = "legslash"|"compassslash", direction = "left"|"right",
  --            hitsToDouble = n, explanation = "..." }

  local LL = blademaster.getLL()
  local RL = blademaster.getRL()
  local P = blademaster.state.primaryDamage    -- Primary damage
  local S = blademaster.state.secondaryDamage  -- Secondary damage
  local C = blademaster.state.compassDamage    -- Compassslash damage
  local target = blademaster.config.legPrepThreshold  -- 90%

  -- If both already at 90%+, we're ready
  if LL >= target and RL >= target then
    return {
      attack = "legslash",
      direction = "left",
      hitsToDouble = 0,
      explanation = "Both legs ready for double-break!"
    }
  end

  -- Calculate how many hits needed if we just alternate optimally
  -- Hitting LEFT: LL += P, RL += S
  -- Hitting RIGHT: LL += S, RL += P

  -- Simulate alternating strategy (always hit lower leg)
  local simLL, simRL = LL, RL
  local hits = 0
  local sequence = {}

  while simLL < target or simRL < target do
    hits = hits + 1
    if hits > 20 then break end  -- Safety limit

    if simLL <= simRL then
      -- Hit left (lower)
      simLL = simLL + P
      simRL = simRL + S
      table.insert(sequence, "L")
    else
      -- Hit right (lower)
      simLL = simLL + S
      simRL = simRL + P
      table.insert(sequence, "R")
    end
  end

  -- Check if one leg would break before the other reaches 90%
  -- This happens when the gap is too large
  local highLeg = math.max(LL, RL)
  local lowLeg = math.min(LL, RL)
  local gap = highLeg - lowLeg

  -- Calculate: if we hit the LOW leg, high leg gets +S
  -- Would high leg break (>100) before low leg reaches 90?
  local hitsForLowTo90 = math.ceil((target - lowLeg) / P)
  local highAfterHits = highLeg + (hitsForLowTo90 * S)

  if highAfterHits > 100 and lowLeg < target then
    -- High leg would break early! Need compassslash to balance
    local compassHitsNeeded = math.ceil((target - lowLeg) / C)
    local lowLegDir = (LL < RL) and "left" or "right"

    return {
      attack = "compassslash",
      direction = lowLegDir,
      hitsToDouble = compassHitsNeeded,
      explanation = string.format("Gap too big (%.1f%%). Need %d compassslash %s to catch up",
                                  gap, compassHitsNeeded, lowLegDir)
    }
  end

  -- Normal case: alternate legslash
  local focusDir = (LL <= RL) and "left" or "right"
  return {
    attack = "legslash",
    direction = focusDir,
    hitsToDouble = hits,
    explanation = string.format("%d hits to double-break (sequence: %s)",
                                hits, table.concat(sequence, ""))
  }
end

--------------------------------------------------------------------------------
-- DOUBLE-PREP FOCUS LOGIC
--------------------------------------------------------------------------------

function blademaster.getParried()
  -- Get what the target is parrying - uses tparrying variable
  -- Returns: "left leg", "right leg", "head", "torso", or "none"/false
  local parried = tparrying or ataxiaTemp.parriedLimb or "none"
  if parried == false or parried == "" then
    parried = "none"
  end
  return parried
end

function blademaster.getFocusLeg()
  -- Use optimal path calculation to determine focus leg
  local parried = blademaster.getParried()

  -- If BOTH legs 90%+, either direction breaks both - pick non-parried
  if blademaster.getLL() >= blademaster.config.legPrepThreshold and blademaster.getRL() >= blademaster.config.legPrepThreshold then
    return parried == "left leg" and "right" or "left"
  end

  -- If both legs already broken, focus whichever isn't parried
  if blademaster.getLL() >= 100 and blademaster.getRL() >= 100 then
    return parried == "left leg" and "right" or "left"
  end

  -- Use calculated optimal path
  local path = blademaster.calculateOptimalPath()
  local optimalDir = path.direction

  -- If optimal direction is parried, switch to other leg
  if parried == optimalDir .. " leg" then
    return blademaster.getOtherLeg(optimalDir)
  end

  return optimalDir
end

function blademaster.getOtherLeg(leg)
  return leg == "left" and "right" or "left"
end

function blademaster.getCompassDirection(leg)
  -- Convert leg direction to compass direction for compassslash
  -- SOUTHEAST = left leg
  -- SOUTHWEST = right leg
  if leg == "left" then
    return "southeast"
  elseif leg == "right" then
    return "southwest"
  end
  return leg  -- fallback
end

--------------------------------------------------------------------------------
-- CONDITION CHECKS
--------------------------------------------------------------------------------

function blademaster.checkDoubleBreakReady()
  -- Both legs at 90%+ means next legslash breaks both
  return blademaster.getLL() >= blademaster.config.legPrepThreshold and blademaster.getRL() >= blademaster.config.legPrepThreshold
end

function blademaster.checkBothLegsBroken()
  return blademaster.getLL() >= 100 and blademaster.getRL() >= 100
end

function blademaster.checkLegAboutToBreak()
  -- Check if either leg will break on next hit (for knees priority)
  local LL = blademaster.getLL()
  local RL = blademaster.getRL()
  local P = blademaster.state.primaryDamage
  local S = blademaster.state.secondaryDamage
  local focusLeg = blademaster.getFocusLeg()

  -- If hitting left: LL gets +P, RL gets +S
  -- If hitting right: RL gets +P, LL gets +S
  if focusLeg == "left" then
    return (LL + P >= 100) or (RL + S >= 100)
  else
    return (RL + P >= 100) or (LL + S >= 100)
  end
end

function blademaster.checkKillReady()
  -- Pure damage kill - check if target is low HP and both legs broken
  local targetHP = tonumber(ataxiaTemp.targetHP) or 100
  return targetHP <= blademaster.config.killHealthThreshold and blademaster.checkBothLegsBroken()
end

function blademaster.checkReadyForProne()
  -- BOTH legs need to be broken (100%+) for prone
  return blademaster.checkBothLegsBroken()
end

function blademaster.checkLegPrepped(leg)
  local damage = leg == "left" and blademaster.getLL() or blademaster.getRL()
  return damage >= blademaster.config.legPrepThreshold
end

function blademaster.getPhase()
  -- Determine current combat phase
  if blademaster.checkBothLegsBroken() then
    return "ice"  -- Both legs broken, switch to ice for damage
  else
    return "prep" -- Still prepping legs with lightning
  end
end

--------------------------------------------------------------------------------
-- PARRY HANDLING - REACTIVE AIRFIST
--------------------------------------------------------------------------------

function blademaster.getShin()
  -- Get current shin value from gmcp.Char.Vitals.charstats
  -- Format: { "Bleed: 0", "Rage: 0", "Shin: 16", "Stance: Thyr" }
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

function blademaster.needsAirfist()
  -- Use AIRFIST when target is parrying a leg we want to attack
  -- Requires 20 shin for airfist + 5 shin for infuse = 25 total
  local parried = blademaster.getParried()
  local focusLeg = blademaster.getFocusLeg()
  local focusLegFull = focusLeg .. " leg"

  -- Check shin requirement (20 airfist + 5 infuse = 25 needed)
  -- NOTE: Airfist has NO cooldown, only shin requirement
  local shin = blademaster.getShin()
  local shinNeeded = 25  -- 20 for airfist + 5 for infuse
  if shin < shinNeeded then
    return false, "not enough shin (" .. shin .. "/25)"
  end

  -- Already airfisted - but be less strict, allow re-application
  if tAffs.airfisted then
    return false, "already airfisted"
  end

  -- Check if they're parrying the leg we want to attack
  if parried == focusLegFull then
    return true, "parrying our target leg (" .. parried .. ")"
  end

  -- Also use airfist if they're parrying ANY leg and we keep hitting parry
  if parried == "left leg" or parried == "right leg" then
    return true, "parrying a leg (" .. parried .. ")"
  end

  return false, "not parrying legs (parried: " .. parried .. ")"
end

function blademaster.useAirfist()
  -- Airfist has no cooldown, just shin cost
  return "airfist"
end

--------------------------------------------------------------------------------
-- AFFLICTION SELECTION (Striking)
--------------------------------------------------------------------------------

function blademaster.selectStrike()
  -- Priority order during LIGHTNING prep (lightning infusion gives clumsiness):
  -- 1. AIRFIST if focused leg is parried (reactive) - requires 25 shin (20 + 5 infuse)
  -- 2. STERNUM if in ICE phase (both legs broken) - maximum damage
  -- 3. KNEES when any leg about to break (prone on same hit as break)
  -- 4. HAMSTRING - prevents fleeing, ALWAYS keep up
  -- 5. NECK (paralysis) - lightning already gives clumsy, so strike paralysis
  -- 6. CHEST (hypochondria) - blocks focus curing
  -- 7. SHOULDER (weariness) to block Fitness
  -- 8. EARS (clumsiness) - fallback only

  -- Reactive AIRFIST (only if parrying our leg and we have 25 shin)
  local needsAF, afReason = blademaster.needsAirfist()
  if needsAF then
    return blademaster.useAirfist()
  end

  -- ICE PHASE: Use STERNUM for maximum damage when both legs are broken
  if blademaster.checkBothLegsBroken() then
    return "sternum"
  end

  -- If any leg is about to break, use KNEES to prone on same hit
  if blademaster.checkLegAboutToBreak() and not tAffs.prone then
    return "knees"
  end

  -- Hamstring - prevents fleeing, lasts 10 seconds, use timestamp tracking
  local now = os.time()
  local hamstringExpired = (now - (blademaster.state.lastHamstringTime or 0)) >= blademaster.config.hamstringDuration
  if not tAffs.hamstring or hamstringExpired then
    return "hamstring"
  end

  -- Phase-specific affliction priority
  local phase = blademaster.getPhase()

  if phase == "prep" then
    -- LIGHTNING PREP: Lightning infusion gives clumsiness automatically
    -- So strike for: paralysis > hypochondria > weariness > clumsiness (fallback)
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
  else
    -- ICE PHASE: Apply clumsiness if needed (ice doesn't give it), then others
    if not tAffs.clumsiness then
      return "ears"
    end
    if not tAffs.paralysis then
      return "neck"
    end
    if not tAffs.hypochondria then
      return "chest"
    end
    if not tAffs.weariness then
      return "shoulder"
    end
  end

  -- Default back to paralysis pressure
  return "neck"
end

--------------------------------------------------------------------------------
-- SWORD ATTACK SELECTION
--------------------------------------------------------------------------------

function blademaster.needsCompassslash()
  -- Use calculated optimal path to determine if compassslash is needed
  -- This uses actual damage values from combat instead of hardcoded thresholds

  local path = blademaster.calculateOptimalPath()

  if path.attack == "compassslash" then
    return true, path.direction, path.explanation
  end

  return false, nil, nil
end

function blademaster.shouldSwitchToBody()
  -- Check if we should switch to body attacks (centreslash up = torso/head) instead of legs
  -- This happens when:
  -- 1. Target is parrying a leg
  -- 2. We can't airfist (not enough shin)
  -- 3. The other leg is already prepped (90%+) so hitting it would waste damage

  local parried = blademaster.getParried()

  -- Only relevant if parrying a leg
  if parried ~= "left leg" and parried ~= "right leg" then
    return false, nil
  end

  -- Check if we can airfist
  local canAirfist, _ = blademaster.needsAirfist()
  if canAirfist then
    return false, nil  -- We'll airfist instead
  end

  -- They're parrying a leg and we can't airfist
  -- Check if the OTHER leg is already prepped
  local LL = blademaster.getLL()
  local RL = blademaster.getRL()
  local threshold = blademaster.config.legPrepThreshold

  if parried == "left leg" then
    -- They're parrying left, we'd hit right
    -- If right is already prepped, switch to body
    if RL >= threshold then
      return true, "right leg prepped, switching to body"
    end
  elseif parried == "right leg" then
    -- They're parrying right, we'd hit left
    -- If left is already prepped, switch to body
    if LL >= threshold then
      return true, "left leg prepped, switching to body"
    end
  end

  return false, nil
end

function blademaster.selectSwordAttack()
  local focusLeg = blademaster.getFocusLeg()

  -- Shield handling
  if tAffs.shield then
    return "raze", nil
  end

  -- Rebounding handling
  if tAffs.rebounding then
    return "raze", nil
  end

  -- PARRY BYPASS: If parrying a leg and we can't airfist (no shin) and other leg is prepped
  -- Switch to centreslash up (torso/head) to continue pressure without wasting damage
  local shouldBody, bodyReason = blademaster.shouldSwitchToBody()
  if shouldBody then
    cecho("\n<magenta>*** PARRY BYPASS: " .. bodyReason .. " - using CENTRESLASH UP ***")
    return "centreslash", "up"  -- Hit torso/head instead
  end

  -- After double-break and prone, continue with legslash for mangle
  if tAffs.prone and blademaster.checkReadyForProne() then
    return "legslash", focusLeg
  end

  -- If ready for prone (both legs broken), use BALANCESLASH to knock down
  if blademaster.checkReadyForProne() and not tAffs.prone then
    return "balanceslash", nil
  end

  -- Check if we need compassslash to balance legs
  local needsCompass, compassDir = blademaster.needsCompassslash()
  if needsCompass then
    return "compassslash", compassDir
  end

  -- Focus fire leg (during prep, this alternates to keep both equal)
  return "legslash", focusLeg
end

--------------------------------------------------------------------------------
-- COMBO BUILDER
--------------------------------------------------------------------------------

function blademaster.buildCombo()
  local attack, direction = blademaster.selectSwordAttack()
  local strike = blademaster.selectStrike()

  local combo = ""

  -- INFUSE SELECTION: Lightning during prep, Ice after both legs broken
  if blademaster.checkBothLegsBroken() then
    combo = "infuse ice;"
  else
    combo = "infuse lightning;"
  end

  -- Build attack command
  if attack == "raze" then
    combo = combo .. "raze " .. target
    if strike then
      combo = combo .. " " .. strike
    end
  elseif attack == "balanceslash" then
    combo = combo .. "balanceslash " .. target
    if strike then
      combo = combo .. " " .. strike
    end
  elseif attack == "compassslash" then
    -- Compassslash uses compass directions: southeast = left leg, southwest = right leg
    local compassDir = blademaster.getCompassDirection(direction)
    combo = combo .. "compassslash " .. target .. " " .. compassDir
    if strike then
      combo = combo .. " " .. strike
    end
  elseif attack == "centreslash" then
    -- Centreslash up hits torso/head when bypassing leg parry (no shin for airfist)
    combo = combo .. "centreslash " .. target .. " " .. direction
    if strike then
      combo = combo .. " " .. strike
    end
  elseif attack == "legslash" then
    combo = combo .. "legslash " .. target .. " " .. direction
    if strike then
      combo = combo .. " " .. strike
    end
  elseif attack == "multislash" then
    combo = combo .. "multislash " .. target
    if strike then
      combo = combo .. " " .. strike
    end
  end

  return combo
end

--------------------------------------------------------------------------------
-- MAIN DISPATCH FUNCTION
--------------------------------------------------------------------------------

function blademaster.dispatch.run()
  -- Initialize if missing
  ataxia = ataxia or {}
  ataxia.vitals = ataxia.vitals or {}
  ataxia.settings = ataxia.settings or {}
  ataxiaTemp = ataxiaTemp or {}
  tAffs = tAffs or {}

  -- Safety check
  if not target or target == "" then
    cecho("\n<red>[BM] No target set! Use: tar <name>")
    return
  end

  -- Determine phase
  local phase = blademaster.getPhase()
  local phaseLabel = phase == "ice" and "<blue>Ice" or "<yellow>Lightning"
  local doubleReady = blademaster.checkDoubleBreakReady()

  -- Debug output
  local focusLeg = blademaster.getFocusLeg()
  local targetHP = tonumber(ataxiaTemp.targetHP) or 100
  local path = blademaster.calculateOptimalPath()

  cecho("\n<cyan>[BM " .. phaseLabel .. "<cyan>] Target: " .. tostring(target))
  cecho(" | Focus: " .. focusLeg)
  cecho(" | HP: " .. targetHP .. "%")
  cecho("\n<cyan>[BM " .. phaseLabel .. "<cyan>] LL:" .. string.format("%.1f", blademaster.getLL()) .. "% RL:" .. string.format("%.1f", blademaster.getRL()) .. "%")
  cecho("\n<cyan>[BM " .. phaseLabel .. "<cyan>] Dmg: P=" .. string.format("%.1f", blademaster.state.primaryDamage) .. "% S=" .. string.format("%.1f", blademaster.state.secondaryDamage) .. "%")
  local parried = blademaster.getParried()
  local shin = blademaster.getShin()
  local needsAF, afReason = blademaster.needsAirfist()
  cecho("\n<cyan>[BM " .. phaseLabel .. "<cyan>] Hamstring: " .. (tAffs.hamstring and "YES" or "NO"))
  cecho(" | Clumsy: " .. (tAffs.clumsiness and "YES" or "NO"))
  cecho(" | Frozen: " .. (tAffs.frozen and "YES" or "NO"))
  cecho(" | Parried: " .. parried)
  cecho("\n<cyan>[BM " .. phaseLabel .. "<cyan>] Shin: " .. shin)
  cecho(" | Airfist: " .. (needsAF and "<green>YES" or "<red>NO") .. " <grey>(" .. afReason .. ")")

  if doubleReady and not blademaster.checkBothLegsBroken() then
    cecho("\n<green>*** DOUBLE-BREAK READY - NEXT HIT BREAKS BOTH! ***")
  elseif path.hitsToDouble > 0 then
    cecho("\n<yellow>" .. path.explanation)
  end

  -- Check if compassslash is needed
  local needsCompass, compassDir, compassReason = blademaster.needsCompassslash()
  if needsCompass then
    local compassCardinal = blademaster.getCompassDirection(compassDir)
    cecho("\n<magenta>*** COMPASSSLASH " .. compassCardinal:upper() .. " (" .. compassDir .. " leg): " .. (compassReason or "balancing") .. " ***")
  end

  -- Handle combatQueue if available
  local cmd = ""
  if combatQueue then
    cmd = combatQueue()
  end

  -- KILL PHASE CHECK
  if blademaster.checkKillReady() then
    local strike = blademaster.selectStrike()
    cmd = cmd .. "infuse ice;multislash " .. target
    if strike then
      cmd = cmd .. " " .. strike
    end
    send("queue addclear free " .. cmd)
    cecho("\n<red>*** BM ICE KILL PHASE ***")
    return
  end

  -- BUILD ATTACK
  local attack = blademaster.buildCombo()
  cmd = cmd .. attack

  -- Add assess for limb tracking
  cmd = cmd .. ";assess " .. target

  send("queue addclear free " .. cmd)
end

-- Alias for easy calling
function bmd()
  blademaster.dispatch.run()
end

function bmdispatch()
  blademaster.dispatch.run()
end

--------------------------------------------------------------------------------
-- STATUS DISPLAY
--------------------------------------------------------------------------------

function blademaster.dispatch.status()
  -- Initialize if missing
  tAffs = tAffs or {}
  ataxiaTemp = ataxiaTemp or {}

  local focusLeg = blademaster.getFocusLeg()
  local targetHP = tonumber(ataxiaTemp.targetHP) or 100
  local phase = blademaster.getPhase()
  local doubleReady = blademaster.checkDoubleBreakReady()

  -- Progress bar helper
  local function progressBar(pct, width)
    width = width or 10
    local filled = math.floor((pct / 100) * width)
    if filled > width then filled = width end
    local empty = width - filled
    return string.rep("#", filled) .. string.rep("-", empty)
  end

  cecho("\n<cyan>+============================================+")
  cecho("\n<cyan>|     <white>BLADEMASTER DOUBLE-PREP DISPATCH<cyan>      |")
  cecho("\n<cyan>+============================================+")
  cecho("\n<cyan>| <white>Target: <yellow>" .. tostring(target or "None") .. " <grey>(HP: " .. targetHP .. "%)<cyan>")
  cecho("\n<cyan>| <white>Phase: " .. (phase == "ice" and "<blue>ICE (damage)" or "<yellow>LIGHTNING (prep)") .. "<cyan>")
  cecho("\n<cyan>| <white>Focus Leg: <green>" .. focusLeg .. " <grey>(alternating to keep even)<cyan>")
  cecho("\n<cyan>| <white>Parried: <yellow>" .. blademaster.getParried() .. "<cyan>")
  cecho("\n<cyan>| <white>Damage: <green>P=" .. string.format("%.1f", blademaster.state.primaryDamage) .. "% <yellow>S=" .. string.format("%.1f", blademaster.state.secondaryDamage) .. "% <grey>C=" .. string.format("%.1f", blademaster.state.compassDamage) .. "%<cyan>")
  cecho("\n<cyan>+--------------------------------------------+")
  local LL = blademaster.getLL()
  local RL = blademaster.getRL()
  cecho("\n<cyan>| <white>DOUBLE-PREP STATUS:<cyan>")
  cecho("\n<cyan>|   <white>L Leg: " .. (LL >= 100 and "<green>BROKEN " or (LL >= 90 and "<yellow>READY  " or "<red>       ")) .. string.format("%5.1f%%", LL) .. " [" .. progressBar(LL) .. "]" .. (focusLeg == "left" and " <cyan><-" or ""))
  cecho("\n<cyan>|   <white>R Leg: " .. (RL >= 100 and "<green>BROKEN " or (RL >= 90 and "<yellow>READY  " or "<red>       ")) .. string.format("%5.1f%%", RL) .. " [" .. progressBar(RL) .. "]" .. (focusLeg == "right" and " <cyan><-" or ""))
  cecho("\n<cyan>|   <white>Double-Break: " .. (doubleReady and "<green>*** READY - NEXT HIT BREAKS BOTH! ***" or "<yellow>NO (need both 90%+)"))
  local path = blademaster.calculateOptimalPath()
  if path.hitsToDouble > 0 then
    cecho("\n<cyan>|   <white>Path: <yellow>" .. path.explanation)
  end
  local needsCompass, compassDir, compassReason = blademaster.needsCompassslash()
  if needsCompass then
    local compassCardinal = blademaster.getCompassDirection(compassDir)
    cecho("\n<cyan>|   <magenta>*** COMPASSSLASH " .. compassCardinal:upper() .. " (" .. compassDir .. " leg) ***")
  end
  cecho("\n<cyan>+--------------------------------------------+")
  cecho("\n<cyan>| <white>AFFLICTIONS:<cyan>")
  local hamstringStatus = tAffs.hamstring and (hamstringTimer and "<green>YES" or "<yellow>EXPIRING") or "<red>NO (APPLY!)"
  cecho("\n<cyan>|   <white>Hamstring:  " .. hamstringStatus)
  cecho("\n<cyan>|   <white>Clumsiness: " .. (tAffs.clumsiness and "<green>YES" or "<red>NO (APPLY!)"))
  cecho("\n<cyan>|   <white>Paralysis:  " .. (tAffs.paralysis and "<green>YES" or "<yellow>NO"))
  cecho("\n<cyan>|   <white>Weariness:  " .. (tAffs.weariness and "<green>YES" or "<yellow>NO"))
  cecho("\n<cyan>|   <white>Prone:      " .. (tAffs.prone and "<green>YES" or "<yellow>NO"))
  cecho("\n<cyan>|   <white>Frozen:     " .. (tAffs.frozen and "<blue>YES (ICE BONUS!)" or "<grey>NO"))
  cecho("\n<cyan>|   <white>Airfisted:  " .. (tAffs.airfisted and "<magenta>YES" or "<grey>NO"))
  local shin = blademaster.getShin()
  local needsAF, afReason = blademaster.needsAirfist()
  cecho("\n<cyan>|   <white>Shin:       <yellow>" .. shin .. "<grey> (25 needed for airfist+infuse)")
  cecho("\n<cyan>|   <white>AF Ready:   " .. (needsAF and "<green>YES" or "<red>NO") .. " <grey>(" .. afReason .. ")")
  cecho("\n<cyan>+--------------------------------------------+")
  cecho("\n<cyan>| <white>KILL CONDITIONS:<cyan>")
  cecho("\n<cyan>|   <white>Both Legs Broken: " .. (blademaster.checkBothLegsBroken() and "<green>YES" or "<red>NO"))
  cecho("\n<cyan>|   <white>Target Low HP: " .. (targetHP <= 30 and "<green>YES (" .. targetHP .. "%)" or "<yellow>NO (" .. targetHP .. "%)"))
  cecho("\n<cyan>|   <white>KILL READY: " .. (blademaster.checkKillReady() and "<green>*** YES ***" or "<red>NO"))
  cecho("\n<cyan>+--------------------------------------------+")
  cecho("\n<cyan>| <white>STRATEGY:<cyan>")
  cecho("\n<cyan>|   <grey>1. INFUSE LIGHTNING during prep phase")
  cecho("\n<cyan>|   <grey>2. LEGSLASH alternating (lower leg) to keep ~equal")
  cecho("\n<cyan>|   <grey>3. COMPASSSLASH if gap too big (one leg ahead)")
  cecho("\n<cyan>|   <grey>4. AIRFIST if parrying our leg (needs 25 shin)")
  cecho("\n<cyan>|   <grey>5. When both 90%+: LEGSLASH + KNEES")
  cecho("\n<cyan>|   <grey>   = Double-break + Prone in ONE hit!")
  cecho("\n<cyan>|   <grey>6. Switch to INFUSE ICE + STERNUM after both broken")
  cecho("\n<cyan>|   <grey>7. Continue damage with frozen bonus")
  cecho("\n<cyan>+============================================+\n")
end

-- Alias: bmstatus
function bmstatus()
  blademaster.dispatch.status()
end

--------------------------------------------------------------------------------
-- DAMAGE TRACKING TRIGGER
-- Creates a trigger to capture leg damage from combat
--------------------------------------------------------------------------------

-- State for tracking multi-line damage output
blademaster.damageCapture = {
  pendingPrimary = nil,   -- First damage line (primary)
  pendingLeg = nil,       -- Which leg got primary damage
  lastCaptureTime = 0,    -- Timestamp of last capture
}

-- Call this from a trigger matching:
-- Pattern: ^As you carve into .+, you perceive that you have dealt (\d+\.?\d*)% damage to (?:his|her) (left|right) leg
-- Captures: matches[2] = damage, matches[3] = leg
function blademaster.captureLegDamage(damage, leg)
  damage = tonumber(damage) or 0
  local now = os.time()

  -- If this is within 1 second of last capture, it's the secondary hit
  if blademaster.damageCapture.pendingPrimary and (now - blademaster.damageCapture.lastCaptureTime) < 2 then
    -- This is the secondary damage (off-leg)
    blademaster.state.secondaryDamage = damage
    blademaster.state.primaryDamage = blademaster.damageCapture.pendingPrimary
    blademaster.state.lastPrimaryLeg = blademaster.damageCapture.pendingLeg

    -- Clear pending
    blademaster.damageCapture.pendingPrimary = nil
    blademaster.damageCapture.pendingLeg = nil

    -- Debug output
    -- cecho("\n<grey>[BM Dmg] Updated: P=" .. blademaster.state.primaryDamage .. "% (" .. blademaster.state.lastPrimaryLeg .. ") S=" .. blademaster.state.secondaryDamage .. "%")
  else
    -- This is the first (primary) damage line
    blademaster.damageCapture.pendingPrimary = damage
    blademaster.damageCapture.pendingLeg = leg
    blademaster.damageCapture.lastCaptureTime = now
  end
end

-- Register the trigger if tempRegexTrigger is available (Mudlet)
function blademaster.registerDamageTrigger()
  if tempRegexTrigger then
    -- Kill existing trigger if any
    if blademaster.damageTriggerID then
      killTrigger(blademaster.damageTriggerID)
    end

    -- Create new trigger
    blademaster.damageTriggerID = tempRegexTrigger(
      "^As you carve into .+, you perceive that you have dealt (\\d+\\.?\\d*)% damage to (?:his|her) (left|right) leg",
      function()
        blademaster.captureLegDamage(matches[2], matches[3])
      end
    )
    cecho("\n<green>[BM] Damage tracking trigger registered!")
  else
    cecho("\n<yellow>[BM] tempRegexTrigger not available - create trigger manually")
    cecho("\n<yellow>     Pattern: ^As you carve into .+, you perceive that you have dealt (\\d+\\.?\\d*)% damage to (?:his|her) (left|right) leg")
    cecho("\n<yellow>     Code: blademaster.captureLegDamage(matches[2], matches[3])")
  end
end

-- Also capture compassslash damage (single leg hit)
function blademaster.captureCompassDamage(damage)
  damage = tonumber(damage) or 0
  blademaster.state.compassDamage = damage
end

-- Auto-register trigger on load
blademaster.registerDamageTrigger()
