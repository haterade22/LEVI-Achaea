if isTargeted(matches[2]) then
	tarAffed(envenomList[1])
	if applyAffV3 then applyAffV3(envenomList[1]) end
   local affstruck = envenomList[1]

	table.remove(envenomList, 1)
  if partyrelay then send("pt "..target..": "..affstruck)
  end
end