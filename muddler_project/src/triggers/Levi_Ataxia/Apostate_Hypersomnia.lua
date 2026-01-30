if isTargeted(matches[2]) then
  tarAffed("hypersomnia")
end
if gmcp.Char.Status.class == "Apostate" then
  if demon() == "nightmare" then
    killTimer(tostring(nmTimer))
    nmTimer = tempTimer(8.5, [[nighttick()]])
    killTimer(tostring(mareTimer))
    mareTimer = tempTimer(6.5, [[maretickthing()]])
  end
end




function nighttick()
  if demon() == "nightmare" then
    if tAffs.dementia and tAffs.hypersomnia then
      tarAffed("hellsight")
    else
      killTimer(tostring(nmTimer))
	    nmTimer = tempTimer(8.5, [[nighttick()]])
    end
  end
end

function maretickthing()
  if demon() == "nightmare" then
    if not tAffs.dementia and tAffs.hypersomnia and tAffs.asthma and tAffs.impatience then
      maretick = true
    else
    maretick = false
      killTimer(tostring(mareTimer))
	    mareTimer = tempTimer(6.5, [[maretickthing()]])
    end
  end
end