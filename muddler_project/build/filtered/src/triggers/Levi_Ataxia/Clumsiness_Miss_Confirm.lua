if clumsiness_lastAttacker and isTargeted(clumsiness_lastAttacker) then
	tarAffed("clumsiness")

	-- V3 integration: collapse branches (proves clumsiness present)
	if onTargetFumbleV3 then onTargetFumbleV3() end
end
