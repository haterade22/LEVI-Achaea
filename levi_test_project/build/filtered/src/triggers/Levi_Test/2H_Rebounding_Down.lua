if target == matches[2] then
	targreb = false
	targshield = false
	tAffs.rebounding = false
	tAffs.shield = false
	if removeAffV3 then removeAffV3("shield") end
  removeAffV3("rebounding")
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