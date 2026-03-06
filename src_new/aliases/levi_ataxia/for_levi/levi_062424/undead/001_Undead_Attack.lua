--[[mudlet
type: alias
name: Undead Attack
hierarchy:
- Levi_Ataxia
- Classes
- Undead
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^kp$
command: ''
packageName: ''
]]--

if tAffs.shield then
send("soulbleed batter " ..target)
else
send("soulbleed squeeze " ..target)
end