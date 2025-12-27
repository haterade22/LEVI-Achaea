--[[mudlet
type: alias
name: delete old profiles
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- deleteOldProfiles
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '^delete old (profiles|maps|modules)(?: (\d+))?$'
command: ''
packageName: ''
]]--

deleteOldProfiles(matches[3], matches[2])

--Syntax examples: "delete old profiles"  -> deletes profiles older than 31 days
--					"delete old maps 10"	-> deletes maps older than 10 days