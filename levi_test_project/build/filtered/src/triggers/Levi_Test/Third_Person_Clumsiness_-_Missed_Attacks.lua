if isTargeted(matches[2]) then
	tarAffed("clumsiness")
	if applyAffV3 then applyAffV3("clumsiness") end

	-- V3 integration: collapse branches (proves clumsiness present)
	if onTargetFumbleV3 then onTargetFumbleV3() end
end