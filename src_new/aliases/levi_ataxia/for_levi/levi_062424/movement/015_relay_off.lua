--[[mudlet
type: alias
name: relay off
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
regex: ^relay$
command: ''
packageName: ''
]]--

partyrelay = partyrelay or false
if partyrelay == false then partyrelay = true
cecho("RELAYING ON PARTY NOW")
elseif partyrelay == true then partyrelay = false
cecho("NO LONGER RELAYING ON PARTY")
end