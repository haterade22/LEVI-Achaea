if type(target) == "number" and ataxiaBasher.enabled then
	bashConsoleEcho("denizen", target.." slain!")
	if not ataxiaBasher.manual then
		deleteFull()
	end
	bashStats.slain = bashStats.slain + 1
  ataxiaBasher.shielded = false
	if ataxiaTemp.canJinx then
		ataxiaTemp.canJinx = false
	end
	
	ataxiaTemp.mobhealth = 0
end

	local area = gmcp.Room.Info.area
	if not table.contains(ataxiaBasher.targetList[area], matches[2]) then
		ataxiaBasher_addmob(matches[2])
	end

