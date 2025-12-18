-- unnamed > For Levi > mudlet-mapper > Mudlet Mapper > Game-specific > Starmourn > Lifts

-------------------------------------------------
--         Put your Lua functions here.        --
--                                             --
-- Note that you can also use external Scripts --
-------------------------------------------------
function mmp.liftFloor(roomname,floornum,currentfloor) --string,int,bool
	if not mmp.autowalking then
		return
	end

	--get room name of next in speedwalkpath
	if not speedWalkCounter then
    speedWalkCounter = 1
  end
	local destRoomName = getRoomName(mmp.speedWalkPath[speedWalkCounter])
	if roomname == nil then roomname = destRoomName end

	if roomname == destRoomName then
		if currentfloor then
			send("EXIT LIFT",false) --Lift is on correct floor, can EXIT LIFT
			if mmp.liftTimer then killTimer(mmp.liftTimer) end
		else
			mmp.customwalkdelay(2) --Lift is on incorrect floor arbitrary wait for next trigger line
			if mmp.liftTimer then killTimer(mmp.liftTimer) end
			mmp.liftTimer = tempTimer(1, function() send("KEY LIFT ".. floornum,false) end )	--wait one second before requesting the correct floor (allows other users to enter/exit)
		end
	end
end