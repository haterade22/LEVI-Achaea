--[[mudlet
type: alias
name: Display area for lock/unlock
hierarchy:
- mudlet-mapper
- Mudlet Mapper
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '^arealock(?: (.*))?$'
command: ''
packageName: ''
]]--

mmp.doLockArea(matches[2])