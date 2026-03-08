if not ataxiaBasher.targetList then
	ataxiaEcho("Bashing systems not yet loaded. Run 'levi setup' or 'abinstall' first.")
	return
end
if ataxia.denizensHere and ataxiaBasher.targetList[gmcp.Room.Info.area] then
	ataxiaEcho("Displaying mobs currently in room, but not in target list. Click to add.")
	for i,v in pairs(ataxia.denizensHere) do
		if not table.contains(ataxiaBasher.targetList[gmcp.Room.Info.area], v) and not table.contains(ataxiaBasher.mobIgnore, v) then
			cecho("\n  <green>+ ")
			fg("white")
			echoLink(v, [[ataxiaBasher_addmob("]]..v..[[")]], "Add "..v.." to denizen list.", true)
			cecho(" <green>+")
		end
	end
	send(" ")
end