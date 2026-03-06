-- =============================================================================
-- TOTEM CHECKER SYSTEM
-- =============================================================================
--
-- ALIAS:
--   totcheck          : Start checking all rooms in current area
--   totcheck stop     : Abort the checker
--   totcheck status   : Show progress mid-run
--
-- FLOW:
--   1. Generate room path from mapper (current area)
--   2. Navigate to each room via mapper
--   3. Send "probe totem"
--   4. Triggers capture rune slots + empowered status
--   5. Auto-fix: sketch missing runes, empower if needed
--   6. Print summary report when done
-- =============================================================================

-- Namespace
totemChecker = totemChecker or {}

-- Configuration
totemChecker.config = totemChecker.config or {
  runePattern = {
    [1] = "wunjo",
    [2] = "wunjo",
    [3] = "nairat",
    [4] = "nairat",
    [5] = "fehu",
    [6] = "fehu",
  },
  -- Rooms to skip (unreachable, special areas, etc.)
  excludeRooms = {
    [4415] = true,
    [5468] = true,
    [5485] = true,
    [10695] = true,
    [11920] = true,
  },
  -- Rooms to add that the mapper doesn't know about
  includeRooms = { 21775, 21777 },
  probeTimeout = 8,
  fixTimeout = 25,
  stuckTimeout = 15,
}

-- Rune description to name mapping (from 738_Runes_on_Totem.lua)
totemChecker.runeDescToName = {
  ["like an open eye"] = "wunjo",
  ["that looks like a stick man"] = "inguz",
  ["shaped like a butterfly"] = "nairat",
  ["like a closed eye"] = "fehu",
  ["resembling a bell"] = "mannaz",
  ["that looks like a nail"] = "sowulu",
  ["that looks like something out of your nightmares"] = "kena",
  ["shaped like a viper"] = "sleizak",
  ["resembling an apple core"] = "loshre",
  ["resembling a square box"] = "pithakhan",
  ["like a lightning bolt"] = "uruz",
  ["resembling a leech"] = "nauthiz",
  ["like an upward-pointing arrow"] = "tiwaz",
}

-- Runtime state
totemChecker.state = totemChecker.state or {
  active = false,
  phase = "idle",
  path = {},
  totalRooms = 0,
  targetRoom = nil,
  useMapperPath = false,
  probeSlots = {},
  probeEmpowered = false,
  probeDataReceived = false,
  probeTimerID = nil,
  fixTimerID = nil,
  fixStartedAt = 0,
  stuckTimerID = nil,
  promptHandler = nil,
  arrivedHandler = nil,
  failedHandler = nil,
  pendingFix = nil,
}

-- Results
totemChecker.results = totemChecker.results or {
  ok = {},
  fixed = {},
  noTotem = {},
  errors = {},
}

-- =============================================================================
-- UTILITY
-- =============================================================================

function totemChecker.echo(text)
  cecho("\n<ansi_light_cyan>[<white>TotemCheck<ansi_light_cyan>]: <white>" .. text)
end

-- =============================================================================
-- START / STOP / STATUS
-- =============================================================================

