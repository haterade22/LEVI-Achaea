--[[mudlet
type: alias
name: SET HERB
hierarchy:
- Levi_Ataxia
- General
- Shopkeeping
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^her (\w+)$
command: ''
packageName: ''
]]--

herbivore = matches[2]
cecho("\n<cyan> YOUR HERB IS <green> "..herbivore:title().." <cyan> !!!")