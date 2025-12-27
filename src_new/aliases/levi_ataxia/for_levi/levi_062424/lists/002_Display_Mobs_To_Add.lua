--[[mudlet
type: alias
name: Display Mobs To Add
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Autobashing
- Lists
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bash add$
command: ''
packageName: ''
]]--

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