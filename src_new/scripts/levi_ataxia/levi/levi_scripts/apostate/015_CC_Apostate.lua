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
-- Replaces old files 001-013 with a single namespace-based system.
-- Backward-compat wrappers live in 014_Levi_Apostate.lua.
-- Integrates with Affliction Tracker V3 (probability-based), V2, or V1.
--
-- Kill Routes (4 modes):
--   1. True Lock  - DEADEYES curse delivery building toward truelock
--   2. Corrupt    - Stack afflictions then demon corrupt for damage/catharsis
--   3. Vivisect   - Truelock -> prone -> shrivel 4 limbs -> vivisect
--   4. Sleep      - Build asthma + impatience + hypersomnia -> sleep curse
--
-- DEADEYES delivers 2 curses per action (2.3s balance).
-- Curses are selected independently via a dual-slot system:
--
--   Curse 1 (primary) - Direct affliction stacking:
--     clumsiness -> asthma -> manaleech -> impatience -> slickness -> anorexia
--     Then: sleep/nightmare synergies -> sensitivity -> fillers -> class lock aff
--
--   Curse 2 (secondary) - Lock support via sicken cascade:
--     sicken (delivers paralysis) -> impatience -> asthma
--     -> sicken again (delivers manaleech/slickness when asthma protects smoke)
--     -> anorexia -> slickness -> manaleech -> fillers -> class lock aff
--
-- Sicken cascade: sicken delivers paralysis -> manaleech -> slickness in order,
-- based on what the target already has. Asthma blocks smoke cures, protecting
-- manaleech and slickness once applied.
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
-- DUAL-SLOT CURSE PRIORITY ENGINE
--
-- DEADEYES takes 2 curses. Each slot has its own independent priority chain.
-- selectCurses() orchestrates both and handles overrides (curseward, truelock).
--
-- Curse 1 (selectPrimaryCurse): direct affliction delivery
--   clumsiness -> asthma -> manaleech -> impatience -> slickness -> anorexia
--   -> sleep mode / nightmare synergy / sensitivity -> fillers -> class lock aff
--
-- Curse 2 (selectSecondaryCurse): sicken cascade + lock support
--   sicken (paralysis) -> impatience -> asthma
--   -> sicken (manaleech/slickness, protected by asthma blocking smoke cure)
--   -> anorexia -> slickness -> manaleech -> fillers -> class lock aff
--
-- Curse 2 never duplicates curse 1 (c1 passed as parameter to avoid overlap).
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

-- Curse 1: Primary offensive priority chain
function apostate.selectPrimaryCurse()
  -- Core lock building: clumsiness -> asthma -> manaleech -> impatience -> slickness -> anorexia
  if not apostate.hasAff("clumsiness") then return "clumsy" end
  if not apostate.hasAff("asthma") then return "asthma" end
  if not apostate.hasAff("manaleech") then return "manaleech" end
  if not apostate.hasAff("impatience") then return "impatience" end
  if not apostate.hasAff("slickness") then return "slickness" end
  if not apostate.hasAff("anorexia") then return "anorexia" end

  -- Sleep mode
  if apostate.state.mode == "sleep" then
    local tarInsomnia = false
    if ataxiaTemp and ataxiaTemp.tarInsomnia ~= nil then
      tarInsomnia = ataxiaTemp.tarInsomnia
    end
    if apostate.hasAff("impatience") and apostate.hasAff("hypersomnia") and not tarInsomnia then
      return "sleep"
    end
  end

  -- Nightmare synergy: push dementia for hellsight chain
  if maretick and not apostate.hasAff("hellsight") and
     apostate.hasAff("hypersomnia") and not apostate.hasAff("dementia") and
     apostate.hasAff("asthma") and apostate.hasAff("impatience") then
    return "dementia"
  end

  -- Sensitivity when deaf
  if apostate.hasAff("deafness") and not apostate.hasAff("sensitivity") then
    local tarClass = ataxiaNDB_getClass and ataxiaNDB_getClass(target) or ""
    if tarClass ~= "Blademaster" and tarClass ~= "Monk" then
      return "sensitivity"
    end
  end

  -- Fillers
  for _, f in ipairs(apostate.fillers) do
    if not apostate.hasAff(f.aff) then
      return f.curse
    end
  end

  -- Class lock affliction
  if getLockingAffliction then
    local lockAff = getLockingAffliction(target)
    if lockAff and not apostate.hasAff(lockAff) then
      return lockAff
    end
  end

  return "clumsy"  -- ultimate fallback
end

-- Curse 2: Lock support chain (sicken for paralysis/slickness, then lock affs)
function apostate.selectSecondaryCurse(c1)
  -- Direct paralysis when target lacks it
  if not apostate.hasAff("paralysis") and c1 ~= "paralysis" then
    return "paralysis"
  end

  -- After paralysis, build other lock components
  if not apostate.hasAff("impatience") and c1 ~= "impatience" then return "impatience" end
  if not apostate.hasAff("asthma") and c1 ~= "asthma" then return "asthma" end

  -- Sicken again: with asthma present, sicken cascades to manaleech/slickness
  -- (asthma blocks smoke cure, protecting both)
  if apostate.hasAff("asthma") and
     (not apostate.hasAff("manaleech") or not apostate.hasAff("slickness")) and
     c1 ~= "sicken" then
    return "sicken"
  end

  -- Remaining lock afflictions
  if not apostate.hasAff("anorexia") and c1 ~= "anorexia" then return "anorexia" end
  if not apostate.hasAff("slickness") and c1 ~= "slickness" then return "slickness" end
  if not apostate.hasAff("manaleech") and c1 ~= "manaleech" then return "manaleech" end

  -- Fillers (skip whatever c1 is using)
  for _, f in ipairs(apostate.fillers) do
    if not apostate.hasAff(f.aff) and c1 ~= f.curse then
      return f.curse
    end
  end

  -- Class lock affliction
  if getLockingAffliction then
    local lockAff = getLockingAffliction(target)
    if lockAff and not apostate.hasAff(lockAff) and c1 ~= lockAff then
      return lockAff
    end
  end

  if c1 ~= "clumsy" then return "clumsy" end
  return "asthma"
end

-- Main curse selection. Returns table of 2 curse names for DEADEYES.
function apostate.selectCurses()
  local locks = apostate.getLocks()

  -- Curseward: must breach first
  if apostate.hasAff("curseward") then
    return {"breach", apostate.selectSecondaryCurse("breach")}
  end

  -- Truelock completion: push class-specific lock affliction
  if locks.truelock >= 0.7 then
    local lockAff = nil
    if getLockingAffliction then
      lockAff = getLockingAffliction(target)
    end
    if lockAff and not apostate.hasAff(lockAff) then
      return {lockAff, apostate.selectSecondaryCurse(lockAff)}
    end
  end

  -- Normal: curse 1 from primary chain, curse 2 from secondary chain
  local c1 = apostate.selectPrimaryCurse()
  local c2 = apostate.selectSecondaryCurse(c1)
  return {c1, c2}
end

-- Convenience accessors
function apostate.getCurse1()
  return apostate.curses[1] or "clumsy"
end

function apostate.getCurse2()
  return apostate.curses[2] or "sicken"
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
-- Entry point called by all backward-compat wrappers in 014_Levi_Apostate.lua.
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

  -- Initialize pm if not set
  if not pm then pm = 100 end

  -- Select curses based on current mode and target state
  apostate.curses = apostate.selectCurses()

  -- Debug echo: curses being sent + stuck afflictions
  apostate.debugEcho()

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
  if ataxiaEcho then
    ataxiaEcho("[Apostate] Mode set to: " .. mode)
  end
end
