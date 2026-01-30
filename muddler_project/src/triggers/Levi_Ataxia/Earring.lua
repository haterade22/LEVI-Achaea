if type(target) ~= "string" then
	return false
end

if isTargeted(matches[2]) then
	selectString(line,1)
	fg("black") bg("orange")
	resetFormat()
  deselect()

	ataxia_boxEcho(target.." EARRING - PRONE / ENTANGLE NOW!", "orange")
  send("cq all;cq all")
end