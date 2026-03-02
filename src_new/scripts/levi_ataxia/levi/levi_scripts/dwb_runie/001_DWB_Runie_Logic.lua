--[[mudlet
type: script
name: DWB Runie Logic
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- RuneWarden
- DWB Runie
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
===============================================================================
                    RUNEWARDEN DWB UNIFIED OFFENSE
===============================================================================

KILL PATHS:

  TORSO DAMAGE (rwtorso):
    Prep legs + torso → break legs (expend → prone) → assault torso (flails)
    → morningstar pressure → assault torso again → repeat until dead
    FORK: If target RESTOREs torso → pivot to skull fractures → pulp

  HEAD PULP (rwpulp):
    Prep head + legs → break legs (expend → prone) → break head
    → assault head (7 mom, mangles) → skull fractures → pulp

  GROUP (rwgroup):
    Prone + torso damage for team coordination

RUNE SETUP (per weapon):
  sketch nairat on each morningstar and each flail
  sketch configuration wielded isaz wunjo sowulu (on each weapon)
  empower priority set isaz wunjo sowulu (sent before each attack)

PARRY HANDLING (all modes):
  A. 2+ momentum → doublewhirl torso/head expend left_arm expend
  B. 1 momentum  → doublewhirl left_arm expend <unprepped non-parried limb>
  C. 0 momentum  → doublewhirl (untargeted, generate momentum)
===============================================================================
]]--

DWBWhirlDamage = DWBWhirlDamage or 0

dwbRunie = dwbRunie or {}

-------------------------------------------------------------------------------
-- CONFIG (editable)
-------------------------------------------------------------------------------

dwbRunie.config = dwbRunie.config or {
  weapons = {
    morningstar = { left = "morningstar511732", right = "morningstar511735" },
    flail       = { left = "flail343168",       right = "flail408566"      },
  },
  empower = "isaz wunjo sowulu",
  prepThreshold       = 99.9,
  breakThreshold      = 100,
  bisectThreshold     = 34,
  skullFracturesForPulp = 5,
}

-------------------------------------------------------------------------------
-- STATE (per-fight, auto-reset on target change)
-------------------------------------------------------------------------------

dwbRunie.state = dwbRunie.state or {
  mode       = "torso",
  lastTarget = nil,
}

-------------------------------------------------------------------------------
-- MODE SWITCHING
-------------------------------------------------------------------------------

function dwbRunie.setMode(mode)
  dwbRunie.state.mode = mode
  ataxiaEcho("DWB Runie mode: " .. mode:upper())
end

function dwbRunie.status()
  local st = dwbRunie.state
  local mom = dwbRunie.getMomentum()
  local sp = ataxia.settings.separator

  ataxiaEcho("=== DWB Runie Status ===")
  ataxiaEcho("Mode: " .. (st.mode or "torso"):upper())
  ataxiaEcho("Momentum: " .. mom)

  if target and lb and lb[target] and lb[target].hits then
    local limbs = {"left leg", "right leg", "head", "torso", "left arm", "right arm"}
    for _, limb in ipairs(limbs) do
      local dmg = dwbRunie.getLimbDamage(limb)
      local status = ""
      if dwbRunie.isBroken(limb) then status = " [BROKEN]"
      elseif dwbRunie.isPrepped(limb) then status = " [PREPPED]"
      elseif dwbRunie.isDWPrepped(limb) then status = " [DW-PREPPED]"
      end
      ataxiaEcho(string.format("  %-10s %5.1f%%%s", limb, dmg, status))
    end
    if ataxiaTemp.fractures then
      ataxiaEcho("  Skull fractures: " .. (ataxiaTemp.fractures.skullfractures or 0))
      ataxiaEcho("  Cracked ribs:    " .. (ataxiaTemp.fractures.crackedribs or 0))
    end
  else
    ataxiaEcho("  No target or no limb data")
  end
end

-------------------------------------------------------------------------------
-- HELPERS: LIMB DAMAGE
-------------------------------------------------------------------------------

