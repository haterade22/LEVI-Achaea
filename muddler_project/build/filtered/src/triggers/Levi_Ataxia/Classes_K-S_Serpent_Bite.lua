if isTargeted(matches[2]) then
	if matches[3] ~= "loki" and matches[3] ~= "camus" then
		tarAffed(venom_to_aff(matches[3]))
		if applyAffV3 then applyAffV3(venom_to_aff(matches[3])) end
	end
end