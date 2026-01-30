--[[mudlet
type: alias
name: QUASH ARC
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- Monks
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^qa$
command: ''
packageName: ''
]]--

send("queue addclear free wield shield longsword;quash "..target..";arc "..target.." prefarar")