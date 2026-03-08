if isTargeted(matches[2]) then
	selectString(line,1)
	fg("tomato")
	resetFormat()
	erAff("hamstring")
	if hamstringTimer then killTimer(hamstringTimer) end

if not ataxia.afflictions.aeon and partyrelay then
  send("pt " ..target..": ")
end
end