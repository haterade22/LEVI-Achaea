-- Shikudo V2 Dispatch Kill Logic System
-- Based on Pharaus's approach: Focus fire, clumsy first, SPINKICK burst
-- Kill requires: Prone + Broken leg + Broken head + Windpipe damage (needle)
--
-- KEY SPINKICK MECHANIC:
-- SPINKICK hits torso if standing, HEAD if prone
-- If prone + damaged head (level 2) -> SPINKICK instantly MANGLES head (level 3)!
-- This means we only need to get head to damaged (100%), then SPINKICK = instant mangle
--
-- IMPROVEMENTS (2026-01-03, from Blademaster lessons learned):
-- 1. getKai() / canKaiSurge() - Track Kai energy for KAI SURGE (31 cost)
-- 2. checkWillBreakLeg() - Predict if next hit breaks focus leg
-- 3. getPhase() / getPhaseLabel() - Dynamic phase detection with colored labels
-- 4. Enhanced status display with phase indicator and predictions
-- 5. SWEEP handles mounted targets (dismount + prone in one action)

shikudov2 = shikudov2 or {}
shikudov2.state = {
  phase = "PREP",  -- PREP, PRONE, KILL
  focusLeg = nil,  -- Which leg we're focusing (left or right)
}

-- Config values (can be adjusted)
shikudov2.config = {
  breakThreshold = 100,   -- Limb damage % for broken
  kaiSurgeCost = 31,      -- Kai energy needed for KAI SURGE
  kuroDamage = 12.0,      -- Estimated damage per KURO hit (adjust based on stats)
}

-- Max kata per form before stumble
shikudov2.maxKata = {
  Tykonos = 12,
  Willow = 12,
  Rain = 24,
  Oak = 12,
  Gaital = 12,
  Maelstrom = 12
}

--------------------------------------------------------------------------------
-- HELPER FUNCTIONS (Learned from Blademaster)
--------------------------------------------------------------------------------

function shikudov2.getKai()
  -- Kai energy is stored in ataxia.vitals.class for Monk
  return ataxia.vitals.class or 0
end

function shikudov2.canKaiSurge()
  -- Check if we have enough Kai for KAI SURGE (dismount + prone + prevents remount)
  return shikudov2.getKai() >= shikudov2.config.kaiSurgeCost
end

function shikudov2.checkWillBreakLeg()
  -- Predict if next KURO/FLASHHEEL will break the focus leg
  -- Like Blademaster's checkWillPrepBothLegs() but for single leg break
  local focusLeg = shikudov2.getFocusLeg()
  local legDamage = focusLeg == "left" and tLimbs.LL or tLimbs.RL
  local threshold = shikudov2.config.breakThreshold
  local damage = shikudov2.config.kuroDamage

  -- Already broken = false
  if legDamage >= threshold then
    return false
  end

  -- Will break on next hit?
  return (legDamage + damage >= threshold)
end

function shikudov2.getPhase()
  -- Determine current combat phase based on conditions
  -- Returns: "prep", "prone", "kill", "dispatch"

  local legBroken = (tLimbs.LL >= 100 or tLimbs.RL >= 100)
  local headBroken = (tLimbs.H >= 100 or tAffs.damagedhead)
  local hasWindpipe = (tAffs.damagedwindpipe or tAffs.crushedthroat)

  -- DISPATCH: All conditions met
  if tAffs.prone and legBroken and headBroken and hasWindpipe then
    return "dispatch"
  end

  -- KILL: Prone + leg broken, working on head/windpipe
  if tAffs.prone and legBroken then
    return "kill"
  end

  -- PRONE: Leg broken, need to prone target
  if legBroken and not tAffs.prone then
    return "prone"
  end

  -- PREP: Building leg damage
  return "prep"
end

function shikudov2.getPhaseLabel()
  -- Returns colored phase label for status display (like Blademaster)
  local phase = shikudov2.getPhase()
  local labels = {
    prep = "<yellow>PREP",
    prone = "<blue>PRONE",
    kill = "<magenta>KILL",
    dispatch = "<green>DISPATCH",
  }
  return labels[phase] or "<grey>Unknown"
end

--------------------------------------------------------------------------------
-- KILL CONDITION CHECKS
--------------------------------------------------------------------------------

