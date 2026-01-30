if type(target) == "number" and ataxiaBasher.enabled and not ataxiaBasher.manual then
	deleteFull()
else
	deleteLine()
	cecho("\n<NavajoWhite>[RIFT]: <green>+<white>"..matches[2].." <grey>"..matches[3]:title()..". Total: <white>"..matches[4]..".")
end

if tonumber(matches[4]) > 50 and riftMsgList[matches[3]] then
	riftMsgList[matches[3]] = nil
end
