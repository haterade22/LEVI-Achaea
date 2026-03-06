--[[mudlet
type: alias
name: OUT
hierarchy:
- Levi_Ataxia
- RAGEPULL
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bo$
command: ''
packageName: ''
]]--

if ataxia.vitals.rage >= 14 then

send("cq all;out;overwhelm "..bashtarget..";leap in")

end