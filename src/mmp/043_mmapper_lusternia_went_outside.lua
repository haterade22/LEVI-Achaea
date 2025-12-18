-- unnamed > For Levi > mudlet-mapper > Mudlet Mapper > Game-specific > Lusternia > mmapper_lusternia_went_outside

function mmapper_lusternia_went_outside()
  -- track whenever we need to use items when we get outside!
  if
    not mmp.autowalking or
    mmp.game ~= "lusternia" or
    (mmp.currentroom == mmp.speedWalkPath[#mmp.speedWalkPath])
  then
    return
  end
  -- repath, maybe that'll allow us to use wings now.
  raiseEvent("mmp link externals")
	local previousDirection = mmp.speedWalkDir[speedWalkCounter]
  mmp.getPath(mmp.currentroom, mmp.speedWalkPath[#mmp.speedWalkPath])
  -- don't need to check return value since that fact shouldnt've changed
  -- if our path didn't change, re-instate it as it was (since the new path starts from this room that we checked at)
  if
    speedWalkDir[1]~=previousDirection
  then
    speedWalkCounter = 0
    mmp.echo("We got outside - going to shortcut with 'bix device.")
		if mmp.speedWalk.type == "room" then
			mmp.gotoRoom(mmp.speedWalkPath[#mmp.speedWalkPath])
		else
			mmp.gotoAreaID(getRoomArea(mmp.speedWalkPath[#mmp.speedWalkPath]))
		end
    mmp.ignore_speedwalking = true
  end
  raiseEvent("mmp clear externals")
end