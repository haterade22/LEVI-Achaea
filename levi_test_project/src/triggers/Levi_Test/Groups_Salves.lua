if isTargeted(matches[2]) then
tdeliverance = false
  if passiveFailsafe then restorePassiveCure() end
	erAff("slickness")

	-- V3 integration: salve proves slickness absent
	if onTargetApplySalveV3 then onTargetApplySalveV3() end

	targetIshere = true
end