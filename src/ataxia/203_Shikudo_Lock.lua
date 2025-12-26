-- Shikudo Lock Offense System
-- Focus: Pure affliction-based locking with Telepathy integration
-- Kill Route: Softlock -> Venomlock -> Hardlock -> Truelock -> Damage Pressure
--
-- Lock Progression:
--   Softlock:   asthma + anorexia + slickness
--   Venomlock:  softlock + paralysis
--   Hardlock:   venomlock + impatience (Telepathy)
--   Truelock:   hardlock + weariness (blocks Fitness)

shikudoLock = shikudoLock or {}
shikudoLock.state = {
  phase = "SOFTLOCK",     -- SOFTLOCK, VENOMLOCK, HARDLOCK, TRUELOCK, KILL
  lastTelepathy = 0,      -- Timestamp of last telepathy use
}

-- Note: Uses global 'mindlocked' variable (set in 099_Login_Function.lua)
-- Triggers should set mindlocked = true when mindlock is established

-- Max kata per form before stumble
shikudoLock.maxKata = {
  Tykonos = 12,
  Willow = 12,
  Rain = 24,
  Oak = 12,
  Gaital = 12,
  Maelstrom = 12
}

--------------------------------------------------------------------------------
-- LOCK CONDITION CHECKS
--------------------------------------------------------------------------------

function shikudoLock.checkSoftlock()
  return tAffs.asthma and tAffs.anorexia and tAffs.slickness
end

function shikudoLock.checkVenomlock()
  return shikudoLock.checkSoftlock() and tAffs.paralysis
end

function shikudoLock.checkHardlock()
  return shikudoLock.checkVenomlock() and tAffs.impatience
end

function shikudoLock.checkTruelock()
  return shikudoLock.checkHardlock() and tAffs.weariness
end

function shikudoLock.updatePhase()
  if shikudoLock.checkTruelock() then
    shikudoLock.state.phase = "KILL"
  elseif shikudoLock.checkHardlock() then
    shikudoLock.state.phase = "TRUELOCK"
  elseif shikudoLock.checkVenomlock() then
    shikudoLock.state.phase = "HARDLOCK"
  elseif shikudoLock.checkSoftlock() then
    shikudoLock.state.phase = "VENOMLOCK"
  else
    shikudoLock.state.phase = "SOFTLOCK"
  end
end

--------------------------------------------------------------------------------
-- FORM HELPERS
--------------------------------------------------------------------------------

function shikudoLock.inForm(...)
  local currentForm = ataxia.vitals.form or "Oak"
  for _, form in ipairs({...}) do
    if currentForm == form then
      return true
    end
  end
  return false
end

function shikudoLock.hasAbility(ability)
  local form = ataxia.vitals.form or "Oak"
  local formAbilities = {
    Tykonos = {"thrust", "sweep", "risingkick"},
    Willow = {"dart", "hiru", "hiraku", "flashheel"},
    Rain = {"kuro", "hiru", "ruku", "frontkick"},
    Oak = {"kuro", "nervestrike", "livestrike", "ruku", "risingkick"},
    Gaital = {"needle", "sweep", "kuro", "ruku", "jinzuku", "spinkick", "flashheel", "dawnkick"},
    Maelstrom = {"ruku", "livestrike", "jinzuku", "sweep", "risingkick", "crescent"}
  }

  local abilities = formAbilities[form] or {}
  for _, a in ipairs(abilities) do
    if a == ability then
      return true
    end
  end
  return false
end

--------------------------------------------------------------------------------
-- FORM TRANSITION LOGIC
--------------------------------------------------------------------------------

