--[[mudlet
type: alias
name: ICEWALL
hierarchy:
- Levi_Ataxia
- General
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^ice (\w+)$
command: ''
packageName: ''
]]--

local ring = ataxia.getArtefact("ring") or "ring"
send("clearqueue all;point "..ring.." "..matches[2])