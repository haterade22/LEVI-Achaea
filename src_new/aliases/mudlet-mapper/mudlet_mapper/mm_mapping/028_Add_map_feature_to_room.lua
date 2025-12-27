--[[mudlet
type: alias
name: Add map feature to room
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- mm Mapping
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^(?:room create feature|rcf) (?:v(\d+) )?(.+)$
command: ''
packageName: ''
]]--

mmp.roomCreateMapFeature(matches[3], matches[2] == "" and mmp.currentroom or tonumber(matches[2]))