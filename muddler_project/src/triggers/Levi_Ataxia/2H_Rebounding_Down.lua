if target == matches[2] then
	targreb = false
	targshield = false
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