function shikudoLock.shouldTransition()
  local form = ataxia.vitals.form or "Oak"
  local kata = ataxia.vitals.kata or 0

  if kata < 5 then
    return nil  -- Need at least 5 kata to transition
  end

  -- PRIORITY 1: Need anorexia? Go to Willow (has Hiraku)
  if not tAffs.anorexia and form ~= "Willow" then
    if form == "Tykonos" then return "Willow" end
    if form == "Rain" then return "Tykonos" end  -- Rain -> Tykonos -> Willow (indirect)
    if form == "Oak" then return "Willow" end
    if form == "Gaital" then return "Rain" end   -- Gaital -> Rain -> Tykonos -> Willow
    if form == "Maelstrom" then return "Oak" end -- Maelstrom -> Oak -> Willow
  end

  -- PRIORITY 2: Have anorexia, need other lock affs? Go to Oak
  if tAffs.anorexia and form ~= "Oak" then
    if form == "Willow" then return "Rain" end   -- Willow -> Rain -> Oak
    if form == "Rain" then return "Oak" end
    if form == "Gaital" then return "Rain" end
    if form == "Maelstrom" then return "Oak" end
  end

  -- PRIORITY 3: In kill phase, stay in high-damage form or go to Gaital for spinkick
  if shikudoLock.state.phase == "KILL" then
    if tAffs.prone and form ~= "Gaital" then
      if form == "Oak" then return "Gaital" end
      if form == "Rain" then return "Oak" end
    end
  end

  -- PRIORITY 4: Near kata limit - avoid stumble
  local maxKata = shikudoLock.maxKata[form] or 12

  if kata >= maxKata - 3 then
    if form == "Oak" then return "Willow" end
    if form == "Willow" then return "Rain" end  -- Rain has 24 kata!
    if form == "Tykonos" then return "Willow" end
    if form == "Gaital" then return "Rain" end
    if form == "Maelstrom" then return "Oak" end
  end

  return nil
end

--------------------------------------------------------------------------------
-- KICK SELECTION
--------------------------------------------------------------------------------

function shikudoLock.selectKick()
  local form = ataxia.vitals.form or "Oak"

  if form == "Gaital" then
    -- SPINKICK on prone = massive head damage
    if tAffs.prone then
      return "spinkick"
    end
    -- FLASHHEEL for leg damage (useful for pressure)
    return "flashheel left"

  elseif form == "Oak" then
    -- RISINGKICK for head damage
    return "risingkick head"

  elseif form == "Willow" then
    -- FLASHHEEL for leg damage
    return "flashheel left"

  elseif form == "Rain" then
    -- FRONTKICK for arm damage
    return "frontkick left"

  elseif form == "Maelstrom" then
    -- CRESCENT for high damage (kill phase)
    if shikudoLock.state.phase == "KILL" then
      return "crescent"
    end
    return "risingkick head"

  else -- Tykonos
    return "risingkick torso"
  end
end

--------------------------------------------------------------------------------
-- STAFF STRIKE SELECTION - AFFLICTION PRIORITY
--------------------------------------------------------------------------------

function shikudoLock.selectStaff(slot)
  local form = ataxia.vitals.form or "Oak"
  local phase = shikudoLock.state.phase

  -- In KILL phase, switch to damage-focused attacks
  if phase == "KILL" then
    return shikudoLock.selectDamageStaff(slot)
  end

  -- Otherwise, prioritize lock afflictions
  if form == "Oak" then
    return shikudoLock.selectOakStaff(slot)
  elseif form == "Willow" then
    return shikudoLock.selectWillowStaff(slot)
  elseif form == "Rain" then
    return shikudoLock.selectRainStaff(slot)
  elseif form == "Gaital" then
    return shikudoLock.selectGaitalStaff(slot)
  elseif form == "Maelstrom" then
    return shikudoLock.selectMaelstromStaff(slot)
  else -- Tykonos
    return shikudoLock.selectTykonosStaff(slot)
  end
end

function shikudoLock.selectOakStaff(slot)
  -- Oak has: livestrike (asthma), nervestrike (paralysis), ruku (slickness/clumsiness), kuro (weariness)
  -- Priority: asthma > slickness > paralysis > weariness > clumsiness

  if slot == 1 then
    -- First slot: prioritize missing lock afflictions
    if not tAffs.asthma then
      return "livestrike"
    elseif not tAffs.slickness then
      return "ruku torso"
    elseif not tAffs.paralysis then
      return "nervestrike"
    elseif not tAffs.weariness then
      return "kuro left"
    else
      return "ruku left"  -- clumsiness for pressure
    end
  else
    -- Second slot: stack or reapply
    if not tAffs.weariness then
      return "kuro right"
    elseif not tAffs.clumsiness then
      return "ruku right"
    elseif not tAffs.asthma then
      return "livestrike"
    else
      return "kuro left"  -- maintain weariness
    end
  end
