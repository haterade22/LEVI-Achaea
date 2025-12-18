-- unnamed > For Levi > mudlet-mapper > Mudlet Mapper > Utilities > mmp_relock_areas

function mmp_relock_areas()
	local getAreaRooms, lockRoom, lockedareas = getAreaRooms, lockRoom, mmp.locked

	for areaid, areaname in pairs(getAreaTableSwap()) do
		if lockedareas[areaid] then
			local rooms = getAreaRooms(areaid) or {}
			for _, roomid in pairs(rooms) do
				lockRoom(roomid, true)
			end
		else
			local rooms = getAreaRooms(areaid) or {}
			for _, roomid in pairs(rooms) do
				lockRoom(roomid, false)
			end
		end
	end

	-- make sure area with ID 0 is locked - this was causing crashing issues
	local rooms = getAreaRooms(0) or {}
	for _, roomid in pairs(rooms) do
		lockRoom(roomid, true)
	end
end