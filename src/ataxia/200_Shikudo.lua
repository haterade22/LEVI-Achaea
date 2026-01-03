-- Shikudo Dispatch Kill Logic System
-- Focused on: Rain prep → Gaital kill → DISPATCH
-- Kill requires: Prone + Broken leg + Broken head + Windpipe damage (needle)

shikudo = shikudo or {}
shikudo.state = {
  phase = "PREP",  -- PREP, PRONE, KILL
}

--------------------------------------------------------------------------------
-- CONFIG VALUES (can be adjusted)
--------------------------------------------------------------------------------

shikudo.config = {
  breakThreshold = 100,   -- Limb damage % for broken
  prepThreshold = 90,     -- Limb damage % for prepped
  kaiSurgeCost = 31,      -- Kai energy needed for KAI SURGE
  kuroDamage = 12.0,      -- Estimated damage per KURO hit (adjust based on stats)
}

--------------------------------------------------------------------------------
-- HELPER FUNCTIONS (ported from Blademaster improvements)
--------------------------------------------------------------------------------

function shikudo.getKai()
  -- Kai energy is stored in ataxia.vitals.class for Monk
  return ataxia.vitals.class or 0
end

function shikudo.canKaiSurge()
  return shikudo.getKai() >= shikudo.config.kaiSurgeCost
end

