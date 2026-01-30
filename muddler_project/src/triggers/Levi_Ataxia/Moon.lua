local moons = {"stupidity", "masochism", "hallucinations", "hypersomnia", "confusion", "epilepsy","claustrophobia", "agoraphobia"}
if not moonAff then
	for i=1, #moons do
		if not haveAff(moons[i]) then
			tarAffed(moons[i])
			break
		end
	end
else
	tarAffed(moonAff)
	moonAff = false
end

	if readAuraAffs and readAuraAffs.count then
		readAuraAffs.count = readAuraAffs.count + 1
	end	