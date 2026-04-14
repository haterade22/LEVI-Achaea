--[[mudlet
type: script
name: CC_Shikudo_GodMode
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

--[[
================================================================================
SHIKUDO GOD MODE (5-Limb Dispatch)
================================================================================

Preps ALL 5 limbs (both legs, both arms, head) to 92%+ then executes a
3-combo sequence that breaks everything, followed by dispatch or lock fork.

HYPERFOCUS: Always head. Checked and set at start of each tick.

BUILD PHASE (Rain/Oak/Gaital):
  Prep both legs, both arms, head to 92+.
  Light any hit that would break a prepped limb.
  Aff priority: 2-aff hits (kuro@12/ruku@10+), clumsiness,
  lethargy, leg prep, arm prep, filler.

EXECUTE (Gaital, all 5 at 92+):
  Combo 1: sweep + flashheel left  -> prone, left leg broken
  Combo 2: ruku left + ruku right + flashheel right
           -> both arms broken, right leg broken
  Combo 3: needle + [smart staff] + flashheel left
           -> head broken (needle+hyperfocus), crushedthroat, aff

COMBO 4 DECISION:
  prone + damagedhead + crushedthroat -> DISPATCH
  crushedthroat cured + 3+ lock affs  -> Rain, lock fork
  target <= 38% HP + kata >= 5 -> MAELSTROM + crescent override

Usage: shikudo.setMode("godmode") then press sk key

REQUIRED READING:
  - .claude/classes/monk.md (class mechanics)
  - .claude/classes/lock_types.md (lock definitions)
================================================================================
]]--

shikudo = shikudo or {}
shikudo.godmode = shikudo.godmode or {}

-- ============================================================
--  CONSTANTS
-- ============================================================
shikudo.godmode.PREP_THRESHOLD = 92
shikudo.godmode.LOCK_FORK_MIN_AFFS = 3
shikudo.godmode.MAELSTROM_HP_THRESHOLD = 38

-- ============================================================
--  STATE (computed fresh each tick by calcLimbs)
-- ============================================================
local gm = {}  -- local state table, reset at top of run() every tick

-- Lock affs constant (hoisted out of calcLimbs for performance)
local GM_LOCK_AFFS = {
  "slickness", "asthma", "addiction", "weariness",
  "paralysis", "anorexia", "impatience", "confusion"
}

-- ============================================================
--  SECTION 1: LIMB DAMAGE HELPER
--  Reads from lb[target].hits (the canonical source fed by triggers)
--  Maps short keys (LL, RL, LA, RA, H, T) to long names
-- ============================================================
local LIMB_NAMES = {
  LL = "left leg", RL = "right leg",
  LA = "left arm", RA = "right arm",
  H = "head", T = "torso"
}

local function getLimb(key)
  if not target or not lb or not lb[target] or not lb[target].hits then
    return 0
  end
  return lb[target].hits[LIMB_NAMES[key]] or 0
end

-- ============================================================
--  SECTION 2: LIMB STATE CALCULATOR
-- ============================================================
function shikudo.godmode.calcLimbs()
  local ld = ataxiaTables.limbData
  local thresh = shikudo.godmode.PREP_THRESHOLD

  -- Cache limb values for this tick
  gm.LL = getLimb("LL")
  gm.RL = getLimb("RL")
  gm.LA = getLimb("LA")
  gm.RA = getLimb("RA")
  gm.H  = getLimb("H")
  gm.T  = getLimb("T")

  -- Arms: prepped = at threshold, ruku would break
  gm.laRUK  = (gm.LA + ld.shikRuku >= 100)
  gm.raRUK  = (gm.RA + ld.shikRuku >= 100)
  gm.laPREP = (gm.LA >= thresh)
  gm.raPREP = (gm.RA >= thresh)

  -- Legs: prepped = one hit breaks, not already broken
  gm.llKUR   = (gm.LL + ld.shikKuro >= 100) and not tAffs.damagedleftleg
  gm.rlKUR   = (gm.RL + ld.shikKuro >= 100) and not tAffs.damagedrightleg
  gm.llFLASH = (gm.LL + ld.shikFlashheel >= 100) and not tAffs.damagedleftleg
  gm.rlFLASH = (gm.RL + ld.shikFlashheel >= 100) and not tAffs.damagedrightleg

  -- Head: needle breaks at 92+ with hyperfocus head
  gm.hNEED  = (gm.H + ld.shikNeedle >= 100)
  gm.hPREP  = (gm.H >= 86)
  gm.hNERV  = (gm.H + ld.shikNervestrike >= 100)
  gm.hHIRU  = (gm.H + ld.shikHiru >= 100)
  gm.hHIRA  = (gm.H + ld.shikHiraku >= 100)
  gm.hHIHI  = (gm.H + ld.shikHiru + ld.shikHiraku >= 100)
  -- Combined risingkick+nervestrike would break head prematurely
  gm.hNERVRIS = (gm.H + ld.shikNervestrike + ld.shikRisingkick >= 100)

  -- Broken limb checks (broken = possibleStates, damaged/mangled = tAffs only)
  gm.bothLegsBroken = (haveAff("brokenleftleg") or tAffs.damagedleftleg)
                   and (haveAff("brokenrightleg") or tAffs.damagedrightleg)
  gm.bothArmsBroken = (haveAff("brokenleftarm") or tAffs.damagedleftarm)
                   and (haveAff("brokenrightarm") or tAffs.damagedrightarm)

  -- All 5 prepped: ready to execute
  gm.executeReady = gm.llFLASH and gm.rlFLASH
                  and gm.laPREP and gm.raPREP
                  and gm.hPREP

  -- Lock affs check
  local lockCount = 0
  for _, aff in ipairs(GM_LOCK_AFFS) do
    if haveAff(aff) then lockCount = lockCount + 1 end
  end
  gm.lockCount = lockCount
  gm.lockForkReady = gm.bothArmsBroken and lockCount >= shikudo.godmode.LOCK_FORK_MIN_AFFS

  -- Low HP override
  gm.lowHp = ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= shikudo.godmode.MAELSTROM_HP_THRESHOLD
end

-- ============================================================
--  SECTION 3: LIGHT/NO-LIGHT CALCULATOR
--  Only protects limbs in BUILD phase. Never called in execute.
-- ============================================================
local function shouldLight(limb, damageValue, simulated)
  local current = (gm[limb] or 0) + (simulated or 0)
  if limb == "LL" then
    return (current + damageValue >= 100) and not tAffs.damagedleftleg
  elseif limb == "RL" then
    return (current + damageValue >= 100) and not tAffs.damagedrightleg
  elseif limb == "LA" then
    return (current + damageValue >= 100) and not tAffs.damagedleftarm
  elseif limb == "RA" then
    return (current + damageValue >= 100) and not tAffs.damagedrightarm
  elseif limb == "H" then
    return (current + damageValue >= 100) and gm.hPREP
  end
  return false  -- torso: never light
end

-- ============================================================
--  SECTION 3: FORM-SPECIFIC ATTACK PRIORITIES
-- ============================================================
-- Each prios function sets gm.staff = {} and gm.kick = "none"

-- ── TYKONOS ─────────────────────────────────────────────────
local function tykonosPrios()
  gm.staff = {}
  gm.kick = "none"
  if not haveAff("prone") then table.insert(gm.staff, "sweep") end
  gm.kick = gm.hNERVRIS and "risingkick torso" or "risingkick head"
end

-- ── WILLOW ──────────────────────────────────────────────────
local function willowPrios()
  gm.staff = {}
  gm.kick = "none"
  local ld = ataxiaTables.limbData

  -- Kick: flashheel for leg prep
  if not gm.llFLASH and ataxiaTemp.parriedLimb ~= "left leg" then
    gm.kick = "flashheel left"
  elseif not gm.rlFLASH then
    gm.kick = "flashheel right"
  else
    if not haveAff("prone") then table.insert(gm.staff, "sweep") end
    gm.kick = "spinkick"
  end

  -- Staff: hiru + hiraku for head prep with light guards
  if not gm.hHIHI then
    table.insert(gm.staff, gm.hHIRU and "hiru light" or "hiru")
    table.insert(gm.staff, gm.hHIRA and "hiraku light" or "hiraku")
  else
    table.insert(gm.staff, "hiru light")
    table.insert(gm.staff, "hiraku light")
  end
end

-- ── RAIN ────────────────────────────────────────────────────
local function rainPrios()
  gm.staff = {}
  gm.kick = "none"
  local f = ataxia.vitals.form
  local k = ataxia.vitals.kata
  local ld = ataxiaTables.limbData


  -- LOCK FORK: both arms broken + 3+ lock affs -> push lock
  if gm.lockForkReady then
    gm.kick = "frontkick left"
    local slot1, slot2 = nil, nil
    if not haveAff("weariness") then
      slot1 = "kuro left"
    elseif not haveAff("lethargy") then
      slot1 = "kuro right"
    elseif not haveAff("clumsiness") then
      slot1 = "ruku torso"
    end
    if not haveAff("slickness") and not slot1 then
      slot1 = "ruku torso"
    elseif not haveAff("slickness") then
      slot2 = "ruku torso"
    end
    if not slot1 then slot1 = "kuro left" end
    if not slot2 then slot2 = "kuro right" end
    table.insert(gm.staff, slot1)
    if slot2 then table.insert(gm.staff, slot2) end
    return
  end

  -- Normal build: check prep status
  local allLegsDone = gm.llFLASH and gm.rlFLASH
  local allArmsDone = gm.laPREP and gm.raPREP

  -- All 5 prepped: hold with lights
  if allLegsDone and allArmsDone and gm.hPREP then
    gm.kick = "none"
    if not haveAff("slickness") then
      table.insert(gm.staff, "ruku torso")
    else
      table.insert(gm.staff, gm.hHIRU and "hiru light" or "hiru")
    end
    table.insert(gm.staff, "kuro light left")
    return
  end

  -- Legs and arms prepped but head not yet: hiru for head pressure
  if allLegsDone and allArmsDone and not gm.hPREP then
    gm.kick = "none"
    table.insert(gm.staff, gm.hHIRU and "hiru light" or "hiru")
    table.insert(gm.staff, "kuro light left")
    return
  end

  -- Frontkick: targets arms. Don't kick a prepped arm (kicks can't go light).
  local sim = {}
  local leftSafe  = ataxiaTemp.parriedLimb ~= "left arm" and not gm.laRUK
  local rightSafe = ataxiaTemp.parriedLimb ~= "right arm" and not gm.raRUK
  if leftSafe and (not rightSafe or gm.LA <= gm.RA) then
    gm.kick = "frontkick left"
    sim.LA = (sim.LA or 0) + ld.shikFrontkick
  elseif rightSafe then
    gm.kick = "frontkick right"
    sim.RA = (sim.RA or 0) + ld.shikFrontkick
  else
    gm.kick = "none"
  end

  -- Slot picker helpers
  local function pickKuro()
    if not gm.llKUR and (gm.rlKUR or gm.LL <= gm.RL) then
      local light = shouldLight("LL", ld.shikKuro, sim.LL)
      local s = light and "kuro light left" or "kuro left"
      if not light then sim.LL = (sim.LL or 0) + ld.shikKuro end
      return s
    elseif not gm.rlKUR then
      local light = shouldLight("RL", ld.shikKuro, sim.RL)
      local s = light and "kuro light right" or "kuro right"
      if not light then sim.RL = (sim.RL or 0) + ld.shikKuro end
      return s
    end
    return "kuro light left"
  end

  local function pickRuku()
    if gm.LA <= gm.RA then
      local light = shouldLight("LA", ld.shikRuku, sim.LA)
      local s = light and "ruku light left" or "ruku left"
      if not light then sim.LA = (sim.LA or 0) + ld.shikRuku end
      return s
    else
      local light = shouldLight("RA", ld.shikRuku, sim.RA)
      local s = light and "ruku light right" or "ruku right"
      if not light then sim.RA = (sim.RA or 0) + ld.shikRuku end
      return s
    end
  end

  local slot1, slot2 = nil, nil

  -- Priority 1: kuro@12+ for wea+leth
  if k >= 12 and not haveAff("lethargy") then
    slot1 = pickKuro()
  end
  -- Priority 2: ruku@10+ for clu+hleech
  if k >= 10 and not haveAff("healthleech") then
    if not slot1 then slot1 = pickRuku()
    elseif not slot2 then slot2 = pickRuku() end
  end
  -- Priority 3: clumsiness
  if not haveAff("clumsiness") then
    if not slot1 then slot1 = pickRuku()
    elseif not slot2 then slot2 = pickRuku() end
  end
  -- Priority 4: lethargy
  if not haveAff("lethargy") then
    if not slot1 then slot1 = pickKuro()
    elseif not slot2 and (not slot1 or not slot1:find("kuro")) then
      slot2 = pickKuro()
    end
  end
  -- Priority 5: leg prep
  if not slot1 then slot1 = pickKuro() end
  -- Priority 6: arm prep
  if not slot1 then slot1 = pickRuku() end
  if not slot2 then
    if slot1 and slot1:find("kuro") then
      slot2 = pickRuku()
    elseif slot1 and slot1:find("ruku") then
      slot2 = pickKuro()
    else
      slot2 = pickRuku()
    end
  end
  -- Priority 7: filler
  if not slot1 then slot1 = "ruku torso" end
  if not slot2 then slot2 = gm.hHIRU and "hiru light" or "hiru" end

  table.insert(gm.staff, slot1)
  if slot2 then table.insert(gm.staff, slot2) end
end

-- ── OAK ─────────────────────────────────────────────────────
local function oakPrios()
  gm.staff = {}
  gm.kick = "none"
  local ld = ataxiaTables.limbData

  local allPrepped = gm.llFLASH and gm.rlFLASH and gm.laPREP and gm.raPREP and gm.hPREP

  if allPrepped then
    -- Light only to build kata
    gm.kick = "risingkick torso"
    if not haveAff("paralysis") then
      table.insert(gm.staff, "nervestrike light")
    else
      table.insert(gm.staff, "livestrike light")
    end
    if not haveAff("asthma") then
      table.insert(gm.staff, "livestrike light")
    elseif not haveAff("slickness") then
      table.insert(gm.staff, "ruku torso")
    else
      table.insert(gm.staff, "nervestrike light")
    end
    return
  end

  -- Kick selection with risingkick safety check
  if not gm.hPREP then
    if gm.hNERVRIS then
      -- Combined risingkick+nervestrike would break head: redirect kick to torso
      gm.kick = "risingkick torso"
    else
      gm.kick = "risingkick head"
    end
  else
    gm.kick = "risingkick torso"
  end

  -- Slot 1: nervestrike for head prep
  if not gm.hPREP then
    local light = gm.hNERV  -- nervestrike alone would break head
    table.insert(gm.staff, light and "nervestrike light" or "nervestrike")
  elseif not haveAff("paralysis") then
    local light = shouldLight("H", ld.shikNervestrike, 0)
    table.insert(gm.staff, light and "nervestrike light" or "nervestrike")
  else
    if not haveAff("asthma") then
      table.insert(gm.staff, "livestrike")
    elseif not haveAff("slickness") then
      table.insert(gm.staff, "ruku torso")
    end
  end

  -- Slot 2: leg or arm prep with light guard
  if not gm.llKUR and (gm.rlKUR or gm.LL <= gm.RL) then
    local light = shouldLight("LL", ld.shikKuro, 0)
    table.insert(gm.staff, light and "kuro light left" or "kuro left")
  elseif not gm.rlKUR then
    local light = shouldLight("RL", ld.shikKuro, 0)
    table.insert(gm.staff, light and "kuro light right" or "kuro right")
  elseif not gm.laPREP then
    local light = shouldLight("LA", ld.shikRuku, 0)
    table.insert(gm.staff, light and "ruku light left" or "ruku left")
  elseif not gm.raPREP then
    local light = shouldLight("RA", ld.shikRuku, 0)
    table.insert(gm.staff, light and "ruku light right" or "ruku right")
  elseif not haveAff("asthma") then
    table.insert(gm.staff, "livestrike")
  elseif not haveAff("slickness") then
    table.insert(gm.staff, "ruku torso")
  end
end

-- ── GAITAL ──────────────────────────────────────────────────
-- STATELESS execute: reads game state each tick to determine
-- which combo to fire. No phase tracking needed.
local function gaitalPrios()
  gm.staff = {}
  gm.kick = "none"
  local k = ataxia.vitals.kata
  local ld = ataxiaTables.limbData


  -- LOW HP OVERRIDE: 38% or below -> Maelstrom for crescent
  if gm.lowHp and k >= 5 then
    gm.staff[1] = "maelstrom_override"
    return
  end

  -- DISPATCH: prone + damagedhead + crushedthroat
  if haveAff("prone") and tAffs.damagedhead and haveAff("crushedthroat") then
    gm.staff[1] = "dispatch"
    return
  end

  -- LOCK FORK: both arms broken + 3+ lock affs -> flow Rain
  if gm.lockForkReady then
    gm.staff[1] = "lock_fork"
    return
  end

  -- COMBO 3: prone + both arms broken + right leg broken/damaged
  -- needle + smart jab + flashheel left
  local rightLegBroken = tAffs.damagedrightleg or haveAff("brokenrightleg")
  if haveAff("prone") and gm.bothArmsBroken and rightLegBroken then
    gm.staff = {}
    table.insert(gm.staff, "needle")
    if not haveAff("clumsiness") then
      table.insert(gm.staff, gm.LA <= gm.RA and "ruku left" or "ruku right")
    elseif not haveAff("lethargy") then
      table.insert(gm.staff, "kuro right")
    elseif not haveAff("slickness") then
      table.insert(gm.staff, "ruku torso")
    elseif not haveAff("addiction") then
      table.insert(gm.staff, "jinzuku")
    else
      table.insert(gm.staff, gm.LA <= gm.RA and "ruku left" or "ruku right")
    end
    gm.kick = "flashheel left"
    return
  end

  -- RE-NEEDLE: prone + damagedhead + crushedthroat cured
  if haveAff("prone") and tAffs.damagedhead and not haveAff("crushedthroat") then
    gm.staff = {}
    table.insert(gm.staff, "needle")
    if not haveAff("clumsiness") then
      table.insert(gm.staff, gm.LA <= gm.RA and "ruku left" or "ruku right")
    elseif not haveAff("lethargy") then
      table.insert(gm.staff, "kuro right")
    elseif not haveAff("slickness") then
      table.insert(gm.staff, "ruku torso")
    else
      table.insert(gm.staff, "jinzuku")
    end
    if not tAffs.damagedleftleg and not haveAff("brokenleftleg") then
      gm.kick = "flashheel left"
    elseif not tAffs.damagedrightleg and not haveAff("brokenrightleg") then
      gm.kick = "flashheel right"
    else
      gm.kick = "none"
    end
    return
  end

  -- COMBO 2: prone + left leg broken/damaged + not both arms broken yet
  local leftLegBroken = tAffs.damagedleftleg or haveAff("brokenleftleg")
  if haveAff("prone") and leftLegBroken and not gm.bothArmsBroken then
    gm.staff = {}
    table.insert(gm.staff, "ruku left")
    table.insert(gm.staff, "ruku right")
    gm.kick = "flashheel right"
    return
  end

  -- COMBO 1: all 5 prepped, not prone
  if gm.executeReady and not haveAff("prone") then
    gm.staff = {}
    table.insert(gm.staff, "sweep")
    gm.kick = "flashheel left"
    return
  end

  -- KATA GUARD: not in execute, kata deep -> filler only
  if k >= 10 and not gm.executeReady then
    gm.kick = "none"
    table.insert(gm.staff, not haveAff("slickness") and "ruku torso" or "jinzuku")
    table.insert(gm.staff, not haveAff("addiction") and "jinzuku" or "ruku torso")
    return
  end

  -- STILL BUILDING in Gaital: flashheel legs, kuro/ruku staff
  local simLL, simRL = 0, 0

  if not gm.llFLASH and not tAffs.damagedleftleg
  and (gm.rlFLASH or gm.LL <= gm.RL)
  and ataxiaTemp.parriedLimb ~= "left leg" then
    gm.kick = "flashheel left"
    simLL = simLL + ld.shikFlashheel
  elseif not gm.rlFLASH and not tAffs.damagedrightleg then
    gm.kick = "flashheel right"
    simRL = simRL + ld.shikFlashheel
  else
    gm.kick = "none"
  end

  -- Staff jabs with cumulative damage tracking
  local function gPickKuro()
    if not gm.llKUR and (gm.rlKUR or gm.LL <= gm.RL) then
      local light = shouldLight("LL", ld.shikKuro, simLL)
      local s = light and "kuro light left" or "kuro left"
      if not light then simLL = simLL + ld.shikKuro end
      return s
    elseif not gm.rlKUR then
      local light = shouldLight("RL", ld.shikKuro, simRL)
      local s = light and "kuro light right" or "kuro right"
      if not light then simRL = simRL + ld.shikKuro end
      return s
    end
    return nil
  end

  local simLA, simRA = 0, 0  -- arm sim tracking for ruku
  local function gPickRuku()
    if not gm.laPREP then
      local light = shouldLight("LA", ld.shikRuku, simLA)
      local s = light and "ruku light left" or "ruku left"
      if not light then simLA = simLA + ld.shikRuku end
      return s
    elseif not gm.raPREP then
      local light = shouldLight("RA", ld.shikRuku, simRA)
      local s = light and "ruku light right" or "ruku right"
      if not light then simRA = simRA + ld.shikRuku end
      return s
    end
    return gm.LA <= gm.RA and "ruku light left" or "ruku light right"
  end

  local j1, j2 = nil, nil
  if not haveAff("clumsiness") then j1 = gPickRuku()
  elseif not haveAff("lethargy") then j1 = gPickKuro() end
  if not j1 then j1 = gPickKuro() end
  if not j1 then j1 = gPickRuku() end
  if not j1 then j1 = not haveAff("addiction") and "jinzuku" or "ruku torso" end

  if j1 and j1:find("kuro left") then
    j2 = not gm.rlKUR and gPickKuro() or gPickRuku()
  elseif j1 and j1:find("kuro right") then
    j2 = not gm.llKUR and gPickKuro() or gPickRuku()
  elseif j1 and j1:find("ruku") then
    j2 = gPickKuro()
  end
  if not j2 then j2 = not haveAff("addiction") and "jinzuku" or "ruku torso" end

  table.insert(gm.staff, j1)
  if j2 then table.insert(gm.staff, j2) end
end

-- ── MAELSTROM ───────────────────────────────────────────────
local function maelstromPrios()
  gm.staff = {}
  gm.kick = "none"
  local killReady = tAffs.damagedhead and haveAff("crushedthroat")

  if gm.lowHp and haveAff("prone") and killReady then
    gm.kick = "crescent"
  elseif haveAff("prone") and killReady then
    gm.kick = "risingkick torso"
    table.insert(gm.staff, "livestrike")
  elseif not haveAff("prone") then
    table.insert(gm.staff, "sweep")
    gm.kick = "risingkick torso"
  else
    gm.kick = "risingkick torso"
    table.insert(gm.staff, "livestrike")
  end
end

-- ============================================================
--  SECTION 4: FORM SWAP (Condition-Based)
-- ============================================================
function shikudo.godmode.formswap()
  local f = ataxia.vitals.form
  local k = ataxia.vitals.kata
  local targetForm = nil

  -- Low HP override: Gaital -> Maelstrom for crescent
  if f == "Gaital" and gm.lowHp and k >= 5 then
    return "Maelstrom"
  end

  -- Lock fork: Gaital -> Rain to push lock
  if f == "Gaital" and gm.lockForkReady then
    if k >= 5 then return "Rain"
    else return f end
  end

  if f == "Tykonos" then
    targetForm = k >= 5 and "Willow" or "Tykonos"

  elseif f == "Willow" then
    local legsWorked = gm.llFLASH or gm.rlFLASH or gm.llKUR or gm.rlKUR
    if (k >= 5 and legsWorked) or k >= 8 then
      targetForm = "Rain"
    else
      targetForm = "Willow"
    end

  elseif f == "Rain" then
    -- Lock fork: stay in Rain
    if gm.lockForkReady then
      return "Rain"
    end
    local legsPrepped = gm.llKUR and gm.rlKUR
    local armsAndLegs = legsPrepped and gm.laPREP and gm.raPREP
    if k >= 5 and armsAndLegs and gm.hPREP then
      targetForm = "Oak"
    elseif k >= 5 and legsPrepped and (haveAff("weariness") or haveAff("lethargy")) then
      targetForm = "Oak"
    elseif k >= 22 then
      targetForm = "Oak"
    else
      targetForm = "Rain"
    end

  elseif f == "Oak" then
    local allPrepped = gm.llFLASH and gm.rlFLASH and gm.laPREP and gm.raPREP and gm.hPREP
    local partialDone = (gm.llFLASH or gm.rlFLASH) and gm.hPREP
    local affsCooking = haveAff("paralysis") or haveAff("asthma")
    if k >= 5 and allPrepped then
      targetForm = "Gaital"
    elseif k >= 5 and partialDone and affsCooking then
      targetForm = "Gaital"
    elseif k >= 10 then
      targetForm = "Gaital"
    else
      targetForm = "Oak"
    end

  elseif f == "Gaital" then
    local killReady = tAffs.damagedhead and haveAff("crushedthroat")
    local midExecute = haveAff("prone") and (tAffs.damagedhead or gm.bothLegsBroken
                       or gm.bothArmsBroken)
    if k >= 10 and not gm.executeReady and not killReady
    and not gm.lockForkReady and not midExecute then
      targetForm = "Rain"
    else
      targetForm = "Gaital"
    end

  elseif f == "Maelstrom" then
    local killReady = tAffs.damagedhead and haveAff("crushedthroat")
    if (k >= 5 and not gm.lowHp and not killReady) or k >= 8 then
      targetForm = "Oak"
    else
      targetForm = "Maelstrom"
    end
  end

  return targetForm or f
end

-- ============================================================
--  SECTION 5: ATTACK ASSEMBLY + SEND (Main Entry Point)
-- ============================================================
function shikudo.godmode.run()
  -- Initialize safety
  ataxia = ataxia or {}
  ataxia.vitals = ataxia.vitals or {}
  ataxia.balances = ataxia.balances or {}
  ataxia.settings = ataxia.settings or {}
  ataxia.settings.separator = ataxia.settings.separator or "::"
  ataxiaTemp = ataxiaTemp or {}
  tAffs = tAffs or {}

  local sp = ataxia.settings.separator
  local f = ataxia.vitals.form
  local k = ataxia.vitals.kata

  -- Reset state table (prevents stale sentinels from prior tick)
  gm = {}

  -- Safety check
  if not target or target == "" then
    cecho("\n<red>[Shikudo GM] No target set! Use: tar <name>")
    return
  end

  -- limbData guard
  if not ataxiaTables or not ataxiaTables.limbData then
    cecho("\n<red>[Shikudo GM] Limb data not initialized yet")
    return
  end

  -- Paused / stupidity / lock break check
  if ataxia.settings.paused then return end
  if ataxia.afflictions and ataxia.afflictions.stupidity then return end
  if ataxia_needLockBreak and ataxia_needLockBreak() then
    if ataxia_lockBreak then ataxia_lockBreak() end
    return
  end

  -- Init form if none
  if not f or f == "" or f == "none" then
    send("adopt rain form")
    return
  end

  -- Breakpoint calc if needed
  if not shikudo_limbDamage then
    shikudo_breakPoint(5000)
  end

  -- Debug output (suppressed during autobashing)
  if not ataxiaBasher or not ataxiaBasher.enabled then
    cecho("\n<cyan>[Shikudo:<yellow>GODMODE<cyan>] <yellow>" .. tostring(target))
    cecho(" <cyan>| <green>" .. f)
    cecho(" <cyan>| k:<yellow>" .. k)
  end

  -- Compute all limb state
  shikudo.godmode.calcLimbs()

  -- Build pre-attack queue (transmute, stand, etc.)
  local atk = ""
  if combatQueue then
    atk = combatQueue()
  end

  -- Mind lock if not already mindlocked
  if not mindlocked and not startingMindlock then
    atk = atk .. "mind lock " .. target .. sp
  end

  -- Transmute
  local xmute = math.ceil(ataxia.vitals.maxhp * 0.80)
  local mpl = ataxia.vitals.mp - (ataxia.vitals.maxmp * 0.30)
  local hpl = xmute - ataxia.vitals.hp
  if hpl > 1 then
    local tomute = (hpl < mpl and hpl or mpl)
    if tomute > 100 then atk = "transmute " .. tomute .. sp .. atk end
  end

  -- Kai boost
  if ataxia.vitals.kai and ataxia.vitals.kai >= 11 and not (ataxia.defences and ataxia.defences.kaiboost) then
    atk = atk .. "kai boost" .. sp
  end

  -- ── HYPERFOCUS CHECK ──────────────────────────────────────
  local hyperOk = ataxiaTemp.hyperLimb == "head"
  if not hyperOk and f ~= "Gaital" then
    send("queue addclear eqbal " .. atk .. "hyperfocus head")
    cecho(" <magenta>| SETTING HYPERFOCUS HEAD")
    return
  end

  -- ── DISPATCH CHECK ────────────────────────────────────────
  if haveAff("prone") and tAffs.damagedhead and haveAff("crushedthroat") then
    local isMhaldorian = tCity == "Mhaldor" or tCity == "(Mhaldor)"
    if isMhaldorian then
      atk = atk .. "incapacitate " .. target
      cecho("\n<yellow>*** INCAPACITATE ***")
    else
      atk = atk .. "dispatch " .. target
      cecho("\n<red>*** DISPATCH KILL ***")
    end
    send("queue addclear eqbal " .. atk)
    return
  end

  -- ── SHIELD CHECK ──────────────────────────────────────────
  if tAffs.shield then
    atk = atk .. "combo " .. target .. " shatter"
    send("queue addclear eqbal " .. atk)
    return
  end

  -- ── FORM-SPECIFIC PRIORITIES ──────────────────────────────
  if f == "Tykonos" then tykonosPrios()
  elseif f == "Willow" then willowPrios()
  elseif f == "Rain" then rainPrios()
  elseif f == "Oak" then oakPrios()
  elseif f == "Gaital" then gaitalPrios()
  elseif f == "Maelstrom" then maelstromPrios()
  else
    -- Unknown form, try to adopt Rain
    send("adopt rain form")
    return
  end

  -- ── FORM TRANSITION ───────────────────────────────────────
  local targetForm = shikudo.godmode.formswap()
  local needTransition = (f ~= targetForm)

  if needTransition then
    if k >= 5 then
      send("cq all" .. sp .. "transition to the " .. targetForm .. " form" .. sp .. atk)
      cecho(" <yellow>-> " .. targetForm)
    else
      send("cq all" .. sp .. "adopt " .. targetForm .. " form")
      cecho(" <yellow>-> adopt " .. targetForm)
    end
    return
  end

  -- ── SPECIAL ACTIONS ───────────────────────────────────────

  -- Hyperfocus set (from prios)
  if gm.staff[1] == "hyperfocus head" then
    send("queue addclear eqbal " .. atk .. "hyperfocus head")
    return
  end

  -- Maelstrom override (from Gaital prios)
  if gm.staff[1] == "maelstrom_override" then
    send("cq all" .. sp .. "transition to the Maelstrom form" .. sp .. atk)
    cecho(" <red>-> MAELSTROM (low HP)")
    return
  end

  -- Lock fork: flow Rain (from Gaital prios)
  if gm.staff[1] == "lock_fork" then
    if k >= 5 then
      send("cq all" .. sp .. "transition to the Rain form" .. sp .. atk)
      cecho(" <magenta>-> RAIN (lock fork)")
    else
      send("cq all" .. sp .. "adopt Rain form")
      cecho(" <magenta>-> adopt Rain (lock fork)")
    end
    return
  end

  -- Dispatch (from prios)
  if gm.staff[1] == "dispatch" then
    local isMhaldorian = tCity == "Mhaldor" or tCity == "(Mhaldor)"
    if isMhaldorian then
      atk = atk .. "incapacitate " .. target
    else
      atk = atk .. "dispatch " .. target
    end
    cecho("\n<red>*** DISPATCH ***")
    send("queue addclear eqbal " .. atk)
    return
  end

  -- ── SWEEP HANDLING ────────────────────────────────────────
  -- Combo 1 execute: drop hyperfocus so needle breaks head next combo
  if gm.staff[1] == "sweep" then
    local hyperLimb = ataxiaTemp.hyperLimb
    if hyperLimb and hyperLimb ~= "none" and hyperLimb ~= "" then
      atk = atk .. "hyperfocus none" .. sp
      ataxiaTemp.hyperNeedsRaise = true
    end
    local c = gm.kick ~= "none" and "sweep " .. gm.kick or "sweep"
    atk = atk .. "combo " .. target .. " " .. c
    cecho(" <red>| EXECUTE C1: sweep")
    send("queue addclear eqbal " .. atk)
    return
  end

  -- ── STANDARD COMBO ASSEMBLY ───────────────────────────────
  local s1 = gm.staff[1] or ""
  local s2 = gm.staff[2] or ""
  local combo = ""

  -- Combo order: Rain/Oak+clumsiness = kick first. Others = staff first, kick last.
  local kickFirst = (f == "Rain") or (f == "Oak" and haveAff("clumsiness"))

  if kickFirst then
    if gm.kick ~= "none" and s1 ~= "" and s2 ~= "" then
      combo = gm.kick .. " " .. s1 .. " " .. s2
    elseif gm.kick ~= "none" and s1 ~= "" then
      combo = gm.kick .. " " .. s1
    elseif s1 ~= "" and s2 ~= "" then
      combo = s1 .. " " .. s2
    elseif s1 ~= "" then
      combo = s1
    end
  else
    if s1 ~= "" and s2 ~= "" and gm.kick ~= "none" then
      combo = s1 .. " " .. s2 .. " " .. gm.kick
    elseif s1 ~= "" and gm.kick ~= "none" then
      combo = s1 .. " " .. gm.kick
    elseif s1 ~= "" and s2 ~= "" then
      combo = s1 .. " " .. s2
    elseif gm.kick ~= "none" then
      combo = gm.kick
    elseif s1 ~= "" then
      combo = s1
    end
  end

  if combo ~= "" then
    atk = atk .. "combo " .. target .. " " .. combo
  end

  send("queue addclear eqbal " .. atk)
end

-- ============================================================
--  SECTION 6: STATUS DISPLAY
-- ============================================================
function shikudo.godmode.status()
  tAffs = tAffs or {}
  ataxia = ataxia or {}
  ataxia.vitals = ataxia.vitals or {}
  ataxiaTemp = ataxiaTemp or {}

  local f = ataxia.vitals.form or "Unknown"
  local k = ataxia.vitals.kata or 0
  local thresh = shikudo.godmode.PREP_THRESHOLD

  -- Read limb data from lb[target].hits (same source as calcLimbs)
  local ll = getLimb("LL")
  local rl = getLimb("RL")
  local la = getLimb("LA")
  local ra = getLimb("RA")
  local h  = getLimb("H")

  -- Recalc state if limbData available
  if ataxiaTables and ataxiaTables.limbData then
    gm = {}
    shikudo.godmode.calcLimbs()
  end

  local function limbColor(val)
    if val >= 100 then return "<red>"
    elseif val >= thresh then return "<green>"
    elseif val >= 70 then return "<yellow>"
    else return "<grey>" end
  end

  local function checkMark(val)
    return val >= thresh and "<green>[X]" or "<red>[ ]"
  end

  cecho("\n<cyan>╔══════════════════════════════════════════════╗")
  cecho("\n<cyan>║         <white>SHIKUDO GOD MODE<cyan>                     ║")
  cecho("\n<cyan>╠══════════════════════════════════════════════╣")
  cecho("\n<cyan>║ <white>Target: <yellow>" .. tostring(target or "None"))
  cecho("\n<cyan>║ <white>Form: <green>" .. f .. " <grey>(k:" .. k .. ")")
  cecho("\n<cyan>║ <white>Hyper: " .. tostring(ataxiaTemp.hyperLimb or "none"))
  cecho("\n<cyan>╠══════════════════════════════════════════════╣")
  cecho("\n<cyan>║ <white>5-LIMB PREP (" .. thresh .. "%+ threshold):")
  cecho("\n<cyan>║   " .. checkMark(ll) .. " <white>L Leg: " .. limbColor(ll) .. string.format("%.1f%%", ll))
  cecho("\n<cyan>║   " .. checkMark(rl) .. " <white>R Leg: " .. limbColor(rl) .. string.format("%.1f%%", rl))
  cecho("\n<cyan>║   " .. checkMark(la) .. " <white>L Arm: " .. limbColor(la) .. string.format("%.1f%%", la))
  cecho("\n<cyan>║   " .. checkMark(ra) .. " <white>R Arm: " .. limbColor(ra) .. string.format("%.1f%%", ra))
  cecho("\n<cyan>║   " .. checkMark(h) .. " <white>Head:  " .. limbColor(h) .. string.format("%.1f%%", h))

  local phase = "BUILD"
  if gm.executeReady then phase = "EXECUTE" end
  if gm.lockForkReady then phase = "LOCK FORK" end
  cecho("\n<cyan>║ <white>Phase: <yellow>" .. phase)

  cecho("\n<cyan>╠══════════════════════════════════════════════╣")
  cecho("\n<cyan>║ <white>KILL CONDITIONS:")
  cecho("\n<cyan>║   <white>Prone: " .. (tAffs.prone and "<green>YES" or "<red>NO"))
  cecho("\n<cyan>║   <white>Head Broken: " .. (tAffs.damagedhead and "<green>YES" or "<red>NO"))
  cecho("\n<cyan>║   <white>Windpipe: " .. ((tAffs.damagedwindpipe or tAffs.crushedthroat) and "<green>YES" or "<red>NO"))
  cecho("\n<cyan>║   <white>Lock Affs: <yellow>" .. (gm.lockCount or 0) .. "/3")
  cecho("\n<cyan>╚══════════════════════════════════════════════╝")
end

-- ============================================================
--  SECTION 7: CONVENIENCE ALIASES
-- ============================================================
function skgodmode()
  shikudo.setMode("godmode")
  shikudo.dispatch()
end

function skgmstatus()
  shikudo.setMode("godmode")
  shikudo.godmode.status()
end
