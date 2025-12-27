--[[mudlet
type: alias
name: PRICE
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
regex: ^pri (\d+)$
command: ''
packageName: ''
]]--

send("price "..herbivore.." at "..matches[2])