function dwbRunie.getLimbDamage(limb)
  if not target or not lb or not lb[target] or not lb[target].hits then return 0 end
  return tonumber(lb[target].hits[limb]) or 0
end

function dwbRunie.getWhirlDamage()
  return tonumber(DWBWhirlDamage) or 0
end

-- One whirl hit would break this limb (single weapon hit)
function dwbRunie.isPrepped(limb)
  local dmg = dwbRunie.getLimbDamage(limb)
  local whirl = dwbRunie.getWhirlDamage()
  if whirl <= 0 then return false end
  return (dmg + whirl >= dwbRunie.config.prepThreshold) and not dwbRunie.isBroken(limb)
end

-- Doublewhirl (both weapons on same limb) would break this limb
function dwbRunie.isDWPrepped(limb)
  local dmg = dwbRunie.getLimbDamage(limb)
  local whirl2 = dwbRunie.getWhirlDamage() * 2
  if whirl2 <= 0 then return false end
  return (dmg + whirl2 >= dwbRunie.config.prepThreshold) and not dwbRunie.isBroken(limb)
end

function dwbRunie.isBroken(limb)
  local dmg = dwbRunie.getLimbDamage(limb)
  if dmg >= dwbRunie.config.breakThreshold then return true end
  local affName = "damaged" .. limb:gsub(" ", "")
  return dwbRunie.hasAff(affName)
end

function dwbRunie.isMangled(limb)
  if dwbRunie.getLimbDamage(limb) >= 200 then return true end
  if limb == "head" then return dwbRunie.hasAff("concussion") end
  return false
end

-------------------------------------------------------------------------------
-- HELPERS: COMBAT STATE
-------------------------------------------------------------------------------

function dwbRunie.getMomentum()
  return tonumber(ataxia.vitals.class) or 0
end

function dwbRunie.canAssaultHead()
  return dwbRunie.getMomentum() >= 7
end

function dwbRunie.canAssaultTorso()
  return dwbRunie.getMomentum() >= 3
end

function dwbRunie.canDoubleAssaultTorso()
  return dwbRunie.getMomentum() >= 6
end

function dwbRunie.canPulp()
  if not dwbRunie.hasAff("prone") then return false end
  if dwbRunie.isMangled("head") then return true end
  if ataxiaTemp.fractures and (ataxiaTemp.fractures.skullfractures or 0) >= dwbRunie.config.skullFracturesForPulp then
    return true
  end
  return false
end

function dwbRunie.isProne()
  return dwbRunie.hasAff("prone")
end

function dwbRunie.isParried()
  return ataxiaTemp.parriedLimb and ataxiaTemp.parriedLimb ~= "none"
end

function dwbRunie.getParriedLimb()
  return ataxiaTemp.parriedLimb or "none"
end

function dwbRunie.isParryDisabled()
  return dwbRunie.hasAff("numbedleftarm")
end

function dwbRunie.useBisect()
  return ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= dwbRunie.config.bisectThreshold
end

-------------------------------------------------------------------------------
-- HELPERS: AFFLICTION TRACKING (V3 → V2 → V1)
-------------------------------------------------------------------------------

function dwbRunie.hasAff(aff)
  -- V3 system (highest priority - probability-based)
  if affConfigV3 and affConfigV3.enabled then
    return haveAffV3(aff)
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

-------------------------------------------------------------------------------
-- HELPERS: COMMAND BUILDING
-------------------------------------------------------------------------------

function dwbRunie.wield(weaponType)
  local w = dwbRunie.config.weapons[weaponType]
  if not w then return "" end
  return "wield left " .. w.left .. ";wield right " .. w.right
end

function dwbRunie.empower()
  return "empower priority set " .. dwbRunie.config.empower
end

function dwbRunie.wieldAndEmpower(weaponType)
  return dwbRunie.wield(weaponType) .. ";" .. dwbRunie.empower()
end

