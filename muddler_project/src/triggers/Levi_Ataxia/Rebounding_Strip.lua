if type(target) == "string" and isTargeted(matches[2]) then
	tAffs.rebounding = false
	tAffs.shield = false
	-- V3 tracking support
	if affConfigV3 and affConfigV3.enabled and removeAffV3 then
		removeAffV3("rebounding")
		removeAffV3("shield")
	end
	-- V2 tracking support
	if ataxia and ataxia.settings and ataxia.settings.useAffTrackingV2 then
		if removeAffV2 then
			removeAffV2("rebounding")
			removeAffV2("shield")
		elseif tAffsV2 then
			tAffsV2.rebounding = 0
			tAffsV2.shield = 0
		end
	end
	selectString(line,1)
	setBold(true)
	fg("NavajoWhite")
	resetFormat()
end

if matches[2] == target then
	tAffs.rebounding = false
	tAffs.shield = false
	-- V3 tracking support
	if affConfigV3 and affConfigV3.enabled and removeAffV3 then
		removeAffV3("rebounding")
		removeAffV3("shield")
	end
	-- V2 tracking support
	if ataxia and ataxia.settings and ataxia.settings.useAffTrackingV2 then
		if removeAffV2 then
			removeAffV2("rebounding")
			removeAffV2("shield")
		elseif tAffsV2 then
			tAffsV2.rebounding = 0
			tAffsV2.shield = 0
		end
	end
end
