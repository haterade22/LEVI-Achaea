targreb = false
tAffs.rebounding = false

-- V3 tracking support
if affConfigV3 and affConfigV3.enabled and removeAffV3 then
	removeAffV3("rebounding")
end
-- V2 tracking support
if ataxia and ataxia.settings and ataxia.settings.useAffTrackingV2 then
	if removeAffV2 then
		removeAffV2("rebounding")
	elseif tAffsV2 then
		tAffsV2.rebounding = 0
	end
end