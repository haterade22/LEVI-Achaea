if isTargeted(matches[3]) then
	ataxiaTemp.dragoncurse = matches[2]
end

tempTimer(matches[4],[[send("pt " ..matches[2]..": "..matches[3]")]])