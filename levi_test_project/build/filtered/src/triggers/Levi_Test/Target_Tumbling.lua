if isTargeted(matches[2]) then
	selectString(line, 1)
	fg("orange")
	setBold(true)
	resetFormat()
	ataxia_boxEcho("TARGET IS TUMBLING - CANCEL IT!", "black:orange")
	ataxiaTemp.tarTumble = true
	if ataxiaTemp.tumbleTimer then killTimer(ataxiaTemp.tumbleTimer) end
	ataxiaTemp.tumbleTimer = tempTimer(5, [[ataxiaTemp.tarTumble = nil;
		ataxiaTemp.tumbleTimer = nil;
	]])
end