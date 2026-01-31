--[[mudlet
type: alias
name: Extract Minerals
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Other stuff
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^ext$
command: ''
packageName: ''
]]--

ataxiaExtraction = ataxiaExtraction or {}
local a = gmcp.Room.Info.area 

if ataxiaExtraction[a] then
  send("queue addclear free extract "..ataxiaExtraction[a],false)
else
  send("minerals",false)
end
