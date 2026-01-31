if isTargeted(matches[2]) then
tdeliverance = false
  if passiveFailsafe then restorePassiveCure() end

	-- V2 integration: notify smoke detection for disambiguation
	if onTargetSmokeV2 then onTargetSmokeV2(matches[2]) end

	-- V3 integration: handle smoke cure (proves asthma absent AND creates branches for smoke-curable affs)
	if onSmokeCureV3 then onSmokeCureV3() end

	-- Kill disambiguation timer - smoke proves asthma is cured
	if kelpDisambiguateTimer then killTimer(kelpDisambiguateTimer); kelpDisambiguateTimer = nil end

	-- Smoking proves asthma was cured (they couldn't smoke with asthma)
	erAff("asthma")

	-- If we had uncertain kelp afflictions, now we know: asthma was cured
	-- Keep other kelp affs (they weren't cured)
	if lastKelpAffs then
		lastKelpAffs = nil
		ataxiaEcho("Smoke confirmed: asthma cured, other kelp affs still present.")
	end

	-- Legacy backtrack support
	if lastKelp and lastKelp ~= "asthma" then
		tAffs[lastKelp] = true
		lastKelp = nil
		ataxiaEcho("Backtracked asthma being cured with last eat.")
	elseif lastKelp and lastKelp == "asthma" then
		lastKelp = nil
	end

	local sAffs = {"aeon", "deadening", "tension",
		"disloyalty","manaleech", "slickness", "unweavingspirit"}


	if haveAff("hellsight") and not haveAff("inquisition") then
		erAff("hellsight")		
	else	
		for i=1, #sAffs do
			if tAffs[sAffs[i]] then
				erAff(sAffs[i])
				break
			end
		end	
	end
	
	if ataxiaTemp.snapTimer then killTimer(ataxiaTemp.snapTimer); ataxiaTemp.snapTimer = nil end
	
	targetIshere = true
end