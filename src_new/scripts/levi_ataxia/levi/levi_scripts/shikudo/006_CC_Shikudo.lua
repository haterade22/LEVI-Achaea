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
  hyperfocus = nil,  -- Current hyperfocus target: nil, "head", "left leg", "right leg", etc.
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

-- Get damage for a specific attack (from shikudo_limbDamage table or defaults)
-- If targetLimb is provided and matches hyperfocus, damage is HALVED
function shikudo.getAttackDamage(attack, targetLimb)
  local defaults = {
    kuro = 9.2, thrust = 14.5, needle = 10.6, nervestrike = 13.4,
    hiru = 4.3, hiraku = 4.3, livestrike = 7.8, ruku = 4.5,
    dart = 4.4, flashheel = 9.2, risingkick = 9.2, frontkick = 9.2,
    spinkick = 27.0  -- Massive damage on prone
  }
  local baseDamage
  if shikudo_limbDamage and shikudo_limbDamage[attack] then
    baseDamage = shikudo_limbDamage[attack]
  else
    baseDamage = defaults[attack] or 10  -- Default to 10% if unknown
  end

  -- HYPERFOCUS: If attacking a hyperfocused limb, damage is HALVED
  if targetLimb and shikudo.state.hyperfocus == targetLimb then
    return baseDamage / 2
  end

  return baseDamage
end

-- CORE FUNCTION: How many hits until this limb is prepped?
-- Returns: 0 = already prepped, 1 = one hit preps it, 2+ = needs multiple
-- Note: Accounts for hyperfocus (halved damage if hyperfocused on this limb)
function shikudo.hitsToPrep(limb, attack)
  local current = shikudo.getLimbDamage(limb)
  local dmg = shikudo.getAttackDamage(attack, limb)  -- Pass limb for hyperfocus check
  local threshold = 100 - dmg  -- "Prepped" = one hit from break

  if current >= threshold then
    return 0  -- Already prepped
  elseif current + dmg >= threshold then
    return 1  -- One hit will prep it
  else
    return 2  -- Needs 2+ hits
  end
end

-- Convenience: Is limb already prepped for this attack?
function shikudo.isLimbPrepped(limb, attack)
  return shikudo.hitsToPrep(limb, attack) == 0
end

-- Convenience: Will ONE hit prep this limb?
function shikudo.willOneHitPrep(limb, attack)
  return shikudo.hitsToPrep(limb, attack) == 1
end

function shikudo.getLegPrepThreshold(leg)
  -- Use kuro damage as the baseline (safest threshold for legs)
  -- Account for hyperfocus if specified
  local legName = leg or "left leg"
  local kuro = shikudo_limbDamage and shikudo_limbDamage.kuro or 9.2
  if shikudo.state.hyperfocus == legName then
    kuro = kuro / 2  -- Halved damage when hyperfocused
  end
  return 100 - kuro
end

function shikudo.getHeadPrepThreshold()
  -- Head threshold depends on form (different attacks do different damage)
  -- Account for hyperfocus if head is hyperfocused
  local form = ataxia.vitals.form or "Rain"
  local dmg
  if form == "Oak" then
    dmg = shikudo_limbDamage and shikudo_limbDamage.nervestrike or 7.8
  elseif form == "Gaital" then
    dmg = shikudo_limbDamage and shikudo_limbDamage.needle or 10.6
  else
    dmg = shikudo_limbDamage and shikudo_limbDamage.hiru or 4.3
  end

  if shikudo.state.hyperfocus == "head" then
    dmg = dmg / 2  -- Halved damage when hyperfocused
  end
  return 100 - dmg
end

function shikudo.isLegPrepped(leg)
  local limbName = (leg == "left" or leg == "LL") and "left leg" or "right leg"
  local threshold = shikudo.getLegPrepThreshold(limbName)
  return shikudo.getLimbDamage(limbName) >= threshold
end

