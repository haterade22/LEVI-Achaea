--[[mudlet
type: alias
name: Set Highlight Prioritiy
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Ataxia NDB
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^an prio (enemies|city)$
command: ''
packageName: ''
]]--

local type, colour = matches[2], matches[3]

if ataxiaNDB.highlightPriority ~= matches[2] then
	ataxiaNDB.highlightPriority = matches[2]
	ataxiaEcho("Highlighting will give priority to "..ataxiaNDB.highlightPriority..".")
	ataxiaNDB_enemyHighlights()
else
	ataxiaEcho("Already prioritising highlighting of that.")
end
