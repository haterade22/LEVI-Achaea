--[[mudlet
type: alias
name: Re-honours everyone.
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
regex: ^an recreate$
command: ''
packageName: ''
]]--

local count = 0
ataxiaEcho("Updating everyone who's currently in the database.")
for i,v in pairs(ataxiaNDB.players) do
	count = count + 1
	ataxiaNDB_Acquire(v.name:title(),false)
end
ataxiaEcho("Update complete. Total of "..count.." people have been re-checked.")