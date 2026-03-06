--[[mudlet
type: alias
name: Set Bait
hierarchy:
- Levi_Ataxia
- Ataxia
- Fishing
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^afish bait (\w+)$
command: ''
packageName: ''
]]--

ataxia.fishing.bait = matches[2]:lower()
ataxiaEcho("Bait has been changed to: <green>"..matches[2]:lower()..".")