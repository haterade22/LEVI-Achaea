--[[mudlet
type: script
name: Locate System
hierarchy:
- Levi_Ataxia
- Leviticus
- Locate Relay
]]--

LocateSystem = LocateSystem or {}

local ls = LocateSystem

ls.DELAY         = 0.90
ls.city          = ""
ls.queue         = {}
ls.results       = {}
ls.failed        = {}
ls.current       = nil
ls.timerID       = nil
ls.running       = false
ls.retryFlag     = false
ls.isEnemyScan   = false

ls.whobNames     = {}
ls.whobResults   = {}
ls.whobActive    = false

function ls.start(city)
  ls.city        = city
  ls.queue       = {}
  ls.results     = {}
  ls.failed      = {}
  ls.current     = nil
  ls.running     = false
  ls.retryFlag   = false
  ls.isEnemyScan = false
  ls.whobNames   = {}
  ls.whobResults = {}
  ls.whobActive  = false
  cecho("<cyan>[Locate] Starting scan for <yellow>" .. city .. "<cyan>...\n")
  enableTrigger("locate_relay")
  send("qwc " .. city)
end

function ls.beginWhob()
  for _, name in ipairs(ls.queue) do
    ls.whobNames[name:lower()] = name
  end
  ls.whobActive = true
  send("config pagelength 250")
  tempTimer(0.2, function()
    send("who b")
  end)
end

function ls.resolveWhobRoom(roomName)
  local t = mmp.searchRoomExact(roomName)
  if not t or not next(t) then return roomName end
  local roomid = next(t)
  if type(roomid) ~= "number" then
    for k, v in pairs(t) do
      if type(v) == "number" then roomid = v break end
    end
  end
  if not roomid then return roomName end
  local areaId = getRoomArea(roomid)
  local areaName = mmp.areatabler and mmp.areatabler[areaId] or nil
  if areaName then
    areaName = mmp.cleanAreaName and mmp.cleanAreaName(areaName) or areaName
    return roomName .. " in " .. areaName
  end
  return roomName
end

function ls.whobParseLine(line)
  if not ls.whobActive then return end
  local name, room = line:match("^([A-Z][a-z]+)%s+%((.-)%)%s*$")
  if name and room then
    local lname = name:lower()
    if ls.whobNames[lname] then
      local resolved = ls.resolveWhobRoom(room)
      ls.whobResults[name] = resolved
    end
  end
end

function ls.whobFinish()
  if not ls.whobActive then return end
  ls.whobActive = false
  send("config pagelength 30")

  local newQueue = {}
  for _, name in ipairs(ls.queue) do
    if ls.whobResults[name] then
      ls.results[name] = ls.whobResults[name]
      cecho("<cyan>[Locate] <green>Who B hit: <white>" .. name .. " - " .. ls.whobResults[name] .. "\n")
    else
      table.insert(newQueue, name)
    end
  end
  ls.queue = newQueue

  local saved = #ls.whobResults
  cecho("<cyan>[Locate] Who B resolved <green>" .. saved .. "<cyan> names, farsee queue reduced to <yellow>" .. #ls.queue .. "<cyan>.\n")

  if #ls.queue == 0 then
    ls.finish()
  else
    ls.running = true
    tempTimer(0.9, function() ls.nextFarsee() end)
  end
end

function ls.beginQueue()
  if #ls.queue == 0 then
    cecho("<red>[Locate] No names found in qwc output.\n")
    return
  end
  cecho("<cyan>[Locate] Queuing <yellow>" .. #ls.queue .. "<cyan> names, running Who B first...\n")
  ls.beginWhob()
end

function ls.nextFarsee()
  if #ls.queue == 0 then
    ls.finish()
    return
  end
  ls.current   = table.remove(ls.queue, 1)
  ls.retryFlag = false
  send("farsee " .. ls.current)
  ls.timerID = tempTimer(ls.DELAY * 1.1, function()
    if ls.current then
      ls.handleFail(ls.current)
    end
  end)
end

function ls.handleResult(name, room)
  if ls.timerID then killTimer(ls.timerID) ls.timerID = nil end
  ls.results[name] = room
  ls.current = nil
  tempTimer(ls.DELAY, function() ls.nextFarsee() end)
end

function ls.handleFail(name)
  if ls.timerID then killTimer(ls.timerID) ls.timerID = nil end
  ls.results[name] = nil
  ls.current = nil
  ls.nextFarsee()
end

function ls.finish()
  ls.running = false
  disableTrigger("locate_relay")

  local rooms = {}
  local order = {}
  for name, room in pairs(ls.results) do
    if room then
      if not rooms[room] then
        rooms[room] = {}
        table.insert(order, room)
      end
      table.insert(rooms[room], name)
    end
  end

  table.sort(order)
  for _, room in ipairs(order) do
    table.sort(rooms[room])
  end

  local lines = {}
  local totalLocated = 0
  for _, room in ipairs(order) do
    local names = rooms[room]
    totalLocated = totalLocated + #names
    local nameStr = ls.formatNameList(names)
    table.insert(lines, room .. ": " .. nameStr .. " (" .. #names .. ")")
  end

  local header
  if ls.isEnemyScan then
    header = "Targets Located [" .. totalLocated .. "]"
    ls.isEnemyScan = false
  else
    local cityName = ls.city:sub(1,1):upper() .. ls.city:sub(2):lower()
    header = "Located " .. cityName .. "[" .. totalLocated .. "]"
  end

  cecho("<green>\n" .. header .. "\n")
  for _, line in ipairs(lines) do
    cecho("<white>" .. line .. "\n")
  end
  cecho("<cyan>Total located: " .. totalLocated .. "\n")

  local ptParts = {}
  table.insert(ptParts, "pt " .. header)
  for _, line in ipairs(lines) do
    if line and line ~= "" then
      table.insert(ptParts, "pt " .. line)
    end
  end

  local chunkSize = 20
  for i = 1, #ptParts, chunkSize do
    local chunk = {}
    for j = i, math.min(i + chunkSize - 1, #ptParts) do
      table.insert(chunk, ptParts[j])
    end
    local delay = math.floor((i - 1) / chunkSize) * 0.5
    tempTimer(delay, function()
      send(table.concat(chunk, "::"))
    end)
  end
end

function ls.formatNameList(names)
  if #names == 1 then
    return names[1]
  elseif #names == 2 then
    return names[1] .. " and " .. names[2]
  else
    local t = {}
    for i = 1, #names - 1 do t[i] = names[i] end
    return table.concat(t, ", ") .. ", and " .. names[#names]
  end
end

function ls.parseQWC(line)
  local cleaned = line:gsub("Plus another %d+ whose presence.*", "")
                      :gsub("[%.%(%d+ total%)]+$", "")
                      :gsub(" and ", ", ")
  for name in cleaned:gmatch("[A-Z][a-z]+") do
    table.insert(ls.queue, name)
  end
end
