if isTargeted(matches[2]) and tAffs.bleed and tAffs.bleed >= 140 then
	erAff("haemophilia")
	if removeAffV3 then removeAffV3("haemophilia") end
	tAffs.bleed = 0
end