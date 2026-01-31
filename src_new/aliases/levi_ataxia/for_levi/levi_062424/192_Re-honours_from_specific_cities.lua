--[[mudlet
type: alias
name: Re-honours from specific cities
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Ataxia NDB
- Actions
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^an redo (\w+)$
command: ''
packageName: ''
]]--

local count = 0
ataxiaEcho("Re-checking everyone matching the '"..matches[2].."' city.")
for i,v in pairs(ataxiaNDB.players) do
  if v.city:lower() == matches[2]:lower() then
	 ataxiaNDB_Acquire(v.name:title(),false)
   count = count + 1
  end
end
ataxiaEcho("Update complete. Total of "..count.." people have been re-checked.")