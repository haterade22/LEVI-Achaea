-- unnamed > For Levi > mudlet-mapper > Mudlet Mapper > Game-specific > Achaea > mmapper_achaea_went_outside

-- track whenever we need to use wings or aero soar when we get outside!
function mmapper_achaea_went_outside()
  if not mmp.autowalking or not (mmp.settings.duanathar or mmp.settings.duanatharan or mmp.settings.duantahar or mmp.settings.duanatharic or mmp.settings.soar) or mmp.game ~= "achaea" or
    (mmp.currentroom == mmp.speedWalkPath[#mmp.speedWalkPath]) or
    table.contains(gmcp.Room.Info.details, "indoors")
  then return end

  -- repath, maybe that'll allow us to use wings now.
  raiseEvent("mmp link externals")
	local previousDirection = mmp.speedWalkDir[speedWalkCounter]
	if mmp.speedWalk.type == "room" then
	  mmp.getPath(mmp.currentroom, mmp.speedWalkPath[#mmp.speedWalkPath]) -- don't need to check return value since that fact shouldnt've changed
	else
		mmp.gotoAreaID(getRoomArea(mmp.speedWalkPath[#mmp.speedWalkPath]))
	end

  -- if our path didn't change, re-instate it as it was (since the new path starts from this room that we checked at)
  if speedWalkDir[1]~=previousDirection then
    speedWalkCounter = 0
    mmp.echo("We got outside - going to shortcut with wings.")
		if mmp.speedWalk.type == "room" then
			mmp.gotoRoom(mmp.speedWalkPath[#mmp.speedWalkPath])
		else
			mmp.gotoAreaID(getRoomArea(mmp.speedWalkPath[#mmp.speedWalkPath]))
		end
    mmp.ignore_speedwalking = true
  end
	raiseEvent("mmp clear externals")
end