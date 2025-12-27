--[[mudlet
type: script
name: CC_Shikudo
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- Shikudo Script - Levi
- Shikudo
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- Shikudo Dispatch Kill Logic System
-- Focused on: Rain prep → Gaital kill → DISPATCH
-- Kill requires: Prone + Broken leg + Broken head + Windpipe damage (needle)

shikudo = shikudo or {}
shikudo.state = {
  phase = "PREP",  -- PREP, PRONE, KILL
}

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
  local ll = shikudo.getLimbDamage("left leg")
  local rl = shikudo.getLimbDamage("right leg")
  local h = shikudo.getLimbDamage("head")
  local legBroken = (ll >= 100 or rl >= 100)
  local headBroken = (h >= 100 or tAffs.damagedhead)
  local windpipe = (tAffs.damagedwindpipe or tAffs.crushedthroat)

  return prone and legBroken and headBroken and windpipe
end

function shikudo.checkReadyForProne()
  -- At least one leg prepped enough to sweep + break
  local ll = shikudo.getLimbDamage("left leg")
  local rl = shikudo.getLimbDamage("right leg")
  return (ll >= 90 or rl >= 90)
end

function shikudo.checkLegsPrepped()
  -- Both legs have some damage for sweep effectiveness
  local ll = shikudo.getLimbDamage("left leg")
  local rl = shikudo.getLimbDamage("right leg")
  return (ll >= 70 and rl >= 70)
end

function shikudo.checkHeadPrepped()
  -- Head has enough damage to break with needle + spinkick burst
  return (shikudo.getLimbDamage("head") >= 70)
end

--------------------------------------------------------------------------------
-- DYNAMIC PREP THRESHOLDS (based on actual damage per hit)
-- "Prepped" = ONE HIT away from breaking (100%)
-- Uses lb[target].hits["limb"] for limb damage tracking
--------------------------------------------------------------------------------

-- Helper to safely get limb damage from lb[target].hits
function shikudo.getLimbDamage(limb)
  if not target or not lb or not lb[target] or not lb[target].hits then
    return 0
  end
  return lb[target].hits[limb] or 0
end

function shikudo.getLegPrepThreshold()
  -- Use kuro damage as the baseline (safest threshold for legs)
  local kuro = shikudo_limbDamage and shikudo_limbDamage.kuro or 9.2
  return 100 - kuro
end

function shikudo.getHeadPrepThreshold()
  -- Head threshold depends on form (different attacks do different damage)
  local form = ataxia.vitals.form or "Rain"
  local dmg
  if form == "Oak" then
    dmg = shikudo_limbDamage and shikudo_limbDamage.nervestrike or 7.8
  elseif form == "Gaital" then
    dmg = shikudo_limbDamage and shikudo_limbDamage.needle or 10.6
  else
    dmg = shikudo_limbDamage and shikudo_limbDamage.hiru or 4.3
  end
  return 100 - dmg
end

function shikudo.isLegPrepped(leg)
  local threshold = shikudo.getLegPrepThreshold()
  if leg == "left" or leg == "LL" then
    return shikudo.getLimbDamage("left leg") >= threshold
  else
    return shikudo.getLimbDamage("right leg") >= threshold
  end
end

function shikudo.areBothLegsPrepped()
  local threshold = shikudo.getLegPrepThreshold()
  return shikudo.getLimbDamage("left leg") >= threshold and shikudo.getLimbDamage("right leg") >= threshold
end

function shikudo.isDynamicHeadPrepped()
  return shikudo.getLimbDamage("head") >= shikudo.getHeadPrepThreshold()
end

-- Global leg protection: returns true if safe to hit this leg
function shikudo.isLegSafe(leg)
  -- If head is already prepped, legs are safe to break
  if shikudo.isDynamicHeadPrepped() then
    return true
  end
  -- If head not prepped, don't hit prepped legs
  return not shikudo.isLegPrepped(leg)
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

  local legsPrepped = shikudo.areBothLegsPrepped()
  local headPrepped = shikudo.isDynamicHeadPrepped()

  -- PRIORITY 1: ALL LIMBS READY → Go to Gaital for kill
  if legsPrepped and headPrepped then
    if form == "Oak" then return "Gaital" end
    if form == "Rain" then return "Oak" end
    if form == "Willow" then return "Rain" end
    if form == "Tykonos" then return "Willow" end
    if form == "Maelstrom" then return "Oak" end
  end

  -- PRIORITY 2: LEGS PREPPED, HEAD NOT → Go to Oak for head prep
  if legsPrepped and not headPrepped then
    if form == "Rain" then return "Oak" end
    if form == "Tykonos" then return "Willow" end  -- Tykonos→Willow→Rain→Oak
    if form == "Willow" then return "Rain" end
    if form == "Oak" then return nil end  -- Stay in Oak, prep head
  end

  -- PRIORITY 3: Near kata limit - transition to avoid stumble
  local maxKata = shikudo.maxKata[form] or 12

  if maxKata == 12 and kata >= 9 then
    if form == "Oak" then return "Willow" end
    if form == "Willow" then return "Rain" end
    if form == "Tykonos" then return "Willow" end
    if form == "Maelstrom" then return "Oak" end
  end

  -- Rain at 21+ kata - ALWAYS go to Oak (resets kata, can prep legs OR head)
  if form == "Rain" and kata >= 21 then
    return "Oak"  -- Oak has kuro (legs) AND nervestrike (head)
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
  local ll = shikudo.getLimbDamage("left leg")
  local rl = shikudo.getLimbDamage("right leg")
  local h = shikudo.getLimbDamage("head")

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
    elseif h < 90 and parried ~= "head" then
      return "risingkick head"
    else
      return "risingkick torso"
    end

  elseif form == "Gaital" then
    -- Kill phase kicks
    if tAffs.prone and (h >= 90 or tAffs.damagedhead) then
      return "spinkick"  -- Massive head damage on prone
    end
    -- FLASHHEEL for leg breaks
    if ll < rl and parried ~= "left leg" then
      return "flashheel left"
    elseif parried ~= "right leg" then
      return "flashheel right"
    else
      return "flashheel left"
    end

  elseif form == "Willow" then
    -- FLASHHEEL for legs
    if ll < rl and parried ~= "left leg" then
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
      if h < 90 then
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
    local leftPrepped = shikudo.isLegPrepped("left")
    local rightPrepped = shikudo.isLegPrepped("right")
    local bothLegsPrepped = leftPrepped and rightPrepped
    local headPrepped = shikudo.isDynamicHeadPrepped()

    -- If all prepped, we shouldn't be in Tykonos - use LIGHT
    if bothLegsPrepped and headPrepped then
      if slot == 1 then
        return "thrust light head"
      else
        return "thrust light torso"
      end
    end

    -- Tykonos has SWEEP available! Use it when all limbs are ready
    if bothLegsPrepped and headPrepped and not tAffs.prone then
      if slot == 1 then
        return "sweep"  -- Sweep uses both arm balances
      else
        return nil  -- No second staff attack with sweep
      end
    end

    -- Continue leg prep if needed
    if slot == 1 then
      if not leftPrepped and parried ~= "left leg" then
        return "thrust left leg"
      elseif not rightPrepped and parried ~= "right leg" then
        return "thrust right leg"
      elseif not headPrepped and parried ~= "head" then
        return "thrust head"
      else
        return "thrust light torso"
      end
    else
      if not rightPrepped and parried ~= "right leg" then
        return "thrust right leg"
      elseif not leftPrepped and parried ~= "left leg" then
        return "thrust left leg"
      elseif not headPrepped then
        return "thrust head"
      else
        return "thrust light torso"
      end
    end
  end
end

function shikudo.selectRainStaff(slot, parried)
  -- Rain: KURO (legs), HIRU (head), RUKU (arms/torso)
  -- LIGHT modifier: Use when limbs prepped to avoid breaking prematurely

  local leftPrepped = shikudo.isLegPrepped("left")
  local rightPrepped = shikudo.isLegPrepped("right")
  local bothLegsPrepped = leftPrepped and rightPrepped
  local headPrepped = shikudo.isDynamicHeadPrepped()
  local kata = ataxia.vitals.kata or 0

  if slot == 1 then
    -- Priority 1: Prep unprepped legs
    if not leftPrepped and parried ~= "left leg" then
      return "kuro left"
    elseif not rightPrepped and parried ~= "right leg" then
      return "kuro right"
    -- Priority 2: Both legs prepped, work on head (Rain has hiru)
    elseif bothLegsPrepped and not headPrepped and parried ~= "head" then
      return "hiru"
    -- Priority 3: All prepped but can't transition (kata < 5) → LIGHT attacks
    elseif bothLegsPrepped and headPrepped then
      if not tAffs.slickness then
        return "ruku light torso"  -- Affliction without limb damage
      else
        return "hiru light"  -- Build kata safely
      end
    -- Fallback: Use LIGHT on prepped limbs
    else
      return "hiru light"
    end
  else
    -- Secondary slot: Same priority logic
    if not rightPrepped and parried ~= "right leg" then
      return "kuro right"
    elseif not leftPrepped and parried ~= "left leg" then
      return "kuro left"
    elseif bothLegsPrepped and not headPrepped then
      return "hiru"
    elseif not tAffs.slickness then
      return "ruku light torso"
    elseif not tAffs.clumsiness then
      return "ruku light left"  -- Arm damage is fine
    else
      return "hiru light"
    end
  end
end

function shikudo.selectOakStaff(slot, parried)
  -- Oak: KURO (legs), NERVESTRIKE (head), LIVESTRIKE (torso), RUKU
  -- LIGHT modifier: Use when limbs are prepped to avoid breaking prematurely

  local leftPrepped = shikudo.isLegPrepped("left")
  local rightPrepped = shikudo.isLegPrepped("right")
  local bothLegsPrepped = leftPrepped and rightPrepped
  local headPrepped = shikudo.isDynamicHeadPrepped()
  local kata = ataxia.vitals.kata or 0

  if slot == 1 then
    -- Priority 1: If legs NOT prepped, continue leg work (missed in Rain)
    if not leftPrepped and parried ~= "left leg" then
      return "kuro left"
    elseif not rightPrepped and parried ~= "right leg" then
      return "kuro right"
    -- Priority 2: Legs prepped, work on HEAD
    elseif bothLegsPrepped and not headPrepped and parried ~= "head" then
      return "nervestrike"  -- Head damage
    -- Priority 3: All prepped, waiting for transition → LIGHT or afflictions
    elseif bothLegsPrepped and headPrepped then
      if not tAffs.asthma then
        return "livestrike light"  -- Asthma without breaking
      else
        return "nervestrike light"
      end
    else
      return "nervestrike light"
    end
  else
    -- Secondary: Same logic, alternate targets
    if not rightPrepped and parried ~= "right leg" then
      return "kuro right"
    elseif not leftPrepped and parried ~= "left leg" then
      return "kuro left"
    elseif not headPrepped and parried ~= "head" then
      return "nervestrike"
    elseif not tAffs.asthma then
      return "livestrike light"
    elseif not tAffs.clumsiness then
      return "ruku light left"  -- Arms are safe
    else
      return "nervestrike light"
    end
  end
end

function shikudo.selectGaitalStaff(slot, parried)
  -- Gaital: NEEDLE (head/windpipe), SWEEP (prone), KURO (legs)
  -- Kill phase: sweep → break legs → spinkick/needle head → dispatch

  local ll = shikudo.getLimbDamage("left leg")
  local rl = shikudo.getLimbDamage("right leg")
  local h = shikudo.getLimbDamage("head")

  local headPrepped = shikudo.isDynamicHeadPrepped()
  local headBroken = (h >= 100 or tAffs.damagedhead)
  local hasWindpipe = (tAffs.damagedwindpipe or tAffs.crushedthroat)
  local legsBroken = (ll >= 100 or rl >= 100)
  local bothLegsPrepped = shikudo.areBothLegsPrepped()

  -- PHASE 1: Not prone yet → SWEEP + break legs
  if not tAffs.prone and bothLegsPrepped and headPrepped then
    if slot == 1 then
      return "sweep"  -- Prones target
    else
      -- Break legs while sweeping
      if ll < 100 and parried ~= "left leg" then
        return "kuro left"
      else
        return "kuro right"
      end
    end
  end

  -- PHASE 2: Prone + legs broken → break head + windpipe
  if tAffs.prone and legsBroken then
    if slot == 1 then
      if not headBroken then
        return "needle"  -- Head damage + windpipe
      elseif not hasWindpipe then
        return "needle light"  -- Just windpipe
      else
        return "needle"  -- All done, keep pressure
      end
    else
      return "needle"
    end
  end

  -- PHASE 2b: Prone but legs not broken yet - break them
  if tAffs.prone and not legsBroken then
    if slot == 1 then
      if ll < 100 and parried ~= "left leg" then
        return "kuro left"
      else
        return "kuro right"
      end
    else
      if rl < 100 and parried ~= "right leg" then
        return "kuro right"
      else
        return "kuro left"
      end
    end
  end

  -- Fallback: build toward kill conditions
  if slot == 1 then
    if not tAffs.prone then return "sweep" end
    return "needle"
  else
    return "kuro left"
  end
end

function shikudo.selectWillowStaff(slot, parried)
  -- Willow: DART (fast), HIRU (head), HIRAKU (head)
  local h = shikudo.getLimbDamage("head")

  if slot == 1 then
    if h < 70 and parried ~= "head" then
      return "hiru"
    else
      return "hiraku"
    end
  else
    if h < 90 then
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

  -- Debug: Show what we have
  cecho("\n<cyan>[Shikudo] Target: " .. tostring(target))
  cecho(" | Form: " .. tostring(ataxia.vitals.form))
  cecho(" | Kata: " .. tostring(ataxia.vitals.kata))
  cecho("\n<cyan>[Shikudo] Limbs - H:" .. shikudo.getLimbDamage("head") .. " LL:" .. shikudo.getLimbDamage("left leg") .. " RL:" .. shikudo.getLimbDamage("right leg"))
  cecho(" | Ready for Prone: " .. (shikudo.checkReadyForProne() and "YES" or "NO"))

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
  end

  send("queue addclear free " .. cmd)

  -- Debug output
  if ataxia.debug then
    cecho("\n<cyan>[Shikudo] Form: " .. form .. " | Kata: " .. kata)
    cecho("\n<cyan>[Shikudo] H:" .. shikudo.getLimbDamage("head") .. " LL:" .. shikudo.getLimbDamage("left leg") .. " RL:" .. shikudo.getLimbDamage("right leg"))
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

  -- Get dynamic thresholds
  local legThreshold = shikudo.getLegPrepThreshold()
  local headThreshold = shikudo.getHeadPrepThreshold()
  local leftPrepped = shikudo.isLegPrepped("left")
  local rightPrepped = shikudo.isLegPrepped("right")
  local bothLegsPrepped = shikudo.areBothLegsPrepped()
  local headPrepped = shikudo.isDynamicHeadPrepped()

  cecho("\n<cyan>╔══════════════════════════════════════════╗")
  cecho("\n<cyan>║         <white>SHIKUDO STATUS<cyan>                  ║")
  cecho("\n<cyan>╠══════════════════════════════════════════╣")
  cecho("\n<cyan>║ <white>Target: <yellow>" .. tostring(target or "None") .. "<cyan>")
  cecho("\n<cyan>║ <white>Form: <green>" .. form .. " <grey>(" .. kata .. "/" .. maxKata .. " kata)<cyan>")
  cecho("\n<cyan>╠══════════════════════════════════════════╣")
  cecho("\n<cyan>║ <white>DYNAMIC THRESHOLDS (1 hit from break):<cyan>")
  cecho("\n<cyan>║   <white>Leg Prep: <yellow>" .. string.format("%.1f%%", legThreshold) .. "<cyan>")
  cecho("\n<cyan>║   <white>Head Prep: <yellow>" .. string.format("%.1f%%", headThreshold) .. "<cyan>")
  cecho("\n<cyan>╠══════════════════════════════════════════╣")
  cecho("\n<cyan>║ <white>LIMB DAMAGE:<cyan>")
  cecho("\n<cyan>║   <white>Head: " .. (headPrepped and "<green>" or "<red>") .. string.format("%.1f%%", shikudo.getLimbDamage("head")) .. (headPrepped and " PREPPED" or ""))
  cecho("\n<cyan>║   <white>L Leg: " .. (leftPrepped and "<green>" or "<red>") .. string.format("%.1f%%", shikudo.getLimbDamage("left leg")) .. (leftPrepped and " PREPPED" or ""))
  cecho("\n<cyan>║   <white>R Leg: " .. (rightPrepped and "<green>" or "<red>") .. string.format("%.1f%%", shikudo.getLimbDamage("right leg")) .. (rightPrepped and " PREPPED" or ""))
  cecho("\n<cyan>╠══════════════════════════════════════════╣")
  cecho("\n<cyan>║ <white>KILL CONDITIONS:<cyan>")
  cecho("\n<cyan>║   <white>Prone: " .. (tAffs.prone and "<green>YES" or "<red>NO"))
  cecho("\n<cyan>║   <white>Leg Broken: " .. ((shikudo.getLimbDamage("left leg") >= 100 or shikudo.getLimbDamage("right leg") >= 100) and "<green>YES" or "<red>NO"))
  cecho("\n<cyan>║   <white>Head Broken: " .. ((shikudo.getLimbDamage("head") >= 100 or tAffs.damagedhead) and "<green>YES" or "<red>NO"))
  cecho("\n<cyan>║   <white>Windpipe: " .. ((tAffs.damagedwindpipe or tAffs.crushedthroat) and "<green>YES" or "<red>NO"))
  cecho("\n<cyan>║   <white>DISPATCH READY: " .. (shikudo.checkDispatchReady() and "<green>*** YES ***" or "<red>NO"))
  cecho("\n<cyan>╠══════════════════════════════════════════╣")
  cecho("\n<cyan>║ <white>PREP STATUS:<cyan>")
  cecho("\n<cyan>║   <white>Both Legs Prepped: " .. (bothLegsPrepped and "<green>YES" or "<yellow>NO"))
  cecho("\n<cyan>║   <white>Head Prepped: " .. (headPrepped and "<green>YES" or "<yellow>NO"))
  cecho("\n<cyan>║   <white>Ready for Gaital: " .. ((bothLegsPrepped and headPrepped) and "<green>YES" or "<yellow>NO"))
  cecho("\n<cyan>╚══════════════════════════════════════════╝\n")
end

-- Alias: skstatus
function skstatus()
  shikudo.status()
end
