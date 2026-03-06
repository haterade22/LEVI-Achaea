--[[mudlet
type: alias
name: BANDERSHOOT
hierarchy:
- Levi_Ataxia
- General
- Egghunt
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^b (\w+)$
command: ''
packageName: ''
]]--

send("queue addclear free bandershoot "..matches[2])