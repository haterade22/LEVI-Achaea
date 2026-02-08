if target == matches[2] then
	tAffs.rebounding = false
  removeAffV3("rebounding")
	-- V2 tracking support
	if ataxia and ataxia.settings and ataxia.settings.useAffTrackingV2 then
		if removeAffV2 then
			removeAffV2("rebounding")
		elseif tAffsV2 then
			tAffsV2.rebounding = 0
		end
	end
	selectString(line,1)
	setBold(true)
	fg("NavajoWhite")
	resetFormat()
end

--Archaeon reaches out and nimbly plucks the arrow from the air.
--You begin sketching a thurisaz rune on the ground.

