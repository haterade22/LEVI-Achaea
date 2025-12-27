--[[mudlet
type: alias
name: Delete map feature
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- mm Mapping
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^feature delete (.+)$
command: ''
packageName: ''
]]--

mmp.deleteMapFeature(matches[2]:trim())