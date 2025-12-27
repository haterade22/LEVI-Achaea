--[[mudlet
type: alias
name: Room find
hierarchy:
- mudlet-mapper
- Mudlet Mapper
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^(?:rf|room find) (.+)$
command: ''
packageName: ''
]]--

mmp.roomFind(matches[2])