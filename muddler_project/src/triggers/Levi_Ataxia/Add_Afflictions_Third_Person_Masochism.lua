if isTargeted(matches[2]) then
	tarAffed("masochism")
  confirmAffV2("masochism")
end

if gmcp.Char.Status.class == "Apostate" then
  if bloodworm() == true then
    killTimer(tostring(wormTimer))
    wormTimer = tempTimer(7.5, [[wormtick()]])
   
  end
end




function wormtick()
  if bloodworm() == true then
    if tAffs.masochism and not tAffs.deafness then
      tarAffed("dizziness")
      confirmAffV2("dizziness")
    else
      killTimer(tostring(wormTimer))
	    wormTimer = tempTimer(7.5, [[wormtick()]])
    end
  end
end