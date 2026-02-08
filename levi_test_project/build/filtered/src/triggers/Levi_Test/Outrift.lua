if not ataxiaTemp.ignoreOutrift then outrifted(matches[3], matches[2]) end

if not riftMsgList then riftMsgList = {} end
if type(target) == "number" and ataxiaBasher.enabled and not ataxiaBasher.manual then
	deleteFull()
else
	deleteLine()
	cecho("\n<NavajoWhite>[RIFT]: <red>-<white>"..matches[2].." <grey>"..matches[3]:title()..". Remaining: <white>"..matches[4]..".")
end

if tonumber(matches[4]) <= 1 and not riftMsgList[matches[3]] then
	send("msg "..gmcp.Char.Name.name.." We likely ran out of "..matches[3]..". Should probably buy some more.")
	riftMsgList[matches[3]] = true
end