local x = multimatches[1][1]:lower()

for _, npc in pairs(ataxiaBasher.targetList[gmcp.Room.Info.area]) do
	if string.find(x, npc:lower()) then
		if not ataxiaBasher.manual then
			deleteFull()
		end
	end
end
