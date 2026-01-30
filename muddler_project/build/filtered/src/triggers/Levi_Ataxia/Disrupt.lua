if isTargeted(matches[2]) then
	tarAffed("disrupted")
  tempTimer(10, [[erAff("disrupted")]])
  if partyrelay then
    send("pt disrupt on "..matches[2],false)
  end  
end