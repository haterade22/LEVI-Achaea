ataxiaBasher.mobIgnore = ataxiaBasher.mobIgnore or {}
if ataxia.denizensHere and ataxiaBasher.targetList[gmcp.Room.Info.area] then
	ataxiaEcho("Displaying mobs currently in room, but not in ignore list.")
	for i,v in pairs(ataxia.denizensHere) do
		if not table.contains(ataxiaBasher.mobIgnore, v) then
			cecho("\n  <green>+ ")
			fg("white")
			echoLink(v, [[ataxiaBasher_ignoremob("]]..v..[[")]], "Add "..v.." to denizen ignore list.", true)
			cecho(" <green>+")
		end
	end
	send(" ")
end