function shikudov2.checkDispatchReady()
  -- All 4 conditions for dispatch
  local prone = tAffs.prone
  local legBroken = (tLimbs.LL >= 100 or tLimbs.RL >= 100)
  local headBroken = (tLimbs.H >= 100 or tAffs.damagedhead)
  local windpipe = (tAffs.damagedwindpipe or tAffs.crushedthroat)

  return prone and legBroken and headBroken and windpipe
end

function shikudov2.checkReadyForProne()
  -- V2: ONE leg needs to be broken (100%+) for sweep
  -- Different from V1 which required both legs at 90%
  return (tLimbs.LL >= 100 or tLimbs.RL >= 100)
end

function shikudov2.checkHeadPrepped()
  -- V2: Need head at damaged (100%/level 2)
  -- Then SPINKICK on prone will instantly MANGLE it (level 3)!
  -- So we prep head to 100% with NEEDLE, then SPINKICK for instant mangle
  return (tLimbs.H >= 100 or tAffs.damagedhead)
end

function shikudov2.checkReadyForGaital()
  -- Ready when we have ONE leg broken (100%+)
  -- Head prep is minimal - we'll burst it with SPINKICK
  return shikudov2.checkReadyForProne()
end

--------------------------------------------------------------------------------
-- FOCUS FIRE LOGIC
--------------------------------------------------------------------------------

function shikudov2.getFocusLeg()
  -- V2 KEY INSIGHT: Focus fire ONE leg until broken, then switch
  -- Always hit the leg with MORE damage (closer to breaking)
  local parried = ataxiaTemp.parriedLimb or "none"

  -- If one leg is already broken, focus the other
  if tLimbs.LL >= 100 then
    return parried == "right leg" and "left" or "right"
  elseif tLimbs.RL >= 100 then
    return parried == "left leg" and "right" or "left"
  end

  -- Focus the leg with more damage (closer to breaking)
  if tLimbs.LL >= tLimbs.RL then
    return parried == "left leg" and "right" or "left"
  else
    return parried == "right leg" and "left" or "right"
  end
end

function shikudov2.getOtherLeg(leg)
  return leg == "left" and "right" or "left"
end

--------------------------------------------------------------------------------
-- FORM TRANSITION LOGIC
--------------------------------------------------------------------------------

function shikudov2.shouldTransition()
  local kata = ataxia.vitals.kata or 0
  local form = ataxia.vitals.form

  if kata < 5 then
    return nil  -- Need at least 5 kata to transition
  end

  -- Already in kill form - stay here
  if form == "Gaital" then
    return nil
  end

  -- PRIORITY 1: Ready for kill phase - go to Gaital
  -- V2 only needs ONE leg broken (100%+)
  if shikudov2.checkReadyForGaital() then
    if form == "Oak" then
      return "Gaital"
    elseif form == "Rain" then
      return "Oak"  -- Rain -> Oak -> Gaital
    elseif form == "Willow" then
      return "Rain"
    elseif form == "Tykonos" then
      return "Willow"
    elseif form == "Maelstrom" then
      return "Oak"
    end
  end

  -- PRIORITY 2: Get to Oak for clumsy/paralysis/leg prep
  if form ~= "Oak" then
    if form == "Rain" and kata >= 5 then
      return "Oak"
    elseif form == "Willow" and kata >= 5 then
      return "Rain"
    elseif form == "Tykonos" and kata >= 5 then
      return "Willow"
    elseif form == "Maelstrom" and kata >= 5 then
      return "Oak"
    end
  end

  -- PRIORITY 3: Near kata limit - avoid stumble
  local maxKata = shikudov2.maxKata[form] or 12

  if maxKata == 12 and kata >= 9 then
    if form == "Oak" then
      return "Willow"  -- Oak -> Willow -> Rain for more kata
    elseif form == "Willow" then
      return "Rain"  -- Rain has 24 kata!
    elseif form == "Tykonos" then
      return "Willow"
    elseif form == "Maelstrom" then
      return "Oak"
    end
  end

  -- Rain form: 24 kata max, transition at 21+
  if form == "Rain" and kata >= 21 then
    return "Oak"  -- Go to Oak for better attacks
  end

  return nil
end

--------------------------------------------------------------------------------
-- KICK SELECTION
--------------------------------------------------------------------------------

