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

-- Get damage for a specific attack (from shikudo_limbDamage table or defaults)
function shikudo.getAttackDamage(attack)
  local defaults = {
    kuro = 9.2, thrust = 14.5, needle = 10.6, nervestrike = 13.4,
    hiru = 4.3, hiraku = 4.3, livestrike = 7.8, ruku = 4.5,
    dart = 4.4, flashheel = 9.2, risingkick = 9.2, frontkick = 9.2,
    spinkick = 27.0  -- Massive damage on prone
  }
  if shikudo_limbDamage and shikudo_limbDamage[attack] then
    return shikudo_limbDamage[attack]
  end
  return defaults[attack] or 10  -- Default to 10% if unknown
end

-- CORE FUNCTION: How many hits until this limb is prepped?
-- Returns: 0 = already prepped, 1 = one hit preps it, 2+ = needs multiple
function shikudo.hitsToPrep(limb, attack)
  local current = shikudo.getLimbDamage(limb)
  local dmg = shikudo.getAttackDamage(attack)
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
    -- RISINGKICK can hit head - use hitsToPrep for coordination
    local headHits = shikudo.hitsToPrep("head", "risingkick")

    if tAffs.prone then
      ataxiaTemp.kickTarget = "head"
      return "risingkick head"  -- Stuns if prone
    elseif headHits >= 2 and parried ~= "head" then
      ataxiaTemp.kickTarget = "head"
      return "risingkick head"  -- Head needs 2+ hits, kick can help
    elseif headHits == 1 and parried ~= "head" then
      -- One hit preps head - kick does it, staff does other things
      ataxiaTemp.kickTarget = "head"
      return "risingkick head"
    else
      -- Head prepped or parried → hit torso
      ataxiaTemp.kickTarget = "torso"
      return "risingkick torso"
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

    if leftHits > 0 and parried ~= "left leg" then
      ataxiaTemp.kickTarget = "left leg"
      return "flashheel left"
    elseif rightHits > 0 and parried ~= "right leg" then
      ataxiaTemp.kickTarget = "right leg"
      return "flashheel right"
    else
      ataxiaTemp.kickTarget = "left leg"  -- Both prepped, just hit one
      return "flashheel left"
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
  -- Tykonos's risingkick can hit head - coordinate with kick via kickTarget

  local leftHits = shikudo.hitsToPrep("left leg", "thrust")
  local rightHits = shikudo.hitsToPrep("right leg", "thrust")
  local headHits = shikudo.hitsToPrep("head", "thrust")
  local kickHitsHead = ataxiaTemp.kickTarget == "head"

  -- If all prepped, use LIGHT or sweep
  if leftHits == 0 and rightHits == 0 and headHits == 0 then
    if not tAffs.prone then
      if slot == 1 then
        return "sweep"  -- Sweep uses both arm balances
      else
        return nil  -- No second staff with sweep
      end
    else
      if slot == 1 then
        return "thrust light torso"
      else
        return "thrust light head"
      end
    end
  end

  if slot == 1 then
    -- LEGS first
    if leftHits >= 2 and parried ~= "left leg" then
      return "thrust left leg"
    elseif leftHits == 1 and parried ~= "left leg" then
      return "thrust left leg"
    elseif rightHits >= 2 and parried ~= "right leg" then
      return "thrust right leg"
    elseif rightHits == 1 and parried ~= "right leg" then
      return "thrust right leg"

    -- HEAD
    elseif headHits >= 2 and parried ~= "head" then
      return "thrust head"
    elseif headHits == 1 then
      if kickHitsHead then
        return "thrust light torso"  -- Kick preps head
      else
        return "thrust head"
      end
    else
      return "thrust light torso"
    end

  else  -- slot == 2
    if rightHits >= 2 and parried ~= "right leg" then
      return "thrust right leg"
    elseif leftHits == 1 and rightHits > 0 and parried ~= "right leg" then
      return "thrust right leg"  -- Slot 1 did left, slot 2 does right
    elseif rightHits == 1 and leftHits > 0 and parried ~= "left leg" then
      return "thrust left leg"
    elseif leftHits == 1 or rightHits == 1 then
      -- Slot 1 prepped a leg → do head or torso
      if headHits > 0 and parried ~= "head" then
        return "thrust head"
      else
        return "thrust light torso"
      end
    elseif headHits >= 2 and parried ~= "head" then
      return "thrust head"
    elseif headHits == 1 then
      return "thrust light torso"  -- Slot 1 or kick prepped head
    else
      return "thrust light torso"
    end
  end
end

