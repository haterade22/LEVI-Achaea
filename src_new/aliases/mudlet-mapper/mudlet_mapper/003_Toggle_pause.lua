--[[mudlet
type: alias
name: Toggle pause
hierarchy:
- mudlet-mapper
- Mudlet Mapper
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^mpp(?:\s?(on|off))?$
command: ''
packageName: ''
]]--

mmp.pause(matches[2])