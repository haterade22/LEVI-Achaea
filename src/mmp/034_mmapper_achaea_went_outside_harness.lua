-- unnamed > For Levi > mudlet-mapper > Mudlet Mapper > Game-specific > Achaea > mmapper_achaea_went_outside_harness

-- use Stratospheric Harness in Achaea -- PapaGuacamole
	
function mmapper_achaea_went_outside_harness()

	local area = mmp.getAreaName(mmp.currentroom)
	local areaid = getRoomArea(mmp.currentroom)
  if not mmp.autowalking or not mmp.settings.harness or not (mmp.game == "achaea") or
    (mmp.currentroom == mmp.speedWalkPath[#mmp.speedWalkPath]) or
    table.contains(gmcp.Room.Info.details, "indoors") or
    (not mmp.oncontinent(areaid, "Eastern_Isles") and not mmp.oncontinent(areaid, "Northern_Isles") and not mmp.oncontinent(areaid, "Western_Isles"))
		then return end

	local madeEast, madeNorth, madeWest

 	-- eastern isles
 	if mmp.oncontinent(areaid, "Eastern_Isles") then
 		addSpecialExit(mmp.currentroom, 54231, [[script:send("shake harness")]])
 		mmp.clearpathcache() -- clear cache so mmp.getPath accounts for the new way
 		madeEast = true
 	-- northern isles
 	elseif mmp.oncontinent(areaid, "Northern_Isles") then
 		addSpecialExit(mmp.currentroom, 48719, [[script:send("shake harness")]])
 		mmp.clearpathcache() -- clear cache so mmp.getPath accounts for the new way
 		madeNorth = true
 	-- western isles
 	elseif mmp.oncontinent(areaid, "Western_Isles") then
 		addSpecialExit(mmp.currentroom, 54632, [[script:send("shake harness")]])
 		mmp.clearpathcache() -- clear cache so mmp.getPath accounts for the new way
 		madeWest = true
 	end

	mmp.getPath(mmp.currentroom, mmp.speedWalkPath[#mmp.speedWalkPath]) -- don't need to check return value since that fact shouldnt've changed
	-- if our path didn't change, re-instate it as it was (since the new path starts from this room that we checked at)
	if speedWalkDir[1]:find("harness", 1, true) then
	speedWalkCounter = 0
		mmp.echo("We got outside - going to shortcut with harness.")
		if mmp.speedWalk.type == "room" then
			mmp.gotoRoom(mmp.speedWalkPath[#mmp.speedWalkPath])
		else
			mmp.gotoAreaID(getRoomArea(mmp.speedWalkPath[#mmp.speedWalkPath]))
		end
		mmp.ignore_speedwalking = true
 	end
	
  if madeEast then mmp.clearspecials{54231}
  elseif madeNorth then mmp.clearspecials{48719}
  elseif madeWest then mmp.clearspecials{54632} end

end