function shikudo.selectRainStaff(slot, parried)
  -- Rain: KURO (legs), HIRU (head), RUKU (arms/torso)
  -- Rain's frontkick hits ARMS, so staff has 2 slots for legs/head

  -- CORE: How many hits until each limb is prepped?
  local leftHits = shikudo.hitsToPrep("left leg", "kuro")
  local rightHits = shikudo.hitsToPrep("right leg", "kuro")
  local headHits = shikudo.hitsToPrep("head", "hiru")  -- Rain uses hiru for head

  if slot == 1 then
    -- LEGS: Apply hitsToPrep logic
    if leftHits >= 2 and parried ~= "left leg" then
      return "kuro left"  -- Needs 2+ hits, can use slot 1
    elseif leftHits == 1 and parried ~= "left leg" then
      return "kuro left"  -- One hit preps it, slot 2 will do something else
    elseif rightHits >= 2 and parried ~= "right leg" then
      return "kuro right"
    elseif rightHits == 1 and parried ~= "right leg" then
      return "kuro right"

    -- HEAD: If legs prepped, work on head
    elseif leftHits == 0 and rightHits == 0 then
      if headHits >= 1 and parried ~= "head" then
        return "hiru"  -- Head needs work
      else
        -- All prepped → afflictions
        if not tAffs.slickness then
          return "ruku light torso"
        else
          return "hiru light"
        end
      end
    else
      return "hiru light"
    end

  else  -- slot == 2
    -- Check what slot 1 did and adjust
    if rightHits >= 2 and parried ~= "right leg" then
      return "kuro right"  -- Needs 2+ hits
    elseif leftHits == 1 and rightHits > 0 and parried ~= "right leg" then
      -- Slot 1 prepped left leg → slot 2 works on right
      return "kuro right"
    elseif rightHits == 1 and leftHits > 0 and parried ~= "left leg" then
      -- Slot 1 prepped right leg → slot 2 works on left
      return "kuro left"
    elseif leftHits == 1 or rightHits == 1 then
      -- Slot 1 prepped a leg, slot 2 does affliction/head
      if headHits > 0 and parried ~= "head" then
        return "hiru"
      elseif not tAffs.slickness then
        return "ruku torso"
      elseif not tAffs.clumsiness then
        return "ruku left"
      else
        return "hiru light"
      end
    elseif leftHits == 0 and rightHits == 0 then
      -- Both legs prepped
      if headHits >= 2 and parried ~= "head" then
        return "hiru"
      elseif headHits == 1 then
        -- Slot 1 hit head → slot 2 does affliction
        if not tAffs.slickness then
          return "ruku torso"
        elseif not tAffs.clumsiness then
          return "ruku left"
        else
          return "hiru light"
        end
      else
        -- Head prepped too
        if not tAffs.slickness then
          return "ruku light torso"
        else
          return "hiru light"
        end
      end
    else
      return "hiru light"
    end
  end
end

function shikudo.selectOakStaff(slot, parried)
  -- Oak: KURO (legs), NERVESTRIKE (head), LIVESTRIKE (torso), RUKU
  -- Oak's risingkick can hit HEAD - coordinate with kick via kickTarget

  -- CORE: How many hits until each limb is prepped?
  local leftHits = shikudo.hitsToPrep("left leg", "kuro")
  local rightHits = shikudo.hitsToPrep("right leg", "kuro")
  local headHitsNeeded = shikudo.hitsToPrep("head", "nervestrike")

  -- Check if kick is hitting head (set by selectKick)
  local kickHitsHead = ataxiaTemp.kickTarget == "head"

  if slot == 1 then
    -- LEGS: If not prepped, continue leg work
    if leftHits > 0 and parried ~= "left leg" then
      return "kuro left"
    elseif rightHits > 0 and parried ~= "right leg" then
      return "kuro right"

    -- HEAD: Apply hitsToPrep logic, accounting for kick
    elseif headHitsNeeded >= 3 and parried ~= "head" then
      return "nervestrike"  -- Needs 3+, all slots can hit
    elseif headHitsNeeded == 2 and parried ~= "head" then
      return "nervestrike"  -- Needs 2, staff1 can hit (staff2 may vary)
    elseif headHitsNeeded == 1 then
      if kickHitsHead then
        -- Kick already preps it → staff does something else
        if not tAffs.asthma then return "livestrike" end
        if not tAffs.clumsiness then return "ruku left" end
        return "nervestrike light"
      else
        -- Kick missed head → staff1 preps it
        return "nervestrike"
      end
    elseif headHitsNeeded == 0 then
      if not tAffs.asthma then return "livestrike light" end
      return "nervestrike light"
    else
      return "nervestrike light"
    end

  else  -- slot == 2
    if rightHits > 0 and parried ~= "right leg" then
      return "kuro right"
    elseif leftHits > 0 and parried ~= "left leg" then
      return "kuro left"

    -- HEAD: Account for both kick and staff1
    elseif headHitsNeeded >= 3 and parried ~= "head" then
      return "nervestrike"  -- All 3 slots can hit
    elseif headHitsNeeded == 2 then
      if kickHitsHead then
        return "nervestrike"  -- Kick + staff1 = 2 hits, staff2 can help
      else
        -- Only staff1 hit head → staff2 does something else
        if not tAffs.asthma then return "livestrike" end
        if not tAffs.clumsiness then return "ruku left" end
        return "nervestrike light"
      end
    elseif headHitsNeeded == 1 then
      -- One of kick or staff1 prepped it → staff2 must do something else
      if not tAffs.asthma then return "livestrike" end
      if not tAffs.clumsiness then return "ruku left" end
      if not tAffs.slickness then return "ruku torso" end
      return "nervestrike light"
    elseif headHitsNeeded == 0 then
      if not tAffs.asthma then return "livestrike light" end
      if not tAffs.clumsiness then return "ruku left" end
      return "nervestrike light"
    else
      return "nervestrike light"
    end
  end