function shikudo.areBothLegsPrepped()
  local leftThreshold = shikudo.getLegPrepThreshold("left leg")
  local rightThreshold = shikudo.getLegPrepThreshold("right leg")
  return shikudo.getLimbDamage("left leg") >= leftThreshold and shikudo.getLimbDamage("right leg") >= rightThreshold
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
-- HYPERFOCUS MANAGEMENT
-- Hyperfocus bypasses parry but HALVES damage to that limb
-- IMPORTANT: Hyperfocus costs 3.4s balance, so we ALWAYS hyperfocus HEAD
-- and keep it there for the entire fight. No switching!
--------------------------------------------------------------------------------

-- Set hyperfocus state (called by trigger when hyperfocus is set/cleared)
function shikudo.setHyperfocus(limb)
  if limb == "none" or limb == nil then
    shikudo.state.hyperfocus = nil
    cecho("\n<yellow>[Shikudo] Hyperfocus: NONE")
  else
    -- Normalize limb names
    local normalized = limb
    if limb == "left leg" or limb == "leftleg" or limb == "ll" then
      normalized = "left leg"
    elseif limb == "right leg" or limb == "rightleg" or limb == "rl" then
      normalized = "right leg"
    end
    shikudo.state.hyperfocus = normalized
    cecho("\n<yellow>[Shikudo] Hyperfocus: " .. normalized)
  end
end

-- Check if hyperfocus is already set to head (our target)
function shikudo.isHyperfocusSet()
  return shikudo.state.hyperfocus == "head"
end

-- Get the hyperfocus command for combat start
-- We ALWAYS want hyperfocus head - set once at fight start
-- Returns: "hyperfocus head" if not set, nil if already set
function shikudo.getHyperfocusCommand()
  -- If already hyperfocused on head, no command needed
  if shikudo.state.hyperfocus == "head" then
    return nil
  end

  -- Set hyperfocus to head at combat start (costs 3.4s balance but worth it)
  return "hyperfocus head"
end

