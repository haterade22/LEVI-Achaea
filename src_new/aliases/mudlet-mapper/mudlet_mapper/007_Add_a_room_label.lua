--[[mudlet
type: alias
name: Add a room label
hierarchy:
- mudlet-mapper
- Mudlet Mapper
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^room label (.+)$
command: ''
packageName: ''
]]--

mmp.roomLabel(matches[2])