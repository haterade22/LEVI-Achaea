--[[mudlet
type: alias
name: FLYING
hierarchy:
- Levi_Ataxia
- General
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^flyy$
command: ''
packageName: ''
]]--

send("clearqueue all;spur "..ataxia.getMount().." skyward")