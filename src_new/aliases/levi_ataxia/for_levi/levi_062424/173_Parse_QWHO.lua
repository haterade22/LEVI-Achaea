--[[mudlet
type: alias
name: Parse QWHO
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Ataxia NDB
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '^qwp(?: (\w+)|)$'
command: ''
packageName: ''
]]--

if not ataxiaNDB then
	ataxiaEcho("Name database not currently loaded.")
else
	parsingQW = true
	peopleOnline = {}
	if matches[2] then
		parsingCity = matches[2]
	end
	sendGMCP("Comm.Channel.Players")
	send(" ")
	ataxiaNDB_GetOnline()
end