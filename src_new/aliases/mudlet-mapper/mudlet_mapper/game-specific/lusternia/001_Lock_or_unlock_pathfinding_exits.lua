--[[mudlet
type: alias
name: Lock or unlock pathfinding exits
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- Game-specific
- Lusternia
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: (?i)^(lock|unlock) paths$
command: ''
packageName: ''
]]--

mmp.lockpaths(matches[2]:lower()=="lock")