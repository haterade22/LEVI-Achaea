-- Blademaster Ice Dispatch System
-- Kill Route: Ice infuse -> frozen -> focus fire legs -> pure damage kill
-- Based on Shikudo V2 architecture
--
-- KEY MECHANICS:
-- 1. Focus fire ONE leg until broken, then switch
-- 2. Reactive AIRFIST - only when focused leg is parried
-- 3. INFUSE ICE on every attack for frozen + bonus damage
-- 4. EARS (clumsiness) first - makes salve applications fail
-- 5. Target can't cure frozen while applying restoration to legs!

blademaster = blademaster or {}
blademaster.dispatch = blademaster.dispatch or {}
blademaster.state = {
  focusLeg = nil,         -- "left" or "right"
  lastAirfist = 0,        -- Timestamp of last airfist usage
}

-- Configuration
blademaster.config = {
  legBreakThreshold = 100,      -- % damage for broken leg
  legPrepThreshold = 70,        -- % damage to consider "prepped"
  killHealthThreshold = 30,     -- HP% to start kill phase
  airfistCooldown = 8,          -- Seconds between airfist uses
}

--------------------------------------------------------------------------------
-- FOCUS FIRE LOGIC (V2 Style)
--------------------------------------------------------------------------------

function blademaster.getFocusLeg()
  -- V2 KEY: Focus fire ONE leg until broken, then switch
  local parried = ataxiaTemp.parriedLimb or "none"

  -- If one leg is already broken, focus the other
  if tLimbs.LL >= 100 then
    return parried == "right leg" and "left" or "right"
  elseif tLimbs.RL >= 100 then
    return parried == "left leg" and "right" or "left"
  end

  -- Focus the leg with MORE damage (closer to breaking)
  if tLimbs.LL >= tLimbs.RL then
    return parried == "left leg" and "right" or "left"
  else
    return parried == "right leg" and "left" or "right"
  end
end

function blademaster.getOtherLeg(leg)
  return leg == "left" and "right" or "left"
end

--------------------------------------------------------------------------------
-- KILL CONDITION CHECKS
--------------------------------------------------------------------------------

function blademaster.checkKillReady()
  -- Pure damage kill - check if target is low HP and we have frozen
  local targetHP = tonumber(ataxiaTemp.targetHP) or 100
  local hasLegBroken = (tLimbs.LL >= 100 or tLimbs.RL >= 100)

  return targetHP <= blademaster.config.killHealthThreshold and hasLegBroken
end

function blademaster.checkReadyForProne()
  -- ONE leg needs to be broken (100%+) for BALANCESLASH knockdown
  return (tLimbs.LL >= 100 or tLimbs.RL >= 100)
end

function blademaster.checkLegPrepped(leg)
  -- Check if leg is near break threshold
  local limbKey = leg == "left" and "LL" or "RL"
  return tLimbs[limbKey] >= blademaster.config.legPrepThreshold
end

function blademaster.isIced()
  -- Check if target has ice-related afflictions
  return tAffs.shivering or tAffs.frozen
end

--------------------------------------------------------------------------------
-- PARRY HANDLING - REACTIVE AIRFIST
--------------------------------------------------------------------------------

function blademaster.needsAirfist()
  -- ONLY use AIRFIST when focused leg is being parried
  local focusLeg = blademaster.getFocusLeg()
  local parried = ataxiaTemp.parriedLimb or "none"
  local focusLegFull = focusLeg .. " leg"

  -- Check cooldown
  local now = os.time()
  if (now - blademaster.state.lastAirfist) < blademaster.config.airfistCooldown then
    return false
  end

  -- Already airfisted
  if tAffs.airfisted then
    return false
  end

  -- Check if parrying our focus leg
  return parried == focusLegFull
end

function blademaster.useAirfist()
  blademaster.state.lastAirfist = os.time()
  return "airfist"
end

--------------------------------------------------------------------------------
-- AFFLICTION SELECTION (Striking)
--------------------------------------------------------------------------------

