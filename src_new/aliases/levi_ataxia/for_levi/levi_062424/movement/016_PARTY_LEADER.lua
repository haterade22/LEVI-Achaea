--[[mudlet
type: alias
name: PARTY LEADER
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- General
- MOVEMENT
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^pl (\w+)$
command: ''
packageName: ''
]]--

partyleader = matches[2]:title()
cecho(""..partyleader.." IS YOUR FRIGGIN LEADER NOW")