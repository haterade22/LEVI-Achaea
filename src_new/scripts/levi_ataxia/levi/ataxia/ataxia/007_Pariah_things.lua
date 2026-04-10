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

-- Shared class-aware clumsiness check: returns true if target class is impacted by clumsiness.
-- Used by both pariah (logograph routing) and serpent (ekanelia venom selection).
function ataxia_wantClumsiness()
  local class = tarClass or ""
  return class ~= "air"
      and class ~= "fire"
      and class ~= "magi"
      and class ~= "sylvan"
      and class ~= "occultist"
      and class ~= "bard"
      and class ~= "jester"
      and class ~= "blademaster"
      and class ~= "water"
      and class ~= "druid"
      and class ~= "sentinel"
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