function blademaster.selectStrike()
  -- Priority order for ice damage route:
  -- 1. AIRFIST if focused leg is parried (reactive)
  -- 2. EARS (clumsiness) - FIRST priority affliction
  -- 3. KNEES (prone) when leg is broken
  -- 4. NECK (paralysis) for pressure
  -- 5. SHOULDER (weariness) to block Fitness

  -- Reactive AIRFIST
  if blademaster.needsAirfist() then
    return blademaster.useAirfist()
  end

  -- Clumsiness FIRST - makes them fail salve applications
  if not tAffs.clumsiness then
    return "ears"
  end

  -- If leg is broken, go for prone
  if blademaster.checkReadyForProne() and not tAffs.prone then
    return "knees"
  end

  -- Paralysis for pressure
  if not tAffs.paralysis then
    return "neck"
  end

  -- Weariness blocks Fitness (passive para cure)
  if not tAffs.weariness then
    return "shoulder"
  end

  -- Default back to clumsiness pressure
  return "ears"
end

--------------------------------------------------------------------------------
-- SWORD ATTACK SELECTION
--------------------------------------------------------------------------------

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

  -- If prone and leg broken, continue leg damage for mangle
  if tAffs.prone and blademaster.checkReadyForProne() then
    return "legslash", focusLeg
  end

  -- If ready for prone (leg broken), use BALANCESLASH to knock down
  if blademaster.checkReadyForProne() and not tAffs.prone then
    return "balanceslash", nil
  end

  -- Focus fire leg
  return "legslash", focusLeg
end

--------------------------------------------------------------------------------
-- COMBO BUILDER
--------------------------------------------------------------------------------