end

function shikudoLock.selectWillowStaff(slot)
  -- Willow has: hiraku (anorexia+stuttering), hiru (dizziness/confusion), dart
  -- Priority: anorexia (critical for lock)

  if slot == 1 then
    if not tAffs.anorexia then
      return "hiraku"
    else
      return "hiru"  -- dizziness for mental stack
    end
  else
    -- Keep reapplying anorexia
    return "hiraku"
  end
end

function shikudoLock.selectRainStaff(slot)
  -- Rain has: kuro (weariness), hiru (dizziness), ruku (slickness/clumsiness)
  -- Priority: slickness > weariness > clumsiness

  if slot == 1 then
    if not tAffs.slickness then
      return "ruku torso"
    elseif not tAffs.weariness then
      return "kuro left"
    else
      return "ruku left"  -- clumsiness
    end
  else
    if not tAffs.weariness then
      return "kuro right"
    else
      return "hiru"  -- dizziness
    end
  end
end

function shikudoLock.selectGaitalStaff(slot)
  -- Gaital has: needle, sweep, kuro, ruku, jinzuku
  -- Priority: slickness > weariness > addiction

  if slot == 1 then
    if not tAffs.slickness then
      return "ruku torso"
    elseif not tAffs.weariness then
      return "kuro left"
    elseif not tAffs.addiction then
      return "jinzuku"
    else
      return "kuro left"
    end
  else
    if not tAffs.weariness then
      return "kuro right"
    elseif not tAffs.clumsiness then
      return "ruku right"
    else
      return "jinzuku"
    end
  end
end

function shikudoLock.selectMaelstromStaff(slot)
  -- Maelstrom has: ruku, livestrike, jinzuku, sweep
  -- Priority: asthma > slickness > addiction

  if slot == 1 then
    if not tAffs.asthma then
      return "livestrike"
    elseif not tAffs.slickness then
      return "ruku torso"
    elseif not tAffs.addiction then
      return "jinzuku"
    else
      return "livestrike"
    end
  else
    if not tAffs.slickness then
      return "ruku torso"
    else
      return "jinzuku"
    end
  end
end

function shikudoLock.selectTykonosStaff(slot)
  -- Tykonos has: thrust, sweep (limited options)
  return "thrust left leg"
end

--------------------------------------------------------------------------------
-- DAMAGE STAFF SELECTION (KILL PHASE)
--------------------------------------------------------------------------------

function shikudoLock.selectDamageStaff(slot)
  local form = ataxia.vitals.form or "Oak"

  if form == "Oak" then
    -- Livestrike + Nervestrike = high damage
    return slot == 1 and "livestrike" or "nervestrike"
  elseif form == "Gaital" then
    -- Needle for throat damage (bonus: can setup Dispatch)
    return slot == 1 and "needle" or "kuro left"
  elseif form == "Maelstrom" then
    return slot == 1 and "livestrike" or "jinzuku"
  elseif form == "Willow" then
    return slot == 1 and "hiru" or "hiraku"
  elseif form == "Rain" then
    return slot == 1 and "kuro left" or "kuro right"
  else
    return "thrust left leg"
  end
end

--------------------------------------------------------------------------------
-- TELEPATHY INTEGRATION
--------------------------------------------------------------------------------

function shikudoLock.selectTelepathy()
  -- Telepathy uses EQ balance, separate from BAL (staff attacks)
  -- This allows simultaneous affliction pressure

  -- Check if we have EQ
  if not ataxia.balances.eq then
    return nil
  end

  -- Priority 1: Establish mindlock (uses global 'mindlocked' variable)
  if not mindlocked then
    return "mindlock " .. target
  end

  -- Priority 2: Impatience for hardlock (CRITICAL)
  if shikudoLock.checkSoftlock() and not tAffs.impatience then
    return "impatience " .. target
  end

  -- Priority 3: Batter for mental pressure (stupidity + epilepsy + dizziness)
  if shikudoLock.checkSoftlock() then
    return "batter " .. target
  end

  -- Priority 4: Paralyse as backup for paralysis
  if not tAffs.paralysis and mindlocked then
    return "paralyse " .. target
  end

  return nil
