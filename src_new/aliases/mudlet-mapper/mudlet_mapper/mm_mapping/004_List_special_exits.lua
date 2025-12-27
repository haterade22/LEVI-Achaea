--[[mudlet
type: alias
name: List special exits
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- mm Mapping
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '^spe list(?: (.+))?$'
command: ''
packageName: ''
]]--

mmp.listSpecialExits(matches[2])