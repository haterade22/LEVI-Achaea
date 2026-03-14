--[[mudlet
type: script
name: Locate World
hierarchy:
- Levi_Ataxia
- Leviticus
- Locate Relay
]]--

LocateWorld = LocateWorld or {}

local lw = LocateWorld

lw.CITIES = {
  "Ashtan", "Mhaldor", "Cyrene", "Eleusis", "Targossas", "Hashan"
}

lw.queue         = {}
lw.results       = {}
lw.current       = nil
lw.timerID       = nil
lw.running       = false
lw.city          = ""
lw.cityData      = {}
lw.areaData      = {}
lw.NICcount      = 0

lw.whobNames     = {}
lw.whobResults   = {}
lw.whobActive    = false

function lw.start()
  lw.queue         = {}
  lw.results       = {}
  lw.current       = nil
  lw.running       = false
  lw.city          = "world"
  lw.cityData      = {}
  lw.areaData      = {}
  lw.NICcount      = 0
  lw.whobNames     = {}
  lw.whobResults   = {}
  lw.whobActive    = false
  cecho("<cyan>[LocateWorld] Starting world scan...\n")
  enableTrigger("locate_relay")
  send("qw")
end

function lw.beginWhob()
  for _, name in ipairs(lw.queue) do
    lw.whobNames[name:lower()] = name
  end
  lw.whobActive = true
  send("config pagelength 250")
  tempTimer(0.2, function()
    send("who b")
  end)
end

function lw.resolveWhobRoom(roomName)
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

function lw.whobParseLine(line)
  if not lw.whobActive then return end
  local name, room = line:match("^([A-Z][a-z]+)%s+%((.-)%)%s*$")
  if name and room then
    local lname = name:lower()
    if lw.whobNames[lname] then
      local resolved = lw.resolveWhobRoom(room)
      lw.whobResults[name] = resolved
    end
  end
end

