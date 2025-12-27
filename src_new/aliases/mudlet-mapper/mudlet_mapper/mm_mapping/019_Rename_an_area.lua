--[[mudlet
type: alias
name: Rename an area
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- mm Mapping
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^area rename (.+)$
command: ''
packageName: ''
]]--

mmp.renameArea(matches[2])