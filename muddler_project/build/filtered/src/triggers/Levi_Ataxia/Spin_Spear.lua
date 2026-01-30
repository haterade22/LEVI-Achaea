if type(target) == "string" and isTargeted(matches[2]) then
	selectString(line, 1)
	fg("red")
	setBold(true)
	resetFormat()
	send("cq eqbal")
	ataxia_boxEcho("STOP ATTACKING "..matches[2]:upper(), "black:red")
	
end