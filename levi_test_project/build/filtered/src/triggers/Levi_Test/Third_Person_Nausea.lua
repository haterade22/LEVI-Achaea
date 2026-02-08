if isTargeted(matches[2]) then
	tarAffed("nausea")
	if applyAffV3 then applyAffV3("nausea") end

	-- V3 integration: collapse branches (proves nausea present)
	if onTargetVomitV3 then onTargetVomitV3() end
end