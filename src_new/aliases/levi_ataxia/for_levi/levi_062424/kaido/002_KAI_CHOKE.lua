--[[mudlet
type: alias
name: KAI CHOKE
hierarchy:
- Levi_Ataxia
- Classes
- Monk
- Kaido
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^kc$
command: ''
packageName: ''
]]--

if ataxia.vitals.class >= 10 then 
send("queue addclear free kai choke " ..target)
else
send("queue addclear free mind crush " ..target)

end
