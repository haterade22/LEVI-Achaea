if isTargeted(matches[2]) then
	tarAffed("masochism")
	if applyAffV3 then applyAffV3("masochism") end
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
      if applyAffV3 then applyAffV3("dizziness") end
      confirmAffV2("dizziness")
    else
      killTimer(tostring(wormTimer))
	    wormTimer = tempTimer(7.5, [[wormtick()]])
    end
  end
end