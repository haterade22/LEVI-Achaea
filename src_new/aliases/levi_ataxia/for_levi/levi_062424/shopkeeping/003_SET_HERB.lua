--[[mudlet
type: alias
name: SET HERB
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- General
- SHOPKEEPING
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^her (\w+)$
command: ''
packageName: ''
]]--

herbivore = matches[2]
cecho("\n<cyan> YOUR HERB IS <green> "..herbivore:title().." <cyan> !!!")