--[[mudlet
type: alias
name: Kaido Surge
hierarchy:
- Levi_Ataxia
- Classes
- Monk
- Kaido
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^ks$
command: ''
packageName: ''
]]--

if ataxia.vitals.class >= 31 then 
send("queue addclear free kai surge " ..target)
end
