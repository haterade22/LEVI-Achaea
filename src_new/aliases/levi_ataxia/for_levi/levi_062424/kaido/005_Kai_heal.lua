--[[mudlet
type: alias
name: Kai heal
hierarchy:
- Levi_Ataxia
- Classes
- Monk
- Kaido
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^kh$
command: ''
packageName: ''
]]--

if ataxia.vitals.class >= 21 then 
send("queue addclear free kai heal")
end
