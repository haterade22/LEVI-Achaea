if isTargeted(matches[2]) then
	tarAffed("haemophilia")
	if applyAffV3 then applyAffV3("haemophilia") end
	
	if tAffs.bleed == nil then tAffs.bleed = 0 end
	tAffs.bleed = tAffs.bleed + 200
end