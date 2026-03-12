--- mock_mudlet.lua — Minimal Mudlet API mock for unit testing
-- Stubs core Mudlet functions so combat logic can run outside the client.
-- Usage: require("tests.mock_mudlet") at the top of test files.

local M = {}

-- Capture tables for assertions
M.sent_commands = {}
M.raised_events = {}
M.echoed_lines = {}
M.active_timers = {}
M.active_triggers = {}
M.named_handlers = {}

-- Timer ID counter
local _timer_id = 0
local _trigger_id = 0

--- Reset all captured state between tests
function M.reset()
  M.sent_commands = {}
  M.raised_events = {}
  M.echoed_lines = {}
  M.active_timers = {}
  M.active_triggers = {}
  M.named_handlers = {}
  _timer_id = 0
  _trigger_id = 0
end

-- Core send functions
function send(cmd, echo)
  table.insert(M.sent_commands, cmd)
end

function sendAll(...)
  for _, cmd in ipairs({...}) do
    table.insert(M.sent_commands, cmd)
  end
end

function sendGMCP(msg)
  table.insert(M.sent_commands, "GMCP:" .. msg)
end

-- Echo/display functions
function cecho(text)
  table.insert(M.echoed_lines, text)
end

function decho(text)
  table.insert(M.echoed_lines, text)
end

function hecho(text)
  table.insert(M.echoed_lines, text)
end

function echo(text)
  table.insert(M.echoed_lines, text)
end

function display(val)
  table.insert(M.echoed_lines, tostring(val))
end

function debugc(text)
  -- silent in tests
end

-- Timer functions
function tempTimer(delay, callback)
  _timer_id = _timer_id + 1
  M.active_timers[_timer_id] = { delay = delay, callback = callback }
  return _timer_id
end

function killTimer(id)
  M.active_timers[id] = nil
end

-- Trigger functions
function tempTrigger(pattern, callback)
  _trigger_id = _trigger_id + 1
  M.active_triggers[_trigger_id] = { pattern = pattern, callback = callback }
  return _trigger_id
end

function tempRegexTrigger(pattern, callback)
  _trigger_id = _trigger_id + 1
  M.active_triggers[_trigger_id] = { pattern = pattern, callback = callback, regex = true }
  return _trigger_id
end

function tempExactMatchTrigger(pattern, callback)
  _trigger_id = _trigger_id + 1
  M.active_triggers[_trigger_id] = { pattern = pattern, callback = callback, exact = true }
  return _trigger_id
end

function killTrigger(id)
  M.active_triggers[id] = nil
end

-- Alias functions
function tempAlias(pattern, callback)
  return 1
end

function killAlias(id) end

-- Enable/disable stubs
function enableTrigger(name) return true end
function disableTrigger(name) return true end
function enableAlias(name) return true end
function disableAlias(name) return true end
function enableTimer(name) return true end
function disableTimer(name) return true end
function enableKey(name) return true end
function disableKey(name) return true end
function enableScript(name) return true end
function disableScript(name) return true end
function exists(name, type) return 0 end
function isActive(name, type) return 0 end

-- Event system
function raiseEvent(event, ...)
  table.insert(M.raised_events, { name = event, args = {...} })
  -- Fire registered handlers
  if M.named_handlers[event] then
    for _, handler in pairs(M.named_handlers[event]) do
      handler(event, ...)
    end
  end
end

function registerAnonymousEventHandler(event, func)
  if not M.named_handlers[event] then
    M.named_handlers[event] = {}
  end
  table.insert(M.named_handlers[event], func)
  return #M.named_handlers[event]
end

function registerNamedEventHandler(namespace, name, event, func)
  if not M.named_handlers[event] then
    M.named_handlers[event] = {}
  end
  M.named_handlers[event][namespace .. "." .. name] = func
end

function killAnonymousEventHandler(id) end

-- Path / environment stubs
function getMudletHomeDir()
  return "/tmp/mudlet-test"
end

function getProfilePath()
  return "/tmp/mudlet-test/profiles/test"
end

function getOS()
  return "TestOS"
end

