--[[mudlet
type: alias
name: Move room to another area
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- mm Mapping
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^room area (?:v(\d+) )?(.+)$
command: ''
packageName: ''
]]--

mmp.roomArea(matches[2], matches[3])