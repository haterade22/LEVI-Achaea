if target == matches[2] then
	tAffs.rebounding = false
	-- V2 tracking support
	if ataxia and ataxia.settings and ataxia.settings.useAffTrackingV2 then
		if removeAffV2 then
			removeAffV2("rebounding")
		elseif tAffsV2 then
			tAffsV2.rebounding = 0
		end
	end
end