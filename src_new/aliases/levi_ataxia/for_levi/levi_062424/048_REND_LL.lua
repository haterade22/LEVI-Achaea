--[[mudlet
type: alias
name: REND LL
hierarchy:
- Levi_Ataxia
- Classes
- Dragon
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^rll$
command: ''
packageName: ''
]]--

if enmesh == 2 then

send("rend "..target.." left leg curare")

end
