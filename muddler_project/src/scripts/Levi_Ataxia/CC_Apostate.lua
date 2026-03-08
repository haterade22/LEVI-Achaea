--[[mudlet
type: script
name: CC_Apostate
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- APOSTATE
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[mudlet
type: script
name: CC_Apostate
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- APOSTATE
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--------------------------------------------------------------------------------
-- CC_Apostate: Unified Apostate Offensive System (V3 Integration)
--
-- Replaces old files 001-014 with a single namespace-based system.
-- Backward-compat wrappers, daemon utilities, and nightmare tracking below.
-- Integrates with Affliction Tracker V3 (probability-based), V2, or V1.
--
-- Kill Routes (6 modes):
--   1. True Lock  - DEADEYES curse delivery building toward truelock
--   2. Mental     - Flood goldenseal+lobelia (IMP→STU→DIZ→VER) then lock
--   3. Group      - Pure lock pieces, no hinder, no probability gates
--   4. Corrupt    - Stack afflictions then demon corrupt for damage/catharsis
--   5. Vivisect   - Truelock -> prone -> shrivel 4 limbs -> vivisect
--   6. Sleep      - Build asthma + impatience + hypersomnia -> sleep curse
--
-- DEADEYES delivers 2 curses per action (2.3s balance).
-- Curses are selected independently via a dual-slot system:
--
--   Curse 1 (primary) - Truelock chain with asthma-conditional branching:
--     No asthma: clumsiness(33%) -> weariness(33%) -> asthma
--     With asthma(50%+): manaleech -> impatience -> sicken (slickness)
--     -> anorexia -> weariness -> class lock aff -> voyria (fallback)
--     Once asthma lands, clumsiness is skipped — lock speed over hinder.
--     Clumsy+weariness are both kelp-cured: forces 2 kelp eats before asthma.
--
--   Curse 2 (secondary) - Paralysis-first, then fill missing lock pieces:
--     paralysis -> asthma -> manaleech (gated by asthma) -> impatience
--     -> sicken (slickness) -> anorexia -> weariness -> class lock aff -> voyria
--
-- Manaleech is smoke-cured: only delivered behind asthma.
-- Sicken delivers slickness when manaleech is present on the target.
-- Asthma blocks smoke cures, protecting manaleech and slickness once applied.
--
-- Lock progression: softlock (asthma+anorexia+slickness) -> hardlock (+impatience)
--   -> truelock (+paralysis) -> class lock aff for kill
--
-- Corrupt damage: physical affs x7 + mental affs x8 + smoke affs x9,
-- weighted by V3 probability when available.
--------------------------------------------------------------------------------

apostate = apostate or {}

--------------------------------------------------------------------------------
-- STATE & CONFIG
--------------------------------------------------------------------------------

apostate.state = {
  mode = "lock",            -- "lock", "corrupt", "vivisect", "sleep", "group", "mental"
  corrupted = false,        -- corrupt has been fired (awaiting catharsis)
  lastCorruptTime = 0,      -- corrupt cooldown tracking
  daeggerhere = false,      -- daegger summoned
  freshblood = false,       -- fresh blood available for bloodpact
  fiendthing = "nightmare", -- preferred lesser daemon
  wantDisloyalty = false,   -- disfigure toggle
  disfigureSent = false,    -- disfigure spam protection (once per asthma round)
  disfigureTrigger = nil,   -- one-shot tempTrigger ID for disfigure on deadeyes text
  pendingDisfigure = false, -- flag: disfigure should fire with next deadeyes
  asthmaConfirmTimer = nil, -- timer: confirm asthma present if target doesn't smoke
  baalzadeenSummoned = false, -- summon sent, awaiting GMCP confirmation
  partyrelay = true,        -- relay to party
}

apostate.config = {
  corruptThreshold = 0.7,   -- V3 probability threshold for corrupt damage calc
  lockThreshold = 0.3,      -- V3 threshold for "has affliction" in lock decisions
  catharsisThreshold = 50,  -- mana % for catharsis execute
  sapThreshold = 60,        -- mana % for sap consideration
  debugEcho = false,        -- echo debug info
}

-- Internal: current curse selections
apostate.curses = {}

--------------------------------------------------------------------------------
-- V3 ROUTING HELPERS (Blademaster pattern)
--------------------------------------------------------------------------------

-- Check if target has an affliction (V3 is always on, routes through global haveAff)
function apostate.hasAff(aff)
  return haveAff(aff)
end

-- Get affliction probability (0.0-1.0).
function apostate.getAffProb(aff)
  return getAffProbabilityV3 and getAffProbabilityV3(aff) or 0
end

-- Check which tracking system is active
function apostate.getTrackingSystem()
  return "V3"
end

-- Get lock status with probabilities
function apostate.getLocks()
  if affConfigV3 and affConfigV3.enabled and getLockStatusV3 then
    return getLockStatusV3()
  end
  -- Fallback: boolean-based lock detection
  local hasAll = function(affs)
    for _, aff in ipairs(affs) do
      if not apostate.hasAff(aff) then return 0 end
    end
    return 1.0
  end
  return {
    softlock = hasAll({"anorexia", "asthma", "slickness"}),
    hardlock = hasAll({"anorexia", "asthma", "slickness", "impatience"}),
    truelock = hasAll({"anorexia", "asthma", "slickness", "impatience", "paralysis"}),
  }
end

--------------------------------------------------------------------------------
-- CORRUPT DAMAGE CALCULATOR (V3-aware)
--------------------------------------------------------------------------------

function apostate.corruptDmg()
  local physAffs = {
    "clumsiness", "paralysis", "asthma", "sensitivity",
    "nausea", "stupidity", "impatience",
  }
  local mentalAffs = {
    "vertigo", "agoraphobia", "dizziness", "claustrophobia",
    "paranoia", "dementia", "masochism", "recklessness",
    "epilepsy", "confusion", "anorexia", "addiction", "weariness",
  }
  local smokeAffs = {"manaleech", "healthleech"}

  local total = 0
  for _, aff in ipairs(physAffs) do
    total = total + (apostate.getAffProb(aff) * 7)
  end
  for _, aff in ipairs(mentalAffs) do
    total = total + (apostate.getAffProb(aff) * 8)
  end
  for _, aff in ipairs(smokeAffs) do
    total = total + (apostate.getAffProb(aff) * 9)
  end
  return total
end

--------------------------------------------------------------------------------
-- DUAL-SLOT CURSE PRIORITY ENGINE
--
-- DEADEYES takes 2 curses. Each slot has its own independent priority chain.
-- selectCurses() orchestrates both and handles overrides (curseward, truelock).
--
-- Curse 1 (selectPrimaryCurse): Truelock chain, asthma-conditional
--   No asthma: clumsiness(33%) -> asthma
--   With asthma: manaleech -> impatience -> sicken -> anorexia
--   -> class lock aff -> voyria (fallback)
--
-- Curse 2 (selectSecondaryCurse): Paralysis-first, then fill lock pieces
--   paralysis -> asthma -> manaleech(gated) -> impatience -> sicken -> anorexia
--   -> class lock aff -> voyria (fallback)
--
-- Curse 2 never duplicates curse 1 (c1 passed as parameter to avoid overlap).
-- Manaleech is smoke-cured: only delivered behind asthma.
-- Sicken delivers slickness when manaleech is present on target.
--------------------------------------------------------------------------------

-- Filler afflictions shared by both curse slots
apostate.fillers = {
  {aff = "stupidity",      curse = "stupid"},
  {aff = "dizziness",      curse = "dizzy"},
  {aff = "weariness",      curse = "weariness"},
  {aff = "nausea",         curse = "vomiting"},
  {aff = "confusion",      curse = "confusion"},
  {aff = "addiction",       curse = "addiction"},
  {aff = "epilepsy",       curse = "epilepsy"},
  {aff = "dementia",       curse = "dementia"},
  {aff = "vertigo",        curse = "vertigo"},
  {aff = "recklessness",   curse = "reckless"},
  {aff = "masochism",      curse = "masochism"},
  {aff = "agoraphobia",    curse = "agoraphobia"},
  {aff = "claustrophobia", curse = "claustrophobia"},
  {aff = "paranoia",       curse = "paranoia"},
}

-- Evileye curse name conversion for getLockingAffliction() mismatches
local EVILEYE_CURSE_MAP = {
  paralyse = "paralysis",     -- Jester, Occultist, Shaman, Underworld
}

local function toEvileyeCurse(curse)
  return EVILEYE_CURSE_MAP[curse] or curse
end

-- Curse 1: Truelock priority chain (V3-aware gating)
-- Without asthma: clumsiness(33%) → weariness(33%) → asthma (kelp stack: both must stick before asthma)
-- With asthma(33%+): manaleech + disfigure → impatience → slickness → anorexia → weariness → class lock → voyria
-- Manaleech at 33% asthma = early pressure: if they smoke, asthma collapses to 0%.
-- If they don't smoke, asthma is confirmed and manaleech sticks.
-- Once asthma lands, skip clumsiness entirely and push lock pieces ASAP.
function apostate.selectPrimaryCurse()
  local asthmaProb = apostate.getAffProb("asthma")

  if asthmaProb >= 0.33 then
    -- Asthma likely → push manaleech + disfigure (probes asthma: smoke = no asthma, no smoke = confirmed)
    -- Skip clumsiness: lock speed > hinder pressure
    if not apostate.hasAff("manaleech") then return "manaleech" end
    if not apostate.hasAff("impatience") then return "impatience" end

    -- Slickness via sicken (delivers slickness when manaleech present)
    if apostate.hasAff("impatience") and not apostate.hasAff("slickness") then
      return "sicken"
    end

    -- Anorexia only after slickness (no point blocking eating if they can still apply)
    if apostate.hasAff("slickness") and not apostate.hasAff("anorexia") then
      return "anorexia"
    end

    -- Weariness (truelock piece)
    if not apostate.hasAff("weariness") then return "weariness" end
  else
    -- No asthma: build kelp stack (clumsy+weariness) then push asthma
    -- Both are kelp-cured — delivering both forces target to eat kelp twice before asthma.
    -- Only advance to asthma once BOTH are at 33%+.
    if apostate.getAffProb("clumsiness") < 0.33 then return "clumsy" end
    if apostate.getAffProb("weariness") < 0.33 then return "weariness" end
    return "asthma"
  end

  -- Class lock affliction (recklessness, voyria, etc.)
  if getLockingAffliction then
    local lockAffName = getLockingAffliction("name")
    local lockAffCurse = toEvileyeCurse(getLockingAffliction())
    if lockAffName and not apostate.hasAff(lockAffName) then
      return lockAffCurse
    end
  end

  -- Voyria fallback (syphon cures it every 10s, always useful pressure)
  return "plague"
end

-- Curse 2: Paralysis-first, then fill missing lock pieces
-- Manaleech gated behind asthma (smoke-cured without it)
-- When c1 is anorexia, pair with sicken to fill uncertain slickness/paralysis.
function apostate.selectSecondaryCurse(c1)
  -- Anorexia + sicken pairing: sicken fills whatever cascade piece is missing
  -- (slickness if they lost it, paralysis if slickness is stuck)
  -- Only skip when both slickness AND paralysis are confirmed at 100%
  if c1 == "anorexia" then
    if apostate.getAffProb("slickness") < 1.0 or apostate.getAffProb("paralysis") < 1.0 then
      return "sicken"
    end
  end

  -- 1. Paralysis: always first
  if not apostate.hasAff("paralysis") and c1 ~= "paralysis" then
    return "paralysis"
  end

  -- 2. Fill missing lock pieces (skipping c1)
  -- Asthma first (blocks smoking, protects manaleech)
  if not apostate.hasAff("asthma") and c1 ~= "asthma" then return "asthma" end

  -- Manaleech at 50%+ asthma (smoke-cured without it; also probes asthma certainty)
  if apostate.getAffProb("asthma") >= 0.33 and not apostate.hasAff("manaleech") and c1 ~= "manaleech" then
    return "manaleech"
  end

  if not apostate.hasAff("impatience") and c1 ~= "impatience" then return "impatience" end

  -- Slickness via sicken (gated by impatience + asthma 50%+)
  if apostate.hasAff("impatience") and apostate.getAffProb("asthma") >= 0.33
     and not apostate.hasAff("slickness") and c1 ~= "sicken" then
    return "sicken"
  end

  -- Anorexia only after slickness (no point blocking eating if they can still apply)
  -- Also allow when c1=sicken since sicken delivers slickness this round
  if (apostate.hasAff("slickness") or c1 == "sicken") and not apostate.hasAff("anorexia") and c1 ~= "anorexia" then
    return "anorexia"
  end

  -- Weariness (truelock piece)
  if not apostate.hasAff("weariness") and c1 ~= "weariness" then return "weariness" end

  -- 3. Class lock affliction
  if getLockingAffliction then
    local lockAffName = getLockingAffliction("name")
    local lockAffCurse = toEvileyeCurse(getLockingAffliction())
    if lockAffName and not apostate.hasAff(lockAffName) and c1 ~= lockAffCurse then
      return lockAffCurse
    end
  end

  -- 4. Voyria fallback
  if c1 ~= "plague" then return "plague" end
  return "paralysis"
end

--------------------------------------------------------------------------------
-- GROUP MODE CURSE SELECTION
-- Pure lock pieces, no hinder (clumsiness/weariness), no probability gates.
-- Curse 1: impatience → asthma → manaleech → slickness(sicken) → anorexia → class lock → voyria
-- Curse 2: paralysis → fill missing lock pieces in same order
--------------------------------------------------------------------------------

function apostate.selectPrimaryCurseGroup()
  if not apostate.hasAff("impatience") then return "impatience" end
  if not apostate.hasAff("asthma") then return "asthma" end
  if not apostate.hasAff("manaleech") then return "manaleech" end
  if not apostate.hasAff("slickness") then return "sicken" end
  if not apostate.hasAff("anorexia") then return "anorexia" end

  -- Class lock affliction
  if getLockingAffliction then
    local lockAffName = getLockingAffliction("name")
    local lockAffCurse = toEvileyeCurse(getLockingAffliction())
    if lockAffName and not apostate.hasAff(lockAffName) then
      return lockAffCurse
    end
  end

  return "plague"
end

function apostate.selectSecondaryCurseGroup(c1)
  -- Anorexia + sicken pairing (same logic as lock mode)
  if c1 == "anorexia" then
    if apostate.getAffProb("slickness") < 1.0 or apostate.getAffProb("paralysis") < 1.0 then
      return "sicken"
    end
  end

  -- 1. Paralysis: always first
  if not apostate.hasAff("paralysis") and c1 ~= "paralysis" then
    return "paralysis"
  end

  -- 2. Fill missing lock pieces (skipping c1)
  if not apostate.hasAff("impatience") and c1 ~= "impatience" then return "impatience" end
  if not apostate.hasAff("asthma") and c1 ~= "asthma" then return "asthma" end
  if not apostate.hasAff("manaleech") and c1 ~= "manaleech" then return "manaleech" end
  if not apostate.hasAff("slickness") and c1 ~= "sicken" then return "sicken" end
  if not apostate.hasAff("anorexia") and c1 ~= "anorexia" then return "anorexia" end

  -- Class lock affliction
  if getLockingAffliction then
    local lockAffName = getLockingAffliction("name")
    local lockAffCurse = toEvileyeCurse(getLockingAffliction())
    if lockAffName and not apostate.hasAff(lockAffName) and c1 ~= lockAffCurse then
      return lockAffCurse
    end
  end

  if c1 ~= "plague" then return "plague" end
  return "paralysis"
end

--------------------------------------------------------------------------------
-- MENTAL MODE CURSE SELECTION
-- Flood goldenseal+lobelia with mental affs. Once impatience + 2 other
-- mentals are stuck, transition to lock mode curse selectors for physical lock.
--
-- Curse 1: impatience → stupid → dizzy → vertigo → (lock selectors)
-- Curse 2: paralysis (blocks tree) → fill mental pieces → (lock selectors)
-- All delivery thresholds at 25% (deliver once, move on to flood cures).
-- Transition gate (mentalReady): impatience(100%) + 2 of {stupidity, dizziness, vertigo}(25%) → lock
--------------------------------------------------------------------------------

-- Count how many mental stack affs are stuck (excludes impatience — that's the gate)
function apostate.mentalStackCount()
  local count = 0
  local mentals = {"stupidity", "dizziness", "vertigo"}
  for _, aff in ipairs(mentals) do
    if apostate.hasAff(aff) then count = count + 1 end
  end
  return count
end

-- Check if mental mode should transition to lock curse selectors
-- Requires impatience CONFIRMED (100%) + 2 of {stupidity, dizziness, vertigo} at 25%+
function apostate.mentalReady()
  return apostate.getAffProb("impatience") >= 1.0 and apostate.mentalStackCount() >= 2
end

function apostate.selectPrimaryCurseMental()
  -- If mental stack is ready, transition to lock selectors
  if apostate.mentalReady() then
    return apostate.selectPrimaryCurse()
  end

  -- Mental stack priority: impatience → stupid → dizzy → vertigo
  -- All at 25% delivery threshold — deliver each once then move on.
  -- The 100% impatience gate is in mentalReady() (transition to lock), not here.
  if apostate.getAffProb("impatience") < 0.25 then return "impatience" end
  if apostate.getAffProb("stupidity") < 0.25 then return "stupid" end
  if apostate.getAffProb("dizziness") < 0.25 then return "dizzy" end
  if apostate.getAffProb("vertigo") < 0.25 then return "vertigo" end

  -- All mentals stuck but transition not met — fill with lock
  return apostate.selectPrimaryCurse()
end

function apostate.selectSecondaryCurseMental(c1)
  -- If mental stack is ready, transition to lock selectors
  if apostate.mentalReady() then
    return apostate.selectSecondaryCurse(c1)
  end

  -- Always paralysis (blocks tree, which would randomly cure a mental)
  if not apostate.hasAff("paralysis") and c1 ~= "paralysis" then
    return "paralysis"
  end

  -- Paralysis stuck — fill missing mental pieces (skipping c1)
  -- All at 25% delivery threshold (same as primary — flood cures, don't loop)
  if apostate.getAffProb("impatience") < 0.25 and c1 ~= "impatience" then return "impatience" end
  if apostate.getAffProb("stupidity") < 0.25 and c1 ~= "stupid" then return "stupid" end
  if apostate.getAffProb("dizziness") < 0.25 and c1 ~= "dizzy" then return "dizzy" end
  if apostate.getAffProb("vertigo") < 0.25 and c1 ~= "vertigo" then return "vertigo" end

  -- All mentals stuck — fill with lock secondary
  return apostate.selectSecondaryCurse(c1)
end

-- Main curse selection. Returns table of 2 curse names for DEADEYES.
-- Routes to lock, group, or mental mode based on apostate.state.mode.
function apostate.selectCurses()
  local locks = apostate.getLocks()
  local mode = apostate.state.mode

  -- Secondary selector for the current mode
  local secondaryFn = apostate.selectSecondaryCurse
  if mode == "group" then secondaryFn = apostate.selectSecondaryCurseGroup
  elseif mode == "mental" then secondaryFn = apostate.selectSecondaryCurseMental end

  -- Curseward: must breach first (all modes)
  if apostate.hasAff("curseward") then
    return {"breach", secondaryFn("breach")}
  end

  -- Truelock completion: push class-specific lock affliction (all modes)
  if locks.truelock >= 0.7 then
    if getLockingAffliction then
      local lockAffName = getLockingAffliction("name")
      local lockAffCurse = toEvileyeCurse(getLockingAffliction())
      if lockAffName and not apostate.hasAff(lockAffName) then
        return {lockAffCurse, secondaryFn(lockAffCurse)}
      end
    end
  end

  -- Group mode: pure lock pieces, no hinder
  if mode == "group" then
    local c1 = apostate.selectPrimaryCurseGroup()
    local c2 = apostate.selectSecondaryCurseGroup(c1)
    return {c1, c2}
  end

  -- Mental mode: stack goldenseal/lobelia affs then transition to lock
  if mode == "mental" then
    local c1 = apostate.selectPrimaryCurseMental()
    local c2 = apostate.selectSecondaryCurseMental(c1)
    return {c1, c2}
  end

  -- Lock mode (default): truelock chain with hinder setup
  local c1 = apostate.selectPrimaryCurse()
  local c2 = apostate.selectSecondaryCurse(c1)
  return {c1, c2}
end

-- Convenience accessors
function apostate.getCurse1()
  return apostate.curses[1] or "clumsy"
end

function apostate.getCurse2()
  return apostate.curses[2] or "paralysis"
end

--------------------------------------------------------------------------------
-- KILL CONDITION CHECKERS
--------------------------------------------------------------------------------

function apostate.needVivisect()
  return apostate.hasAff("brokenrightarm") and apostate.hasAff("brokenleftarm")
     and apostate.hasAff("brokenrightleg") and apostate.hasAff("brokenleftleg")
end

function apostate.needCatharsis()
  return pm and pm < apostate.config.catharsisThreshold
end

function apostate.needCorrupt()
  -- Health-based kill: corrupt damage >= assessed health
  if ataxiaTemp and ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= apostate.corruptDmg() then
    return true
  end
  -- Mana-based setup: corrupt will push mana into catharsis range
  if pm and (pm - apostate.corruptDmg() <= 15) and
     not apostate.hasAff("anorexia") and not apostate.hasAff("slickness") then
    return true
  end
  return false
end

function apostate.needShieldStrip()
  return (apostate.needCatharsis() or apostate.state.corrupted) and apostate.hasAff("shield")
end

function apostate.needTrample()
  local locks = apostate.getLocks()
  return locks.truelock >= 0.7 and apostate.hasAff("prone")
end

function apostate.needShrivel()
  if apostate.state.mode ~= "vivisect" then return false end
  local locks = apostate.getLocks()
  return locks.truelock >= 0.7 and apostate.hasAff("prone") and not apostate.needVivisect()
end

function apostate.nextShrivelLimb()
  if not apostate.hasAff("brokenrightarm") then return "right arm" end
  if not apostate.hasAff("brokenleftarm") then return "left arm" end
  if not apostate.hasAff("brokenrightleg") then return "right leg" end
  return "left leg"
end

function apostate.needSap()
  return pm and pm <= apostate.config.sapThreshold and pm > apostate.config.catharsisThreshold
end

--------------------------------------------------------------------------------
-- PRE/POST ATTACK BUILDERS
-- Pre: bloodpact setup, daegger summon for catharsis/prone
-- Post: bloodworm summon, daemon resummon, disfigure for disloyalty
--------------------------------------------------------------------------------

function apostate.buildPreAttack()
  local state = apostate.state

  -- Bloodpact if fresh blood and no pentagram
  if state.freshblood and apopentagram and not apopentagram() then
    return "summon daegger;wield daegger shield;demon bloodpact " .. target ..
           " for " .. state.fiendthing .. ";order " .. state.fiendthing .. " kill " .. target .. ";"
  end

  -- Summon daegger if needed for catharsis or prone situations
  if (apostate.needCatharsis() or apostate.hasAff("prone")) and not state.daeggerhere then
    return "summon daegger;wield daegger shield;"
  end

  return nil
end

function apostate.buildPostAttack()
  local state = apostate.state
  local c1 = apostate.getCurse1()
  local c2 = apostate.getCurse2()

  -- Summon bloodworms if fresh blood available
  if bloodworm and not bloodworm() and state.freshblood then
    return ";summon bloodworms"
  end

  -- Dispel wrong daemon and resummon correct one
  if apopentagram and apopentagram() and demon and demon() ~= state.fiendthing then
    return ";summon daegger;wield daegger shield;dispel pentagram;summon " .. state.fiendthing
  end

  -- Disfigure for disloyalty
  if state.wantDisloyalty and apostate.hasAff("asthma") and not apostate.hasAff("disloyalty") then
    return ";disfigure " .. target
  end

  return nil
end

--------------------------------------------------------------------------------
-- UNIFIED ATTACK BUILDER
-- Priority: vivisect > shield strip > trample > catharsis > corrupt
--   > corrupt followup > shrivel > DEADEYES (default curse delivery)
--------------------------------------------------------------------------------

function apostate.buildAttack()
  local atk = combatQueue()
  local c1 = apostate.getCurse1()
  local c2 = apostate.getCurse2()

  -- Pre/post attack commands
  local preCmd = apostate.buildPreAttack()
  local postCmd = apostate.buildPostAttack()

  -- Kill condition checks (priority order)
  if apostate.needVivisect() then
    atk = atk .. "wield shield;dismount;vivisect " .. target .. ";assess " .. target

  elseif apostate.needShieldStrip() then
    atk = atk .. "wield shield;demon strip " .. target .. ";assess " .. target

  elseif apostate.needTrample() then
    atk = atk .. "wield shield;trample;assess " .. target

  elseif apostate.needCatharsis() and not apostate.needShieldStrip() then
    atk = atk .. "wield shield;demon catharsis " .. target .. ";assess " .. target

  elseif apostate.needCorrupt() then
    atk = atk .. "wield shield;demon corrupt " .. target .. " paralysis;assess " .. target

  elseif apostate.state.corrupted and not apostate.hasAff("shield") then
    -- Corrupt already fired, follow up with catharsis
    atk = atk .. "wield shield;demon catharsis " .. target .. ";assess " .. target

  elseif apostate.needShrivel() then
    local limb = apostate.nextShrivelLimb()
    atk = atk .. "wield shield;dismount;shrivel " .. limb .. " " .. target .. ";assess " .. target

  else
    -- Default: DEADEYES curse delivery
    atk = atk .. "wield shield;deadeyes " .. target .. " " .. c1 .. " " .. c2

    -- Disfigure on EQ when cursing asthma (lock mode only, once per asthma round)
    -- Fires with the asthma deadeyes so we can observe if target smokes before
    -- committing to manaleech next round (avoids wasting manaleech without asthma)
    -- Sent as separate queue entry in dispatch() so it doesn't fire immediately
    -- (server-side ; splits commands — disfigure would consume EQ before deadeyes fires)
    if (apostate.state.mode == "lock" or apostate.state.mode == "mental")
       and (c1 == "asthma" or c2 == "asthma")
       and not apostate.state.disfigureSent then
      apostate.state.pendingDisfigure = true
      apostate.state.disfigureSent = true
    end

    atk = atk .. ";assess " .. target

    -- Add contemplate if no post-attack actions pending
    if not postCmd then
      atk = atk .. ";contemplate " .. target
    end
  end

  return preCmd, atk, postCmd
end

--------------------------------------------------------------------------------
-- MAIN DISPATCH
-- Entry point called by all backward-compat wrappers and aliases.
-- Validates target, selects curses, builds attack, ensures baalzadeen, sends.
--------------------------------------------------------------------------------

function apostate.dispatch()
  -- Ensure target exists and is in room
  if not target then return end
  if ataxia and ataxia.playersHere and not table.contains(ataxia.playersHere, target) then
    return
  end

  -- Don't act under aeon
  if ataxia and ataxia.afflictions and ataxia.afflictions.aeon then return end

  -- Rebound hold gate
  if reboundHold and reboundHold.gate(apostate.dispatch) then return end

  -- Initialize pm if not set
  if not pm then pm = 100 end

  -- Select curses based on current mode and target state
  apostate.curses = apostate.selectCurses()

  -- Reset disfigure flag when asthma is no longer a curse (ready for next asthma round)
  if apostate.curses[1] ~= "asthma" and apostate.curses[2] ~= "asthma" then
    apostate.state.disfigureSent = false
    -- Kill stale disfigure trigger from a previous asthma round
    if apostate.state.disfigureTrigger then
      killTrigger(apostate.state.disfigureTrigger)
      apostate.state.disfigureTrigger = nil
    end
  end

  -- Debug echo: curses being sent + stuck afflictions
  apostate.debugEcho()

  -- Build the attack
  local preCmd, atkCmd, postCmd = apostate.buildAttack()

  -- Ensure Baalzadeen is present (only summon once, wait for confirmation)
  if baalzadeen and not baalzadeen() and not apostate.state.baalzadeenSummoned then
    send("queue prepend free summon baalzadeen")
    apostate.state.baalzadeenSummoned = true
  end

  -- Don't send if paralysed
  if ataxia and ataxia.afflictions and ataxia.afflictions.paralysis then return end

  -- Assemble and send
  local fullCmd = ""
  if preCmd and postCmd then
    fullCmd = preCmd .. atkCmd .. postCmd
  elseif postCmd then
    fullCmd = atkCmd .. postCmd
  elseif preCmd then
    fullCmd = preCmd .. atkCmd
  else
    fullCmd = atkCmd
  end

  send("queue addclearfull freestand " .. fullCmd)

  -- Disfigure via one-shot trigger: fires when deadeyes curse text appears
  -- Can't use queue (auto-queue fires deadeyes first, consuming balance)
  if apostate.state.pendingDisfigure then
    -- Kill stale trigger from previous dispatch
    if apostate.state.disfigureTrigger then
      killTrigger(apostate.state.disfigureTrigger)
      apostate.state.disfigureTrigger = nil
    end
    local tgt = target  -- capture for closure
    apostate.state.disfigureTrigger = tempTrigger("curse of asthma", function()
      send("disfigure " .. tgt)
      killTrigger(apostate.state.disfigureTrigger)
      apostate.state.disfigureTrigger = nil
    end)
    apostate.state.pendingDisfigure = false
  end

  -- Asthma confirmation: if we delivered smoke-curable curses and target doesn't smoke,
  -- asthma is confirmed present (blocking their smoke cures)
  if apostate.curses[1] == "manaleech" or apostate.curses[2] == "manaleech" then
    if apostate.state.asthmaConfirmTimer then
      killTimer(apostate.state.asthmaConfirmTimer)
    end
    local asthmaProb = apostate.getAffProb("asthma")
    if asthmaProb > 0 and asthmaProb < 1.0 then
      apostate.state.asthmaConfirmTimer = tempTimer(2.5, function()
        apostate.state.asthmaConfirmTimer = nil
        if collapseAffPresentV3 then
          collapseAffPresentV3("asthma")
          apostate.debugEcho()
          cecho("\n<yellow>[APO]<reset> V3: Asthma confirmed (target didn't smoke)\n")
        end
      end)
    end
  end
end

--------------------------------------------------------------------------------
-- DEBUG / STATUS
--------------------------------------------------------------------------------

function apostate.debugEcho()
  local c1 = apostate.curses and apostate.curses[1] or "?"
  local c2 = apostate.curses and apostate.curses[2] or "?"

  -- Key lock afflictions to track
  local lockAffs = {"clumsiness", "asthma", "manaleech", "impatience", "slickness", "anorexia", "paralysis"}
  local stuck = {}
  for _, aff in ipairs(lockAffs) do
    if apostate.hasAff(aff) then
      stuck[#stuck + 1] = aff
    end
  end

  local stuckStr = #stuck > 0 and table.concat(stuck, ", ") or "none"
  local sys = apostate.getTrackingSystem()

  cecho("\n<yellow>[APO]<reset> Curses: <green>" .. c1 .. "<reset> + <green>" .. c2 ..
    "<reset> | Stuck(<cyan>" .. sys .. "<reset>): <red>" .. stuckStr .. "<reset>\n")
end

function apostate.status()
  local sys = apostate.getTrackingSystem()
  local locks = apostate.getLocks()
  local dmg = apostate.corruptDmg()
  echo("\n=== Apostate Offense Status ===\n")
  echo("  Mode: " .. apostate.state.mode .. "\n")
  echo("  Tracking: " .. sys .. "\n")
  echo("  Corrupt Dmg: " .. string.format("%.1f", dmg) .. "\n")
  echo("  Softlock: " .. string.format("%.0f%%", locks.softlock * 100) .. "\n")
  echo("  Hardlock: " .. string.format("%.0f%%", locks.hardlock * 100) .. "\n")
  echo("  Truelock: " .. string.format("%.0f%%", locks.truelock * 100) .. "\n")

  if apostate.curses and #apostate.curses >= 2 then
    echo("  Curses: " .. apostate.curses[1] .. " + " .. apostate.curses[2] .. "\n")
  end

  echo("  Daemon: " .. apostate.state.fiendthing .. "\n")
  echo("  Corrupted: " .. tostring(apostate.state.corrupted) .. "\n")

  if pm then
    echo("  Target Mana: " .. pm .. "%\n")
  end
  if ataxiaTemp and ataxiaTemp.lastAssess then
    echo("  Last Assess: " .. ataxiaTemp.lastAssess .. "\n")
  end
  echo("================================\n")
end

--------------------------------------------------------------------------------
-- MODE SETTERS (for aliases)
--------------------------------------------------------------------------------

function apostate.setMode(mode)
  apostate.state.mode = mode
  -- Kill stale disfigure trigger on mode change
  if apostate.state.disfigureTrigger then
    killTrigger(apostate.state.disfigureTrigger)
    apostate.state.disfigureTrigger = nil
  end
  if ataxiaEcho then
    ataxiaEcho("[Apostate] Mode set to: " .. mode)
  end
end

--------------------------------------------------------------------------------
-- BACKWARD COMPATIBILITY WRAPPERS
-- Old function names route to the apostate namespace system above.
--------------------------------------------------------------------------------

function leviclumsapo()
  apostate.state.mode = "lock"
  apostate.dispatch()
end

function leviweariapo()
  apostate.state.mode = "lock"
  apostate.dispatch()
end

function levisleepapo()
  apostate.state.mode = "sleep"
  apostate.dispatch()
end

function apostate_lock()
  apostate.state.mode = "lock"
  apostate.dispatch()
end

function apostate_lockattack()
  apostate.dispatch()
end

function apostate_lockImpale()
  apostate.state.mode = "lock"
  apostate.dispatch()
end

function apostate_sleepattack()
  apostate.state.mode = "sleep"
  apostate.dispatch()
end

function apostate_clumsy()
  apostate.state.mode = "lock"
  apostate.dispatch()
end

function apostate_vivisect()
  apostate.state.mode = "vivisect"
  apostate.dispatch()
end

function apostate_weari()
  apostate.state.mode = "lock"
  apostate.dispatch()
end

function apostate_mental()
  apostate.setMode("mental")
  apostate.dispatch()
end

function apostate_kelp()
  apostate.state.mode = "lock"
  apostate.dispatch()
end

function apostate_group()
  apostate.state.mode = "group"
  apostate.dispatch()
end

function apostate_clumsyillusion()
  apostate.state.mode = "lock"
  apostate.dispatch()
end

-- Legacy corruptDmg wrapper
function corruptDmg()
  return apostate.corruptDmg()
end

function corruptKill()
  if ataxiaTemp and ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= apostate.corruptDmg() then
    apostate.state.mode = "corrupt"
    apostate.dispatch()
  end
end

function cathCorrupt()
  if pm and pm - apostate.corruptDmg() <= 20 then
    apostate.state.mode = "corrupt"
    apostate.dispatch()
  end
end

--------------------------------------------------------------------------------
-- DAEMON UTILITY FUNCTIONS (used by CC_Apostate and triggers)
--------------------------------------------------------------------------------

function bloodPact()
  if not apo.pentagram() then
    if bloodTimer then
      if not dsum then
        addToCommand("summon daegger")
      end
      addToCommand(
        "wield daegger shield;demon bloodpact &tar for " ..
        pentagramEnt ..
        "/order loyals kill &tar"
      )
    end
  elseif apo.demon() ~= pentagramEnt then
    if not dsum then
      addToCommand("summon daegger")
    end
    addToCommand("wield daegger shield;dispel pentagram;summon " .. pentagramEnt)
  end
end

function bloodworm()
  if not ataxia or not ataxia.denizensHere then return false end
  for _, name in pairs(ataxia.denizensHere) do
    if name:lower():find("bloodworm") then return true end
  end
  return false
end

function baalzadeen()
  if ataxia and ataxia.denizensHere then
    for _, name in pairs(ataxia.denizensHere) do
      if name:lower():find("baalzadeen") then
        return true
      end
    end
  end
  return false
end

function apopentagram()
  if not zgui.roomItemList then
    return false
  end
  if table.contains(zgui.roomItemList, "a floating silver pentagram") then
    return true
  else
    return false
  end
end

function demon()
  if not ataxia or not ataxia.denizensHere then return false end
  for _, name in pairs(ataxia.denizensHere) do
    local ln = name:lower()
    if ln:find("daemonite") then return "daemonite"
    elseif ln:find("nightmare") then return "nightmare"
    elseif ln:find("razor fiend") then return "fiend"
    end
  end
  return ""
end

function daemonite()
  if not ataxia or not ataxia.denizensHere then return false end
  for _, name in pairs(ataxia.denizensHere) do
    if name:lower():find("daemonite") then return true end
  end
  return false
end

function fiend()
  if not ataxia or not ataxia.denizensHere then return false end
  for _, name in pairs(ataxia.denizensHere) do
    if name:lower():find("razor fiend") then return true end
  end
  return false
end

--------------------------------------------------------------------------------
-- NIGHTMARE TRACKING (timer-based affliction prediction)
--------------------------------------------------------------------------------

function nightmare()
  if gmcp.Char.Status.class == "Apostate" and demon() == "nightmare" then
    maretick = tempTimer(6.5, [[maretick = false; maretick = true]])
    nightmareaff = tempTimer(8.5, [[nightmareaff = false; nightmareaff = true]])

    if nightmareaff and tAffs.dementia and tAffs.hypersomnia then
      tarAffed("hellsight")
    elseif nightmareaff and tAffs.hypersomnia and not tAffs.dementia then
      tarAffed("dementia")
    end
  end
end
