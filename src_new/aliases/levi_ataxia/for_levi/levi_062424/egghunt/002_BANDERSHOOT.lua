--[[mudlet
type: alias
name: BANDERSHOOT
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- EGGHUNT
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^b (\w+)$
command: ''
packageName: ''
]]--

send("queue addclear free bandershoot "..matches[2])