function shikudov2.selectKick()
  local form = ataxia.vitals.form or "Oak"
  local focusLeg = shikudov2.getFocusLeg()

  if form == "Gaital" then
    -- SPINKICK MECHANIC:
    -- If prone + damaged head (level 2/100%+) -> instantly MANGLES head (level 3)!
    -- Only use SPINKICK when prone AND head is already damaged
    local headDamaged = (tLimbs.H >= 100 or tAffs.damagedhead)
    if tAffs.prone and headDamaged then
      return "spinkick"  -- Instant mangle!
    end

    -- FLASHHEEL when sweeping to break leg
    if shikudov2.checkReadyForProne() and not tAffs.prone then
      -- Break the OTHER leg during sweep
      local otherLeg = shikudov2.getOtherLeg(focusLeg)
      return "flashheel " .. otherLeg
    end

    -- DAWNKICK for epilepsy pressure or FLASHHEEL for legs
    if tLimbs[focusLeg == "left" and "LL" or "RL"] < 100 then
      return "flashheel " .. focusLeg
    else
      return "dawnkick"  -- Epilepsy
    end

  elseif form == "Oak" then
    -- RISINGKICK head for some head damage
    return "risingkick head"

  elseif form == "Rain" then
    -- FRONTKICK for arm damage (minor)
    return "frontkick left"

  elseif form == "Willow" then
    -- FLASHHEEL for legs
    return "flashheel " .. focusLeg

  elseif form == "Maelstrom" then
    -- CRESCENT if prone and low health
    if tAffs.prone and (tonumber(ataxiaTemp.targetHP) or 100) <= 50 then
      return "crescent"
    end
    return "risingkick head"

  else -- Tykonos
    return "risingkick torso"
  end
end

--------------------------------------------------------------------------------
-- STAFF STRIKE SELECTION
--------------------------------------------------------------------------------

function shikudov2.selectStaff(slot)
  local form = ataxia.vitals.form or "Oak"

  if form == "Oak" then
    return shikudov2.selectOakStaff(slot)
  elseif form == "Gaital" then
    return shikudov2.selectGaitalStaff(slot)
  elseif form == "Rain" then
    return shikudov2.selectRainStaff(slot)
  elseif form == "Willow" then
    return shikudov2.selectWillowStaff(slot)
  elseif form == "Maelstrom" then
    return shikudov2.selectMaelstromStaff(slot)
  else -- Tykonos
    return shikudov2.selectTykonosStaff(slot)
  end
end

function shikudov2.selectOakStaff(slot)
  -- V2 Oak Priority:
  -- 1. Clumsiness FIRST (ruku left/right)
  -- 2. Paralysis (nervestrike)
  -- 3. Focus fire ONE leg (kuro)

  local focusLeg = shikudov2.getFocusLeg()

  if slot == 1 then
    -- Priority 1: Clumsiness is KING
    if not tAffs.clumsiness then
      return "ruku left"
    end
    -- Priority 2: Paralysis pressure
    if not tAffs.paralysis then
      return "nervestrike"
    end
    -- Priority 3: Focus fire leg
    return "kuro " .. focusLeg
  else
    -- Slot 2: More of the same
    if not tAffs.clumsiness then
      return "ruku right"  -- Double up on clumsy attempts
    end
    -- Focus fire SAME leg
    return "kuro " .. focusLeg
  end
end

function shikudov2.selectGaitalStaff(slot)
  -- V2 Gaital Priority:
  -- 1. SWEEP if ready (one leg broken) and not prone
  -- 2. NEEDLE + focus on getting prone target ready for dispatch
  -- 3. Focus fire legs with KURO

  local focusLeg = shikudov2.getFocusLeg()
  local hasWindpipe = (tAffs.damagedwindpipe or tAffs.crushedthroat)

  -- SWEEP CHECK: If one leg broken and target not prone
  if shikudov2.checkReadyForProne() and not tAffs.prone then
    if slot == 1 then
      return "sweep"  -- Sweep uses both arm balances
    else
      return nil  -- No second staff with sweep
    end
  end

  -- If target is prone, focus on windpipe + head
  if tAffs.prone then
    if slot == 1 then
      -- NEEDLE for windpipe damage
      return "needle"
    else
      -- More NEEDLE or KURO for the other leg
      if not hasWindpipe then
        return "needle"  -- Need windpipe
      else
        -- Break the other leg to keep them down
        local otherLeg = shikudov2.getOtherLeg(focusLeg)
        if tLimbs[otherLeg == "left" and "LL" or "RL"] < 100 then
          return "kuro " .. otherLeg
        else
          return "needle"
        end
      end
    end
  end

  -- Not prone, not ready for sweep - focus fire leg
  if slot == 1 then
    return "kuro " .. focusLeg
  else
    -- Double up on same leg!
    return "kuro " .. focusLeg
  end