function lw.whobFinish()
  if not lw.whobActive then return end
  lw.whobActive = false
  send("config pagelength 30")

  local newQueue = {}
  for _, name in ipairs(lw.queue) do
    if lw.whobResults[name] then
      lw.results[name] = lw.whobResults[name]
      cecho("<cyan>[LocateWorld] <green>Who B hit: <white>" .. name .. " - " .. lw.whobResults[name] .. "\n")
    else
      table.insert(newQueue, name)
    end
  end
  lw.queue = newQueue

  cecho("<cyan>[LocateWorld] Who B resolved <green>" .. #lw.whobResults .. "<cyan> names, farsee queue reduced to <yellow>" .. #lw.queue .. "<cyan>.\n")

  if #lw.queue == 0 then
    lw.finish()
  else
    lw.running = true
    tempTimer(0.9, function() lw.nextFarsee() end)
  end
end

function lw.beginQueue()
  if #lw.queue == 0 then
    cecho("<red>[LocateWorld] No names found in qw output.\n")
    return
  end
  cecho("<cyan>[LocateWorld] Queuing <yellow>" .. #lw.queue .. "<cyan> names, running Who B first...\n")
  lw.beginWhob()
end

function lw.nextFarsee()
  if #lw.queue == 0 then
    lw.finish()
    return
  end
  lw.current = table.remove(lw.queue, 1)
  send("farsee " .. lw.current)
  lw.timerID = tempTimer(LocateSystem.DELAY * 1.1, function()
    if lw.current then
      lw.handleFail(lw.current)
    end
  end)
end

function lw.handleResult(name, room)
  if lw.timerID then killTimer(lw.timerID) lw.timerID = nil end
  lw.results[name] = room
  lw.current = nil
  tempTimer(LocateSystem.DELAY, function() lw.nextFarsee() end)
end

function lw.handleFail(name)
  if lw.timerID then killTimer(lw.timerID) lw.timerID = nil end
  lw.results[name] = nil
  lw.current = nil
  lw.nextFarsee()
end

function lw.detectCity(room)
  for _, city in ipairs(lw.CITIES) do
    if room:find(city) then
      return city
    end
  end
  return nil
end

function lw.extractArea(room)
  local area = room:match(" in (.+)$")
  return area or room
end

function lw.groupByRoom(nameRoomMap)
  local rooms = {}
  local order = {}
  for name, room in pairs(nameRoomMap) do
    if not rooms[room] then
      rooms[room] = {}
      table.insert(order, room)
    end
    table.insert(rooms[room], name)
  end
  table.sort(order)
  for _, room in ipairs(order) do
    table.sort(rooms[room])
  end
  return rooms, order
end

function lw.finish()
  lw.running = false
  lw.city    = ""
  disableTrigger("locate_relay")

  lw.cityData = {}
  lw.areaData = {}
  lw.NICcount = 0

  for name, room in pairs(lw.results) do
    if room then
      local city = lw.detectCity(room)
      if city then
        if not lw.cityData[city] then
          lw.cityData[city] = { names = {}, rooms = {} }
        end
        table.insert(lw.cityData[city].names, name)
        lw.cityData[city].rooms[name] = room
      else
        local area = lw.extractArea(room)
        if not lw.areaData[area] then
          lw.areaData[area] = { names = {}, rooms = {} }
        end
        table.insert(lw.areaData[area].names, name)
        lw.areaData[area].rooms[name] = room
      end
    else
      lw.NICcount = lw.NICcount + 1
    end
  end

  for _, data in pairs(lw.cityData) do table.sort(data.names) end
  for _, data in pairs(lw.areaData) do table.sort(data.names) end

  local cityOrder = {}
  for city, _ in pairs(lw.cityData) do table.insert(cityOrder, city) end
  table.sort(cityOrder)

  local areaOrder = {}
  for area, _ in pairs(lw.areaData) do table.insert(areaOrder, area) end
  table.sort(areaOrder)

  cecho("<green>\n===== World Locate Results =====\n")
  for _, city in ipairs(cityOrder) do
    local data = lw.cityData[city]
    cecho("<yellow>[" .. city .. "]<white>: (" .. #data.names .. ")\n")
    local rooms, order = lw.groupByRoom(data.rooms)
    for _, room in ipairs(order) do
      local names = rooms[room]
      cecho("<white>  " .. room .. ": (" .. #names .. ") " .. table.concat(names, ", ") .. "\n")
    end
  end

  if #areaOrder > 0 then
    cecho("<green>----- Elsewhere -----\n")
    for _, area in ipairs(areaOrder) do
      local data = lw.areaData[area]
      cecho("<yellow>[" .. area .. "]<white>: (" .. #data.names .. ")\n")
      local rooms, order = lw.groupByRoom(data.rooms)
      for _, room in ipairs(order) do
        local names = rooms[room]
        cecho("<white>  " .. room .. ": (" .. #names .. ") " .. table.concat(names, ", ") .. "\n")
      end
    end
  end

  if lw.NICcount > 0 then
    cecho("<yellow>[NIC]<white>: (" .. lw.NICcount .. ")\n")
  end
  cecho("<green>================================\n")

  local ptParts = {}
  table.insert(ptParts, "pt World Locate -")
  for _, city in ipairs(cityOrder) do
    local data = lw.cityData[city]
    local nameStr = LocateSystem.formatNameList(data.names)
    table.insert(ptParts, "pt [" .. city .. "]: (" .. #data.names .. ") - " .. nameStr)
  end
  if lw.NICcount > 0 then
    table.insert(ptParts, "pt [NIC]: (" .. lw.NICcount .. ")")
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

function lw.outputLocation(label, data)
  local rooms, order = lw.groupByRoom(data.rooms)
  cecho("<green>[" .. label .. "] (" .. #data.names .. "):\n")
  for _, room in ipairs(order) do
    local names = rooms[room]
    cecho("<white>  " .. room .. ": (" .. #names .. ") " .. table.concat(names, ", ") .. "\n")
  end
  local ptParts = {}
  table.insert(ptParts, "pt [" .. label .. "] (" .. #data.names .. ") - " .. LocateSystem.formatNameList(data.names))
  for _, room in ipairs(order) do
    local names = rooms[room]
    table.insert(ptParts, "pt " .. room .. ": (" .. #names .. ") " .. LocateSystem.formatNameList(names))
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

function lw.lookupLocation(location)
  local searchStr = location:lower()
  for city, data in pairs(lw.cityData) do
    if city:lower() == searchStr then
      lw.outputLocation(city, data)
      return
    end
  end
  for area, data in pairs(lw.areaData) do
    if area:lower():find(searchStr) then
      lw.outputLocation(area, data)
      return
    end
  end
  cecho("<red>[LocateWorld] No stored data found for: " .. location .. "\n")
end

function lw.summary()
  if not lw.cityData or not next(lw.cityData) then
    cecho("<red>[LocateWorld] No scan data available. Run lw first.\n")
    return
  end
  local cityOrder = {}
  for city, _ in pairs(lw.cityData) do table.insert(cityOrder, city) end
  table.sort(cityOrder)
  local areaOrder = {}
  for area, _ in pairs(lw.areaData) do table.insert(areaOrder, area) end
  table.sort(areaOrder)
  cecho("<green>\n===== World Locate Summary =====\n")
  for _, city in ipairs(cityOrder) do
    local data = lw.cityData[city]
    cecho("<yellow>[" .. city .. "]<white>: (" .. #data.names .. ") - " .. table.concat(data.names, ", ") .. "\n")
  end
  if #areaOrder > 0 then
    cecho("<green>----- Elsewhere -----\n")
    for _, area in ipairs(areaOrder) do
      local data = lw.areaData[area]
      cecho("<yellow>[" .. area .. "]<white>: (" .. #data.names .. ") - " .. table.concat(data.names, ", ") .. "\n")
    end
  end
  if lw.NICcount > 0 then
    cecho("<yellow>[NIC]<white>: (" .. lw.NICcount .. ")\n")
  end
  cecho("<green>================================\n")
end

function lw.parseQW(line)
  local cleaned = line:gsub("Plus another %d+ whose presence.*", "")
                      :gsub("[%.%(%d+ total%)]+$", "")
                      :gsub(" and ", ", ")
  for name in cleaned:gmatch("[A-Z][a-z]+") do
    table.insert(lw.queue, name)
  end
end
