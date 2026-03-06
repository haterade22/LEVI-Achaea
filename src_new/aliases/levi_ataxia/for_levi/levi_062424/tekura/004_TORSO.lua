--[[mudlet
type: alias
name: TORSO
hierarchy:
- Levi_Ataxia
- Classes
- Monk
- TEKURA
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^tor$
command: ''
packageName: ''
]]--

if ataxiaTemp.class == "Monk" then

monktorso()

else

torsopath()

end