--[[mudlet
type: alias
name: (LEVIBARS) Vital Bars
hierarchy:
- Levi_Ataxia
- Systems
- zGUI Redux
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^levibars(?: (.+))?$
command: ''
packageName: ''
]]--

ataxia.bars.dispatch(matches[2])