-- Build prefix: combatQueue + wield + empower
function dwbRunie.buildPrefix(weaponType)
  return combatQueue() .. dwbRunie.wieldAndEmpower(weaponType) .. ";"
end

function dwbRunie.sendAttack(atk)
  if not atk or atk == "" then return end
  if table.contains(ataxia.playersHere, target) then
    if not engaged then
      send("queue addclear freestand " .. atk .. ";engage " .. target)
    else
      send("queue addclear freestand " .. atk)
    end
  end
end

-------------------------------------------------------------------------------
-- HELPERS: LIMB SELECTION
-------------------------------------------------------------------------------

-- Returns the limb with lower damage (prep that one first)
function dwbRunie.lowerDamageLimb(limbA, limbB)
  return dwbRunie.getLimbDamage(limbA) <= dwbRunie.getLimbDamage(limbB) and limbA or limbB
end

-- Get list of limbs from the prep set that still need prep (not prepped, not broken)
function dwbRunie.getUnpreppedLimbs(prepLimbs)
  local unprepped = {}
  for _, limb in ipairs(prepLimbs) do
    if not dwbRunie.isPrepped(limb) and not dwbRunie.isBroken(limb) then
      table.insert(unprepped, limb)
    end
  end
  return unprepped
end

-- Check if all prep targets are prepped or broken
function dwbRunie.allPrepped(prepLimbs)
  for _, limb in ipairs(prepLimbs) do
    if not dwbRunie.isPrepped(limb) and not dwbRunie.isBroken(limb) then
      return false
    end
  end
  return true
end

-- Pick unprepped limb that isn't the parried one
function dwbRunie.pickUnparriedUnprepped(prepLimbs)
  local parried = dwbRunie.getParriedLimb()
  local unprepped = dwbRunie.getUnpreppedLimbs(prepLimbs)
  for _, limb in ipairs(unprepped) do
    if limb ~= parried then return limb end
  end
  -- All unprepped limbs are parried — fall back to any unprepped
  if #unprepped > 0 then return unprepped[1] end
  -- All prepped — fall back to a filler limb
  return "right arm"
end

-- Pick a filler limb (not in the prep set, not parried)
function dwbRunie.pickFillerLimb(prepLimbs)
  local parried = dwbRunie.getParriedLimb()
  local fillers = {"left arm", "right arm"}
  for _, limb in ipairs(fillers) do
    local inPrepSet = false
    for _, pl in ipairs(prepLimbs) do
      if pl == limb then inPrepSet = true; break end
    end
    if not inPrepSet and limb ~= parried then return limb end
  end
  return "right arm"
end

-------------------------------------------------------------------------------
-- SHARED: PARRY RESPONSE (used by all modes during PREP)
-------------------------------------------------------------------------------

function dwbRunie.buildParryResponse(prepLimbs, primaryExpendLimb)
  local mom = dwbRunie.getMomentum()
  local sp = ";"
  local pre = dwbRunie.buildPrefix("morningstar")

  if mom >= 2 then
    -- Case A: 2+ momentum → expend primary limb + expend left arm (disable parry)
    return pre .. "doublewhirl " .. target .. " " .. primaryExpendLimb .. " expend left arm expend;sizeup " .. target .. ";assess " .. target
  elseif mom >= 1 then
    -- Case B: 1 momentum → left arm expend + unprepped non-parried limb
    local fillLimb = dwbRunie.pickUnparriedUnprepped(prepLimbs)
    return pre .. "doublewhirl " .. target .. " left arm expend " .. fillLimb .. ";sizeup " .. target .. ";assess " .. target
  else
    -- Case C: 0 momentum → untargeted doublewhirl to generate momentum
    return pre .. "doublewhirl " .. target .. ";sizeup " .. target .. ";assess " .. target
  end
end

-------------------------------------------------------------------------------
-- SHARED: PREP PHASE (used by torso + pulp modes)
-------------------------------------------------------------------------------

