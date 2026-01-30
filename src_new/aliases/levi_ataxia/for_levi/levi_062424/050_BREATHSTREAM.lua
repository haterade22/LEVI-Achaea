--[[mudlet
type: alias
name: BREATHSTREAM
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- DRAGON
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^br (\w+)$
command: ''
packageName: ''
]]--

breathstreamdirection = matches[2]
send("queue addclear free stand;wield shield;breathstream "..target.." "..matches[2].. ";summon ice")