end

function shikudov2.selectRainStaff(slot)
  -- Rain: Focus fire legs with KURO
  local focusLeg = shikudov2.getFocusLeg()

  if slot == 1 then
    -- Priority: Clumsy if not present
    if not tAffs.clumsiness then
      return "ruku left"
    end
    return "kuro " .. focusLeg
  else
    -- Double up on same leg
    return "kuro " .. focusLeg
  end
end

function shikudov2.selectWillowStaff(slot)
  -- Willow: Head attacks for transition
  if slot == 1 then
    return "hiru"
  else
    return "hiraku"
  end
end

function shikudov2.selectMaelstromStaff(slot)
  -- Maelstrom: SWEEP if ready, otherwise afflictions
  if shikudov2.checkReadyForProne() and not tAffs.prone then
    if slot == 1 then
      return "sweep"
    else
      return nil
    end
  end

  if slot == 1 then
    if not tAffs.asthma then
      return "livestrike"
    else
      return "ruku torso"
    end
  else
    if not tAffs.addiction then
      return "jinzuku"
    else
      return "livestrike"
    end
  end
end

function shikudov2.selectTykonosStaff(slot)
  -- Tykonos: SWEEP if ready, otherwise THRUST to legs
  local focusLeg = shikudov2.getFocusLeg()

  if shikudov2.checkReadyForProne() and not tAffs.prone then
    if slot == 1 then
      return "sweep"
    else
      return nil
    end
  end

  -- THRUST to focus leg
  return "thrust " .. focusLeg .. " leg"
end

--------------------------------------------------------------------------------
-- COMBO BUILDER
--------------------------------------------------------------------------------

function shikudov2.buildCombo()
  local kick = shikudov2.selectKick()
  local staff1 = shikudov2.selectStaff(1)
  local staff2 = shikudov2.selectStaff(2)

  -- Handle sweep (uses both arm balances)
  if staff1 == "sweep" then
    if kick then
      return "combo $tar sweep " .. kick
    else
      return "combo $tar sweep"
    end
  end

  -- Normal combo: kick + staff1 + staff2
  local combo = "combo $tar"
  if kick then combo = combo .. " " .. kick end
  if staff1 then combo = combo .. " " .. staff1 end
  if staff2 then combo = combo .. " " .. staff2 end

  return combo
end

--------------------------------------------------------------------------------
-- MAIN DISPATCH FUNCTION
--------------------------------------------------------------------------------

