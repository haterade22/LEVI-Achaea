--[[mudlet
type: alias
name: Show Colours
hierarchy:
- Levi_Ataxia
- Ataxia
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^colours (\d+)$
command: ''
packageName: ''
]]--

showColours(tonumber(matches[2]))


--lua showColours()