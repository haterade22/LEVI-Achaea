--[[mudlet
type: alias
name: Delete map feature from room
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- mm Mapping
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^(?:room delete feature|rdf) (?:v(\d+) )?(.+)$
command: ''
packageName: ''
]]--

mmp.roomDeleteMapFeature(matches[3], matches[2] == "" and mmp.currentroom or tonumber(matches[2]))