if isTargeted(matches[2]) then
	tarAffed("nausea")

	-- V3 integration: collapse branches (proves nausea present)
	if onTargetVomitV3 then onTargetVomitV3() end
end