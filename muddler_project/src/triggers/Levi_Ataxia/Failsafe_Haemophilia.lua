if isTargeted(matches[2]) and tAffs.bleed and tAffs.bleed >= 140 then
	erAff("haemophilia")
	tAffs.bleed = 0
end