function shikudov2.dispatch()
  -- Initialize if missing
  ataxia = ataxia or {}
  ataxia.vitals = ataxia.vitals or {}
  ataxia.settings = ataxia.settings or {}
  ataxia.settings.separator = ataxia.settings.separator or ";"
  ataxia.playersHere = ataxia.playersHere or {}
  ataxiaTemp = ataxiaTemp or {}
  tLimbs = tLimbs or {H = 0, T = 0, LL = 0, RL = 0, LA = 0, RA = 0}
  tAffs = tAffs or {}

  -- Get phase and focus leg
  local phase = shikudov2.getPhase()
  local phaseLabel = shikudov2.getPhaseLabel()
  local focusLeg = shikudov2.getFocusLeg()
  local kai = shikudov2.getKai()

  -- Debug output with phase indicator (like Blademaster)
  cecho("\n<magenta>[V2 " .. phaseLabel .. "<magenta>] Target: " .. tostring(target))
  cecho(" | Form: " .. tostring(ataxia.vitals.form))
  cecho(" | Kata: " .. tostring(ataxia.vitals.kata))
  cecho("\n<magenta>[V2 " .. phaseLabel .. "<magenta>] Focus: " .. focusLeg)
  cecho(" | LL:" .. string.format("%.1f", tLimbs.LL) .. "% RL:" .. string.format("%.1f", tLimbs.RL) .. "%")
  cecho(" | H:" .. string.format("%.1f", tLimbs.H) .. "%")
  cecho(" | Kai:" .. kai)

  -- Phase-specific messages (like Blademaster)
  if phase == "prep" then
    if shikudov2.checkWillBreakLeg() then
      cecho("\n<blue>*** FINAL PREP - Next hit breaks " .. focusLeg .. " leg! ***")
    else
      cecho("\n<yellow>*** PREP - Focus fire " .. focusLeg .. " leg ***")
    end
  elseif phase == "prone" then
    if shikudov2.canKaiSurge() then
      cecho("\n<blue>*** PRONE PHASE - SWEEP ready (or KAI SURGE available: " .. kai .. " Kai) ***")
    else
      cecho("\n<blue>*** PRONE PHASE - SWEEP to prone! ***")
    end
  elseif phase == "kill" then
    local headBroken = (tLimbs.H >= 100 or tAffs.damagedhead)
    local hasWindpipe = (tAffs.damagedwindpipe or tAffs.crushedthroat)
    if not headBroken then
      cecho("\n<magenta>*** KILL PHASE - NEEDLE for head + SPINKICK to mangle! ***")
    elseif not hasWindpipe then
      cecho("\n<magenta>*** KILL PHASE - NEEDLE for windpipe! ***")
    else
      cecho("\n<green>*** DISPATCH READY! ***")
    end
  elseif phase == "dispatch" then
    cecho("\n<green>*** DISPATCH NOW! ***")
  end

  -- Safety check
  if not target or target == "" then
    cecho("\n<red>[V2] No target set! Use: tar <name>")
    return
  end

  local form = ataxia.vitals.form or "Oak"
  local kata = ataxia.vitals.kata or 0

  -- Handle combatQueue
  local cmd = ""
  if combatQueue then
    cmd = combatQueue()
  end

  -- KILL CHECK
  if shikudov2.checkDispatchReady() then
    cmd = cmd .. "wield staff489282;dispatch " .. target
    send("queue addclear free " .. cmd)
    cecho("\n<red>*** V2 DISPATCH KILL ***")
    return
  end

  -- SHIELD CHECK
  if tAffs.shield then
    local kick = shikudov2.selectKick()
    cmd = cmd .. "wield staff489282;combo " .. target .. " shatter " .. kick
    send("queue addclear free " .. cmd)
    return
  end

  -- BUILD ATTACK
  local attack = shikudov2.buildCombo()
  attack = attack:gsub("%$tar", target)

  cmd = cmd .. "wield staff489282;" .. attack

  -- TRANSITION CHECK - add at END of combo
  local transition = shikudov2.shouldTransition()
  if transition then
    cmd = cmd .. ";transition to the " .. transition .. " form"
    cecho("\n<yellow>[V2] Transitioning to " .. transition)
  end

  send("queue addclear free " .. cmd)
end

-- Alias for backwards compatibility
function levishikudov2()
  shikudov2.dispatch()
end

--------------------------------------------------------------------------------
-- STATUS COMMAND
--------------------------------------------------------------------------------