-- Stopwatch stubs
function createStopWatch(name) return 1 end
function startStopWatch(id) end
function stopStopWatch(id) end
function resetStopWatch(id) end
function getStopWatchTime(id) return 0 end
function getEpoch() return os.time() end

-- Download stubs
function downloadFile(path, url) return true end

-- GUI stubs (no-op in tests)
function createLabel(...) return "label1" end
function createMiniConsole(...) return "console1" end
function createGauge(...) return "gauge1" end
function moveWindow(...) end
function resizeWindow(...) end
function setLabelStyleSheet(...) end
function setBackgroundColor(...) end
function setBorderColor(...) end
function setBorderTop(...) end
function setBorderBottom(...) end
function setBorderLeft(...) end
function setBorderRight(...) end
function setAppStyleSheet(...) end
function getMainWindowSize() return 1920, 1080 end
function getUserWindowSize(...) return 400, 300 end
function setMiniConsoleFontSize(...) end
function setFont(...) end
function setFontSize(...) end
function showNotification(...) end
function openUrl(...) end
function setClipboardText(...) end

-- Selection/formatting stubs
function selectString(...) return 0 end
function selectSection(...) end
function setBold(...) end
function setItalics(...) end
function setUnderline(...) end
function setStrikeOut(...) end
function setFgColor(...) end
function setBgColor(...) end
function resetFormat() end
function moveCursor(...) end
function moveCursorEnd(...) end
function getLineCount() return 1 end
function getLineNumber() return 1 end
function getCurrentLine() return "" end
function getLastLineNumber() return 1 end
function wrapLine(...) end
function setWindowWrap(...) end
function appendBuffer(...) end
function copy(...) end
function paste(...) end

-- Link/popup stubs
function cechoLink(...) end
function dechoLink(...) end
function echoLink(...) end
function cechoPopup(...) end
function dechoPopup(...) end
function echoPopup(...) end

-- Key stubs
function tempKey(...) return 1 end

-- Sound stubs
function playSoundFile(...) end
function stopSounds() end

-- Window stubs
function closeUserWindow(...) end
function hideWindow(...) end
function showWindow(...) end

-- Expand alias
function expandAlias(cmd) send(cmd) end
function feedTriggers(text) end

-- Geyser / Adjustable stubs
Geyser = Geyser or {}
Adjustable = Adjustable or {}

-- GMCP stub
gmcp = gmcp or {}

-- Mudlet implicit variables
matches = matches or {}
multimatches = multimatches or {}
line = ""

-- Mapper stubs (minimal)
function createMapper(...) end
function centerview(...) end
function addRoom(...) end
function createRoomID() return 1 end
function getRoomName(...) return "" end
function getRoomArea(...) return 0 end
function getRoomCoordinates(...) return 0, 0, 0 end
function getRoomExits(...) return {} end
function getAreaRooms(...) return {} end
function getAreaTable() return {} end
function searchRoom(...) return {} end
function getPath(...) return false end
function speedwalk(...) end

-- Lua extension stubs that Mudlet adds
if not table.save then
  function table.save(t, f) end
end
if not table.load then
  function table.load(f) return {} end
end
if not io.exists then
  io.exists = function(path)
    local f = io.open(path, "r")
    if f then f:close() return true end
    return false
  end
end

--- Fire all pending timers (for testing async logic)
function M.fire_timers()
  for id, timer in pairs(M.active_timers) do
    if type(timer.callback) == "function" then
      timer.callback()
    elseif type(timer.callback) == "string" then
      loadstring(timer.callback)()
    end
  end
  M.active_timers = {}
end

--- Get the last N sent commands
function M.last_commands(n)
  n = n or 1
  local result = {}
  for i = math.max(1, #M.sent_commands - n + 1), #M.sent_commands do
    table.insert(result, M.sent_commands[i])
  end
  return result
end

--- Check if a specific command was sent
function M.was_sent(cmd)
  for _, c in ipairs(M.sent_commands) do
    if c == cmd then return true end
  end
  return false
end

--- Check if a specific event was raised
function M.was_raised(event_name)
  for _, e in ipairs(M.raised_events) do
    if e.name == event_name then return true end
  end
  return false
end

return M
