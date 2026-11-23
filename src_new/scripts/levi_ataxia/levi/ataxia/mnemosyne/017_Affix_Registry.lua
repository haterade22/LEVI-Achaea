--[[mudlet
type: script
name: Affix Registry
hierarchy:
- Levi_Ataxia
- Ataxia
- Mnemosyne
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
    ============================================================================
    THE AFFIX REGISTRY  (v4.7.511)
    ============================================================================

    User, 2026-11-21, with Ricketts, Splinterbark and Suffering of Abbadon on the wade status:
    "What happened to us planning for the ongoing effects (affixes?) of the wading?"

    There was no plan. Since v4.7.288 an affix got code only after it hurt us, one trigger at a
    time, and nothing said which affixes of THIS run had a response and which had none. Worse,
    the run's affix list (`M.history.affixes`) was written only with telemetry on
    (`onEffectsHeader` returned on `not M._inRun()`), so `M.hasAffix` was always false for a
    player without a tracker token -- the Prey and Sanguine Restoration checks never ran.

    This file holds:
      * `ataxiaTemp.mnemAffixes` -- this run's affixes, { [name] = description }, written from
        the "Ongoing effects:" block with telemetry on or off, cleared at run start and run end.
      * `M.AFFIX_REGISTRY` -- one row per affix: what our code does about it (`does`), and the
        flags other code reads (`spawnsOnKill`). A row's text is a claim about OUR code, so each
        names the file that does it.
      * `M.onAffixesSeen(list)` -- records the run's affixes and says ONE line per new affix:
        what we do about it, or "no response" with the game's sentence. An affix with no row is
        visible the first ripple it appears, not after the death it causes.
      * `M.runHasAffix(name)` -- exact name, this run, telemetry-independent.
      * `M._spawnHold()` -- the explorer's post-clear hold for the spawn-on-kill affixes.
      * `M.runAffixPermanentAffs()` -- "permanent <affliction>" in this run's affix sentences
        (Tenderised Flesh, Outcast), read by `M.runPermanentAffs` (004).
]]--

ataxia = ataxia or {}
ataxia.mnemosyne = ataxia.mnemosyne or {}
local M = ataxia.mnemosyne

