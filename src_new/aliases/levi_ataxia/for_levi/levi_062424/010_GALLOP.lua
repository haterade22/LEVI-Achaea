--[[mudlet
type: alias
name: GALLOP
hierarchy:
- Levi_Ataxia
- General
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^ga (\w+)$
command: ''
packageName: ''
]]--

send("clearqueue all;remove shackle;gallop " ..matches[2].. ";wear shackle")