--[[mudlet
type: alias
name: Undead Attack
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
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