end

--------------------------------------------------------------------------------
-- COMBO BUILDER
--------------------------------------------------------------------------------

function shikudoLock.buildCombo()
  local kick = shikudoLock.selectKick()
  local staff1 = shikudoLock.selectStaff(1)
  local staff2 = shikudoLock.selectStaff(2)

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

function shikudoLock.dispatch()
  -- Initialize if missing
  ataxia = ataxia or {}
  ataxia.vitals = ataxia.vitals or {}
  ataxia.balances = ataxia.balances or {}
  ataxia.settings = ataxia.settings or {}
  ataxia.settings.separator = ataxia.settings.separator or ";"
  ataxiaTemp = ataxiaTemp or {}
  tLimbs = tLimbs or {H = 0, T = 0, LL = 0, RL = 0, LA = 0, RA = 0}
  tAffs = tAffs or {}

  -- Update current phase
  shikudoLock.updatePhase()

  -- Debug output
  local form = ataxia.vitals.form or "Unknown"
  local kata = ataxia.vitals.kata or 0
  local phase = shikudoLock.state.phase

  cecho("\n<cyan>[LOCK] Target: " .. tostring(target))
  cecho(" | Phase: <yellow>" .. phase)
  cecho(" <cyan>| Form: " .. form)
  cecho(" | Kata: " .. kata)

  cecho("\n<cyan>[LOCK] Affs: ")
  cecho(tAffs.asthma and "<green>asthma " or "<red>asthma ")
  cecho(tAffs.anorexia and "<green>anorexia " or "<red>anorexia ")
  cecho(tAffs.slickness and "<green>slickness " or "<red>slickness ")
  cecho(tAffs.paralysis and "<green>para " or "<red>para ")
  cecho(tAffs.impatience and "<green>impat " or "<red>impat ")
  cecho(tAffs.weariness and "<green>weary" or "<red>weary")

  -- Safety check
  if not target or target == "" then
    cecho("\n<red>[LOCK] No target set! Use: tar <name>")
    return
  end

  -- Handle combatQueue
  local cmd = ""
  if combatQueue then
    cmd = combatQueue()
  end

  -- SHIELD CHECK
  if tAffs.shield then
    local kick = shikudoLock.selectKick()
    cmd = cmd .. "wield staff;combo " .. target .. " shatter " .. kick
    send("queue addclear free " .. cmd)
    return
  end

  -- BUILD ATTACK
  local attack = shikudoLock.buildCombo()
  attack = attack:gsub("%$tar", target)

  cmd = cmd .. "wield staff;" .. attack

  -- TELEPATHY INTEGRATION - add if EQ available
  local telepathy = shikudoLock.selectTelepathy()
  if telepathy then
    cmd = cmd .. ";" .. telepathy
    cecho("\n<magenta>[LOCK] Telepathy: " .. telepathy)
  end

  -- TRANSITION CHECK - add at END of combo
  local transition = shikudoLock.shouldTransition()
  if transition then
    cmd = cmd .. ";transition to the " .. transition .. " form"
    cecho("\n<yellow>[LOCK] Transitioning to " .. transition)
  end

  send("queue addclear free " .. cmd)
end

--------------------------------------------------------------------------------
-- STATUS COMMAND
--------------------------------------------------------------------------------

