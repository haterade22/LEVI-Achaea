local moons = {"stupidity", "masochism", "hallucinations", "hypersomnia", "confusion", "epilepsy","claustrophobia", "agoraphobia"}
if not moonAff then
	for i=1, #moons do
		if not haveAff(moons[i]) then
			tarAffed(moons[i])
			if applyAffV3 then applyAffV3(moons[i]) end
			break
		end
	end
else
	tarAffed(moonAff)
	if applyAffV3 then applyAffV3(moonAff) end
	moonAff = false
end

	if readAuraAffs and readAuraAffs.count then
		readAuraAffs.count = readAuraAffs.count + 1
	end	