function shikudov2.status()
  -- Initialize if missing
  tLimbs = tLimbs or {H = 0, T = 0, LL = 0, RL = 0, LA = 0, RA = 0}
  tAffs = tAffs or {}
  ataxia = ataxia or {}
  ataxia.vitals = ataxia.vitals or {}

  local form = ataxia.vitals.form or "Unknown"
  local kata = ataxia.vitals.kata or 0
  local maxKata = shikudov2.maxKata[form] or 12
  local focusLeg = shikudov2.getFocusLeg()
  local phase = shikudov2.getPhase()
  local phaseLabel = shikudov2.getPhaseLabel()
  local kai = shikudov2.getKai()

  cecho("\n<magenta>+============================================+")
  cecho("\n<magenta>|         <white>SHIKUDO V2 STATUS<magenta>                 |")
  cecho("\n<magenta>+============================================+")
  cecho("\n<magenta>| <white>Phase: " .. phaseLabel .. "<magenta>")
  cecho("\n<magenta>| <white>Target: <yellow>" .. tostring(target or "None") .. "<magenta>")
  cecho("\n<magenta>| <white>Form: <green>" .. form .. " <grey>(" .. kata .. "/" .. maxKata .. " kata)<magenta>")
  cecho("\n<magenta>| <white>Kai: " .. (kai >= 31 and "<green>" or "<yellow>") .. kai .. " <grey>(31 for KAI SURGE)<magenta>")
  cecho("\n<magenta>| <white>Focus Leg: <cyan>" .. focusLeg .. "<magenta>")
  cecho("\n<magenta>+--------------------------------------------+")
  cecho("\n<magenta>| <white>AFFLICTIONS (V2 Priority):<magenta>")
  cecho("\n<magenta>|   <white>Clumsiness: " .. (tAffs.clumsiness and "<green>YES" or "<red>NO (APPLY FIRST!)"))
  cecho("\n<magenta>|   <white>Paralysis: " .. (tAffs.paralysis and "<green>YES" or "<yellow>NO"))
  cecho("\n<magenta>+--------------------------------------------+")
  cecho("\n<magenta>| <white>LIMB DAMAGE (Focus Fire):<magenta>")

  -- Left leg with prediction
  local llColor = tLimbs.LL >= 100 and "<green>BROKEN " or (tLimbs.LL >= 70 and "<yellow>" or "<red>")
  local llFocus = focusLeg == "left" and " <cyan><--FOCUS" or ""
  local llPredict = ""
  if focusLeg == "left" and shikudov2.checkWillBreakLeg() then
    llPredict = " <blue>(BREAKS NEXT!)"
  end
  cecho("\n<magenta>|   <white>L Leg: " .. llColor .. string.format("%.1f%%", tLimbs.LL) .. llFocus .. llPredict)

  -- Right leg with prediction
  local rlColor = tLimbs.RL >= 100 and "<green>BROKEN " or (tLimbs.RL >= 70 and "<yellow>" or "<red>")
  local rlFocus = focusLeg == "right" and " <cyan><--FOCUS" or ""
  local rlPredict = ""
  if focusLeg == "right" and shikudov2.checkWillBreakLeg() then
    rlPredict = " <blue>(BREAKS NEXT!)"
  end
  cecho("\n<magenta>|   <white>R Leg: " .. rlColor .. string.format("%.1f%%", tLimbs.RL) .. rlFocus .. rlPredict)

  cecho("\n<magenta>|   <white>Head: " .. (tLimbs.H >= 100 and "<green>DAMAGED " or (tLimbs.H >= 70 and "<yellow>" or "<red>")) .. string.format("%.1f%%", tLimbs.H) .. " <grey>(need 100%/damaged)")
  cecho("\n<magenta>+--------------------------------------------+")
  cecho("\n<magenta>| <white>KILL CONDITIONS:<magenta>")
  cecho("\n<magenta>|   <white>Prone: " .. (tAffs.prone and "<green>YES" or "<red>NO") .. (shikudov2.canKaiSurge() and " <grey>(KAI SURGE ready)" or ""))
  cecho("\n<magenta>|   <white>Leg Broken (ONE): " .. ((tLimbs.LL >= 100 or tLimbs.RL >= 100) and "<green>YES" or "<red>NO"))
  cecho("\n<magenta>|   <white>Head Damaged: " .. ((tLimbs.H >= 100 or tAffs.damagedhead) and "<green>YES (SPINKICK -> mangle)" or "<yellow>NO (need 100%)"))
  cecho("\n<magenta>|   <white>Windpipe: " .. ((tAffs.damagedwindpipe or tAffs.crushedthroat) and "<green>YES" or "<red>NO"))
  cecho("\n<magenta>|   <white>DISPATCH READY: " .. (shikudov2.checkDispatchReady() and "<green>*** YES ***" or "<red>NO"))
  cecho("\n<magenta>+--------------------------------------------+")
  cecho("\n<magenta>| <white>V2 STRATEGY:<magenta>")
  cecho("\n<magenta>|   " .. (phase == "prep" and "<cyan>>" or "<grey>") .. " 1. Clumsy FIRST (ruku)")
  cecho("\n<magenta>|   " .. (phase == "prep" and "<cyan>>" or "<grey>") .. " 2. Paralysis (nervestrike)")
  cecho("\n<magenta>|   " .. (phase == "prep" and "<cyan>>" or "<grey>") .. " 3. Focus fire ONE leg to 100%")
  cecho("\n<magenta>|   " .. (phase == "prone" and "<cyan>>" or "<grey>") .. " 4. SWEEP + FLASHHEEL (prone + break)")
  cecho("\n<magenta>|   " .. (phase == "kill" and "<cyan>>" or "<grey>") .. " 5. NEEDLE + SPINKICK (windpipe + mangle)")
  cecho("\n<magenta>|   " .. (phase == "dispatch" and "<cyan>>" or "<grey>") .. " 6. DISPATCH")
  cecho("\n<magenta>+============================================+\n")
end

-- Alias: skv2status
function skv2status()
  shikudov2.status()
end
