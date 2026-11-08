--[[mudlet
type: script
name: Pariah things
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Combat
- Offensive Things
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--------------------------------------------------------------------------------
-- Pariah namespace initialization
-- Loads before levi_scripts/ so pariah.state is ready when 001_Pariah_Logic runs.
--------------------------------------------------------------------------------

pariah = pariah or {}

pariah.state = {
  lastLogograph  = nil,    -- string: current logograph ("nest","bear", etc.) or nil
  bladePrepared  = false,  -- bool: knife has blood for ensorcell/crux
  burrow         = false,  -- string|false: swarm plague name burrowed (e.g. "pyramides")
  infestTimer    = nil,    -- tempTimer handle
  virulenceTimer = nil,    -- tempTimer handle
  latencyTimer   = nil,    -- tempTimer handle (non-nil = latency active on target)
  ensorcellTimer = nil,    -- tempTimer handle
  expose         = false,  -- bool: expose window is open
}

pariah.config = {
  plagueStackThreshold = 2,
  latencyThreshold     = 3,
}

function pariah.echo(text)
  cecho("\n<cyan>[Pariah] " .. text)
end

function pariah.reset()
  if pariah.state.infestTimer    then killTimer(pariah.state.infestTimer)    end
  if pariah.state.virulenceTimer then killTimer(pariah.state.virulenceTimer) end
  if pariah.state.latencyTimer   then killTimer(pariah.state.latencyTimer)   end
  if pariah.state.ensorcellTimer then killTimer(pariah.state.ensorcellTimer) end
  pariah.state.lastLogograph  = nil
  pariah.state.bladePrepared  = false
  pariah.state.burrow         = false
  pariah.state.infestTimer    = nil
  pariah.state.virulenceTimer = nil
  pariah.state.latencyTimer   = nil
  pariah.state.ensorcellTimer = nil
  pariah.state.expose         = false
  ataxia_Echo("Reset pariah variables.")
  send("swarms", false)
end

-- Our TARGET's class, lowercase, or "" when it is not known.
-- First the NDB entry for the target: every class source writes it (classDetect.setAttackerClass
-- for any player whose class line we see, onTargetChanged's cached class, and the API lookup), and
-- it is keyed by the target's own name. "Unknown" (no entry) and a nil class count as not known.
-- Then classDetect's attacker class, but only when that attacker IS the target: attackerClass is
-- whoever last hit US, so in a group it can be a bystander's class.
-- This replaced the global tarClass, which nothing assigned, so the class was always "".
function ataxia_targetClass()
  if type(target) ~= "string" or target == "" then return "" end
  local class
  if ataxiaNDB_getClass then
    local c = ataxiaNDB_getClass(target)
    if type(c) == "string" and c ~= "" and c ~= "Unknown" then class = c end
  end
  if not class then
    local cd = classDetect and classDetect.state
    if cd and type(cd.attackerName) == "string" and type(cd.attackerClass) == "string"
       and cd.attackerName:lower() == target:lower() then
      class = cd.attackerClass
    end
  end
  return class and class:lower() or ""
end

-- We want clumsiness on every class it affects. The user: "33 percent chance to miss your target is
-- huge. Additionally, it starts the kelp stack needed to stick Asthma."
-- This list is the user's, 2026-11-08: "Tekura Monk, Sylvan, Magi, Blademaster, and Elemental Lords
-- are all immune to clumsiness." An unknown class keeps clumsiness.
-- Nothing writes "Tekura": a monk reads "Monk" until a staff line says "Shikudo"
-- (determine_class/006). A Shikudo that kicked first, or one the API filled in, can read "Monk"
-- and count as immune until it hits us with the staff. Shikudo is not immune: our Shikudo seats
-- print "You fumble your strike, the attack going wide."
local CLUMSINESS_IMMUNE = {
  monk = true, tekura = true,
  sylvan = true,
  magi = true,
  blademaster = true,
  airlord = true, earthlord = true, firelord = true, waterlord = true,
}

-- One spelling per class. Class detect writes "Earthlord", game text has "Earth Lord" and "Earth
-- Lady", and GMCP has "earth Elemental Lord" and "air Elemental Lady".
local function clumsinessClassKey(class)
  return (class:lower():gsub("%s+", ""):gsub("elemental", ""):gsub("lady$", "lord"))
end

-- Shared class-aware clumsiness check: returns true if target class is impacted by clumsiness.
-- Used by both pariah (logograph routing) and serpent (ekanelia venom selection).
-- `class` is optional (any case); without it the target's class is read (ataxia_targetClass).
function ataxia_wantClumsiness(class)
  return not CLUMSINESS_IMMUNE[clumsinessClassKey(class or ataxia_targetClass())]
end

function pariah.canGraph(logo)
  local graphs = {
    serpent = {"nest", "scales", "skein"},
    bear    = {"jackal", "scarab"},
    sun     = {"serpent"},
    nest    = {"bear", "skein"},
    scales  = {"bear"},
    skein   = {"scarab", "sun"},
    scarab  = {"jackal"},
    jackal  = {"serpent"},
  }
  if logo == "scorpion" then
    if ataxia.vitals.epitaph >= 4 then
      return true
    else
      return false
    end
  elseif not pariah.state.lastLogograph then
    return true
  elseif table.contains(graphs[pariah.state.lastLogograph], logo) then
    return true
  else
    return false
  end
end

function pariah.canVirulence()
  if checkAffList({"rebbies", "sandfever", "flushings", "pyramides"}, 3) then
    return true
  else
    return false
  end
end

function pariah.doVirulence()
  local need = {"rebbies", "sandfever", "flushings", "pyramides"}
  local plague = false

  for _, aff in pairs(need) do
    if not haveAff(aff) then
      plague = aff
      break
    end
  end
  if not plague then plague = "mycalium" end
  return plague
end

-- Backward-compat stubs
function ataxia_resetPariah()  pariah.reset()               end
function pariah_canGraph(logo) return pariah.canGraph(logo)  end
function pariah_canVirulence() return pariah.canVirulence()  end
function pariah_doVirulence()  return pariah.doVirulence()   end
