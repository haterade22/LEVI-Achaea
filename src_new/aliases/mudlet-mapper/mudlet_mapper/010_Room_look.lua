--[[mudlet
type: alias
name: Room look
hierarchy:
- mudlet-mapper
- Mudlet Mapper
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '^(?:rl|room look)(?: (.+))?$'
command: ''
packageName: ''
]]--

mmp.roomLook(matches[2])