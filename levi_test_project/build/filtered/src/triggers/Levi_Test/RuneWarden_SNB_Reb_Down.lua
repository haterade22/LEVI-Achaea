targreb = false
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