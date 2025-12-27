--[[mudlet
type: alias
name: Delete an area
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- mm Mapping
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^area delete (.+)$
command: ''
packageName: ''
]]--

mmp.deleteArea(matches[2])