end

function shikudo.selectGaitalStaff(slot, parried)
  -- Gaital: NEEDLE (head/windpipe), SWEEP (prone), KURO (legs)
  -- SWEEP uses BOTH arm balances - only kick allowed with sweep!
  -- Kill sequence:
  --   1. sweep + flashheel (prones + breaks one leg)
  --   2. spinkick + needle + needle (breaks head + windpipe)
  --   3. dispatch

  local ll = shikudo.getLimbDamage("left leg")
  local rl = shikudo.getLimbDamage("right leg")
  local h = shikudo.getLimbDamage("head")

  local headBroken = (h >= 100 or tAffs.damagedhead)
  local hasWindpipe = (tAffs.damagedwindpipe or tAffs.crushedthroat)
  local legsBroken = (ll >= 100 or rl >= 100)
  local bothLegsPrepped = shikudo.areBothLegsPrepped()
  local headPrepped = shikudo.isDynamicHeadPrepped()

  -- PHASE 1: Not prone yet → SWEEP (uses both arms, kick breaks leg)
  if not tAffs.prone and bothLegsPrepped and headPrepped then
    if slot == 1 then
      return "sweep"  -- Prones target, kick (flashheel) breaks leg
    else
      return nil  -- SWEEP uses both arm balances - no second staff!
    end
  end

  -- PHASE 2: Prone + at least one leg broken → head + windpipe
  if tAffs.prone and legsBroken then
    if slot == 1 then
      if not headBroken then
        return "needle"  -- Head damage + windpipe (spinkick also hits head)
      elseif not hasWindpipe then
        return "needle"  -- Need windpipe
      else
        return "needle"  -- Keep pressure
      end
    else
      return "needle"  -- Double needle for windpipe
    end
  end

  -- PHASE 2b: Prone but legs not broken yet - break them
  if tAffs.prone and not legsBroken then
    if slot == 1 then
      if ll < 100 and parried ~= "left leg" then return "kuro left" end
      return "kuro right"
    else
      if rl < 100 and parried ~= "right leg" then return "kuro right" end
      return "kuro left"
    end
  end

  -- Fallback: build toward kill conditions
  if slot == 1 then
    if not tAffs.prone then return "sweep" end
    return "needle"
  else
    -- If we returned sweep in slot 1, we shouldn't be here
    return "needle"
  end
end

function shikudo.selectWillowStaff(slot, parried)
  -- Willow: DART (fast), HIRU (head), HIRAKU (head)
  -- Willow's flashheel hits LEGS - coordinate with kick via kickTarget

  local leftHits = shikudo.hitsToPrep("left leg", "flashheel")  -- Kick does legs
  local rightHits = shikudo.hitsToPrep("right leg", "flashheel")
  local headHits = shikudo.hitsToPrep("head", "hiru")
  local kickHitsLeg = ataxiaTemp.kickTarget and ataxiaTemp.kickTarget:find("leg")

  if slot == 1 then
    -- HEAD: Primary focus in Willow (staff does head, kick does legs)
    if headHits >= 2 and parried ~= "head" then
      return "hiru"
    elseif headHits == 1 and parried ~= "head" then
      return "hiru"  -- Slot 2 will do something else
    elseif headHits == 0 then
      -- Head prepped, do torso or wait
      return "dart torso"
    else
      return "dart torso"
    end

  else  -- slot == 2
    if headHits >= 2 and parried ~= "head" then
      return "hiraku"  -- Continue head work
    elseif headHits == 1 then
      -- Slot 1 prepped head → do something else
      return "dart torso"
    else
      return "dart torso"
    end
  end
end

function shikudo.selectMaelstromStaff(slot, parried)
  -- Maelstrom: RUKU, LIVESTRIKE, JINZUKU, SWEEP
  -- Maelstrom is more affliction-focused, less limb prep
  -- Kick (risingkick) hits head

  -- Check for sweep conditions (uses both arms, only kick allowed)
  if not tAffs.prone and shikudo.areBothLegsPrepped() and shikudo.isDynamicHeadPrepped() then
    if slot == 1 then
      return "sweep"
    else
      return nil  -- Sweep uses both arm balances
    end
  end

  -- Affliction priority
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
      return "livestrike light"
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