-- Reset hyperfocus state (call when combat ends)
function shikudo.resetHyperfocus()
  shikudo.state.hyperfocus = nil
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

  -- Gaital: START form (parry bypass) OR kill form
  if form == "Gaital" then
    local legsPrepped = shikudo.areBothLegsPrepped()
    local headPrepped = shikudo.isDynamicHeadPrepped()

    -- KILL PHASE: If all limbs prepped, stay for kill
    if legsPrepped and headPrepped then
      if shikudo.checkDispatchReady() then
        return nil  -- Stay for dispatch
      end
      -- If stuck in Gaital kill phase too long, cycle out
      if kata >= 9 then
        return "Maelstrom"  -- Maelstrom → Oak → back to Gaital
      end
      return nil  -- Stay and keep trying for kill
    end

    -- START PHASE: Limbs not prepped, stay for parry bypass until kata 9
    if kata >= 9 then
      return "Rain"  -- Go to Rain for leg prep
    end
    return nil
  end

  local legsPrepped = shikudo.areBothLegsPrepped()
  local headPrepped = shikudo.isDynamicHeadPrepped()

  -- PRIORITY 0 (HIGHEST): KATA LIMIT - Must transition before stumbling
  -- Willow transitions early (6 kata) to avoid over-prepping legs
  -- Oak only goes to Gaital (never back to Willow with prepped legs)

  -- Willow: transition after 2 combos (6 kata) to get to Rain quickly
  if form == "Willow" and kata >= 6 then
    return "Rain"
  end

  -- Other non-Rain forms: transition at 9 kata
  if form ~= "Rain" and form ~= "Willow" and kata >= 9 then
    if form == "Oak" then
      if legsPrepped and headPrepped then
        return "Gaital"  -- Ready for kill
      else
        return nil  -- Stay in Oak, finish head prep (risk stumble but protect legs)
      end
    end
    if form == "Tykonos" then return "Willow" end
    if form == "Maelstrom" then return "Oak" end
  end

  -- PRIORITY 1: ALL LIMBS READY → Go to Gaital for kill
  if legsPrepped and headPrepped then
    if form == "Oak" then return "Gaital" end
    if form == "Rain" then return "Oak" end
    if form == "Willow" then return "Rain" end
    if form == "Tykonos" then return "Willow" end
    if form == "Maelstrom" then return "Oak" end
  end

  -- PRIORITY 2: LEGS PREPPED, HEAD NOT → Continue prepping or transition
  -- Note: Rain can continue prepping head with hiru (24 kata max), so don't force Oak transition
  if legsPrepped and not headPrepped then
    -- Rain: Stay and prep head with hiru until kata 21 (has 24 kata max)
    -- Don't force Oak transition - Rain can do both leg and head prep
    if form == "Rain" then
      -- Only go to Oak at kata 21+ for safety
      if kata >= 21 then return "Oak" end
      -- Otherwise stay in Rain and continue prepping head with hiru
      return nil
    end
    if form == "Tykonos" then return "Willow" end  -- Tykonos→Willow→Rain→Oak
    if form == "Willow" then return "Rain" end
    -- Oak: fall through, will be handled by Priority 0 at kata 9
  end

  -- Rain at 21+ kata - ALWAYS go to Oak (safety transition before 24 kata stumble)
  if form == "Rain" and kata >= 21 then
    return "Oak"
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

  -- Initialize kickTarget for staff coordination
  ataxiaTemp.kickTarget = nil

  if form == "Rain" then
    -- FRONTKICK targets ARMS (different from legs/head)
    if parried ~= "left arm" then
      ataxiaTemp.kickTarget = "left arm"
      return "frontkick left"
    else
      ataxiaTemp.kickTarget = "right arm"
      return "frontkick right"
    end

  elseif form == "Oak" then
    -- OAK: Kick comes LAST (combo order: staff1 + staff2 + kick)
    -- NERVESTRIKE FIRST for paralysis, then kick at the end
    local headHits = shikudo.hitsToPrep("head", "risingkick")

    if tAffs.prone then
      ataxiaTemp.kickTarget = "head"
      return "risingkick head"  -- Stuns if prone
    elseif headHits >= 1 and parried ~= "head" then
      ataxiaTemp.kickTarget = "head"
      return "risingkick head"  -- Contribute to head damage
    else
      ataxiaTemp.kickTarget = "torso"
      return "risingkick torso"  -- Default to torso
    end

  elseif form == "Gaital" then
    -- KILL PHASE: Spinkick on prone for massive head damage
    local headHits = shikudo.hitsToPrep("head", "spinkick")

    if tAffs.prone and (headHits > 0 or not tAffs.damagedhead) then
      ataxiaTemp.kickTarget = "head"
      return "spinkick"  -- Massive head damage on prone
    end

    -- Not prone yet or head done → flashheel legs
    local leftHits = shikudo.hitsToPrep("left leg", "flashheel")
    local rightHits = shikudo.hitsToPrep("right leg", "flashheel")

    if leftHits > 0 and parried ~= "left leg" then
      ataxiaTemp.kickTarget = "left leg"
      return "flashheel left"
    elseif rightHits > 0 and parried ~= "right leg" then
      ataxiaTemp.kickTarget = "right leg"
      return "flashheel right"
    else
      ataxiaTemp.kickTarget = "left leg"
      return "flashheel left"
    end

  elseif form == "Willow" then
    -- FLASHHEEL targets legs
    local leftHits = shikudo.hitsToPrep("left leg", "flashheel")
    local rightHits = shikudo.hitsToPrep("right leg", "flashheel")

    -- Safe to hit if needs more damage
    if leftHits > 0 and parried ~= "left leg" then
      ataxiaTemp.kickTarget = "left leg"
      return "flashheel left"
    elseif rightHits > 0 and parried ~= "right leg" then
      ataxiaTemp.kickTarget = "right leg"
      return "flashheel right"
    -- Both prepped - check if safe to break
    elseif shikudo.isLegSafe("left") then
      ataxiaTemp.kickTarget = "left leg"
      return "flashheel left"  -- Head prepped, safe to break
    else
      -- Unsafe! Willow only has flashheel (legs). Hit already broken if possible
      local ll = shikudo.getLimbDamage("left leg")
      local rl = shikudo.getLimbDamage("right leg")
      if ll >= 100 then
        ataxiaTemp.kickTarget = "left leg"
        return "flashheel left"  -- Already broken, no harm
      elseif rl >= 100 then
        ataxiaTemp.kickTarget = "right leg"
        return "flashheel right"  -- Already broken, no harm
      else
        -- Neither broken, both prepped, head not ready
        -- Hit left but flag for immediate transition
        ataxiaTemp.kickTarget = "left leg"
        ataxiaTemp.needsUrgentTransition = true
        return "flashheel left"
      end
    end

  elseif form == "Maelstrom" then
    -- CRESCENT if target is prone and low health
    if tAffs.prone and (tonumber(ataxiaTemp.targetHP) or 100) <= 50 then
      ataxiaTemp.kickTarget = "torso"
      return "crescent"  -- Finishing move
    end
    ataxiaTemp.kickTarget = "head"
    return "risingkick head"

  else -- Tykonos
    -- RISINGKICK targets head or torso
    local headHits = shikudo.hitsToPrep("head", "risingkick")

    if headHits >= 2 and parried ~= "head" then
      ataxiaTemp.kickTarget = "head"
      return "risingkick head"
    elseif headHits == 1 and parried ~= "head" then
      ataxiaTemp.kickTarget = "head"
      return "risingkick head"
    else
      ataxiaTemp.kickTarget = "torso"
      return "risingkick torso"
    end
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
    return shikudo.selectTykonosStaff(slot, parried)
  end
