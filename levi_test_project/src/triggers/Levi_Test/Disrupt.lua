if isTargeted(matches[2]) then
	tarAffed("disrupted")
	if applyAffV3 then applyAffV3("disrupted") end
  tempTimer(10, [[erAff("disrupted"); if removeAffV3 then removeAffV3("disrupted") end]])
  if partyrelay then
    send("pt disrupt on "..matches[2],false)
  end  
end