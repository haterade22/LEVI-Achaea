--[[mudlet
type: alias
name: Create an area
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- mm Mapping
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^area add (.+)$
command: ''
packageName: ''
]]--

local t = getAreaTable(); local tr = {}; for k,v in pairs(t) do tr[v] = k end
local newid = table.maxn(tr) + 1

setAreaName( newid, matches[2] )
mmp.echo(string.format("Created new area %s (%d)", matches[2], newid))
centerview(mmp.currentroom)
raiseEvent("mmp areas changed")