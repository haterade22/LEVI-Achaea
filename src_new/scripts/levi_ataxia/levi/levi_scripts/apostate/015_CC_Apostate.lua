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
-- Kill Routes:
--   1. True Lock  - DEADEYES curse delivery building toward truelock
--   2. Corrupt    - Stack afflictions then demon corrupt for damage/catharsis
--   3. Vivisect   - Truelock -> prone -> shrivel 4 limbs -> vivisect
--   4. Sleep      - Build asthma + impatience + hypersomnia -> sleep curse
--
-- DEADEYES delivers 2 curses per action (2.3s balance)
-- Lock priority: clumsiness -> asthma -> manaleech -> impatience -> slickness -> anorexia
--------------------------------------------------------------------------------

apostate = apostate or {}

--------------------------------------------------------------------------------
-- STATE & CONFIG
--------------------------------------------------------------------------------

apostate.state = {
  mode = "lock",            -- "lock", "corrupt", "vivisect", "sleep", "group"
  corrupted = false,        -- corrupt has been fired (awaiting catharsis)
  lastCorruptTime = 0,      -- corrupt cooldown tracking
  daeggerhere = false,      -- daegger summoned
  freshblood = false,       -- fresh blood available for bloodpact
  fiendthing = "nightmare", -- preferred lesser daemon
  wantDisloyalty = false,   -- disfigure toggle
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

-- Check if target has an affliction (V3 -> V2 -> V1 routing)
function apostate.hasAff(aff)
  -- V3 system (highest priority - probability-based)
  if affConfigV3 and affConfigV3.enabled then
    if haveAffV3 then
      return haveAffV3(aff)  -- Uses 30% threshold by default
    end
  end
  -- V2 system
  if ataxia and ataxia.settings and ataxia.settings.useAffTrackingV2 then
    if haveAffV2 then
      return haveAffV2(aff)
    elseif tAffsV2 and tAffsV2[aff] then
      return true
    end
    return false
  end
  -- V1 system
  if tAffs and tAffs[aff] then
    return true
  end
  return false
end

-- Get affliction probability (0.0-1.0). Falls back to binary for V2/V1.
function apostate.getAffProb(aff)
  if affConfigV3 and affConfigV3.enabled and getAffProbabilityV3 then
    return getAffProbabilityV3(aff)
  end
  return apostate.hasAff(aff) and 1.0 or 0
end

-- Check which tracking system is active
function apostate.getTrackingSystem()
  if affConfigV3 and affConfigV3.enabled then return "V3"
  elseif ataxia and ataxia.settings and ataxia.settings.useAffTrackingV2 then return "V2"
  end
  return "V1"
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
-- UNIFIED CURSE PRIORITY ENGINE
--------------------------------------------------------------------------------

-- Remove duplicates from a list while preserving order
local function dedupList(list)
  local seen = {}
  local result = {}
  for _, v in ipairs(list) do
    if not seen[v] then
      seen[v] = true
      table.insert(result, v)
    end
  end
  return result
end

-- Select the top 2 curses for DEADEYES, deduplicating and filling gaps.
function apostate.pickTopTwo(curses)
  curses = dedupList(curses)
  if #curses == 0 then
    return {"clumsy", "asthma"}  -- safety fallback
  end
  if #curses == 1 then
    if curses[1] ~= "clumsy" then
      return {curses[1], "clumsy"}
    else
      return {curses[1], "asthma"}
    end
  end
  return {curses[1], curses[2]}
end

-- Main curse selection. Returns table of 2 curse names for DEADEYES.
function apostate.selectCurses()
  local curses = {}
  local mode = apostate.state.mode
  local locks = apostate.getLocks()

  -- PHASE 0: Curseward check (universal - must breach first)
  if apostate.hasAff("curseward") then
    table.insert(curses, "breach")
  end

  -- PHASE 1: Truelock completion
  -- If near truelock, push class-specific lock affliction
  if locks.truelock >= 0.7 then
    local lockAff = nil
    if getLockingAffliction then
      lockAff = getLockingAffliction(target)
    end
    if lockAff and not apostate.hasAff(lockAff) then
      table.insert(curses, lockAff)
    end
  end

  -- PHASE 2: Core lock building
  -- Sequence: clumsiness -> asthma -> manaleech -> impatience -> slickness -> anorexia

  -- Step 1: Clumsiness (fumble herb eating = delays cures)
  if not apostate.hasAff("clumsiness") then
    table.insert(curses, "clumsy")
  end

  -- Step 2: Asthma (blocks smoking = protects manaleech/asthma from cure)
  if not apostate.hasAff("asthma") then
    table.insert(curses, "asthma")
  end

  -- Step 3: Manaleech (drains mana toward catharsis, smoke-cured but blocked by asthma)
  if not apostate.hasAff("manaleech") then
    table.insert(curses, "manaleech")
  end

  -- Step 4: Impatience (blocks FOCUS = mental affliction cure)
  if not apostate.hasAff("impatience") then
    table.insert(curses, "impatience")
  end

  -- Step 5: Slickness (blocks salve application)
  if not apostate.hasAff("slickness") then
    table.insert(curses, "slickness")
  end

  -- Step 6: Anorexia (blocks eating = herb cures)
  if not apostate.hasAff("anorexia") then
    table.insert(curses, "anorexia")
  end

  -- Step 7: Paralysis (tree block + action denial)
  if not apostate.hasAff("paralysis") then
    table.insert(curses, "paralysis")
  end

  -- PHASE 3: Sleep mode additions
  if mode == "sleep" then
    local tarInsomnia = false
    if ataxiaTemp and ataxiaTemp.tarInsomnia ~= nil then
      tarInsomnia = ataxiaTemp.tarInsomnia
    end
    if apostate.hasAff("impatience") and apostate.hasAff("hypersomnia") and not tarInsomnia then
      table.insert(curses, "sleep")
    end
  end

  -- PHASE 4: Nightmare synergy
  -- If nightmare is active and has delivered hypersomnia, push dementia for hellsight chain
  if maretick and not apostate.hasAff("hellsight") and
     apostate.hasAff("hypersomnia") and not apostate.hasAff("dementia") and
     apostate.hasAff("asthma") and apostate.hasAff("impatience") then
    table.insert(curses, "dementia")
  end

  -- PHASE 5: Sensitivity when deaf (strips deafness + applies sensitivity)
  if apostate.hasAff("deafness") then
    if not apostate.hasAff("sensitivity") then
      local tarClass = ""
      if ataxiaNDB_getClass then
        tarClass = ataxiaNDB_getClass(target) or ""
      end
      -- Skip sensitivity against Blademaster/Monk (deaf is core defense)
      if tarClass ~= "Blademaster" and tarClass ~= "Monk" then
        table.insert(curses, "sensitivity")
      end
    end
  end

  -- PHASE 6: Filler afflictions (corrupt damage padding + lock reinforcement)
  local fillers = {
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
  for _, f in ipairs(fillers) do
    if not apostate.hasAff(f.aff) then
      table.insert(curses, f.curse)
    end
  end

  -- PHASE 7: Class lock affliction if not already covered
  if getLockingAffliction then
    local lockAff = getLockingAffliction(target)
    if lockAff and not apostate.hasAff(lockAff) then
      table.insert(curses, lockAff)
    end
  end

  -- Pick top 2 with dedup
  return apostate.pickTopTwo(curses)
end

-- Convenience accessors
function apostate.getCurse1()
  return apostate.curses[1] or "clumsy"
end

function apostate.getCurse2()
  return apostate.curses[2] or "impatience"
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
--------------------------------------------------------------------------------

function apostate.dispatch()
  -- Ensure target exists and is in room
  if not target then return end
  if ataxia and ataxia.playersHere and not table.contains(ataxia.playersHere, target) then
    return
  end

  -- Don't act under aeon
  if ataxia and ataxia.afflictions and ataxia.afflictions.aeon then return end

  -- Initialize pm if not set
  if not pm then pm = 100 end

  -- Select curses based on current mode and target state
  apostate.curses = apostate.selectCurses()

  -- Build the attack
  local preCmd, atkCmd, postCmd = apostate.buildAttack()

  -- Ensure Baalzadeen is present
  if baalzadeen and not baalzadeen() then
    send("queue prepend free summon baalzadeen")
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

  send("queue addclear freestand " .. fullCmd)
end

--------------------------------------------------------------------------------
-- DEBUG / STATUS
--------------------------------------------------------------------------------

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
  if ataxiaEcho then
    ataxiaEcho("[Apostate] Mode set to: " .. mode)
  end
end
