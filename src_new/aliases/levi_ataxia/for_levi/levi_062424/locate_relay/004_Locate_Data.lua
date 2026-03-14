--[[mudlet
type: alias
name: Locate Data
hierarchy:
- Levi_Ataxia
- General
- Locate Relay
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^locate data (.+)$
command: ''
packageName: ''
]]--

LocateWorld.lookupLocation(matches[2])
