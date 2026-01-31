if isTargeted(matches[2]) then
	tarAffed("clumsiness")

	-- V3 integration: collapse branches (proves clumsiness present)
	if onTargetFumbleV3 then onTargetFumbleV3() end
end