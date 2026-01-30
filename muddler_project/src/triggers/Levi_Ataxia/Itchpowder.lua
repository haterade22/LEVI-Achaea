if isTargeted(matches[2]) then
	if line:find("scratching") then
		tarAffed("impatience")
		tAffs.itching = true
	else
		tarAffed("itching")
	end
end