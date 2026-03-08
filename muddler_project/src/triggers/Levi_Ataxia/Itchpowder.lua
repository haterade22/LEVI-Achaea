if isTargeted(matches[2]) then
	if line:find("scratching") then
		tarAffed("impatience")
		tarAffed("itching")
	else
		tarAffed("itching")
	end
end