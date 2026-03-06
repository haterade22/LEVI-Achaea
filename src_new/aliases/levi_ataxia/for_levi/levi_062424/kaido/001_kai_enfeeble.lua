--[[mudlet
type: alias
name: kai enfeeble
hierarchy:
- Levi_Ataxia
- Classes
- Monk
- Kaido
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^ke$
command: ''
packageName: ''
]]--

if ataxia.vitals.class >= 61 then 
send("queue addclear free kai enfeeble " ..target)
end
