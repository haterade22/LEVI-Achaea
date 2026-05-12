--[[mudlet
type: script
name: Rebound Hold
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- System-related
- Deffing
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--------------------------------------------------------------------------------
-- REBOUND HOLD: Delay attacks when rebounding is about to return
--
-- When our rebounding is stripped and about to come back up, holds the attack
-- so the enemy must waste their action stripping it again. Only activates
-- against physical-attack classes (Knights, Serpent, Psion, Blademaster, Bard).
--
-- Usage:
--   rbhold          Toggle on/off
--   rbhold on/off   Explicit enable/disable
--   rbhold debug    Toggle debug echoes
--   rbhold status   Show current state
--
-- Integration: each class dispatch adds:
--   if reboundHold and reboundHold.gate(dispatchFn) then return end
--------------------------------------------------------------------------------

reboundHold = reboundHold or {}
reboundHold.config = reboundHold.config or {}
reboundHold.state = reboundHold.state or {}

--------------------------------------------------------------------------------
-- CONFIGURATION
--------------------------------------------------------------------------------

reboundHold.config.enabled = false
reboundHold.config.REBOUND_RECOVERY = reboundHold.config.REBOUND_RECOVERY or 8.5
reboundHold.config.HOLD_WINDOW = reboundHold.config.HOLD_WINDOW or 1.0
reboundHold.config.STRIP_WAIT = reboundHold.config.STRIP_WAIT or 1.5
reboundHold.config.MAX_HOLD_TIMEOUT = reboundHold.config.MAX_HOLD_TIMEOUT or 10.0
reboundHold.config.debugEcho = reboundHold.config.debugEcho or false

-- Classes whose attacks are blocked by our rebounding
reboundHold.PHYSICAL_CLASSES = {
  Runewarden = true, Infernal = true, Paladin = true,
  Serpent = true, Psion = true, Blademaster = true, Bard = true,
}

--------------------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------------------

reboundHold.state.reboundLostAt = nil
reboundHold.state.holding = false
reboundHold.state.heldDispatchFn = nil
reboundHold.state.holdTimerId = nil
reboundHold.state.stripWaitTimerId = nil
reboundHold.state.reboundReturnedWhileHolding = false

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------

local function debugEcho(msg)
  if reboundHold.config.debugEcho then
    cecho("\n<yellow>[RBH]<reset> " .. msg)
  end
end

function reboundHold.cancelTimer(timerKey)
  if reboundHold.state[timerKey] then
    killTimer(reboundHold.state[timerKey])
    reboundHold.state[timerKey] = nil
  end
end

function reboundHold.reset()
  reboundHold.state.holding = false
  reboundHold.state.heldDispatchFn = nil
  reboundHold.state.reboundReturnedWhileHolding = false
  reboundHold.cancelTimer("holdTimerId")
  reboundHold.cancelTimer("stripWaitTimerId")
end

--------------------------------------------------------------------------------
-- CORE LOGIC
--------------------------------------------------------------------------------

function reboundHold.shouldHold()
  if not reboundHold.config.enabled then return false end
  if reboundHold.state.holding then return true end
  if ataxiaBasher and ataxiaBasher.enabled then return false end
  if not reboundHold.state.reboundLostAt then return false end

  -- Rebounding already up — no need to hold
  if ataxia and ataxia.defences and ataxia.defences["rebounding"] then return false end

  -- Only hold against physical-attack classes
  local targetClass = ataxiaNDB_getClass and ataxiaNDB_getClass(target)
  if not targetClass or not reboundHold.PHYSICAL_CLASSES[targetClass] then return false end

  -- Predict when rebounding will return
  local elapsed = os.clock() - reboundHold.state.reboundLostAt
  local timeUntilRebound = reboundHold.config.REBOUND_RECOVERY - elapsed

  if timeUntilRebound <= 0 or timeUntilRebound > reboundHold.config.HOLD_WINDOW then
    return false
  end

  debugEcho("Should hold: rebounding in ~" .. string.format("%.1f", timeUntilRebound) .. "s")
  return true
end

function reboundHold.gate(dispatchFn)
  if not reboundHold.shouldHold() then
    return false
  end

  reboundHold.state.holding = true
  reboundHold.state.heldDispatchFn = dispatchFn
  reboundHold.state.reboundReturnedWhileHolding = false

  debugEcho("<cyan>HOLDING<reset> attack — waiting for rebounding")

  -- Safety timeout
  reboundHold.state.holdTimerId = tempTimer(reboundHold.config.MAX_HOLD_TIMEOUT, function()
    reboundHold.state.holdTimerId = nil
    debugEcho("<red>MAX_HOLD_TIMEOUT<reset> expired — firing anyway")
    reboundHold.fire()
  end)

  return true
end

function reboundHold.fire()
  local fn = reboundHold.state.heldDispatchFn
  reboundHold.reset()

  if fn then
    if gmcp.Char.Vitals.bal == "1" then
      fn()
    else
      debugEcho("<red>Lost balance during hold<reset> — attack dropped")
    end
  end
end

--------------------------------------------------------------------------------
-- EVENT CALLBACKS
--------------------------------------------------------------------------------

function reboundHold.onReboundLost()
  reboundHold.state.reboundLostAt = os.clock()
  debugEcho("Rebounding lost at " .. string.format("%.3f", reboundHold.state.reboundLostAt))
end

function reboundHold.onReboundGained()
  if not reboundHold.state.holding then return end

  reboundHold.state.reboundReturnedWhileHolding = true
  debugEcho("Rebounding <green>UP<reset> while holding — waiting for enemy strip")

  -- Cancel safety timeout (rebounding came back, entering strip-wait)
  reboundHold.cancelTimer("holdTimerId")

  -- Start strip-wait: if enemy strips within STRIP_WAIT, fire immediately
  -- If it stays up, fire anyway (attacking with rebounding is fine)
  reboundHold.state.stripWaitTimerId = tempTimer(reboundHold.config.STRIP_WAIT, function()
    reboundHold.state.stripWaitTimerId = nil
    debugEcho("Strip-wait expired (rebounding still up) — firing")
    reboundHold.fire()
  end)
end

function reboundHold.onReboundStrippedDuringWait()
  if not reboundHold.state.holding then return end
  if not reboundHold.state.reboundReturnedWhileHolding then return end

  reboundHold.cancelTimer("stripWaitTimerId")
  debugEcho("<green>Enemy stripped rebounding<reset> — firing immediately (wasted action)")
  reboundHold.fire()
end

--------------------------------------------------------------------------------
-- EVENT HANDLER REGISTRATION
--------------------------------------------------------------------------------

-- Clean up old handlers
if reboundHold._handlers then
  for _, id in pairs(reboundHold._handlers) do
    if killAnonymousEventHandler then killAnonymousEventHandler(id) end
  end
end
reboundHold._handlers = {}

-- Rebounding gained (GMCP defence added)
reboundHold._handlers.defAdd = registerAnonymousEventHandler("gmcp.Char.Defences.Add", function()
  local def = gmcp.Char.Defences.Add.name:lower()
  if def == "rebounding" then
    reboundHold.onReboundGained()
  end
end)

-- Rebounding lost (GMCP defence removed)
reboundHold._handlers.defRemove = registerAnonymousEventHandler("gmcp.Char.Defences.Remove", function()
  local def = gmcp.Char.Defences.Remove[1]:lower()
  if def == "rebounding" then
    if reboundHold.state.holding and reboundHold.state.reboundReturnedWhileHolding then
      reboundHold.onReboundStrippedDuringWait()
    else
      reboundHold.onReboundLost()
    end
  end
end)

-- Cancel hold if we move rooms
reboundHold._handlers.roomChange = registerAnonymousEventHandler("gmcp.Room.Info", function()
  if reboundHold.state.holding then
    debugEcho("<red>Room changed<reset> — cancelling hold")
    reboundHold.reset()
  end
end)

-- Cancel hold if target leaves room
reboundHold._handlers.roomPlayers = registerAnonymousEventHandler("gmcp.Room.Players", function()
  if reboundHold.state.holding and target then
    if ataxia and ataxia.playersHere and not table.contains(ataxia.playersHere, target) then
      debugEcho("<red>Target left room<reset> — cancelling hold")
      reboundHold.reset()
    end
  end
end)

-- Cancel hold on death (hp=0)
reboundHold._handlers.death = registerAnonymousEventHandler("gmcp.Char.Vitals", function()
  if reboundHold.state.holding and gmcp.Char.Vitals.hp == "0" then
    reboundHold.reset()
  end
end)

--------------------------------------------------------------------------------
-- STATUS
--------------------------------------------------------------------------------

function reboundHold.status()
  local cfg = reboundHold.config
  local st = reboundHold.state
  echo("\n=== Rebound Hold Status ===\n")
  echo("  Enabled:          " .. tostring(cfg.enabled) .. "\n")
  echo("  Holding:          " .. tostring(st.holding) .. "\n")
  echo("  Rebound Recovery: " .. cfg.REBOUND_RECOVERY .. "s\n")
  echo("  Hold Window:      " .. cfg.HOLD_WINDOW .. "s\n")
  echo("  Strip Wait:       " .. cfg.STRIP_WAIT .. "s\n")
  echo("  Max Hold Timeout: " .. cfg.MAX_HOLD_TIMEOUT .. "s\n")
  echo("  Debug:            " .. tostring(cfg.debugEcho) .. "\n")
  if st.reboundLostAt then
    local elapsed = os.clock() - st.reboundLostAt
    local eta = cfg.REBOUND_RECOVERY - elapsed
    echo("  Rebound lost:     " .. string.format("%.1f", elapsed) .. "s ago\n")
    echo("  ETA to return:    " .. string.format("%.1f", math.max(0, eta)) .. "s\n")
  else
    echo("  Rebound lost:     (not tracked)\n")
  end
  -- Target class check
  local targetClass = ataxiaNDB_getClass and target and ataxiaNDB_getClass(target)
  if targetClass then
    local physical = reboundHold.PHYSICAL_CLASSES[targetClass] and "YES" or "NO"
    echo("  Target class:     " .. targetClass .. " (physical: " .. physical .. ")\n")
  end
  echo("============================\n")
end

--------------------------------------------------------------------------------
-- ALIAS REGISTRATION
--------------------------------------------------------------------------------

if reboundHold._aliases then
  for _, id in pairs(reboundHold._aliases) do
    if killAlias then killAlias(id) end
  end
end
reboundHold._aliases = {}

if tempAlias then
  reboundHold._aliases.toggle = tempAlias("^rbhold(?: (.+))?$", function()
    local arg = matches[2]
    if arg == "on" then
      reboundHold.config.enabled = true
    elseif arg == "off" then
      reboundHold.config.enabled = false
      reboundHold.reset()
    elseif arg == "debug" then
      reboundHold.config.debugEcho = not reboundHold.config.debugEcho
      cecho("\n<yellow>[RBH]<reset> Debug: " .. tostring(reboundHold.config.debugEcho) .. "\n")
      return
    elseif arg == "status" then
      reboundHold.status()
      return
    else
      reboundHold.config.enabled = not reboundHold.config.enabled
      if not reboundHold.config.enabled then reboundHold.reset() end
    end
    cecho("\n<yellow>[RBH]<reset> Rebound hold: " .. (reboundHold.config.enabled and "<green>ON" or "<red>OFF") .. "<reset>\n")
  end)
end

--------------------------------------------------------------------------------
-- INIT MESSAGE
--------------------------------------------------------------------------------

cecho("\n<yellow>[RBH]<reset> Rebound Hold system loaded. Toggle: <white>rbhold<reset>\n")