function shikudo.checkWillBreakBothLegs()
  -- Predict if next KURO will break both legs (like BM's checkWillPrepBothLegs)
  local threshold = shikudo.config.breakThreshold
  local damage = shikudo.config.kuroDamage
  local ll = tLimbs.LL or 0
  local rl = tLimbs.RL or 0

  -- If both legs already broken, return false
  if ll >= threshold and rl >= threshold then return false end

  -- Check if next hit will put both over 100%
  local llAfter = ll + damage
  local rlAfter = rl + damage

  return (llAfter >= threshold and rlAfter >= threshold)
end

function shikudo.getPhase()
  -- Dynamic phase detection based on combat state
  local ll = tLimbs.LL or 0
  local rl = tLimbs.RL or 0
  local head = tLimbs.H or 0
  local legBroken = (ll >= 100 or rl >= 100)
  local headBroken = (head >= 100 or tAffs.damagedhead)
  local hasWindpipe = (tAffs.damagedwindpipe or tAffs.crushedthroat)

  -- DISPATCH: All conditions met
  if tAffs.prone and legBroken and headBroken and hasWindpipe then
    return "dispatch"
  end

  -- KILL: Prone with broken leg, working on head/windpipe
  if tAffs.prone and legBroken then
    return "kill"
  end

  -- PRONE: Legs prepped, need to sweep
  if shikudo.checkReadyForProne() and not tAffs.prone then
    return "prone"
  end

  -- PREP: Building leg/head damage
  return "prep"
end

function shikudo.getPhaseLabel()
  local phase = shikudo.getPhase()
  local labels = {
    prep = "<yellow>PREP",
    prone = "<blue>PRONE",
    kill = "<magenta>KILL",
    dispatch = "<green>DISPATCH",
  }
  return labels[phase] or "<grey>Unknown"
end

-- Available attacks per form
shikudo.formAttacks = {
  Tykonos = {
    kicks = {"risingkick"},
    staff = {"thrust", "sweep"}
  },
  Willow = {
    kicks = {"flashheel"},
    staff = {"dart", "hiru", "hiraku", "sweep"}
  },
  Rain = {
    kicks = {"frontkick"},
    staff = {"ruku", "kuro", "hiru"}
  },
  Oak = {
    kicks = {"risingkick"},
    staff = {"livestrike", "nervestrike", "ruku", "kuro"}
  },
  Gaital = {
    kicks = {"spinkick", "flashheel", "dawnkick"},
    staff = {"needle", "sweep", "ruku", "jinzuku", "kuro"}
  },
  Maelstrom = {
    kicks = {"risingkick", "crescent"},
    staff = {"ruku", "livestrike", "jinzuku", "sweep"}
  }
}

-- Form transition paths (from → available destinations)
shikudo.transitions = {
  Tykonos = {"Willow"},
  Willow = {"Rain"},
  Rain = {"Tykonos", "Oak"},
  Oak = {"Willow", "Gaital"},
  Gaital = {"Rain", "Maelstrom"},
  Maelstrom = {"Oak"}
}

-- Max kata per form before stumble
shikudo.maxKata = {
  Tykonos = 12,
  Willow = 12,
  Rain = 24,  -- Double chain!
  Oak = 12,
  Gaital = 12,
  Maelstrom = 12
}

--------------------------------------------------------------------------------
-- KILL CONDITION CHECKS
--------------------------------------------------------------------------------

function shikudo.checkDispatchReady()
  -- All 4 conditions for dispatch
  local prone = tAffs.prone
  local legBroken = (tLimbs.LL >= 100 or tLimbs.RL >= 100)
  local headBroken = (tLimbs.H >= 100 or tAffs.damagedhead)
  local windpipe = (tAffs.damagedwindpipe or tAffs.crushedthroat)

  return prone and legBroken and headBroken and windpipe
end

function shikudo.checkReadyForProne()
  -- BOTH legs prepped (90%+) for sweep
  return (tLimbs.LL >= 90 and tLimbs.RL >= 90)
end

function shikudo.checkLegsPrepped()
  -- Both legs have some damage for sweep effectiveness
  return (tLimbs.LL >= 70 and tLimbs.RL >= 70)
end

function shikudo.checkHeadPrepped()
  -- Head has enough damage to break with needle + spinkick burst
  return (tLimbs.H >= 90)
end

function shikudo.checkReadyForGaital()
  -- Ready to transition to Gaital: BOTH legs 90%+ AND head 90%+
  return shikudo.checkReadyForProne() and shikudo.checkHeadPrepped()
end

--------------------------------------------------------------------------------
-- FORM TRANSITION LOGIC
--------------------------------------------------------------------------------

function shikudo.shouldTransition()
  local kata = ataxia.vitals.kata or 0
  local form = ataxia.vitals.form

  if kata < 5 then
    return nil  -- Need at least 5 kata to transition
  end

  -- In Gaital and ready to kill - stay here
  if form == "Gaital" then
    return nil
  end

  -- PRIORITY 1: Ready for kill phase - go toward Gaital IMMEDIATELY
  -- Need BOTH legs 90%+ AND head 70%+ before transitioning to Gaital
  if shikudo.checkReadyForGaital() then
    if form == "Oak" then
      return "Gaital"
    elseif form == "Rain" then
      return "Oak"  -- Rain → Oak → Gaital
    elseif form == "Willow" then
      return "Rain"  -- Willow → Rain → Oak → Gaital
    elseif form == "Tykonos" then
      return "Willow"  -- Fast path to Gaital
    elseif form == "Maelstrom" then
      return "Oak"  -- Maelstrom → Oak → Gaital
    end
  end

  -- PRIORITY 2: Near kata limit - transition to avoid stumble
  local maxKata = shikudo.maxKata[form] or 12

  -- For non-Rain forms (12 kata max), transition at 9+
  if maxKata == 12 and kata >= 9 then
    if form == "Oak" then
      return "Willow"  -- Oak → Willow → Rain for more prep
    elseif form == "Willow" then
      return "Rain"  -- Willow → Rain (24 kata!)
    elseif form == "Tykonos" then
      return "Willow"  -- Tykonos → Willow → Rain
    elseif form == "Maelstrom" then
      return "Oak"  -- Maelstrom → Oak → Willow → Rain
    end
  end

  -- For Rain form (24 kata max), transition at 21+
  if form == "Rain" and kata >= 21 then
    -- Legs not ready, need more prep time - go to Tykonos to reset kata
    return "Tykonos"
  end

  return nil
end

function shikudo.getPathToGaital(currentForm)
  -- Returns next form to transition to on path to Gaital
  local paths = {
    Tykonos = "Willow",
    Willow = "Rain",
    Rain = "Oak",
    Oak = "Gaital",
    Gaital = nil,  -- Already there
    Maelstrom = "Oak"
  }
  return paths[currentForm]
end

--------------------------------------------------------------------------------
-- KICK SELECTION
--------------------------------------------------------------------------------

function shikudo.selectKick()
  local form = ataxia.vitals.form or "Rain"
  local parried = ataxiaTemp.parriedLimb or "none"

  if form == "Rain" then
    -- FRONTKICK targets arms
    if parried ~= "left arm" then
      return "frontkick left"
    else
      return "frontkick right"
    end

  elseif form == "Oak" then
    -- RISINGKICK targets head or torso
    if tAffs.prone then
      return "risingkick head"  -- Stuns if prone
    elseif tLimbs.H < 90 and parried ~= "head" then
      return "risingkick head"
    else
      return "risingkick torso"
    end

  elseif form == "Gaital" then
    -- Kill phase kicks
    if tAffs.prone and (tLimbs.H >= 90 or tAffs.damagedhead) then
      return "spinkick"  -- Massive head damage on prone
    end
    -- FLASHHEEL for leg breaks
    if tLimbs.LL < tLimbs.RL and parried ~= "left leg" then
      return "flashheel left"
    elseif parried ~= "right leg" then
      return "flashheel right"
    else
      return "flashheel left"
    end

  elseif form == "Willow" then
    -- FLASHHEEL for legs
    if tLimbs.LL < tLimbs.RL and parried ~= "left leg" then
      return "flashheel left"
    else
      return "flashheel right"
    end

  elseif form == "Maelstrom" then
    -- CRESCENT if target is prone and low health
    if tAffs.prone and (tonumber(ataxiaTemp.targetHP) or 100) <= 50 then
      return "crescent"
    end
    return "risingkick head"

  else -- Tykonos
    -- RISINGKICK targets head or torso (not legs)
    -- If sweeping and head needs damage, hit head; otherwise torso
    if shikudo.checkReadyForProne() and not tAffs.prone then
      if tLimbs.H < 90 then
        return "risingkick head"  -- Build head damage while proning
      end
    end
    return "risingkick torso"
  end
end

--------------------------------------------------------------------------------
-- STAFF STRIKE SELECTION
--------------------------------------------------------------------------------

function shikudo.selectStaff(slot)
  local form = ataxia.vitals.form or "Rain"
  local parried = ataxiaTemp.parriedLimb or "none"

  -- Slot 1 = primary attack, Slot 2 = secondary attack

  if form == "Rain" then
    return shikudo.selectRainStaff(slot, parried)
  elseif form == "Oak" then
    return shikudo.selectOakStaff(slot, parried)
  elseif form == "Gaital" then
    return shikudo.selectGaitalStaff(slot, parried)
  elseif form == "Willow" then
    return shikudo.selectWillowStaff(slot, parried)
  elseif form == "Maelstrom" then
    return shikudo.selectMaelstromStaff(slot, parried)
  else -- Tykonos
    -- Tykonos has SWEEP available! Use it when FULLY ready (legs + head prepped)
    if shikudo.checkReadyForGaital() and not tAffs.prone then
      if slot == 1 then
        return "sweep"  -- Sweep uses both arm balances
      else
        return nil  -- No second staff attack with sweep
      end
    end

    -- Otherwise: THRUST targets any limb - focus legs first for Dispatch prep
    if slot == 1 then
      if tLimbs.LL < 90 and parried ~= "left leg" then
        return "thrust left leg"
      elseif tLimbs.RL < 90 and parried ~= "right leg" then
        return "thrust right leg"
      elseif tLimbs.H < 70 and parried ~= "head" then
        return "thrust head"
      else
        return "thrust left leg"
      end
    else
      if tLimbs.RL < 90 and parried ~= "right leg" then
        return "thrust right leg"
      elseif tLimbs.LL < 90 and parried ~= "left leg" then
        return "thrust left leg"
      else
        return "thrust head"
      end
    end
  end
end

function shikudo.selectRainStaff(slot, parried)
  -- Rain: KURO (legs), HIRU (head), RUKU (arms/torso)
  -- LIGHT modifier: Use when limbs prepped and need kata to transition

  local kata = ataxia.vitals.kata or 0

  -- If all limbs prepped but we need more kata to transition, use LIGHT
  local needKataForTransition = (shikudo.checkReadyForGaital() and kata < 5)

  if slot == 1 then
    -- Primary: Focus legs first, then head
    if tLimbs.LL < 90 and parried ~= "left leg" then
      return "kuro left"
    elseif tLimbs.RL < 90 and parried ~= "right leg" then
      return "kuro right"
    elseif tLimbs.H < 90 and parried ~= "head" then
      return "hiru"
    elseif needKataForTransition then
      -- Use LIGHT to build kata without messing up limb prep
      return "hiru light"
    else
      return "hiru"
    end
  else
    -- Secondary: Alternate target
    if tLimbs.RL < 90 and parried ~= "right leg" then
      return "kuro right"
    elseif tLimbs.LL < 90 and parried ~= "left leg" then
      return "kuro left"
    elseif tLimbs.H < 90 then
      return "hiru"
    elseif needKataForTransition then
      if not tAffs.slickness then
        return "ruku light torso"
      elseif not tAffs.clumsiness then
        return "ruku light left"
      else
        return "hiru light"
      end
    elseif not tAffs.slickness then
      return "ruku torso"
    elseif not tAffs.clumsiness then
      return "ruku left"
    else
      return "hiru"
    end
  end
end

function shikudo.selectOakStaff(slot, parried)
  -- Oak: KURO (legs), NERVESTRIKE (head), LIVESTRIKE (torso), RUKU
  -- LIGHT modifier: Use when limbs are prepped and we need kata to transition

  local kata = ataxia.vitals.kata or 0

  -- If all limbs prepped but we need more kata to transition, use LIGHT
  local needKataForTransition = (shikudo.checkReadyForGaital() and kata < 5)

  if slot == 1 then
    if tLimbs.LL < 90 and parried ~= "left leg" then
      return "kuro left"
    elseif tLimbs.RL < 90 and parried ~= "right leg" then
      return "kuro right"
    elseif tLimbs.H < 90 and parried ~= "head" then
      return "nervestrike"
    elseif needKataForTransition then
      -- Use LIGHT to build kata without messing up limb prep
      if not tAffs.asthma then
        return "livestrike light"
      else
        return "nervestrike light"
      end
    elseif not tAffs.asthma then
      return "livestrike"
    else
      return "nervestrike"
    end
  else
    if tLimbs.RL < 90 and parried ~= "right leg" then
      return "kuro right"
    elseif tLimbs.LL < 90 and parried ~= "left leg" then
      return "kuro left"
    elseif tLimbs.H < 90 and parried ~= "head" then
      return "nervestrike"
    elseif needKataForTransition then
      if not tAffs.asthma then
        return "livestrike light"
      elseif not tAffs.clumsiness then
        return "ruku light left"
      else
        return "nervestrike light"
      end
    elseif not tAffs.asthma then
      return "livestrike"
    elseif not tAffs.clumsiness and shikudo.checkReadyForProne() then
      return "ruku left"
    else
      return "kuro left"
    end
  end
end

function shikudo.selectGaitalStaff(slot, parried)
  -- Gaital: NEEDLE (head/windpipe), SWEEP (prone), RUKU, FLASHHEEL via kicks
  -- LIGHT modifier: Only use when head broken but still need windpipe

  -- SWEEP CHECK: If ready to prone and not using sweep yet
  if not tAffs.prone and shikudo.checkReadyForProne() then
    if slot == 1 then
      return "sweep"  -- Sweep uses both arm balances, so only one staff attack
    else
      return nil  -- No second staff attack with sweep
    end
  end

  -- If prone, focus on head break + windpipe
  if tAffs.prone then
    local headBroken = (tLimbs.H >= 100 or tAffs.damagedhead)
    local hasWindpipe = (tAffs.damagedwindpipe or tAffs.crushedthroat)

    if slot == 1 then
      if not hasWindpipe then
        -- Need windpipe - use LIGHT only if head already broken
        if headBroken then
          return "needle light"  -- Get windpipe without overkill
        else
          return "needle"  -- Need both head damage and windpipe
        end
      elseif not headBroken then
        return "needle"  -- Still need head damage
      else
        return "needle"  -- Everything done, just keep hitting
      end
    else
      if not headBroken then
        return "needle"
      elseif not hasWindpipe then
        return "needle light"
      else
        return "needle"
      end
    end
  end

  -- Not prone, not ready to sweep - build damage
  if slot == 1 then
    if tLimbs.H < 70 then
      return "needle"
    elseif tLimbs.LL < 90 and parried ~= "left leg" then
      return "kuro left"
    else
      return "needle"
    end
  else
    if tLimbs.RL < 90 and parried ~= "right leg" then
      return "kuro right"
    else
      return "needle"
    end
  end
end

function shikudo.selectWillowStaff(slot, parried)
  -- Willow: DART (fast), HIRU (head), HIRAKU (head)

  if slot == 1 then
    if tLimbs.H < 70 and parried ~= "head" then
      return "hiru"
    else
      return "hiraku"
    end
  else
    if tLimbs.H < 90 then
      return "hiraku"
    else
      return "dart torso"
    end
  end
end

function shikudo.selectMaelstromStaff(slot, parried)
  -- Maelstrom: RUKU, LIVESTRIKE, JINZUKU, SWEEP

  if not tAffs.prone and shikudo.checkReadyForProne() then
    return "sweep"
  end

  if slot == 1 then
    if not tAffs.asthma then
      return "livestrike"
    elseif not tAffs.slickness then
      return "ruku torso"
    else
      return "jinzuku"
    end
  else
    if not tAffs.slickness then
      return "ruku torso"
    elseif not tAffs.addiction then
      return "jinzuku"
    else
      return "livestrike"
    end
  end
end

--------------------------------------------------------------------------------
-- COMBO BUILDER
--------------------------------------------------------------------------------

function shikudo.buildCombo()
  local form = ataxia.vitals.form
  local kick = shikudo.selectKick()
  local staff1 = shikudo.selectStaff(1)
  local staff2 = shikudo.selectStaff(2)

  -- Handle sweep (uses both arm balances, limited combo)
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

function shikudo.dispatch()
  -- Initialize if missing
  ataxia = ataxia or {}
  ataxia.vitals = ataxia.vitals or {}
  ataxia.settings = ataxia.settings or {}
  ataxia.settings.separator = ataxia.settings.separator or ";"
  ataxia.playersHere = ataxia.playersHere or {}
  ataxiaTemp = ataxiaTemp or {}
  tLimbs = tLimbs or {H = 0, T = 0, LL = 0, RL = 0, LA = 0, RA = 0}
  tAffs = tAffs or {}

  -- Phase-based output with Kai energy
  local phase = shikudo.getPhase()
  local phaseLabel = shikudo.getPhaseLabel()
  local kai = shikudo.getKai()
  local kaiColor = shikudo.canKaiSurge() and "<green>" or "<yellow>"

  cecho("\n<cyan>[Shikudo V1] " .. phaseLabel .. " <cyan>| Target: <white>" .. tostring(target))
  cecho(" <cyan>| Form: <white>" .. tostring(ataxia.vitals.form))
  cecho(" <cyan>| Kata: <white>" .. tostring(ataxia.vitals.kata))
  cecho("\n<cyan>[Shikudo V1] Limbs: H=<white>" .. string.format("%.1f%%", tLimbs.H))
  cecho(" <cyan>LL=<white>" .. string.format("%.1f%%", tLimbs.LL))
  cecho(" <cyan>RL=<white>" .. string.format("%.1f%%", tLimbs.RL))
  cecho(" <cyan>| Kai: " .. kaiColor .. kai)
  if shikudo.canKaiSurge() then
    cecho(" <green>KAI SURGE READY")
  end
  if tmounted then
    cecho(" <yellow>| MOUNTED")
  end

  -- Safety check - skip if no target
  if not target or target == "" then
    cecho("\n<red>[Shikudo] No target set! Use: tar <name>")
    return
  end

  -- Skip player check for now during testing (can re-enable later)
  -- if not table.contains(ataxia.playersHere, target) then
  --   cecho("\n<red>[Shikudo] Target not in room")
  --   return
  -- end

  local form = ataxia.vitals.form or "Rain"  -- Default to Rain if not set
  local kata = ataxia.vitals.kata or 0

  -- Handle combatQueue - use empty string if function doesn't exist
  local cmd = ""
  if combatQueue then
    cmd = combatQueue()
  end

  -- KILL CHECK: All conditions met?
  if shikudo.checkDispatchReady() then
    cmd = cmd .. "wield staff489282;dispatch " .. target
    send("queue addclear free " .. cmd)
    cecho("\n<red>*** DISPATCH KILL ***")
    return
  end

  -- SHIELD CHECK
  if tAffs.shield then
    local kick = shikudo.selectKick()
    cmd = cmd .. "wield staff489282;combo " .. target .. " shatter " .. kick
    send("queue addclear free " .. cmd)
    return
  end

  -- BUILD ATTACK
  local attack = shikudo.buildCombo()
  attack = attack:gsub("%$tar", target)

  cmd = cmd .. "wield staff489282;" .. attack

  -- TRANSITION CHECK - add at END of combo for inline transition
  local transition = shikudo.shouldTransition()
  if transition then
    cmd = cmd .. ";transition to the " .. transition .. " form"
    cecho("\n<yellow>[Shikudo] Transitioning to " .. transition .. " after this combo")
  else
    -- Debug: Show why no transition
    local kata = ataxia.vitals.kata or 0
    if shikudo.checkReadyForGaital() and kata >= 5 then
      cecho("\n<red>[Shikudo DEBUG] Ready for Gaital + kata " .. kata .. " but no transition? Form: " .. tostring(form))
    end
  end

  send("queue addclear free " .. cmd)

  -- Debug output
  if ataxia.debug then
    cecho("\n<cyan>[Shikudo] Form: " .. form .. " | Kata: " .. kata)
    cecho("\n<cyan>[Shikudo] H:" .. tLimbs.H .. " LL:" .. tLimbs.LL .. " RL:" .. tLimbs.RL)
    if transition then
      cecho("\n<yellow>[Shikudo] Transitioning to " .. transition)
    end
  end
end

-- Alias for backwards compatibility
function levishikudodispatch()
  shikudo.dispatch()
end

--------------------------------------------------------------------------------
-- STATUS COMMAND
--------------------------------------------------------------------------------

function shikudo.status()
  -- Initialize if missing
  tLimbs = tLimbs or {H = 0, T = 0, LL = 0, RL = 0, LA = 0, RA = 0}
  tAffs = tAffs or {}
  ataxia = ataxia or {}
  ataxia.vitals = ataxia.vitals or {}

  local form = ataxia.vitals.form or "Unknown"
  local kata = ataxia.vitals.kata or 0
  local maxKata = shikudo.maxKata[form] or 12
  local phase = shikudo.getPhase()
  local phaseLabel = shikudo.getPhaseLabel()
  local kai = shikudo.getKai()
  local kaiColor = shikudo.canKaiSurge() and "<green>" or "<yellow>"

  cecho("\n<cyan>╔══════════════════════════════════════════╗")
  cecho("\n<cyan>║         <white>SHIKUDO V1 STATUS<cyan>               ║")
  cecho("\n<cyan>╠══════════════════════════════════════════╣")
  cecho("\n<cyan>║ <white>Phase: " .. phaseLabel .. "<cyan>")
  cecho("\n<cyan>║ <white>Target: <yellow>" .. tostring(target or "None") .. "<cyan>")
  cecho("\n<cyan>║ <white>Form: <green>" .. form .. " <grey>(" .. kata .. "/" .. maxKata .. " kata)<cyan>")
  cecho("\n<cyan>║ <white>Kai: " .. kaiColor .. kai .. (shikudo.canKaiSurge() and " <green>KAI SURGE READY" or "") .. "<cyan>")
  if tmounted then
    cecho("\n<cyan>║ <yellow>*** TARGET IS MOUNTED ***<cyan>")
  end
  cecho("\n<cyan>╠══════════════════════════════════════════╣")
  cecho("\n<cyan>║ <white>LIMB DAMAGE:<cyan>")
  cecho("\n<cyan>║   <white>Head: " .. (tLimbs.H >= 90 and "<green>" or (tLimbs.H >= 70 and "<yellow>" or "<red>")) .. string.format("%.1f%%", tLimbs.H))
  cecho("\n<cyan>║   <white>L Leg: " .. (tLimbs.LL >= 90 and "<green>" or (tLimbs.LL >= 70 and "<yellow>" or "<red>")) .. string.format("%.1f%%", tLimbs.LL))
  cecho("\n<cyan>║   <white>R Leg: " .. (tLimbs.RL >= 90 and "<green>" or (tLimbs.RL >= 70 and "<yellow>" or "<red>")) .. string.format("%.1f%%", tLimbs.RL))
  cecho("\n<cyan>╠══════════════════════════════════════════╣")
  cecho("\n<cyan>║ <white>KILL CONDITIONS:<cyan>")
  cecho("\n<cyan>║   <white>Prone: " .. (tAffs.prone and "<green>YES" or "<red>NO"))
  cecho("\n<cyan>║   <white>Leg Broken: " .. ((tLimbs.LL >= 100 or tLimbs.RL >= 100) and "<green>YES" or "<red>NO"))
  cecho("\n<cyan>║   <white>Head Broken: " .. ((tLimbs.H >= 100 or tAffs.damagedhead) and "<green>YES" or "<red>NO"))
  cecho("\n<cyan>║   <white>Windpipe: " .. ((tAffs.damagedwindpipe or tAffs.crushedthroat) and "<green>YES" or "<red>NO"))
  cecho("\n<cyan>║   <white>DISPATCH READY: " .. (shikudo.checkDispatchReady() and "<green>*** YES ***" or "<red>NO"))
  cecho("\n<cyan>╠══════════════════════════════════════════╣")
  cecho("\n<cyan>║ <white>PREP STATUS:<cyan>")
  cecho("\n<cyan>║   <white>Both Legs Ready (90%+): " .. (shikudo.checkReadyForProne() and "<green>YES" or "<yellow>NO"))
  cecho("\n<cyan>║   <white>Head Ready (90%+): " .. (shikudo.checkHeadPrepped() and "<green>YES" or "<yellow>NO"))
  cecho("\n<cyan>║   <white>READY FOR GAITAL: " .. (shikudo.checkReadyForGaital() and "<green>*** YES ***" or "<yellow>NO"))
  cecho("\n<cyan>╚══════════════════════════════════════════╝\n")
end

-- Alias: skstatus
function skstatus()
  shikudo.status()
end