function shikudoLock.status()
  -- Initialize if missing
  tAffs = tAffs or {}
  ataxia = ataxia or {}
  ataxia.vitals = ataxia.vitals or {}

  local form = ataxia.vitals.form or "Unknown"
  local kata = ataxia.vitals.kata or 0
  local maxKata = shikudoLock.maxKata[form] or 12

  -- Update phase
  shikudoLock.updatePhase()
  local phase = shikudoLock.state.phase

  cecho("\n<cyan>+============================================+")
  cecho("\n<cyan>|         <white>SHIKUDO LOCK STATUS<cyan>                |")
  cecho("\n<cyan>+============================================+")

  cecho("\n<cyan>| <white>Phase: <yellow>" .. phase)
  cecho("\n<cyan>| <white>Form: <yellow>" .. form .. " <white>(<yellow>" .. kata .. "/" .. maxKata .. " kata<white>)")
  cecho("\n<cyan>| <white>Mindlock: " .. (mindlocked and "<green>ACTIVE" or "<red>INACTIVE"))

  cecho("\n<cyan>+--------------------------------------------+")
  cecho("\n<cyan>| <white>LOCK PROGRESS:")

  -- Softlock
  local soft = shikudoLock.checkSoftlock()
  cecho("\n<cyan>|   <white>Softlock:   " .. (soft and "<green>[LOCKED]" or "<yellow>[BUILDING]"))
  cecho("\n<cyan>|     " .. (tAffs.asthma and "<green>[X]" or "<red>[ ]") .. " asthma")
  cecho("  " .. (tAffs.anorexia and "<green>[X]" or "<red>[ ]") .. " anorexia")
  cecho("  " .. (tAffs.slickness and "<green>[X]" or "<red>[ ]") .. " slickness")

  -- Venomlock
  local venom = shikudoLock.checkVenomlock()
  cecho("\n<cyan>|   <white>Venomlock:  " .. (venom and "<green>[LOCKED]" or (soft and "<yellow>[NEXT]" or "<dim_grey>[PENDING]")))
  cecho("\n<cyan>|     " .. (tAffs.paralysis and "<green>[X]" or "<red>[ ]") .. " paralysis")

  -- Hardlock
  local hard = shikudoLock.checkHardlock()
  cecho("\n<cyan>|   <white>Hardlock:   " .. (hard and "<green>[LOCKED]" or (venom and "<yellow>[NEXT]" or "<dim_grey>[PENDING]")))
  cecho("\n<cyan>|     " .. (tAffs.impatience and "<green>[X]" or "<red>[ ]") .. " impatience <dim_grey>(Telepathy)")

  -- Truelock
  local true_lock = shikudoLock.checkTruelock()
  cecho("\n<cyan>|   <white>Truelock:   " .. (true_lock and "<green>[LOCKED]" or (hard and "<yellow>[NEXT]" or "<dim_grey>[PENDING]")))
  cecho("\n<cyan>|     " .. (tAffs.weariness and "<green>[X]" or "<red>[ ]") .. " weariness <dim_grey>(blocks Fitness)")

  cecho("\n<cyan>+--------------------------------------------+")
  cecho("\n<cyan>| <white>PRESSURE AFFS:")
  cecho("\n<cyan>|   " .. (tAffs.clumsiness and "<green>[X]" or "<dim_grey>[ ]") .. " clumsiness")
  cecho("  " .. (tAffs.dizziness and "<green>[X]" or "<dim_grey>[ ]") .. " dizziness")
  cecho("  " .. (tAffs.epilepsy and "<green>[X]" or "<dim_grey>[ ]") .. " epilepsy")
  cecho("\n<cyan>|   " .. (tAffs.addiction and "<green>[X]" or "<dim_grey>[ ]") .. " addiction")
  cecho("  " .. (tAffs.stupidity and "<green>[X]" or "<dim_grey>[ ]") .. " stupidity")

  cecho("\n<cyan>+============================================+")

  if true_lock then
    cecho("\n<green>*** TARGET IS TRUELOCKED - PURE DAMAGE PRESSURE ***")
  elseif hard then
    cecho("\n<yellow>*** HARDLOCKED - Apply weariness for truelock ***")
  elseif venom then
    cecho("\n<yellow>*** VENOMLOCKED - Use Telepathy for impatience ***")
  elseif soft then
    cecho("\n<yellow>*** SOFTLOCKED - Apply paralysis ***")
  end
end

-- Aliases for convenience
function shikudolock()
  shikudoLock.dispatch()
end

function sklstatus()
  shikudoLock.status()
end

function sklockstatus()
  shikudoLock.status()
end
