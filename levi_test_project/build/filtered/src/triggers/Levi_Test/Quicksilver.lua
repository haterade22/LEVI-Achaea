if isTargeted(matches[2]) then
tdeliverance = false
	erAff("slickness")
	if removeAffV3 then removeAffV3("slickness") end
	erAff("paralysis")
	if removeAffV3 then removeAffV3("paralysis") end
	-- Note: fangbarrier comes later with "metallic shell" message
	targetIshere = true
end