end

function shikudo.selectTykonosStaff(slot, parried)
  -- Tykonos: THRUST (any limb), SWEEP
  -- SLOT COORDINATION: Don't hit the same limb twice if it only needs 1 hit

  local leftHits = shikudo.hitsToPrep("left leg", "thrust")
  local rightHits = shikudo.hitsToPrep("right leg", "thrust")
  local headHits = shikudo.hitsToPrep("head", "thrust")
  local kickHitsHead = ataxiaTemp.kickTarget == "head"

  -- If all prepped, use LIGHT or sweep
  if leftHits == 0 and rightHits == 0 and headHits == 0 then
    if not tAffs.prone then
      if slot == 1 then
        ataxiaTemp.slot1Target = "sweep"
        return "sweep"  -- Sweep uses both arm balances
      else
        return nil  -- No second staff with sweep
      end
    else
      if slot == 1 then
        ataxiaTemp.slot1Target = "torso"
        return "thrust light torso"
      else
        return "thrust light head"
      end
    end
  end

  if slot == 1 then
    ataxiaTemp.slot1Target = nil  -- Reset tracking

    -- LEGS first
    if leftHits >= 1 and parried ~= "left leg" then
      ataxiaTemp.slot1Target = "left leg"
      return "thrust left leg"
    elseif rightHits >= 1 and parried ~= "right leg" then
      ataxiaTemp.slot1Target = "right leg"
      return "thrust right leg"

    -- HEAD
    elseif headHits >= 1 and parried ~= "head" then
      if headHits == 1 and kickHitsHead then
        ataxiaTemp.slot1Target = "torso"
        return "thrust light torso"  -- Kick preps head
      else
        ataxiaTemp.slot1Target = "head"
        return "thrust head"
      end
    else
      ataxiaTemp.slot1Target = "torso"
      return "thrust light torso"
    end

  else  -- slot == 2
    local slot1Hit = ataxiaTemp.slot1Target or "none"

    -- LEGS - but NOT the same one slot 1 hit!
    if leftHits >= 1 and slot1Hit ~= "left leg" and parried ~= "left leg" then
      return "thrust left leg"
    elseif rightHits >= 1 and slot1Hit ~= "right leg" and parried ~= "right leg" then
      return "thrust right leg"

    -- HEAD if legs done
    elseif headHits >= 1 and slot1Hit ~= "head" and not kickHitsHead and parried ~= "head" then
      return "thrust head"

    -- FALLBACK to torso
    else
      return "thrust light torso"
    end
  end
end