function totemChecker.start()
  if totemChecker.state.active then
    totemChecker.echo("<red>Already running! Use 'totcheck stop' to abort.")
    return
  end

  -- Generate path
  local path = {}
  local areaName = gmcp.Room.Info.area
  local useMapperPath = false

  local exclude = totemChecker.config.excludeRooms or {}

  if ataxiaBasherPaths and ataxiaBasherPaths[areaName] then
    for i, v in ipairs(ataxiaBasherPaths[areaName]) do
      if not exclude[v] then
        table.insert(path, v)
      end
    end
    totemChecker.echo("Using pre-computed path for <yellow>" .. areaName .. "<white>.")
  else
    -- getAreaRooms() can return a [0] indexed table; use pairs() to catch all entries
    local rooms = getAreaRooms(getRoomArea(mmp.currentroom))
    for _, v in pairs(rooms) do
      if not exclude[v] then
        table.insert(path, v)
      end
    end
    table.sort(path)
    useMapperPath = true
    totemChecker.echo("Using mapper rooms for <yellow>" .. areaName .. "<white>.")
  end

  -- Add extra rooms the mapper doesn't know about
  local include = totemChecker.config.includeRooms or {}
  for _, v in ipairs(include) do
    if not exclude[v] then
      table.insert(path, v)
    end
  end

  if #path == 0 then
    totemChecker.echo("<red>No rooms found in area!")
    return
  end

  -- Reset results
  totemChecker.results = { ok = {}, fixed = {}, noTotem = {}, errors = {} }

  -- Reset state
  totemChecker.state.active = true
  totemChecker.state.phase = "idle"
  totemChecker.state.path = path
  totemChecker.state.totalRooms = #path
  totemChecker.state.pendingFix = nil
  totemChecker.state.useMapperPath = useMapperPath

  -- Register event handlers
  totemChecker.state.promptHandler = registerAnonymousEventHandler(
    "gmcp.Char.Vitals", "totemChecker.onPrompt"
  )
  totemChecker.state.arrivedHandler = registerAnonymousEventHandler(
    "mmapper arrived", "totemChecker.onArrived"
  )
  totemChecker.state.failedHandler = registerAnonymousEventHandler(
    "mmapper failed path", "totemChecker.onPathFail"
  )

  totemChecker.echo("Starting totem check: <yellow>" .. #path ..
    "<white> rooms in <yellow>" .. areaName .. "<white>.")

  -- Begin traversal
  totemChecker.moveToNext()
end

function totemChecker.stop()
  if not totemChecker.state.active then
    totemChecker.echo("Not running.")
    return
  end
  totemChecker.cleanup()
  totemChecker.echo("Totem checker stopped.")
end

function totemChecker.cleanup()
  if totemChecker.state.promptHandler then
    killAnonymousEventHandler(totemChecker.state.promptHandler)
    totemChecker.state.promptHandler = nil
  end
  if totemChecker.state.arrivedHandler then
    killAnonymousEventHandler(totemChecker.state.arrivedHandler)
    totemChecker.state.arrivedHandler = nil
  end
  if totemChecker.state.failedHandler then
    killAnonymousEventHandler(totemChecker.state.failedHandler)
    totemChecker.state.failedHandler = nil
  end
  if totemChecker.state.probeTimerID then
    killTimer(totemChecker.state.probeTimerID)
    totemChecker.state.probeTimerID = nil
  end
  if totemChecker.state.fixTimerID then
    killTimer(totemChecker.state.fixTimerID)
    totemChecker.state.fixTimerID = nil
  end
  if totemChecker.state.stuckTimerID then
    killTimer(totemChecker.state.stuckTimerID)
    totemChecker.state.stuckTimerID = nil
  end

  totemChecker.state.active = false
  totemChecker.state.phase = "idle"
end

