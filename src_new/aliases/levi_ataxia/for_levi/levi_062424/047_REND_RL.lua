--[[mudlet
type: alias
name: REND RL
hierarchy:
- Levi_Ataxia
- Classes
- Dragon
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^rrl$
command: ''
packageName: ''
]]--

if enmesh == 2 then

send("rend "..target.." right leg curare")

end
