--[[mudlet
type: alias
name: Delete all special exits across a map
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- mm Mapping
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '^spe delete all(?: (.+))?$'
command: ''
packageName: ''
]]--

mmp.delSpecialExits(matches[2])