function blademaster.buildCombo()
  local attack, direction = blademaster.selectSwordAttack()
  local strike = blademaster.selectStrike()

  local combo = ""

  -- Add infuse ice
  combo = "infuse ice;"

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
  elseif attack == "legslash" then
    combo = combo .. "legslash " .. target .. " " .. direction
    if strike then
      combo = combo .. " " .. strike
    end
  elseif attack == "multislash" then
    -- Burst damage for kill phase
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
  tLimbs = tLimbs or {H = 0, T = 0, LL = 0, RL = 0, LA = 0, RA = 0}
  tAffs = tAffs or {}

  -- Safety check
  if not target or target == "" then
    cecho("\n<red>[BM Ice] No target set! Use: tar <name>")
    return
  end

  -- Debug output
  local focusLeg = blademaster.getFocusLeg()
  local targetHP = tonumber(ataxiaTemp.targetHP) or 100
  cecho("\n<cyan>[BM Ice] Target: " .. tostring(target))
  cecho(" | Focus: " .. focusLeg)
  cecho(" | HP: " .. targetHP .. "%")
  cecho("\n<cyan>[BM Ice] LL:" .. string.format("%.1f", tLimbs.LL) .. "% RL:" .. string.format("%.1f", tLimbs.RL) .. "%")
  cecho("\n<cyan>[BM Ice] Clumsy: " .. (tAffs.clumsiness and "YES" or "NO"))
  cecho(" | Frozen: " .. (tAffs.frozen and "YES" or "NO"))
  cecho(" | Parried: " .. (ataxiaTemp.parriedLimb or "none"))

  -- Handle combatQueue if available
  local cmd = ""
  if combatQueue then
    cmd = combatQueue()
  end

  -- KILL PHASE CHECK
  if blademaster.checkKillReady() then
    -- Use MULTISLASH for burst damage
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
  tLimbs = tLimbs or {H = 0, T = 0, LL = 0, RL = 0, LA = 0, RA = 0}
  tAffs = tAffs or {}
  ataxiaTemp = ataxiaTemp or {}

  local focusLeg = blademaster.getFocusLeg()
  local targetHP = tonumber(ataxiaTemp.targetHP) or 100

  cecho("\n<cyan>+============================================+")
  cecho("\n<cyan>|       <white>BLADEMASTER ICE DISPATCH<cyan>           |")
  cecho("\n<cyan>+============================================+")
  cecho("\n<cyan>| <white>Target: <yellow>" .. tostring(target or "None") .. " <grey>(HP: " .. targetHP .. "%)<cyan>")
  cecho("\n<cyan>| <white>Focus Leg: <green>" .. focusLeg .. "<cyan>")
  cecho("\n<cyan>| <white>Parried Limb: <yellow>" .. (ataxiaTemp.parriedLimb or "none") .. "<cyan>")
  cecho("\n<cyan>+--------------------------------------------+")
  cecho("\n<cyan>| <white>ICE STATUS:<cyan>")
  cecho("\n<cyan>|   <white>Shivering: " .. (tAffs.shivering and "<blue>YES" or "<grey>NO"))
  cecho("\n<cyan>|   <white>Frozen: " .. (tAffs.frozen and "<blue>YES (BONUS DMG!)" or "<grey>NO"))
  cecho("\n<cyan>+--------------------------------------------+")
  cecho("\n<cyan>| <white>AFFLICTIONS (Priority Order):<cyan>")
  cecho("\n<cyan>|   <white>1. Clumsiness: " .. (tAffs.clumsiness and "<green>YES" or "<red>NO (APPLY FIRST!)"))
  cecho("\n<cyan>|   <white>2. Paralysis: " .. (tAffs.paralysis and "<green>YES" or "<yellow>NO"))
  cecho("\n<cyan>|   <white>3. Weariness: " .. (tAffs.weariness and "<green>YES" or "<yellow>NO"))
  cecho("\n<cyan>|   <white>4. Prone: " .. (tAffs.prone and "<green>YES" or "<yellow>NO"))
  cecho("\n<cyan>|   <white>Airfisted: " .. (tAffs.airfisted and "<magenta>YES" or "<grey>NO"))
  cecho("\n<cyan>+--------------------------------------------+")
  cecho("\n<cyan>| <white>LIMB DAMAGE (Focus Fire):<cyan>")
  cecho("\n<cyan>|   <white>L Leg: " .. (tLimbs.LL >= 100 and "<green>BROKEN " or (tLimbs.LL >= 70 and "<yellow>" or "<red>")) .. string.format("%.1f%%", tLimbs.LL) .. (focusLeg == "left" and " <cyan><--FOCUS" or ""))
  cecho("\n<cyan>|   <white>R Leg: " .. (tLimbs.RL >= 100 and "<green>BROKEN " or (tLimbs.RL >= 70 and "<yellow>" or "<red>")) .. string.format("%.1f%%", tLimbs.RL) .. (focusLeg == "right" and " <cyan><--FOCUS" or ""))
  cecho("\n<cyan>+--------------------------------------------+")
  cecho("\n<cyan>| <white>KILL CONDITIONS:<cyan>")
  cecho("\n<cyan>|   <white>Leg Broken: " .. ((tLimbs.LL >= 100 or tLimbs.RL >= 100) and "<green>YES" or "<red>NO"))
  cecho("\n<cyan>|   <white>Target Low HP: " .. (targetHP <= 30 and "<green>YES (" .. targetHP .. "%)" or "<yellow>NO (" .. targetHP .. "%)"))
  cecho("\n<cyan>|   <white>KILL READY: " .. (blademaster.checkKillReady() and "<green>*** YES ***" or "<red>NO"))
  cecho("\n<cyan>+--------------------------------------------+")
  cecho("\n<cyan>| <white>STRATEGY:<cyan>")
  cecho("\n<cyan>|   <grey>1. INFUSE ICE on every attack")
  cecho("\n<cyan>|   <grey>2. EARS first (clumsiness)")
  cecho("\n<cyan>|   <grey>3. Focus fire ONE leg to 100%")
  cecho("\n<cyan>|   <grey>4. BALANCESLASH + KNEES (prone)")
  cecho("\n<cyan>|   <grey>5. Continue LEGSLASH (mangle attempt)")
  cecho("\n<cyan>|   <grey>6. Pure damage kill while frozen")
  cecho("\n<cyan>|   <grey>Key: They can't cure frozen while healing legs!")
  cecho("\n<cyan>+============================================+\n")
end

-- Alias: bmstatus
function bmstatus()
  blademaster.dispatch.status()
end