function totemChecker.status()
  if not totemChecker.state.active then
    totemChecker.echo("Not running.")
    return
  end
  local remaining = #totemChecker.state.path
  local total = totemChecker.state.totalRooms
  local checked = total - remaining
  totemChecker.echo("Phase: <yellow>" .. totemChecker.state.phase ..
    "<white> | Progress: <yellow>" .. checked .. "/" .. total ..
    "<white> | OK: <green>" .. #totemChecker.results.ok ..
    "<white> | Fixed: <yellow>" .. #totemChecker.results.fixed ..
    "<white> | No Totem: <red>" .. #totemChecker.results.noTotem)
end

-- =============================================================================
-- NAVIGATION
-- =============================================================================

function totemChecker.moveToNext()
  -- Remove current room from path if present
  local currentRoom = tonumber(gmcp.Room.Info.num)
  for i, v in ipairs(totemChecker.state.path) do
    if v == currentRoom then
      table.remove(totemChecker.state.path, i)
      break
    end
  end

  if #totemChecker.state.path == 0 then
    totemChecker.finish()
    return
  end

  totemChecker.state.phase = "moving"
  local nextRoom

  if totemChecker.state.useMapperPath then
    -- Find nearest reachable room (same approach as bashing system)
    local bestRoom, bestDist = nil, 9999
    for _, v in ipairs(totemChecker.state.path) do
      local ok = getPath(tonumber(gmcp.Room.Info.num), v)
      if ok then
        local dist = table.size(speedWalkDir)
        if dist == 1 then
          -- Adjacent room, can't do better
          bestRoom = v
          break
        elseif dist > 0 and dist < bestDist then
          bestDist = dist
          bestRoom = v
        end
      end
    end
    if not bestRoom then
      totemChecker.echo("<red>No reachable rooms remaining. Finishing.")
      totemChecker.finish()
      return
    end
    nextRoom = bestRoom
  else
    -- Pre-computed path: use the order as given
    nextRoom = totemChecker.state.path[1]
  end

  totemChecker.state.targetRoom = nextRoom
  expandAlias("goto " .. nextRoom)
  totemChecker.startStuckTimer()

  local remaining = #totemChecker.state.path
  local total = totemChecker.state.totalRooms
  local checked = total - remaining
  totemChecker.echo("Moving to room <yellow>" .. nextRoom ..
    "<white> (" .. checked .. "/" .. total .. ")")
end

function totemChecker.startStuckTimer()
  if totemChecker.state.stuckTimerID then
    killTimer(totemChecker.state.stuckTimerID)
  end
  local timeout = totemChecker.config.stuckTimeout
  local initialCounter = mmp.speedWalkCounter or 0
  if initialCounter < 1 then return end

  totemChecker.state.stuckTimerID = tempTimer(timeout, function()
    if totemChecker.state.active and totemChecker.state.phase == "moving"
       and mmp.speedWalkCounter and mmp.speedWalkCounter > 0
       and mmp.speedWalkCounter == initialCounter then
      totemChecker.echo("<red>Mapper stuck. Triggering path fail.")
      totemChecker.onPathFail()
    end
    totemChecker.state.stuckTimerID = nil
  end)
end

-- =============================================================================
-- EVENT HANDLERS
-- =============================================================================

function totemChecker.onArrived()
  if not totemChecker.state.active then return end
  if totemChecker.state.phase ~= "moving" then return end

  if totemChecker.state.stuckTimerID then
    killTimer(totemChecker.state.stuckTimerID)
    totemChecker.state.stuckTimerID = nil
  end

  -- Remove arrived room from path
  local currentRoom = tonumber(gmcp.Room.Info.num)
  for i, v in ipairs(totemChecker.state.path) do
    if v == currentRoom then
      table.remove(totemChecker.state.path, i)
      break
    end
  end

  totemChecker.startProbe()
end

function totemChecker.onPrompt()
  if not totemChecker.state.active then return end
  -- Re-entrancy guard: expandAlias/send can fire gmcp.Char.Vitals synchronously,
  -- which would call onPrompt() again while still inside a previous call.
  if totemChecker.state.inPrompt then return end
  totemChecker.state.inPrompt = true

  -- Detect arrival: only when we're actually in the target room
  if totemChecker.state.phase == "moving" then
    local targetRoom = totemChecker.state.targetRoom
    if targetRoom and tonumber(gmcp.Room.Info.num) == targetRoom then
      totemChecker.onArrived()
    end
  end

  -- Process probe results on prompt (after ALL output lines have been received)
  if totemChecker.state.phase == "probing" and totemChecker.state.probeDataReceived then
    totemChecker.onProbeComplete()
  end

  -- Detect fix completion: all queued commands done when bal+eq return
  -- Minimum 2s delay to ensure queue has started processing
  if totemChecker.state.phase == "fixing" then
    if getEpoch() - (totemChecker.state.fixStartedAt or 0) > 2
       and gmcp.Char.Vitals.bal == "1" and gmcp.Char.Vitals.eq == "1" then
      totemChecker.onFixComplete()
    end
  end

  totemChecker.state.inPrompt = false
end

function totemChecker.onPathFail()
  if not totemChecker.state.active then return end
  if totemChecker.state.phase ~= "moving" then return end

  if totemChecker.state.stuckTimerID then
    killTimer(totemChecker.state.stuckTimerID)
    totemChecker.state.stuckTimerID = nil
  end

  -- Remove the actual target room, not path[1] (nearest-room logic means target != path[1])
  local skippedRoom = totemChecker.state.targetRoom or totemChecker.state.path[1]
  if skippedRoom then
    totemChecker.echo("<red>Cannot reach room " .. skippedRoom .. ". Skipping.")
    for i, v in ipairs(totemChecker.state.path) do
      if v == skippedRoom then
        table.remove(totemChecker.state.path, i)
        break
      end
    end
    table.insert(totemChecker.results.errors, {
      roomID = skippedRoom,
      roomName = "unreachable",
      reason = "path failed",
    })
  end

  if #totemChecker.state.path > 0 then
    totemChecker.moveToNext()
  else
    totemChecker.finish()
  end
end

-- =============================================================================
-- PROBING
-- =============================================================================

function totemChecker.startProbe()
  totemChecker.state.probeSlots = {}
  totemChecker.state.probeEmpowered = false
  totemChecker.state.probeDataReceived = false
  totemChecker.state.phase = "probing"

  if totemChecker.state.probeTimerID then
    killTimer(totemChecker.state.probeTimerID)
  end
  totemChecker.state.probeTimerID = tempTimer(
    totemChecker.config.probeTimeout,
    function()
      if totemChecker.state.phase == "probing" then
        totemChecker.echo("<red>Probe timeout in room " ..
          gmcp.Room.Info.num .. ". Moving on.")
        table.insert(totemChecker.results.errors, {
          roomID = tonumber(gmcp.Room.Info.num),
          roomName = gmcp.Room.Info.name or "unknown",
          reason = "probe timeout",
        })
        totemChecker.moveToNext()
      end
    end
  )

  send("probe totem")
end

function totemChecker.onProbeSlot(slotNum, runeName)
  if not totemChecker.state.active then return end
  if totemChecker.state.phase ~= "probing" then return end
  totemChecker.state.probeSlots[slotNum] = runeName
end

function totemChecker.onProbeEmpowered()
  if not totemChecker.state.active then return end
  if totemChecker.state.phase ~= "probing" then return end
  totemChecker.state.probeEmpowered = true
end

function totemChecker.onProbeComplete()
  if not totemChecker.state.active then return end
  if totemChecker.state.phase ~= "probing" then return end

  if totemChecker.state.probeTimerID then
    killTimer(totemChecker.state.probeTimerID)
    totemChecker.state.probeTimerID = nil
  end

  local roomID = tonumber(gmcp.Room.Info.num)
  local roomName = gmcp.Room.Info.name or "unknown"
  local slots = totemChecker.state.probeSlots
  local empowered = totemChecker.state.probeEmpowered

  -- Identify empty slots
  local emptySlots = {}
  for i = 1, 6 do
    if not slots[i] then
      table.insert(emptySlots, i)
    end
  end

  local needsSketch = #emptySlots > 0
  local needsEmpower = not empowered

  if not needsSketch and not needsEmpower then
    totemChecker.echo("<green>OK <dim_grey>room " .. roomID ..
      " (" .. roomName .. ")")
    table.insert(totemChecker.results.ok, {
      roomID = roomID,
      roomName = roomName,
    })
    totemChecker.moveToNext()
  else
    totemChecker.sendFix(emptySlots, needsEmpower, roomID, roomName)
  end
end

function totemChecker.onNoTotem()
  if not totemChecker.state.active then return end
  if totemChecker.state.phase ~= "probing" then return end

  if totemChecker.state.probeTimerID then
    killTimer(totemChecker.state.probeTimerID)
    totemChecker.state.probeTimerID = nil
  end

  local roomID = tonumber(gmcp.Room.Info.num)
  local roomName = gmcp.Room.Info.name or "unknown"

  totemChecker.echo("<red>NO TOTEM <dim_grey>room " .. roomID ..
    " (" .. roomName .. ")")
  table.insert(totemChecker.results.noTotem, {
    roomID = roomID,
    roomName = roomName,
  })
  totemChecker.moveToNext()
end

-- =============================================================================
-- AUTO-FIX
-- =============================================================================

function totemChecker.sendFix(emptySlots, needsEmpower, roomID, roomName)
  totemChecker.state.phase = "fixing"
  totemChecker.state.fixStartedAt = getEpoch()
  local pattern = totemChecker.config.runePattern
  local actionParts = {}

  -- Sketch empty slots
  if #emptySlots > 0 then
    local slotStrs = {}
    for i, slot in ipairs(emptySlots) do
      local rune = pattern[slot]
      if rune then
        local queueCmd = (i == 1) and "addclear" or "add"
        send("queue " .. queueCmd .. " free sketch " .. rune ..
          " on totem on slot " .. slot)
        table.insert(slotStrs, tostring(slot))
      end
    end
    table.insert(actionParts, "sketched slots " .. table.concat(slotStrs, ","))
    totemChecker.echo("<yellow>FIX <dim_grey>room " .. roomID ..
      ": sketching slots " .. table.concat(slotStrs, ", "))
  end

  -- Empower if needed
  if needsEmpower then
    local queueCmd = (#emptySlots == 0) and "addclear" or "add"
    send("queue " .. queueCmd .. " free empower totem")
    table.insert(actionParts, "empowered")
    totemChecker.echo("<yellow>FIX <dim_grey>room " .. roomID .. ": empowering")
  end

  -- Fix timeout
  if totemChecker.state.fixTimerID then
    killTimer(totemChecker.state.fixTimerID)
  end
  totemChecker.state.fixTimerID = tempTimer(
    totemChecker.config.fixTimeout,
    function()
      if totemChecker.state.phase == "fixing" then
        totemChecker.echo("<red>Fix timeout in room " .. roomID .. ". Moving on.")
        table.insert(totemChecker.results.errors, {
          roomID = roomID,
          roomName = roomName,
          reason = "fix timeout",
        })
        totemChecker.moveToNext()
      end
    end
  )

  totemChecker.state.pendingFix = {
    roomID = roomID,
    roomName = roomName,
    action = table.concat(actionParts, " + "),
  }
end

function totemChecker.onFixComplete()
  if totemChecker.state.phase ~= "fixing" then return end

  if totemChecker.state.fixTimerID then
    killTimer(totemChecker.state.fixTimerID)
    totemChecker.state.fixTimerID = nil
  end

  local fix = totemChecker.state.pendingFix
  if fix then
    totemChecker.echo("<green>Fixed <dim_grey>room " .. fix.roomID ..
      " (" .. fix.action .. ")")
    table.insert(totemChecker.results.fixed, fix)
    totemChecker.state.pendingFix = nil
  end

  totemChecker.moveToNext()
end

-- =============================================================================
-- FINISH / REPORT
-- =============================================================================

function totemChecker.finish()
  totemChecker.state.phase = "done"
  totemChecker.cleanup()

  local r = totemChecker.results
  totemChecker.echo("<green>===== TOTEM CHECK COMPLETE =====")
  totemChecker.echo("<green>OK: <white>" .. #r.ok .. " rooms")
  totemChecker.echo("<yellow>Fixed: <white>" .. #r.fixed .. " rooms")
  totemChecker.echo("<red>No Totem: <white>" .. #r.noTotem .. " rooms")
  totemChecker.echo("<red>Errors: <white>" .. #r.errors .. " rooms")

  if #r.noTotem > 0 then
    totemChecker.echo("")
    totemChecker.echo("<red>--- Rooms Missing Totems ---")
    for _, room in ipairs(r.noTotem) do
      totemChecker.echo("  <yellow>" .. room.roomID ..
        " <dim_grey>(" .. room.roomName .. ")")
    end
  end

  if #r.fixed > 0 then
    totemChecker.echo("")
    totemChecker.echo("<yellow>--- Rooms Fixed ---")
    for _, room in ipairs(r.fixed) do
      totemChecker.echo("  <yellow>" .. room.roomID ..
        " <dim_grey>(" .. room.roomName .. ") <white>- " .. room.action)
    end
  end

  if #r.errors > 0 then
    totemChecker.echo("")
    totemChecker.echo("<red>--- Errors ---")
    for _, room in ipairs(r.errors) do
      totemChecker.echo("  <yellow>" .. room.roomID ..
        " <dim_grey>(" .. room.roomName .. ") <white>- " .. room.reason)
    end
  end

  totemChecker.echo("<green>================================")
end
