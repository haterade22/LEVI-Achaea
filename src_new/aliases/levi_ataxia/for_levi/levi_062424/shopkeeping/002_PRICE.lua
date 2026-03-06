--[[mudlet
type: alias
name: PRICE
hierarchy:
- Levi_Ataxia
- General
- Shopkeeping
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^pri (\d+)$
command: ''
packageName: ''
]]--

send("price "..herbivore.." at "..matches[2])