local linefind = matches[2]:lower()
local xyz = ""
linefind = linefind:gsub("-", " ")
for _, mob in pairs(ataxiaBasher.targetList[gmcp.Room.Info.area]) do
	xyz = mob:lower()
	xyz = xyz:gsub("-", " ")
	if linefind:find(xyz) and not haveBeenHit then
		haveBeenHit = tempTimer(1, [[ haveBeenHit = nil ]])
		bashConsoleEcho("denizen", "Denizen attacked us!")
		bashStats.mobhits = bashStats.mobhits + 1
		if not ataxiaBasher.manual then
			deleteFull()
		end
	elseif linefind:find(xyz) and haveBeenHit then
		if not ataxiaBasher.manual then
			deleteFull()
		end
	end
end