if isTargeted(matches[2]) then
	tarAffed("haemophilia")
	
	if tAffs.bleed == nil then tAffs.bleed = 0 end
	tAffs.bleed = tAffs.bleed + 200
end