-- ---------------------------------------------------------------------------
-- The registry. `does` = what our code does about the affix, with the file that does it.
-- Keep a row honest: if a handler is removed, remove or change its row.
-- ---------------------------------------------------------------------------
M.AFFIX_REGISTRY = {
  ["Splinterbark"] = { does = "curing tree off for the run (004 onSplinterbarkSeen, trigger 017)" },
  ["Rimewrought"] = { does = "tattoos treated as dead, tree curing and tattoo keep-up off (004, trigger 096)" },
  ["Famine"] = { does = "horn top-up on each room's last kill (004 onFamineSeen, trigger 097)" },
  ["Haemophiliac"] = { does = "explorer waits for the bleed to clot and 90% HP after a room (008, trigger 029)" },
  ["Last Word"] = { does = "explorer waits for 90% HP after a room (008, trigger 056)" },
  ["Bravado"] = { does = "shields and barriers counted as useless; hit-and-run at 2 denizens (004, trigger 059)" },
  ["Deluge"] = { does = "no flying: the escape ladder stays on the ground (004, trigger 037)" },
  ["Prey"] = { does = "no ground retreat: denizens follow it (009 S._retreatBlock)" },
  ["Sanguine Restoration"] = { does = "Monk battlerage uses Inhibit to stop the pool heal (basher/001); other classes: none" },
  ["Necromantic"] = { does = "a rising thrall makes the explorer re-read the room (trigger 060)" },
  -- "All <type> damage you deal is reduced by N%": trigger 053 records the cut (M.damageNulled).
  ["Fireproof"] = { does = "damage cut recorded (trigger 053)" },
  ["Iceproof"] = { does = "damage cut recorded (trigger 053)" },
  ["Grounded"] = { does = "damage cut recorded (trigger 053)" },
  ["Snakeblood"] = { does = "damage cut recorded (trigger 053)" },
  ["Expansive Lungs"] = { does = "damage cut recorded (trigger 053)" },
  ["Blank Mind"] = { does = "damage cut recorded (trigger 053)" },
  ["Null Magic"] = { does = "damage cut recorded (trigger 053)" },
  ["Steel Skin"] = { does = "damage cut recorded (trigger 053)" },
  -- Ricketts: the live buffer of 2026-11-23 (Monk, kb/raw/live/2026-11-23_ricketts-arm-breaks.txt)
  -- shows both arms break, the swing refused ("You cannot do that because both of your arms must
  -- be whole and unbound."), trigger 344 saying so, and a kick-and-uppercut round 0.4 s later
  -- with one arm still broken. So the existing arm handling is the response. Which event makes
  -- the break (our attack or theirs) is not clear from that log.
  ["Ricketts"] = { does = "SSC mends the breaks; a refused swing with both arms broken is handled (trigger 344)" },
  -- Permanent afflictions from the affix sentence: not counted for the class cure, the blackout
  -- tree or the recovery wait (004 M.runPermanentAffs, v4.7.511).
  ["Tenderised Flesh"] = { does = "permanent tenderskin and sensitivity not counted for cures (004 runPermanentAffs)" },
  ["Outcast"] = { does = "permanent disloyalty not counted for cures (004 runPermanentAffs)" },
  -- A kill can bring a new enemy. The explorer waits for 90% HP after a room (M._spawnHold), so
  -- the spawn, or the next room, does not meet a half-spent health pool.
  ["Deathmarked"] = { spawnsOnKill = true, does = "explorer waits for 90% HP after a room (017 M._spawnHold)" },
  ["Deathbound"] = { spawnsOnKill = true, does = "explorer waits for 90% HP after a room (017 M._spawnHold)" },
  ["Dreambound"] = { spawnsOnKill = true, does = "explorer waits for 90% HP after a room (017 M._spawnHold)" },
  ["Dreamcursed"] = { spawnsOnKill = true, does = "explorer waits for 90% HP after a room (017 M._spawnHold)" },
  ["Heretical"] = { spawnsOnKill = true, does = "explorer waits for 90% HP after a room (017 M._spawnHold)" },
  -- The thornwall or gravehands lines are not captured yet; only the pacing hold applies.
  ["Suffering of Abbadon"] = { spawnsOnKill = true, does = "explorer waits for 90% HP after a room (017 M._spawnHold); thornwall lines not captured" },
}

local SPAWN_HOLD_HP = 90 -- the Last Word / Haemophiliac figure (user, 2026-08-02)

local function inTower()
  return ataxiaBasher ~= nil and ataxiaBasher.inMnemosyne == true
end

local function runSet()
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.mnemAffixes = ataxiaTemp.mnemAffixes or {}
  return ataxiaTemp.mnemAffixes
end

-- Run start and the confirmed run end. A resume clears too: the next WADE STATUS re-reads them.
function M.affixReset()
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.mnemAffixes = {}
  ataxiaTemp.mnemAffixGen = (tonumber(ataxiaTemp.mnemAffixGen) or 0) + 1
  if M.explore then M.explore._spawnWait = nil end
end

-- list: { { name, description }, ... } from the "Ongoing effects:" block.
function M.onAffixesSeen(list)
  if type(list) ~= "table" then return end
  local set = runSet()
  for _, a in ipairs(list) do
    local name = type(a) == "table" and a.name
    if type(name) == "string" and name ~= "" and set[name] == nil then
      set[name] = a.description or ""
      ataxiaTemp.mnemAffixGen = (tonumber(ataxiaTemp.mnemAffixGen) or 0) + 1
      if not (M._quiet and M._quiet()) and M.echo then
        local row = M.AFFIX_REGISTRY[name]
        if row and row.does then
          M.echo("Affix <cyan>" .. name .. "<reset>: " .. row.does)
        else
          M.echo("Affix <cyan>" .. name .. "<reset>: <red>no response in our code<reset> -- "
            .. ((a.description and a.description ~= "") and a.description or "(no description)"))
        end
      end
    end
  end
end

-- Is `name` (exact, any case) one of this run's affixes? Reads the telemetry-independent set,
-- then the history (a reload mid-run empties ataxiaTemp until the next WADE STATUS).
function M.runHasAffix(name)
  if type(name) ~= "string" or name == "" then return false end
  local want = name:lower()
  for n in pairs(runSet()) do
    if n:lower() == want then return true end
  end
  local h = M.history
  for _, a in ipairs((h and h.affixes) or {}) do
    if a.run == h.run and type(a.name) == "string" and a.name:lower() == want then return true end
  end
  return false
end

-- The spawn-on-kill affix of this run, or nil.
function M.runSpawnAffix()
  for n in pairs(runSet()) do
    local row = M.AFFIX_REGISTRY[n]
    if row and row.spawnsOnKill then return n end
  end
  return nil
end

-- TRUE while the explorer should wait after a cleared room: a spawn-on-kill affix is up and HP
-- is below SPAWN_HOLD_HP. Second return: the affix name, for the echo.
function M._spawnHold()
  if not inTower() then return false end
  local name = M.runSpawnAffix()
  if not name then return false end
  local hp = tonumber(ataxia and ataxia.vitals and ataxia.vitals.hpp) or 100
  return hp < SPAWN_HOLD_HP, name
end

-- { [affliction] = <affix> } for "permanent <affliction>" in this run's affix sentences.
function M.runAffixPermanentAffs()
  local out = {}
  if not M._permanentAffsFrom then return out end
  local names = {}
  for n in pairs(runSet()) do names[#names + 1] = n end
  table.sort(names)
  for _, n in ipairs(names) do
    for _, aff in ipairs(M._permanentAffsFrom(runSet()[n])) do out[aff] = out[aff] or n end
  end
  return out
end

-- `mnem affixes`: this run's affixes, each with our response or "no response".
function M.reportAffixRegistry()
  local set = runSet()
  local names = {}
  for n in pairs(set) do names[#names + 1] = n end
  table.sort(names)
  M.echo("<gold>This run's affixes (" .. #names .. "):")
  if #names == 0 then
    return cecho("\n  <grey>(none seen yet -- they are read from WADE STATUS after each GO!)")
  end
  for _, n in ipairs(names) do
    local row = M.AFFIX_REGISTRY[n]
    cecho("\n  <cyan>" .. n .. "<reset>: "
      .. ((row and row.does) and ("<green>" .. row.does) or "<red>no response in our code"))
    if set[n] ~= "" then cecho("\n      <grey>" .. set[n]) end
  end
end
