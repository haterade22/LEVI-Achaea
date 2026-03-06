if type(target) == "string" and isTargeted(matches[2]) then
	tAffs.shield = false
	if removeAffV3 then removeAffV3("shield") end
	selectString(line,1)
	setBold(true)
	fg("NavajoWhite")
	resetFormat()
end

if ataxiaBasher.enabled then
  if not ataxiaBasher.manual then
    deleteFull()
  end
end