--[[mudlet
type: alias
name: DW Set Mode
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- DEPTHSWALKER
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^dwm (\w+)$
command: ''
packageName: ''
]]--

depthswalker.setMode(matches[2])