function shikudo.selectRainStaff(slot, parried)
  -- Rain: KURO (legs), HIRU (head), RUKU (arms/torso)
  -- Rain's PRIMARY JOB is LEG PREP
  -- SLOT COORDINATION: Don't hit the same limb twice if it only needs 1 hit

  local leftHits = shikudo.hitsToPrep("left leg", "kuro")
  local rightHits = shikudo.hitsToPrep("right leg", "kuro")
  local headHits = shikudo.hitsToPrep("head", "hiru")

  if slot == 1 then
    ataxiaTemp.slot1Target = nil  -- Reset tracking

    -- LEGS FIRST (Rain's primary job)
    if leftHits >= 1 and parried ~= "left leg" then
      ataxiaTemp.slot1Target = "left leg"
      return "kuro left"
    elseif rightHits >= 1 and parried ~= "right leg" then
      ataxiaTemp.slot1Target = "right leg"
      return "kuro right"

    -- LEGS PREPPED, work on head
    elseif headHits >= 1 and parried ~= "head" then
      ataxiaTemp.slot1Target = "head"
      return "hiru"
    else
      -- All prepped → afflictions
      ataxiaTemp.slot1Target = "torso"
      if not tAffs.slickness then
        return "ruku light torso"
      else
        return "hiru light"
      end
    end

  else  -- slot == 2
    local slot1Hit = ataxiaTemp.slot1Target or "none"

    -- LEGS - but NOT the same one slot 1 hit!
    if leftHits >= 1 and slot1Hit ~= "left leg" and parried ~= "left leg" then
      return "kuro left"
    elseif rightHits >= 1 and slot1Hit ~= "right leg" and parried ~= "right leg" then
      return "kuro right"

    -- HEAD if legs done
    elseif headHits >= 1 and slot1Hit ~= "head" and parried ~= "head" then
      return "hiru"

    -- FALLBACK to afflictions/arms/torso
    elseif not tAffs.slickness then
      return "ruku torso"
    elseif not tAffs.clumsiness then
      return "ruku left"
    else
      return "hiru light"
    end
  end
end

function shikudo.selectOakStaff(slot, parried)
  -- Oak: KURO (legs), NERVESTRIKE (head), LIVESTRIKE (torso), RUKU
  -- Oak's PRIMARY JOB is HEAD PREP - legs should be prepped from Rain
  -- IMPORTANT: NERVESTRIKE FIRST - paralysis prevents them from parrying!
  -- SLOT COORDINATION: Don't hit the same limb twice if it only needs 1 hit

  local leftHits = shikudo.hitsToPrep("left leg", "kuro")
  local rightHits = shikudo.hitsToPrep("right leg", "kuro")
  local headHits = shikudo.hitsToPrep("head", "nervestrike")
  local kickHitsHead = ataxiaTemp.kickTarget == "head"

  if slot == 1 then
    ataxiaTemp.slot1Target = nil  -- Reset tracking

    -- NERVESTRIKE FIRST when head needs ANY work (paralysis prevents parry!)
    if headHits >= 1 and parried ~= "head" then
      ataxiaTemp.slot1Target = "head"
      return "nervestrike"

    -- HEAD PREPPED, finish legs
    elseif headHits == 0 then
      if leftHits >= 1 and parried ~= "left leg" then
        ataxiaTemp.slot1Target = "left leg"
        return "kuro left"
      elseif rightHits >= 1 and parried ~= "right leg" then
        ataxiaTemp.slot1Target = "right leg"
        return "kuro right"
      elseif not tAffs.asthma then
        ataxiaTemp.slot1Target = "torso"
        return "livestrike"
      else
        -- All limbs prepped, light nervestrike for paralysis
        ataxiaTemp.slot1Target = "head"
        return "nervestrike light"
      end
    else
      ataxiaTemp.slot1Target = "head"
      return "nervestrike light"
    end

  else  -- slot == 2
    local slot1Hit = ataxiaTemp.slot1Target or "none"

    -- HEAD if still needs more work (2+ hits remaining after slot 1)
    if headHits >= 2 and parried ~= "head" then
      return "nervestrike"

    -- LEGS - but NOT the same one slot 1 hit!
    elseif leftHits >= 1 and slot1Hit ~= "left leg" and parried ~= "left leg" then
      return "kuro left"
    elseif rightHits >= 1 and slot1Hit ~= "right leg" and parried ~= "right leg" then
      return "kuro right"

    -- FALLBACK to afflictions/arms/torso
    elseif not tAffs.asthma then
      return "livestrike"
    elseif not tAffs.clumsiness then
      return "ruku left"
    elseif not tAffs.slickness then
      return "ruku torso"
    else
      return "nervestrike light"
    end
  end
end

function shikudo.selectGaitalStaff(slot, parried)
  -- Gaital: NEEDLE (head/windpipe), SWEEP (prone), KURO (legs)
  -- KILL FORM - breaking legs is INTENDED here
  -- SLOT COORDINATION: Still track to avoid hitting same unbroken leg twice

  local ll = shikudo.getLimbDamage("left leg")
  local rl = shikudo.getLimbDamage("right leg")
  local h = shikudo.getLimbDamage("head")

  local headBroken = (h >= 100 or tAffs.damagedhead)
  local hasWindpipe = (tAffs.damagedwindpipe or tAffs.crushedthroat)
  local legsBroken = (ll >= 100 or rl >= 100)
  local bothLegsPrepped = shikudo.areBothLegsPrepped()
  local headPrepped = shikudo.isDynamicHeadPrepped()

  if slot == 1 then
    ataxiaTemp.slot1Target = nil  -- Reset tracking
  end

  -- PHASE 1: Not prone yet → SWEEP (uses both arms, kick breaks leg)
  if not tAffs.prone and bothLegsPrepped and headPrepped then
    if slot == 1 then
      ataxiaTemp.slot1Target = "sweep"
      return "sweep"  -- Prones target, kick (flashheel) breaks leg
    else
      return nil  -- SWEEP uses both arm balances - no second staff!
    end
  end

  -- PHASE 2: Prone + at least one leg broken → head + windpipe
  if tAffs.prone and legsBroken then
    if slot == 1 then
      ataxiaTemp.slot1Target = "head"
      return "needle"
    else
      return "needle"  -- Double needle for windpipe
    end
  end

  -- PHASE 2b: Prone but legs not broken yet - break them
  if tAffs.prone and not legsBroken then
    local slot1Hit = ataxiaTemp.slot1Target or "none"

    if slot == 1 then
      if ll < 100 and parried ~= "left leg" then
        ataxiaTemp.slot1Target = "left leg"
        return "kuro left"
      else
        ataxiaTemp.slot1Target = "right leg"
        return "kuro right"
      end
    else
      -- Slot 2: hit the OTHER leg
      if rl < 100 and slot1Hit ~= "right leg" and parried ~= "right leg" then
        return "kuro right"
      elseif ll < 100 and slot1Hit ~= "left leg" and parried ~= "left leg" then
        return "kuro left"
      else
        return "needle"  -- Fallback to head
      end
    end
  end

  -- Fallback: build toward kill conditions
  if slot == 1 then
    if not tAffs.prone then
      ataxiaTemp.slot1Target = "sweep"
      return "sweep"
    end
    ataxiaTemp.slot1Target = "head"
    return "needle"
  else
    return "needle"
  end
end

function shikudo.selectWillowStaff(slot, parried)
  -- Willow: DART (fast), HIRU (head), HIRAKU (head)
  -- Willow's staff focuses on HEAD, kick does legs
  -- SLOT COORDINATION: Don't hit head twice if it only needs 1 hit

  local headHits = shikudo.hitsToPrep("head", "hiru")

  if slot == 1 then
    ataxiaTemp.slot1Target = nil  -- Reset tracking

    -- HEAD: Primary focus in Willow
    if headHits >= 1 and parried ~= "head" then
      ataxiaTemp.slot1Target = "head"
      return "hiru"
    else
      ataxiaTemp.slot1Target = "torso"
      return "dart torso"
    end

  else  -- slot == 2
    local slot1Hit = ataxiaTemp.slot1Target or "none"

    -- HEAD if still needs work - but NOT if slot 1 just hit it and it only needed 1
    if headHits >= 2 and parried ~= "head" then
      return "hiraku"  -- Continue head work
    elseif headHits >= 1 and slot1Hit ~= "head" and parried ~= "head" then
      return "hiraku"

    -- FALLBACK to torso
    else
      return "dart torso"
    end
  end
end

function shikudo.selectMaelstromStaff(slot, parried)
  -- Maelstrom: RUKU, LIVESTRIKE, JINZUKU, SWEEP
  -- Affliction focused - doesn't hit legs with staff
  -- SLOT COORDINATION: Track for consistency

  if slot == 1 then
    ataxiaTemp.slot1Target = nil  -- Reset tracking
  end

  -- Check for sweep conditions (uses both arms, only kick allowed)
  if not tAffs.prone and shikudo.areBothLegsPrepped() and shikudo.isDynamicHeadPrepped() then
    if slot == 1 then
      ataxiaTemp.slot1Target = "sweep"
      return "sweep"
    else
      return nil  -- Sweep uses both arm balances
    end
  end

  -- Affliction priority
  if slot == 1 then
    if not tAffs.asthma then
      ataxiaTemp.slot1Target = "torso"
      return "livestrike"
    elseif not tAffs.slickness then
      ataxiaTemp.slot1Target = "torso"
      return "ruku torso"
    else
      ataxiaTemp.slot1Target = "torso"
      return "jinzuku"
    end
  else
    if not tAffs.slickness then
      return "ruku torso"
    elseif not tAffs.addiction then
      return "jinzuku"
    else
      return "livestrike light"
    end
  end
end

--------------------------------------------------------------------------------
-- COMBO BUILDER
--------------------------------------------------------------------------------

function shikudo.buildCombo(transition)
  local form = ataxia.vitals.form
  local kick = shikudo.selectKick()
  local staff1 = shikudo.selectStaff(1)
  local staff2 = shikudo.selectStaff(2)

  -- Handle sweep (uses both arm balances, limited combo)
  if staff1 == "sweep" then
    local combo
    if kick then
      combo = "combo $tar sweep " .. kick
    else
      combo = "combo $tar sweep"
    end
    -- Add inline transition if provided
    if transition then
      combo = combo .. " transition " .. transition:lower()
    end
    return combo
  end

  -- OAK: staff1 + staff2 + kick (nervestrike first for paralysis)
  -- OTHER FORMS: kick + staff1 + staff2
  local combo = "combo $tar"
  if form == "Oak" then
    -- Staff first, kick last
    if staff1 then combo = combo .. " " .. staff1 end
    if staff2 then combo = combo .. " " .. staff2 end
    if kick then combo = combo .. " " .. kick end
  else
    -- Normal order: kick first
    if kick then combo = combo .. " " .. kick end
    if staff1 then combo = combo .. " " .. staff1 end
    if staff2 then combo = combo .. " " .. staff2 end
  end

  -- Add inline transition if provided
  if transition then
    combo = combo .. " transition " .. transition:lower()
  end

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
  cecho(" | Hyperfocus: " .. tostring(shikudo.state.hyperfocus or "none"))
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

  -- HYPERFOCUS CHECK: Set hyperfocus head at combat start (costs 3.4s balance)
  -- This is a one-time setup, so we send it separately and wait for balance
  local hyperfocusCmd = shikudo.getHyperfocusCommand()
  if hyperfocusCmd then
    send("queue addclear free " .. cmd .. hyperfocusCmd)
    cecho("\n<yellow>[Shikudo] Setting hyperfocus head (3.4s balance cost)")
    -- Optimistically set state so we don't spam it
    shikudo.state.hyperfocus = "head"
    return  -- Wait for balance before attacking
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

  -- TRANSITION CHECK - get transition before building combo
  local transition = shikudo.shouldTransition()
  if transition then
    cecho("\n<yellow>[Shikudo] Transitioning to " .. transition .. " after this combo")
  end

  -- BUILD ATTACK (includes inline transition if needed)
  local attack = shikudo.buildCombo(transition)
  attack = attack:gsub("%$tar", target)

  cmd = cmd .. "wield staff489282;" .. attack

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

  local hyperfocus = shikudo.state.hyperfocus or "none"

  cecho("\n<cyan>╔══════════════════════════════════════════╗")
  cecho("\n<cyan>║         <white>SHIKUDO STATUS<cyan>                  ║")
  cecho("\n<cyan>╠══════════════════════════════════════════╣")
  cecho("\n<cyan>║ <white>Target: <yellow>" .. tostring(target or "None") .. "<cyan>")
  cecho("\n<cyan>║ <white>Form: <green>" .. form .. " <grey>(" .. kata .. "/" .. maxKata .. " kata)<cyan>")
  cecho("\n<cyan>║ <white>Hyperfocus: " .. (hyperfocus == "head" and "<green>HEAD" or "<yellow>" .. hyperfocus) .. "<cyan>")
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
