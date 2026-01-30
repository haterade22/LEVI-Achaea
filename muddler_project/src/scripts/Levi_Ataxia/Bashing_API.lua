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
ataxiaBasher_stormhammer()
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
ataxiaBasher_stormhammer()
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

-- Death recovery: pause basher on death so it doesn't keep running in a dead state.
-- The character can manually re-enable after resurrection.
function ataxiaBasher_onDeath()
  if not ataxiaBasher.enabled then return end
  ataxiaEcho("Death detected! Pausing basher. Re-enable after resurrection.")
  ataxiaBasher.paused = true
  ataxiaTemp.bashFlee = false
  target = nil
  found_target = false
  send("cq all")
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

registerAnonymousEventHandler("mmapper failed path", "ataxiaBasher_pathFail")
registerAnonymousEventHandler("mmapper arrived", "ataxiaBasher_arrived")
registerAnonymousEventHandler("player death", "ataxiaBasher_onDeath")