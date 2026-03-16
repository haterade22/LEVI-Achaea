--[[mudlet
type: script
name: Target Priority
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- Mage
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

---------------------------------------------------
-- Target Priority Queue System
-- Ordered kill list with cycling, party sync,
-- and presence-aware auto-targeting.
---------------------------------------------------

tprio = tprio or {}
tprio.list = tprio.list or {}
tprio.current = tprio.current or 0
tprio.playersInRoom = tprio.playersInRoom or {}

-- Clean up previous event handlers on reload
if tprio._handlers then
  for _, id in ipairs(tprio._handlers) do
    killAnonymousEventHandler(id)
  end
end
tprio._handlers = {}

---------------------------------------------------
-- Helpers
---------------------------------------------------

local function clamp(val, min, max)
  return math.max(min, math.min(max, val))
end

-- Normalize name to titlecase: first letter upper, rest lower
local function normalizeName(name)
  if not name or type(name) ~= "string" or name == "" then return nil end
  return name:lower():gsub("^%l", string.upper)
end

-- Find index of name in tprio.list, or nil
local function indexOf(name)
  for i, v in ipairs(tprio.list) do
    if v == name then return i end
  end
  return nil
end

-- Strip "the soul of " prefix from player fullnames (GMCP sends these)
local function stripSoulPrefix(fullname)
  if not fullname or type(fullname) ~= "string" then return fullname end
  return fullname:gsub("^the soul of ", "")
end

---------------------------------------------------
-- Core Functions
---------------------------------------------------

-- Add a name to end of list (deduplicated, titlecase normalized)
function tprio.add(name)
  local normalized = normalizeName(name)
  if not normalized then return end
  if indexOf(normalized) then
    ataxiaEcho("Target <white>" .. normalized .. "<plum> is already in the priority list.")
    return
  end
  table.insert(tprio.list, normalized)
  if #tprio.list == 1 then
    tprio.current = 1
  end
  ataxiaEcho("Added <white>" .. normalized .. "<plum> to priority list at position " .. #tprio.list .. ".")
end

-- Remove a name from the list, adjusting current index
function tprio.remove(name)
  local normalized = normalizeName(name)
  if not normalized then return end
  local idx = indexOf(normalized)
  if not idx then
    ataxiaEcho("Target <white>" .. normalized .. "<plum> is not in the priority list.")
    return
  end
  table.remove(tprio.list, idx)
  -- Adjust current index
  if #tprio.list == 0 then
    tprio.current = 0
  elseif tprio.current > #tprio.list then
    tprio.current = #tprio.list
  elseif idx < tprio.current then
    tprio.current = tprio.current - 1
  end
  ataxiaEcho("Removed <white>" .. normalized .. "<plum> from priority list.")
end

-- Clear the list entirely
function tprio.reset()
  tprio.list = {}
  tprio.current = 0
  ataxiaEcho("Priority list cleared.")
end

-- Add multiple names. Accepts a space/comma-separated string or a table.
-- Resets the list first, then adds all.
function tprio.addGroup(input)
  if not input then return end
  tprio.list = {}
  tprio.current = 0

  local names = {}
  if type(input) == "table" then
    names = input
  elseif type(input) == "string" then
    for word in input:gmatch("[^%s,]+") do
      table.insert(names, word)
    end
  end

  for _, name in ipairs(names) do
    local normalized = normalizeName(name)
    if normalized and not indexOf(normalized) then
      table.insert(tprio.list, normalized)
    end
  end

  if #tprio.list > 0 then
    tprio.current = 1
  end
  tprio.print()
end

-- Echo the priority list with numbered positions, highlighting current target
function tprio.print()
  if #tprio.list == 0 then
    ataxiaEcho("Priority list is empty.")
    return
  end
  ataxiaEcho("Target Priority List:")
  for i, name in ipairs(tprio.list) do
    local marker = ""
    if target and normalizeName(target) == name then
      marker = " <yellow><< current"
    elseif i == tprio.current then
      marker = " <dark_turquoise><< queued"
    end
    local color = (target and normalizeName(target) == name) and "<yellow>" or "<white>"
    cecho("\n  " .. color .. i .. ". " .. name .. marker)
  end
end

-- Return a formatted string of the target list
function tprio.string()
  if #tprio.list == 0 then return "(empty)" end
  local parts = {}
  for i, name in ipairs(tprio.list) do
    local prefix = (target and normalizeName(target) == name) and "*" or ""
    table.insert(parts, prefix .. i .. "." .. name)
  end
  return table.concat(parts, ", ")
end

-- Announce to party
function tprio.pt()
  if #tprio.list == 0 then
    ataxiaEcho("Priority list is empty, nothing to announce.")
    return
  end
  send("pt Targets: " .. table.concat(tprio.list, ", "))
end

---------------------------------------------------
-- Cycling Functions
---------------------------------------------------

-- Resync tprio.current to wherever the global `target` actually is in the list
local function resyncCurrent()
  if not target or type(target) ~= "string" or target == "" then return end
  local normalized = normalizeName(target)
  local idx = indexOf(normalized)
  if idx then
    tprio.current = idx
  end
end

-- Cycle to next target in list
function tprio.next()
  if #tprio.list == 0 then
    ataxiaEcho("Priority list is empty.")
    return
  end
  resyncCurrent()
  local next_idx = clamp(tprio.current + 1, 1, #tprio.list)
  if next_idx == tprio.current and #tprio.list > 1 then
    -- Already at end, wrap or stay
    ataxiaEcho("Already at end of priority list.")
    return
  end
  tprio.current = next_idx
  tprio.switchTo(tprio.list[tprio.current])
end

-- Cycle to previous target in list
function tprio.previous()
  if #tprio.list == 0 then
    ataxiaEcho("Priority list is empty.")
    return
  end
  resyncCurrent()
  local prev_idx = clamp(tprio.current - 1, 1, #tprio.list)
  if prev_idx == tprio.current and #tprio.list > 1 then
    ataxiaEcho("Already at start of priority list.")
    return
  end
  tprio.current = prev_idx
  tprio.switchTo(tprio.list[tprio.current])
end

-- Jump to first target in list
function tprio.first()
  if #tprio.list == 0 then
    ataxiaEcho("Priority list is empty.")
    return
  end
  tprio.current = 1
  tprio.switchTo(tprio.list[1])
end

-- The actual target switch. Delegates to existing switchTarget() when available.
function tprio.switchTo(name)
  if not name or type(name) ~= "string" or name == "" then return end
  local normalized = normalizeName(name)
  if not normalized then return end

  -- Update index
  local idx = indexOf(normalized)
  if idx then
    tprio.current = idx
  end

  -- Use existing switchTarget if available (handles all state resets, V3 clearing, events)
  if switchTarget and type(switchTarget) == "function" then
    -- switchTarget reads from matches[2], so we set that up
    -- Actually, switchTarget() overwrites target with matches[2] at line 68-72
    -- We need to set matches[2] for it, or just do it manually
    -- Looking at the code, switchTarget uses matches[2] directly, which is alias-dependent
    -- Safer to do the targeting manually and raise the event
    target = normalized
    send("unally " .. normalized .. ataxia.settings.separator .. "enemy " .. normalized .. ataxia.settings.separator .. "st " .. normalized)
    send("settarget " .. normalized)
    -- Reset combat state (same as switchTarget does)
    if resetStatesV3 then resetStatesV3() end
    if setafflictionstackslevi then setafflictionstackslevi() end
    if targetresetafflictionslevi then targetresetafflictionslevi() end
    if lb and lb.resetAll then lb.resetAll(normalized) end
    php = 100
    targetHealth = 100
    pm = 100
    tburns = 0
    if tAffs then
      tAffs.burns = 0
      tAffs.rebounding = true
      tAffs.shield = false
      tAffs.curseward = false
    end
    if magi and magi.offense and magi.offense.state then magi.offense.state.burns = 0 end
    tBals = {tree = true, focus = true, plant = true, salve = true, timers = {}, passive = true}
    if ataxiaTemp then ataxiaTemp.bleeding = 0 end
    if lb and lb.resetAll then lb.resetAll(normalized) end
    raiseEvent("changed target")
    ataxiaEcho("Priority target: <white>" .. normalized .. "<plum>.")
  else
    -- Fallback if switchTarget doesn't exist
    target = normalized
    send("st " .. normalized)
    send("settarget " .. normalized)
    raiseEvent("changed target")
    ataxiaEcho("Priority target: <white>" .. normalized .. "<plum>.")
  end

  -- Party announce (quiet, no local echo)
  send("pt Target: " .. normalized, false)
end

---------------------------------------------------
-- Presence-Aware Auto-Targeting
---------------------------------------------------

-- Check if a player is currently in the room
local function isPlayerInRoom(name)
  if not name then return false end
  local normalized = normalizeName(name)

  -- Check our local presence table first
  if tprio.playersInRoom[normalized] then return true end

  -- Fallback to ataxia.playersHere
  if ataxia and ataxia.playersHere and type(ataxia.playersHere) == "table" then
    for _, v in pairs(ataxia.playersHere) do
      if normalizeName(v) == normalized then return true end
    end
  end

  return false
end

-- If current target is NOT in the room, auto-switch to first priority target who IS present
function tprio.autoTarget()
  if #tprio.list == 0 then return end

  -- If current target is in the room, do nothing
  if target and type(target) == "string" and target ~= "" then
    if isPlayerInRoom(target) then return end
  end

  -- Find first priority target who is present
  for _, name in ipairs(tprio.list) do
    if isPlayerInRoom(name) then
      if not target or normalizeName(target) ~= name then
        ataxiaEcho("Auto-targeting <white>" .. name .. "<plum> (priority target in room).")
        tprio.switchTo(name)
      end
      return
    end
  end
  -- None found, do nothing (don't clear target)
end

---------------------------------------------------
-- Room Player Tracking (GMCP Events)
---------------------------------------------------

-- Rebuild presence table from full player list
local function onRoomPlayers()
  tprio.playersInRoom = {}
  if not gmcp or not gmcp.Room or not gmcp.Room.Players then return end

  local players = gmcp.Room.Players
  if type(players) ~= "table" then return end

  for _, entry in pairs(players) do
    local fullname = nil
    if type(entry) == "table" then
      fullname = entry.name or entry.fullname
    elseif type(entry) == "string" then
      fullname = entry
    end
    if fullname then
      local name = stripSoulPrefix(fullname)
      local normalized = normalizeName(name)
      if normalized then
        tprio.playersInRoom[normalized] = true
      end
    end
  end

  tprio.autoTarget()
end

-- Incrementally add a player
local function onRoomAddPlayer()
  if not gmcp or not gmcp.Room or not gmcp.Room.AddPlayer then return end

  local entry = gmcp.Room.AddPlayer
  local fullname = nil
  if type(entry) == "table" then
    fullname = entry.name or entry.fullname
  elseif type(entry) == "string" then
    fullname = entry
  end
  if fullname then
    local name = stripSoulPrefix(fullname)
    local normalized = normalizeName(name)
    if normalized then
      tprio.playersInRoom[normalized] = true
    end
  end

  tprio.autoTarget()
end

-- Incrementally remove a player
local function onRoomRemovePlayer()
  if not gmcp or not gmcp.Room or not gmcp.Room.RemovePlayer then return end

  local entry = gmcp.Room.RemovePlayer
  local fullname = nil
  if type(entry) == "table" then
    fullname = entry.name or entry.fullname
  elseif type(entry) == "string" then
    fullname = entry
  end
  if fullname then
    local name = stripSoulPrefix(fullname)
    local normalized = normalizeName(name)
    if normalized then
      tprio.playersInRoom[normalized] = nil
    end
  end

  tprio.autoTarget()
end

---------------------------------------------------
-- Enemy List Sync
---------------------------------------------------

-- Sync in-game enemy list to match priority list
function tprio.syncEnemies()
  if #tprio.list == 0 then
    ataxiaEcho("Priority list is empty, nothing to sync.")
    return
  end
  send("unenemy all")
  for _, name in ipairs(tprio.list) do
    send("enemy " .. name)
  end
  ataxiaEcho("Enemy list synced to priority list (" .. #tprio.list .. " targets).")
end

---------------------------------------------------
-- Register Event Handlers
---------------------------------------------------

table.insert(tprio._handlers,
  registerAnonymousEventHandler("gmcp.Room.Players", onRoomPlayers)
)
table.insert(tprio._handlers,
  registerAnonymousEventHandler("gmcp.Room.AddPlayer", onRoomAddPlayer)
)
table.insert(tprio._handlers,
  registerAnonymousEventHandler("gmcp.Room.RemovePlayer", onRoomRemovePlayer)
)
