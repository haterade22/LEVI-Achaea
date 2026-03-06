if isTargeted(matches[2]) then
	if line:find("scratching") then
		tarAffed("impatience")
		if applyAffV3 then applyAffV3("impatience") end
		tAffs.itching = true
		if applyAffV3 then applyAffV3("itching") end
	else
		tarAffed("itching")
		if applyAffV3 then applyAffV3("itching") end
	end
end