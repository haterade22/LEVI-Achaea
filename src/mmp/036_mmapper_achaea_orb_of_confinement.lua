-- unnamed > For Levi > mudlet-mapper > Mudlet Mapper > Game-specific > Achaea > mmapper_achaea_orb_of_confinement

function mmp.setOrb(city)
  mmp.clearpathcache()
  if mmp.settings["orb"..city:lower()] then
    mmp.echo("Orb of Confinement set as <green>ACTIVE<reset> for " .. city:title())
  else
    mmp.echo("Orb of Confinement set as <red>INACTIVE<reset> for " .. city:title())
  end
end

function mmapper_achaea_orb_of_confinement()

  if
    not mmp.autowalking or
    not (
      mmp.settings.duanathar or
      mmp.settings.duanatharan or
      mmp.settings.duantahar or
      mmp.settings.duanatharic or
      mmp.settings.soar
    ) or
    not (mmp.game == "achaea") or
    (mmp.currentroom == mmp.speedWalkPath[#mmp.speedWalkPath]) or
    table.contains(gmcp.Room.Info.details, "indoors") or
    not mmp.orbed()
  then
    return
  end
  -- repath, just in case we were going to use wings here
  raiseEvent("mmp link externals")
  local previousDirection = mmp.speedWalkDir[speedWalkCounter+1]
  if mmp.speedWalk.type == "room" then
    mmp.getPath(mmp.currentroom, mmp.speedWalkPath[#mmp.speedWalkPath])
    -- don't need to check return value since that fact shouldnt've changed
  else
    mmp.gotoAreaID(getRoomArea(mmp.speedWalkPath[#mmp.speedWalkPath]))
  end
  -- if our path didn't change, re-instate it as it was (since the new path starts from this room that we checked at)
  if speedWalkDir[1] ~= previousDirection then
    speedWalkCounter = 0
    mmp.echo("We're inside, remapping path to not use wings here.")
    if mmp.speedWalk.type == "room" then
      mmp.gotoRoom(mmp.speedWalkPath[#mmp.speedWalkPath])
    else
      mmp.gotoAreaID(getRoomArea(mmp.speedWalkPath[#mmp.speedWalkPath]))
    end
    mmp.ignore_speedwalking = true
  end
  raiseEvent("mmp clear externals")
end