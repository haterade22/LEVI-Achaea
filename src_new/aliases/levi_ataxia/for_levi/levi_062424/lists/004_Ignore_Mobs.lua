--[[mudlet
type: alias
name: Ignore Mobs
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
regex: ^bash ignore$
command: ''
packageName: ''
]]--

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