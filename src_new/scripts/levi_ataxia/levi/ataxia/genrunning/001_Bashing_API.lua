--[[mudlet
type: script
name: Bashing API
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Basher
- Bashing
- genRunning
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[mudlet
type: script
name: Bashing API
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Basher
- Bashing
- genRunning
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function ataxiaBasher_scanRoom()
  need_roomCheck = false
  ataxiaBasher_skipRoom = false
  ignoreCount = 0
  
  for id, mob in pairs(ataxia.denizensHere) do
    if ataxiaBasher.mobIgnore and table.contains(ataxiaBasher.mobIgnore, mob) and ataxiaBasher.enabled then
      ataxiaBasher_skipRoom = true
      ataxiaEcho("Skipping room because "..mob.." is here.")
      break
		elseif ataxiaBasher.dangerList and ataxiaBasher.dangerList[mob] then
      ignoreCount = ignoreCount + 1
      if ignoreCount > ataxiaBasher.dangerCount then
				ataxiaEcho("Skipping room due to too many dangerous mobs.")
				ataxiaBasher_skipRoom = true
				dangerSkip = true
        break
			end
		end
  end
  for _, player in pairs(ataxia.playersHere) do
    local playerData = ataxiaNDB and ataxiaNDB.players and ataxiaNDB.players[player]
    if playerData and playerData.city == "Mhaldor" then
      ataxiaBasher_skipRoom = false
    elseif not table.contains(ataxiaBasher.ignore, player) and ataxiaBasher.enabled then
      ataxiaBasher_skipRoom = true
      ataxiaEcho("Someone is here! --- "..player)
      ataxiaBasher_alert("Normal")
		end
  end 
end

function ataxiaBasher_roomBashed()
	for i,v in pairs(ataxiaBasher_path) do
		if v == tonumber(gmcp.Room.Info.num) then
			table.remove(ataxiaBasher_path, i)
			break
		end
	end
end

function ataxiaBasher_arrived()
	if not ataxiaBasher.areabash then return false end
	ataxiaBasher_roomBashed()
end

function ataxiaBasher_pathFail()
	if not ataxiaBasher.enabled then return false end
	ataxiaEcho("Impass detected. Recalculating route.")
	table.remove(ataxiaBasher_path, 1)

	if #ataxiaBasher_path > 0 then
		expandAlias("goto "..ataxiaBasher_path[1])
		ataxiaBasher_startStuckTimer()
	elseif not ataxiaBasher.manual then
		ataxiaBasher_areaoff()
	end
end

function ataxiaBasher_generatePath()
	ataxiaBasher_path = {}
  ataxiaTemp.mapperPath = nil
	bashWatcher = bashWatcher or createStopWatch()
	startStopWatch(bashWatcher)	
	if ataxiaBasherPaths and ataxiaBasherPaths[gmcp.Room.Info.area] then
		local roomsToAdd = ataxiaBasherPaths[gmcp.Room.Info.area]
		local thisRoom = tonumber(gmcp.Room.Info.num)
		
		if table.contains(roomsToAdd, thisRoom) and table.index_of(roomsToAdd, thisRoom) ~= #roomsToAdd and table.index_of(roomsToAdd, thisRoom) ~= 1 then
			ataxiaEcho("Our room is found in the middle of the path; starting from there instead.")
			table.insert(ataxiaBasher_path, thisRoom)
			local start = table.index_of(roomsToAdd, thisRoom)
			while start < #roomsToAdd do
				start = start + 1
				table.insert(ataxiaBasher_path, roomsToAdd[start])
			end			
		else
			ataxiaEcho("Creating path from scratch using pathing info.")
			for i,v in pairs(ataxiaBasherPaths[gmcp.Room.Info.area]) do
				table.insert(ataxiaBasher_path, v)
			end
		end
	else
		ataxiaEcho("Current area not tracked. Grabbing information from mapper instead.")
    ataxiaTemp.mapperPath = true
		collectRooms, result = getAreaRooms(getRoomArea(mmp.currentroom)), {}
		ataxiaBasher_path = deepcopy(collectRooms)
		table.sort(ataxiaBasher_path)
	end
	ataxiaTemp.basherRooms = #ataxiaBasher_path
	ataxiaEcho("Coordinates and path have been acquired. Total rooms: "..#ataxiaBasher_path.." | Process took: "..stopStopWatch(bashWatcher).."s to complete.")
	expandAlias("goto "..ataxiaBasher_path[1])
	ataxiaBasher_startStuckTimer()
  if ataxia.usegui or ataxia.usegui == nil then
    ataxiagui.basherBar:show()
    ataxiagui.basherBarClear:show()
  end
end

function saveRoomPath()
	bashWatcher = bashWatcher or createStopWatch()
	if #mapping_path < 2 then return end
	startStopWatch(bashWatcher)
	ataxiaBasherPaths[gmcp.Room.Info.area] = {}
	ataxiaEcho("Inputting rooms into the area table for: "..gmcp.Room.Info.area..".")
	for i,v in pairs(mapping_path) do
		table.insert(ataxiaBasherPaths[gmcp.Room.Info.area], v)
	end
	ataxiaEcho(gmcp.Room.Info.area.."'s table has been updated. Process took "..stopStopWatch(bashWatcher).."s to complete.")
	ataxia_saveSettings(false)
end

-- Death recovery: fully disable basher, clear all queues, and retreat after resurrection.
-- Saves the room we died in so we can move back one room to heal up safely.
function ataxiaBasher_onDeath()
  if not ataxiaBasher.enabled then return end

  -- Save safe room before anything else
  -- Check area-specific safe room first (capture area NOW, before respawn changes it)
  local deathArea = gmcp.Room.Info and gmcp.Room.Info.area or nil
  local safeConfig = ataxiaBasher_getAreaSafeRoom(deathArea)
  local safeRoom = (safeConfig and safeConfig.room) or (mmp and mmp.previousroom) or nil

  -- Immediately stop everything
  send("cq all")
  ataxiaBasher.enabled = false
  ataxiaBasher.paused = false
  ataxiaBasher.areabash = false
  ataxiaTemp.bashFlee = false
  autoBashRotation = false
  target = nil
  found_target = false

  -- Kill any active timers that could restart movement/attacks
  if ataxiaTemp.fleeCircuitBreaker then killTimer(ataxiaTemp.fleeCircuitBreaker); ataxiaTemp.fleeCircuitBreaker = nil end
  if ataxiaTemp.fleeReturnTimer then killTimer(ataxiaTemp.fleeReturnTimer); ataxiaTemp.fleeReturnTimer = nil end
  if ataxiaTemp.stuckTimer then killTimer(ataxiaTemp.stuckTimer); ataxiaTemp.stuckTimer = nil end
  if ataxiaBasher_atkTimer then killTimer(ataxiaBasher_atkTimer); ataxiaBasher_atkTimer = nil end
  ataxiaBasher_atk = false
  ataxiaTemp.fleeOriginRoom = nil
  ataxiaTemp.fleeReturning = nil

  -- Stop mapper movement
  if mmp and mmp.pause then mmp.pause("on") end

  raiseEvent("basher disabled")

  ataxiaEcho("DEATH DETECTED! Basher disabled. Queues cleared. Auto-rotation OFF.")

  -- After resurrection/starburst, move to the room before where we died to heal up
  if safeRoom then
    tempTimer(2, function()
      if mmp and mmp.pause then mmp.pause("off") end
      ataxiaEcho("Moving to safe room (v" .. safeRoom .. ") to heal up.")
      expandAlias("goto " .. safeRoom)
    end)
  end
end

-- Flee timeout / circuit breaker: if flee state persists beyond a timeout, disable basher.
-- Set ataxiaBasher.fleeTimeout (seconds, default 20) to configure.
function ataxiaBasher_startFleeTimer()
  if ataxiaTemp.fleeCircuitBreaker then killTimer(ataxiaTemp.fleeCircuitBreaker) end
  local timeout = ataxiaBasher.fleeTimeout or 20
  ataxiaTemp.fleeCircuitBreaker = tempTimer(timeout, function()
    if ataxiaTemp.bashFlee and ataxiaBasher.enabled then
      ataxiaEcho("Flee timeout reached (" .. timeout .. "s). Disabling basher as safety measure.")
      ataxiaBasher_areaoff()
      ataxiaTemp.bashFlee = false
    end
    ataxiaTemp.fleeCircuitBreaker = nil
  end)
end

-- Mapper-stuck detection: if speedwalk counter hasn't changed in X seconds, trigger path fail.
-- Set ataxiaBasher.stuckTimeout (seconds, default 15) to configure.
function ataxiaBasher_startStuckTimer()
  if ataxiaTemp.stuckTimer then killTimer(ataxiaTemp.stuckTimer) end
  if not ataxiaBasher.enabled or ataxiaBasher.manual then return end
  local timeout = ataxiaBasher.stuckTimeout or 15
  local initialCounter = mmp.speedWalkCounter or 0
  if initialCounter < 1 then return end
  ataxiaTemp.stuckTimer = tempTimer(timeout, function()
    if ataxiaBasher.enabled and mmp.speedWalkCounter and mmp.speedWalkCounter > 0
       and mmp.speedWalkCounter == initialCounter then
      ataxiaEcho("Mapper appears stuck (no movement for " .. timeout .. "s). Triggering path fail.")
      ataxiaBasher_pathFail()
    end
    ataxiaTemp.stuckTimer = nil
  end)
end

-- PvP attack detected while bashing: disable basher and flee to Mhaldor
function ataxiaBasher_onAttacked(_, attackerName, attackerClass)
  if not ataxiaBasher or not ataxiaBasher.enabled then return end

  ataxiaEcho("<red>ATTACKED by <white>" .. (attackerName or "unknown") .. " <red>(" .. (attackerClass or "?") .. ") while bashing! Fleeing to Mhaldor.")

  -- Stop everything
  send("cq all")
  autoBashRotation = false
  ataxiaBasher.enabled = false
  ataxiaBasher.paused = false
  ataxiaBasher.areabash = false
  ataxiaBasher_atk = false
  ataxiaTemp.fleeOriginRoom = nil
  ataxiaTemp.fleeReturning = nil
  if ataxiaTemp.fleeReturnTimer then killTimer(ataxiaTemp.fleeReturnTimer); ataxiaTemp.fleeReturnTimer = nil end
  raiseEvent("basher disabled")

  -- Navigate to Mhaldor
  if mmp and mmp.pause then mmp.pause("off") end
  expandAlias("goto Mhaldor")
end

registerAnonymousEventHandler("mmapper failed path", "ataxiaBasher_pathFail")
registerAnonymousEventHandler("mmapper arrived", "ataxiaBasher_arrived")
registerAnonymousEventHandler("player death", "ataxiaBasher_onDeath")
registerAnonymousEventHandler("attacker class detected", "ataxiaBasher_onAttacked")--[[mudlet
type: script
name: Bashing API
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Basher
- Bashing
- genRunning
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function ataxiaBasher_scanRoom()
  need_roomCheck = false
  ataxiaBasher_skipRoom = false
  ignoreCount = 0
  
  for id, mob in pairs(ataxia.denizensHere) do
    if ataxiaBasher.mobIgnore and table.contains(ataxiaBasher.mobIgnore, mob) and ataxiaBasher.enabled then
      ataxiaBasher_skipRoom = true
      ataxiaEcho("Skipping room because "..mob.." is here.")
      break
		elseif ataxiaBasher.dangerList and ataxiaBasher.dangerList[mob] then
      ignoreCount = ignoreCount + 1
      if ignoreCount > ataxiaBasher.dangerCount then
				ataxiaEcho("Skipping room due to too many dangerous mobs.")
				ataxiaBasher_skipRoom = true
				dangerSkip = true
        break
			end
		end
  end
  for _, player in pairs(ataxia.playersHere) do
    local playerData = ataxiaNDB and ataxiaNDB.players and ataxiaNDB.players[player]
    if playerData and playerData.city == "Mhaldor" then
      ataxiaBasher_skipRoom = false
    elseif not table.contains(ataxiaBasher.ignore, player) and ataxiaBasher.enabled then
      ataxiaBasher_skipRoom = true
      ataxiaEcho("Someone is here! --- "..player)
      ataxiaBasher_alert("Normal")
		end
  end 
end

function ataxiaBasher_roomBashed()
	for i,v in pairs(ataxiaBasher_path) do
		if v == tonumber(gmcp.Room.Info.num) then
			table.remove(ataxiaBasher_path, i)
			break
		end
	end
end

function ataxiaBasher_arrived()
	if not ataxiaBasher.areabash then return false end
	ataxiaBasher_roomBashed()
end

function ataxiaBasher_pathFail()
	if not ataxiaBasher.enabled then return false end
	ataxiaEcho("Impass detected. Recalculating route.")
	table.remove(ataxiaBasher_path, 1)

	if #ataxiaBasher_path > 0 then
		expandAlias("goto "..ataxiaBasher_path[1])
		ataxiaBasher_startStuckTimer()
	elseif not ataxiaBasher.manual then
		ataxiaBasher_areaoff()
	end
end

function ataxiaBasher_generatePath()
	ataxiaBasher_path = {}
  ataxiaTemp.mapperPath = nil
	bashWatcher = bashWatcher or createStopWatch()
	startStopWatch(bashWatcher)	
	if ataxiaBasherPaths and ataxiaBasherPaths[gmcp.Room.Info.area] then
		local roomsToAdd = ataxiaBasherPaths[gmcp.Room.Info.area]
		local thisRoom = tonumber(gmcp.Room.Info.num)
		
		if table.contains(roomsToAdd, thisRoom) and table.index_of(roomsToAdd, thisRoom) ~= #roomsToAdd and table.index_of(roomsToAdd, thisRoom) ~= 1 then
			ataxiaEcho("Our room is found in the middle of the path; starting from there instead.")
			table.insert(ataxiaBasher_path, thisRoom)
			local start = table.index_of(roomsToAdd, thisRoom)
			while start < #roomsToAdd do
				start = start + 1
				table.insert(ataxiaBasher_path, roomsToAdd[start])
			end			
		else
			ataxiaEcho("Creating path from scratch using pathing info.")
			for i,v in pairs(ataxiaBasherPaths[gmcp.Room.Info.area]) do
				table.insert(ataxiaBasher_path, v)
			end
		end
	else
		ataxiaEcho("Current area not tracked. Grabbing information from mapper instead.")
    ataxiaTemp.mapperPath = true
		collectRooms, result = getAreaRooms(getRoomArea(mmp.currentroom)), {}
		ataxiaBasher_path = deepcopy(collectRooms)
		table.sort(ataxiaBasher_path)
	end
	ataxiaTemp.basherRooms = #ataxiaBasher_path
	ataxiaEcho("Coordinates and path have been acquired. Total rooms: "..#ataxiaBasher_path.." | Process took: "..stopStopWatch(bashWatcher).."s to complete.")
	expandAlias("goto "..ataxiaBasher_path[1])
	ataxiaBasher_startStuckTimer()
  if ataxia.usegui or ataxia.usegui == nil then
    ataxiagui.basherBar:show()
    ataxiagui.basherBarClear:show()
  end
end

function saveRoomPath()
	bashWatcher = bashWatcher or createStopWatch()
	if #mapping_path < 2 then return end
	startStopWatch(bashWatcher)
	ataxiaBasherPaths[gmcp.Room.Info.area] = {}
	ataxiaEcho("Inputting rooms into the area table for: "..gmcp.Room.Info.area..".")
	for i,v in pairs(mapping_path) do
		table.insert(ataxiaBasherPaths[gmcp.Room.Info.area], v)
	end
	ataxiaEcho(gmcp.Room.Info.area.."'s table has been updated. Process took "..stopStopWatch(bashWatcher).."s to complete.")
	ataxia_saveSettings(false)
end

-- Death recovery: fully disable basher, clear all queues, and retreat after resurrection.
-- Saves the room we died in so we can move back one room to heal up safely.
function ataxiaBasher_onDeath()
  if not ataxiaBasher.enabled then return end

  -- Save safe room before anything else
  -- Check area-specific safe room first (capture area NOW, before respawn changes it)
  local deathArea = gmcp.Room.Info and gmcp.Room.Info.area or nil
  local safeConfig = ataxiaBasher_getAreaSafeRoom(deathArea)
  local safeRoom = (safeConfig and safeConfig.room) or (mmp and mmp.previousroom) or nil

  -- Immediately stop everything
  send("cq all")
  ataxiaBasher.enabled = false
  ataxiaBasher.paused = false
  ataxiaBasher.areabash = false
  ataxiaTemp.bashFlee = false
  autoBashRotation = false
  target = nil
  found_target = false

  -- Kill any active timers that could restart movement/attacks
  if ataxiaTemp.fleeCircuitBreaker then killTimer(ataxiaTemp.fleeCircuitBreaker); ataxiaTemp.fleeCircuitBreaker = nil end
  if ataxiaTemp.fleeReturnTimer then killTimer(ataxiaTemp.fleeReturnTimer); ataxiaTemp.fleeReturnTimer = nil end
  if ataxiaTemp.stuckTimer then killTimer(ataxiaTemp.stuckTimer); ataxiaTemp.stuckTimer = nil end
  if ataxiaBasher_atkTimer then killTimer(ataxiaBasher_atkTimer); ataxiaBasher_atkTimer = nil end
  ataxiaBasher_atk = false
  ataxiaTemp.fleeOriginRoom = nil
  ataxiaTemp.fleeReturning = nil

  -- Stop mapper movement
  if mmp and mmp.pause then mmp.pause("on") end

  raiseEvent("basher disabled")

  ataxiaEcho("DEATH DETECTED! Basher disabled. Queues cleared. Auto-rotation OFF.")

  -- After resurrection/starburst, move to the room before where we died to heal up
  if safeRoom then
    tempTimer(2, function()
      if mmp and mmp.pause then mmp.pause("off") end
      ataxiaEcho("Moving to safe room (v" .. safeRoom .. ") to heal up.")
      expandAlias("goto " .. safeRoom)
    end)
  end
end

-- Flee timeout / circuit breaker: if flee state persists beyond a timeout, disable basher.
-- Set ataxiaBasher.fleeTimeout (seconds, default 20) to configure.
function ataxiaBasher_startFleeTimer()
  if ataxiaTemp.fleeCircuitBreaker then killTimer(ataxiaTemp.fleeCircuitBreaker) end
  local timeout = ataxiaBasher.fleeTimeout or 20
  ataxiaTemp.fleeCircuitBreaker = tempTimer(timeout, function()
    if ataxiaTemp.bashFlee and ataxiaBasher.enabled then
      ataxiaEcho("Flee timeout reached (" .. timeout .. "s). Disabling basher as safety measure.")
      ataxiaBasher_areaoff()
      ataxiaTemp.bashFlee = false
    end
    ataxiaTemp.fleeCircuitBreaker = nil
  end)
end

-- Mapper-stuck detection: if speedwalk counter hasn't changed in X seconds, trigger path fail.
-- Set ataxiaBasher.stuckTimeout (seconds, default 15) to configure.
function ataxiaBasher_startStuckTimer()
  if ataxiaTemp.stuckTimer then killTimer(ataxiaTemp.stuckTimer) end
  if not ataxiaBasher.enabled or ataxiaBasher.manual then return end
  local timeout = ataxiaBasher.stuckTimeout or 15
  local initialCounter = mmp.speedWalkCounter or 0
  if initialCounter < 1 then return end
  ataxiaTemp.stuckTimer = tempTimer(timeout, function()
    if ataxiaBasher.enabled and mmp.speedWalkCounter and mmp.speedWalkCounter > 0
       and mmp.speedWalkCounter == initialCounter then
      ataxiaEcho("Mapper appears stuck (no movement for " .. timeout .. "s). Triggering path fail.")
      ataxiaBasher_pathFail()
    end
    ataxiaTemp.stuckTimer = nil
  end)
end

-- PvP attack detected while bashing: disable basher and flee to Mhaldor
function ataxiaBasher_onAttacked(_, attackerName, attackerClass)
  if not ataxiaBasher or not ataxiaBasher.enabled then return end

  ataxiaEcho("<red>ATTACKED by <white>" .. (attackerName or "unknown") .. " <red>(" .. (attackerClass or "?") .. ") while bashing! Fleeing to Mhaldor.")

  -- Stop everything
  send("cq all")
  autoBashRotation = false
  ataxiaBasher.enabled = false
  ataxiaBasher.paused = false
  ataxiaBasher.areabash = false
  ataxiaBasher_atk = false
  ataxiaTemp.fleeOriginRoom = nil
  ataxiaTemp.fleeReturning = nil
  if ataxiaTemp.fleeReturnTimer then killTimer(ataxiaTemp.fleeReturnTimer); ataxiaTemp.fleeReturnTimer = nil end
  raiseEvent("basher disabled")

  -- Navigate to Mhaldor
  if mmp and mmp.pause then mmp.pause("off") end
  expandAlias("goto Mhaldor")
end

registerAnonymousEventHandler("mmapper failed path", "ataxiaBasher_pathFail")
registerAnonymousEventHandler("mmapper arrived", "ataxiaBasher_arrived")
registerAnonymousEventHandler("player death", "ataxiaBasher_onDeath")
registerAnonymousEventHandler("attacker class detected", "ataxiaBasher_onAttacked")