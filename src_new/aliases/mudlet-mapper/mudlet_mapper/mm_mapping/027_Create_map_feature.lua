--[[mudlet
type: alias
name: Create map feature
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- mm Mapping
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '^feature create (.+?)(?: char (.+))?$'
command: ''
packageName: ''
]]--

mmp.createMapFeature(matches[2]:trim(), (matches[3] and matches[3]:trim()))