function dwbRunie.buildPrepAttack(prepLimbs, primaryExpendLimb)
  local pre = dwbRunie.buildPrefix("morningstar")

  -- Handle parry
  if dwbRunie.isParried() then
    return dwbRunie.buildParryResponse(prepLimbs, primaryExpendLimb)
  end

  -- Normal prep: pick 2 limbs that need work
  local unprepped = dwbRunie.getUnpreppedLimbs(prepLimbs)

  if #unprepped >= 2 then
    -- Two limbs need prep — hit both, lower damage first
    local limb1 = dwbRunie.lowerDamageLimb(unprepped[1], unprepped[2])
    local limb2 = (limb1 == unprepped[1]) and unprepped[2] or unprepped[1]
    return pre .. "doublewhirl " .. target .. " " .. limb1 .. " " .. limb2 .. ";sizeup " .. target .. ";assess " .. target
  elseif #unprepped == 1 then
    -- One limb needs prep — pair with a filler
    local filler = dwbRunie.pickFillerLimb(prepLimbs)
    return pre .. "doublewhirl " .. target .. " " .. unprepped[1] .. " " .. filler .. ";sizeup " .. target .. ";assess " .. target
  else
    -- All prepped (shouldn't reach here if allPrepped check is done first)
    return nil
  end
end

-------------------------------------------------------------------------------
-- SHARED: BREAK PHASE (legs + disable parry)
-------------------------------------------------------------------------------

function dwbRunie.buildBreakSequence(targetLimb)
  local pre = dwbRunie.buildPrefix("morningstar")
  local mom = dwbRunie.getMomentum()

  -- Step 1: Disable parry if needed
  if not dwbRunie.isParryDisabled() and mom >= 1 then
    -- Expend left arm to disable parry, pair with a prepped leg
    local legTarget = dwbRunie.isPrepped("left leg") and "left leg" or "right leg"
    return pre .. "doublewhirl " .. target .. " left arm expend " .. legTarget .. ";sizeup " .. target .. ";assess " .. target
  end

  -- Step 2: Double break legs (parry disabled or no momentum for it)
  local legsNeedBreak = not dwbRunie.isBroken("left leg") or not dwbRunie.isBroken("right leg")
  if legsNeedBreak then
    -- Handle clumsiness
    local disciplineCmd = ataxia.afflictions.clumsiness and "discipline;" or ""
    return pre .. disciplineCmd .. "doublewhirl " .. target .. " right leg expend left leg;sizeup " .. target .. ";assess " .. target
  end

  -- Step 3: Break target limb (head or torso) — target should be prone now
  if not dwbRunie.isBroken(targetLimb) then
    local filler = dwbRunie.pickFillerLimb({targetLimb, "left leg", "right leg"})
    return pre .. "doublewhirl " .. target .. " " .. targetLimb .. " " .. filler .. ";sizeup " .. target .. ";assess " .. target
  end

  return nil -- All broken, proceed to execute
end

-------------------------------------------------------------------------------
-- SHARED: SKULL FRACTURE LOOP
-------------------------------------------------------------------------------

function dwbRunie.buildSkullFractureAttack()
  local pre = dwbRunie.buildPrefix("morningstar")
  local mom = dwbRunie.getMomentum()

  if mom >= 2 then
    return pre .. "doublewhirl " .. target .. " head expend head expend;sizeup " .. target .. ";assess " .. target
  elseif mom >= 1 then
    return pre .. "doublewhirl " .. target .. " head expend head;sizeup " .. target .. ";assess " .. target
  else
    return pre .. "doublewhirl " .. target .. " head head;sizeup " .. target .. ";assess " .. target
  end
end

-------------------------------------------------------------------------------
-- MODE: TORSO DAMAGE
-------------------------------------------------------------------------------

function dwbRunie.buildTorsoAttack()
  local prepLimbs = {"left leg", "right leg", "torso"}
  local mom = dwbRunie.getMomentum()

  -- PREP: not all 3 prepped yet
  if not dwbRunie.allPrepped(prepLimbs) then
    return dwbRunie.buildPrepAttack(prepLimbs, "torso")
  end

  -- BREAK: limbs prepped but not all broken
  if not dwbRunie.isBroken("left leg") or not dwbRunie.isBroken("right leg") or not dwbRunie.isBroken("torso") then
    return dwbRunie.buildBreakSequence("torso")
  end

  -- EXECUTE: all broken, target should be prone
  -- RESTORATION FORK: torso restored but legs still broken → skull fractures
  if not dwbRunie.isBroken("torso") and dwbRunie.isBroken("left leg") and dwbRunie.isBroken("right leg") then
    -- Target restored torso — pivot to skull fractures → pulp
    return dwbRunie.buildSkullFractureAttack()
  end

  -- ASSAULT TORSO (flails, highest priority when momentum allows)
  if dwbRunie.isProne() and dwbRunie.isBroken("torso") then
    if dwbRunie.canDoubleAssaultTorso() then
      local pre = dwbRunie.buildPrefix("flail")
      return pre .. "falcon slay " .. target .. ";assault " .. target .. " torso;assault " .. target .. " torso;sizeup " .. target .. ";assess " .. target
    elseif dwbRunie.canAssaultTorso() then
      local pre = dwbRunie.buildPrefix("flail")
      return pre .. "falcon slay " .. target .. ";assault " .. target .. " torso;sizeup " .. target .. ";assess " .. target
    end
  end

  -- MORNINGSTAR PRESSURE (build momentum between assaults)
  local pre = dwbRunie.buildPrefix("morningstar")
  if mom >= 2 then
    return pre .. "doublewhirl " .. target .. " torso expend torso expend;sizeup " .. target .. ";assess " .. target
  elseif mom >= 1 then
    return pre .. "doublewhirl " .. target .. " torso expend torso;sizeup " .. target .. ";assess " .. target
  else
    return pre .. "doublewhirl " .. target .. " torso torso;sizeup " .. target .. ";assess " .. target
  end
end

-------------------------------------------------------------------------------
-- MODE: HEAD PULP
-------------------------------------------------------------------------------

function dwbRunie.buildPulpAttack()
  local prepLimbs = {"left leg", "right leg", "head"}
  local mom = dwbRunie.getMomentum()

  -- PREP: not all 3 prepped yet
  if not dwbRunie.allPrepped(prepLimbs) then
    return dwbRunie.buildPrepAttack(prepLimbs, "head")
  end

  -- BREAK: limbs prepped but not all broken
  if not dwbRunie.isBroken("left leg") or not dwbRunie.isBroken("right leg") or not dwbRunie.isBroken("head") then
    return dwbRunie.buildBreakSequence("head")
  end

  -- EXECUTE: all broken, target should be prone

  -- ASSAULT HEAD (7 momentum → mangles head instantly)
  if dwbRunie.isProne() and dwbRunie.isBroken("head") and not dwbRunie.isMangled("head") then
    if dwbRunie.canAssaultHead() then
      local pre = dwbRunie.buildPrefix("morningstar")
      return pre .. "falcon slay " .. target .. ";assault " .. target .. " head;sizeup " .. target .. ";assess " .. target
    end
  end

  -- SKULL FRACTURE LOOP (build to 5 skull fractures or head already mangled)
  return dwbRunie.buildSkullFractureAttack()
end

-------------------------------------------------------------------------------
-- MODE: GROUP
-------------------------------------------------------------------------------

function dwbRunie.buildGroupAttack()
  -- Group mode: focus on prone + torso damage, party callouts
  local prepLimbs = {"left leg", "right leg", "torso"}

  -- Prep
  if not dwbRunie.allPrepped(prepLimbs) then
    return dwbRunie.buildPrepAttack(prepLimbs, "torso")
  end

  -- Break
  if not dwbRunie.isBroken("left leg") or not dwbRunie.isBroken("right leg") or not dwbRunie.isBroken("torso") then
    return dwbRunie.buildBreakSequence("torso")
  end

  -- Execute: same as torso but with party callout
  if partyrelay and not ataxia.afflictions.aeon then
    send("pt " .. target .. " PRONE + TORSO BROKEN - PILE ON")
  end

  -- Assault or morningstar pressure
  if dwbRunie.isProne() and dwbRunie.isBroken("torso") then
    if dwbRunie.canAssaultTorso() then
      local pre = dwbRunie.buildPrefix("flail")
      return pre .. "falcon slay " .. target .. ";assault " .. target .. " torso;sizeup " .. target .. ";assess " .. target
    end
  end

  local pre = dwbRunie.buildPrefix("morningstar")
  local mom = dwbRunie.getMomentum()
  if mom >= 2 then
    return pre .. "doublewhirl " .. target .. " torso expend torso expend;sizeup " .. target .. ";assess " .. target
  elseif mom >= 1 then
    return pre .. "doublewhirl " .. target .. " torso expend torso;sizeup " .. target .. ";assess " .. target
  else
    return pre .. "doublewhirl " .. target .. " torso torso;sizeup " .. target .. ";assess " .. target
  end
end

-------------------------------------------------------------------------------
-- MAIN DISPATCH
-------------------------------------------------------------------------------

function dwbRunie.dispatch()
  -- Target change detection
  if dwbRunie.state.lastTarget ~= target then
    dwbRunie.state.lastTarget = target
  end

  -- Safety checks
  if not target or target == "" then
    ataxiaEcho("No target set!")
    return
  end

  if not table.contains(ataxia.playersHere, target) then return end

  -- Initialize limb counter if needed
  if not lb[target] then lb[target] = { hits = {} } end
  if not lb[target].hits then lb[target].hits = {} end
  for _, limb in ipairs({"left leg", "right leg", "left arm", "right arm", "head", "torso"}) do
    lb[target].hits[limb] = lb[target].hits[limb] or 0
  end

  -- Initialize fractures if needed
  if not ataxiaTemp.fractures then
    ataxiaTemp.fractures = { skullfractures = 0, wristfractures = 0, torntendons = 0, crackedribs = 0 }
  end

  -- Lock/aff tracking
  getLockingAffliction()
  checkTargetLocks()

  local atk = nil

  -- Emergency: instant shield
  if myinstantcath == true then
    atk = combatQueue() .. "touch shield"
    dwbRunie.sendAttack(atk)
    return
  end

  -- Bisect: low health finish
  if not dwbRunie.hasAff("shield") and dwbRunie.useBisect() then
    atk = combatQueue() .. "sizeup " .. target .. ";wield bastard;bisect " .. target .. ";assess " .. target
    dwbRunie.sendAttack(atk)
    return
  end

  -- Pulp: shared across all modes (mangled head or 5+ skull fractures + prone)
  if not dwbRunie.hasAff("shield") and dwbRunie.canPulp() then
    atk = combatQueue() .. dwbRunie.wieldAndEmpower("morningstar") .. ";dismount;pulp " .. target .. ";sizeup " .. target .. ";assess " .. target
    dwbRunie.sendAttack(atk)
    return
  end

  -- Raze: strip rebounding/shield
  if dwbRunie.hasAff("rebounding") or dwbRunie.hasAff("shield") then
    atk = combatQueue() .. dwbRunie.wieldAndEmpower("morningstar") .. ";falcon track " .. target .. ";falcon slay " .. target .. ";fracture " .. target .. ";sizeup " .. target .. ";assess " .. target
    dwbRunie.sendAttack(atk)
    return
  end

  -- Mode routing
  local mode = dwbRunie.state.mode or "torso"

  if mode == "torso" then
    atk = dwbRunie.buildTorsoAttack()
  elseif mode == "pulp" then
    atk = dwbRunie.buildPulpAttack()
  elseif mode == "group" then
    atk = dwbRunie.buildGroupAttack()
  else
    atk = dwbRunie.buildTorsoAttack()
  end

  if atk then
    dwbRunie.sendAttack(atk)
  end
end
