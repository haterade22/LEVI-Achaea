--[[mudlet
type: script
name: Class Detect Engine
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- Class Detect
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- Enemy Class Detection + Curingset Auto-Switching
-- Identifies the class of the player attacking us and switches curingset accordingly.
-- 1v1 only: if multiple attackers detected, stays on "normal" curingset.

classDetect = classDetect or {}

--------------------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------------------

classDetect.state = classDetect.state or {
  enabled = true,
  attackerClass = nil,
  attackerName = nil,
  attackers = {},
  currentCuringset = "normal",
  lastSwitchTime = 0,
  combatTimeout = nil,
  lastRoomNum = nil,
}

--------------------------------------------------------------------------------
-- CONFIG (persisted via save/load)
--------------------------------------------------------------------------------

classDetect.config = classDetect.config or {
  combatTimeoutSeconds = 15,
  debounceMs = 500,
  echoSwitches = true,
  proactiveLookup = true,
  apiLookupEnabled = true,
}

--------------------------------------------------------------------------------
-- CURINGSET MAP (1:1, one curingset per class)
--------------------------------------------------------------------------------

classDetect.curingsetMap = classDetect.curingsetMap or {
  ["Serpent"]       = "serpent",
  ["Shaman"]        = "shaman",
  ["Apostate"]      = "apostate",
  ["Bard"]          = "bard",
  ["Blademaster"]   = "blademaster",
  ["Monk"]          = "monk",
  ["Shikudo"]       = "shikudo",
  ["Magi"]          = "magi",
  ["Priest"]        = "priest",
  ["Depthswalker"]  = "depthswalker",
  ["Psion"]         = "psion",
  ["Occultist"]     = "occultist",
  ["Jester"]        = "jester",
  ["Alchemist"]     = "alchemist",
  ["Pariah"]        = "pariah",
  ["Druid"]         = "druid",
  ["Sentinel"]      = "sentinel",
  ["Sylvan"]        = "sylvan",
  ["Infernal"]      = "infernal",
  ["Paladin"]       = "paladin",
  ["Runewarden"]    = "runewarden",
  ["Unnamable"]     = "unnamable",
  ["Airlord"]       = "airlord",
  ["Earthlord"]     = "earthlord",
  ["Firelord"]      = "firelord",
  ["Waterlord"]     = "waterlord",
  ["Dragon"]        = "dragon",
}

--------------------------------------------------------------------------------
-- ECHO
--------------------------------------------------------------------------------

function classDetect.echo(text)
  cecho("\n<dark_orchid>[<light_slate_blue>ClassDetect<dark_orchid>]<lavender>: <plum>" .. text)
end

--------------------------------------------------------------------------------
-- SAVE / LOAD
--------------------------------------------------------------------------------

function classDetect.getSavePath()
  return getMudletHomeDir() .. "/classDetect_config.lua"
end

function classDetect.save()
  local path = classDetect.getSavePath()
  local data = {
    config = classDetect.config,
    curingsetMap = classDetect.curingsetMap,
  }
  table.save(path, data)
end

function classDetect.load()
  local path = classDetect.getSavePath()
  if io.exists(path) then
    local data = {}
    table.load(path, data)
    if data.config then
      for k, v in pairs(data.config) do
        classDetect.config[k] = v
      end
    end
    if data.curingsetMap then
      classDetect.curingsetMap = data.curingsetMap
    end
  end
end

--------------------------------------------------------------------------------
-- ATTACKER COUNT HELPER
--------------------------------------------------------------------------------

local function countAttackers()
  local n = 0
  for _ in pairs(classDetect.state.attackers) do
    n = n + 1
  end
  return n
end

--------------------------------------------------------------------------------
-- CURINGSET SWITCHING (debounced)
--------------------------------------------------------------------------------

function classDetect.switchCuringset(className)
  if not classDetect.state.enabled then return end

  local setName = classDetect.curingsetMap[className] or "normal"
  if setName == classDetect.state.currentCuringset then return end

  local now = getEpoch()
  if (now - classDetect.state.lastSwitchTime) < (classDetect.config.debounceMs / 1000) then return end

  classDetect.state.lastSwitchTime = now
  classDetect.state.currentCuringset = setName
  send("curingset switch " .. setName, false)

  -- Re-apply player's own defence priorities after curingset switch.
  -- Curingsets carry their own SSC defence list which may include abilities
  -- the player doesn't have. This re-sends the correct priorities from the
  -- player's active defence profile (e.g., "shi", "apoo", "bm").
  classDetect.reapplyDefencePriorities()

  if classDetect.config.echoSwitches then
    classDetect.echo("Switched curingset to: <white>" .. setName .. "<plum> (vs <yellow>" .. className .. "<plum>)")
  end
end

--------------------------------------------------------------------------------
-- RESET TO NORMAL
--------------------------------------------------------------------------------

function classDetect.resetToNormal()
  if classDetect.state.currentCuringset == "normal" then
    -- Still clear state even if already on normal
    classDetect.state.attackerClass = nil
    classDetect.state.attackerName = nil
    classDetect.state.attackers = {}
    if classDetect.state.combatTimeout then
      killTimer(classDetect.state.combatTimeout)
      classDetect.state.combatTimeout = nil
    end
    return
  end

  classDetect.state.currentCuringset = "normal"
  classDetect.state.attackerClass = nil
  classDetect.state.attackerName = nil
  classDetect.state.attackers = {}
  if classDetect.state.combatTimeout then
    killTimer(classDetect.state.combatTimeout)
    classDetect.state.combatTimeout = nil
  end

  send("curingset switch normal", false)

  if classDetect.config.echoSwitches then
    classDetect.echo("Combat ended, curingset reset to: <white>normal")
  end
end

--------------------------------------------------------------------------------
-- COMBAT TIMEOUT
--------------------------------------------------------------------------------

function classDetect.resetCombatTimeout()
  if classDetect.state.combatTimeout then
    killTimer(classDetect.state.combatTimeout)
  end
  classDetect.state.combatTimeout = tempTimer(
    classDetect.config.combatTimeoutSeconds,
    function() classDetect.resetToNormal() end
  )
end

--------------------------------------------------------------------------------
-- SET ATTACKER CLASS (called by triggers)
--------------------------------------------------------------------------------

function classDetect.setAttackerClass(attackerName, className)
  if not classDetect.state.enabled then return end
  if not attackerName or attackerName == "" then return end

  attackerName = attackerName:title()

  -- Store in NDB for persistence
  if ataxiaNDB and ataxiaNDB.players then
    ataxiaNDB.players[attackerName] = ataxiaNDB.players[attackerName] or {}
    ataxiaNDB.players[attackerName].class = className
  end

  -- Track unique attackers (1v1 guard)
  classDetect.state.attackers[attackerName:lower()] = true

  -- Reset combat timeout on every incoming attack
  classDetect.resetCombatTimeout()

  -- 1v1 guard: if multiple attackers, reset to normal
  if countAttackers() > 1 then
    if classDetect.state.currentCuringset ~= "normal" then
      classDetect.state.currentCuringset = "normal"
      classDetect.state.attackerClass = nil
      classDetect.state.attackerName = nil
      send("curingset switch normal", false)
      if classDetect.config.echoSwitches then
        classDetect.echo("<red>Multiple attackers detected — staying on <white>normal<plum> curingset")
      end
    end
    return
  end

  -- Single attacker — update and switch
  classDetect.state.attackerName = attackerName
  classDetect.state.attackerClass = className
  classDetect.switchCuringset(className)

  raiseEvent("attacker class detected", attackerName, className)
end

--------------------------------------------------------------------------------
-- PROACTIVE: ON TARGET CHANGE
--------------------------------------------------------------------------------

function classDetect.onTargetChanged()
  if not classDetect.state.enabled then return end
  if not classDetect.config.proactiveLookup then return end
  if not target or target == "" or type(target) == "number" then return end

  local cachedClass = nil
  if ataxiaNDB_getClass then
    cachedClass = ataxiaNDB_getClass(target)
  end

  if cachedClass and cachedClass ~= "Unknown" then
    classDetect.switchCuringset(cachedClass)
    classDetect.state.attackerClass = cachedClass
    classDetect.state.attackerName = target:title()
  elseif classDetect.config.apiLookupEnabled then
    classDetect.apiLookup(target)
  end
end

--------------------------------------------------------------------------------
-- ASYNC API LOOKUP
--------------------------------------------------------------------------------

classDetect._apiPending = classDetect._apiPending or {}

function classDetect.apiLookup(name)
  if not name or name == "" then return end
  local key = name:lower()
  if classDetect._apiPending[key] then return end

  classDetect._apiPending[key] = true
  local path = getMudletHomeDir() .. "/classDetect_" .. key .. ".json"
  downloadFile(path, "http://api.achaea.com/characters/" .. key .. ".json")
end

function classDetect.onApiResponse(_, path)
  if not path or not path:find("classDetect_") then return end

  local key = path:match("classDetect_(%w+)%.json")
  if not key then return end

  classDetect._apiPending[key] = nil

  local f = io.open(path, "r")
  if not f then return end
  local data = f:read("*a")
  f:close()
  os.remove(path)

  if not data or data == "" then return end

  local ok, decoded = pcall(yajl.to_value, data)
  if not ok or not decoded or not decoded.class then return end

  local className = decoded.class
  local titleName = key:lower():gsub("^%l", string.upper)

  -- Cache in NDB
  if ataxiaNDB and ataxiaNDB.players then
    ataxiaNDB.players[titleName] = ataxiaNDB.players[titleName] or {}
    ataxiaNDB.players[titleName].class = className
  end

  -- If still our target, switch
  if target and target:lower() == key then
    classDetect.switchCuringset(className)
    classDetect.state.attackerClass = className
    classDetect.state.attackerName = titleName
    if classDetect.config.echoSwitches then
      classDetect.echo("API lookup: <yellow>" .. titleName .. "<plum> is a <white>" .. className)
    end
  end
end

--------------------------------------------------------------------------------
-- COMBAT END: PLAYER LEFT ROOM
--------------------------------------------------------------------------------

function classDetect.onPlayerLeft()
  if not classDetect.state.enabled then return end
  local person = gmcp.Room.RemovePlayer
  if not person then return end

  -- Remove from attackers set
  classDetect.state.attackers[person:lower()] = nil

  -- If our tracked attacker left, reset
  if classDetect.state.attackerName and
     classDetect.state.attackerName:lower() == person:lower() then
    classDetect.resetToNormal()
  end
end

--------------------------------------------------------------------------------
-- COMBAT END: WE CHANGED ROOMS
--------------------------------------------------------------------------------

function classDetect.onRoomChanged()
  if not classDetect.state.enabled then return end
  if not gmcp or not gmcp.Room or not gmcp.Room.Info then return end

  local newRoom = gmcp.Room.Info.num
  if classDetect.state.lastRoomNum and newRoom ~= classDetect.state.lastRoomNum then
    -- We moved rooms — reset unless we're actively engaged (chasing)
    if not engaged then
      classDetect.resetToNormal()
    end
  end
  classDetect.state.lastRoomNum = newRoom
end

--------------------------------------------------------------------------------
-- COMBAT END: OUR DEATH
--------------------------------------------------------------------------------

function classDetect.onDeath()
  if not classDetect.state.enabled then return end
  if gmcp and gmcp.Char and gmcp.Char.Vitals and gmcp.Char.Vitals.hp == "0" then
    classDetect.resetToNormal()
  end
end

--------------------------------------------------------------------------------
-- STATUS DISPLAY
--------------------------------------------------------------------------------

function classDetect.status()
  cecho("\n<cyan>+==========================================+")
  cecho("\n<cyan>|     <white>CLASS DETECT STATUS<cyan>                  |")
  cecho("\n<cyan>+==========================================+")
  cecho("\n<cyan>| <white>Enabled:     " .. (classDetect.state.enabled and "<green>YES" or "<red>NO"))
  cecho("\n<cyan>| <white>Attacker:    <yellow>" .. (classDetect.state.attackerName or "None"))
  cecho("\n<cyan>| <white>Class:       <yellow>" .. (classDetect.state.attackerClass or "Unknown"))
  cecho("\n<cyan>| <white>Curingset:   <green>" .. classDetect.state.currentCuringset)
  cecho("\n<cyan>| <white>Timeout:     <grey>" .. classDetect.config.combatTimeoutSeconds .. "s")
  local n = countAttackers()
  cecho("\n<cyan>| <white>Attackers:   " .. (n > 1 and "<red>" or "<green>") .. n .. (n > 1 and " (multi — normal)" or ""))
  cecho("\n<cyan>+==========================================+\n")
end

--------------------------------------------------------------------------------
-- SETUP: BULK CREATE CURINGSETS IN-GAME
--------------------------------------------------------------------------------

function classDetect.setup()
  local created = {}
  for _, setName in pairs(classDetect.curingsetMap) do
    if not created[setName] then
      send("curingset new " .. setName, false)
      created[setName] = true
    end
  end
  classDetect.echo("Sent <white>curingset new<plum> for " .. #table.keys(created) .. " curingsets. Check <white>curingset list<plum> in-game.")
end

--------------------------------------------------------------------------------
-- EVENT HANDLER REGISTRATION (with cleanup on reload)
--------------------------------------------------------------------------------

if classDetect._handlers then
  for _, id in pairs(classDetect._handlers) do
    if id then pcall(killAnonymousEventHandler, id) end
  end
end
classDetect._handlers = {}

classDetect._handlers.target = registerAnonymousEventHandler(
  "changed target", "classDetect.onTargetChanged"
)

classDetect._handlers.api = registerAnonymousEventHandler(
  "sysDownloadDone", "classDetect.onApiResponse"
)

classDetect._handlers.playerLeft = registerAnonymousEventHandler(
  "gmcp.Room.RemovePlayer", "classDetect.onPlayerLeft"
)

classDetect._handlers.roomChange = registerAnonymousEventHandler(
  "gmcp.Room.Info", "classDetect.onRoomChanged"
)

classDetect._handlers.death = registerAnonymousEventHandler(
  "gmcp.Char.Vitals", "classDetect.onDeath"
)

--------------------------------------------------------------------------------
-- LOAD SAVED CONFIG
--------------------------------------------------------------------------------

classDetect.load()

classDetect.echo("<green>Class Detect Engine loaded<reset> (enabled: " .. tostring(classDetect.state.enabled) .. ")")
