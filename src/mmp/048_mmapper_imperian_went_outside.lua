-- unnamed > For Levi > mudlet-mapper > Mudlet Mapper > Game-specific > Imperian > mmapper_imperian_went_outside

function mmapper_imperian_went_outside()
  if
    not mmp.autowalking or
    not (mmp.settings.shekinah or mmp.settings.suriel) or
    mmp.game ~= "imperian" or
    (mmp.currentroom == mmp.speedWalkPath[#mmp.speedWalkPath]) or
    table.contains(gmcp.Room.Info.details, "indoors") or
    table.contains(gmcp.Room.Info.details, "considered indoors") or
    not table.contains(mmp.imperian.wingAbleAreas, getRoomArea(mmp.currentroom))
  then
    return
  end
  -- repath, maybe that'll allow us to use wings now.
  raiseEvent("mmp link externals")
  local previousDirection = mmp.speedWalkDir[speedWalkCounter]
  mmp.getPath(mmp.currentroom, mmp.speedWalkPath[#mmp.speedWalkPath])
  -- don't need to check return value since that fact shouldnt've changed
  -- if our path didn't change, re-instate it as it was (since the new path starts from this room that we checked at)
  if speedWalkDir[1] ~= previousDirection then
    speedWalkCounter = 0
    mmp.echo("We got outside - going to shortcut with wings.")
    mmp.gotoRoom(mmp.speedWalkPath[#mmp.speedWalkPath])
    mmp.ignore_speedwalking = true
  end
  raiseEvent("mmp clear externals")
end