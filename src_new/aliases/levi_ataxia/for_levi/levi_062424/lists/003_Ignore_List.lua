--[[mudlet
type: alias
name: Ignore List
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
regex: ^bsi (\w+)$
command: ''
packageName: ''
]]--

if matches[2] == "all" then
	send("unally all")
	for i,v in pairs(gmcp.Room.Players) do
		if not table.contains(ataxiaBasher.ignore, v.name) then
			table.insert(ataxiaBasher.ignore, v.name)
			send("ally "..v.name)
			ataxiaEcho("Won't take notice of "..v.name.." while bashing.")
		end
	end
elseif matches[2] == "rem" or matches[2] == "remove" then
		ataxiaBasher.ignore = {}
		table.insert(ataxiaBasher.ignore, gmcp.Char.Name.name)
		ataxiaEcho("Bashing ignore list has been reset.")
else	
	if table.contains(ataxiaBasher.ignore, matches[2]:title()) then
		for i,v in pairs(ataxiaBasher.ignore) do
			if v == matches[2]:title() then
				ataxiaEcho("Taking notice of <red>"..v.."<LightSkyBlue> while bashing.")
				table.remove(ataxiaBasher.ignore, i)
			end
		end
	else
		table.insert(ataxiaBasher.ignore, matches[2]:title())
		ataxiaEcho("Won't take notice of "..matches[2]:title().." while bashing.")
	end
end

ataxia_saveSettings(false)