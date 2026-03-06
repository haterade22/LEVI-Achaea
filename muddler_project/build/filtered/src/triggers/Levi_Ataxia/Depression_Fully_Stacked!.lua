if isTargeted(matches[2]) then
	selectString(line,1)
	fg("black")
	bg("red")
	setBold(true)
	resetFormat()
	tarAffed("anorexia", "hypochondria", "nausea", "masochism")
	if applyAffV3 then applyAffV3("anorexia"); applyAffV3("hypochondria"); applyAffV3("nausea"); applyAffV3("masochism") end
end