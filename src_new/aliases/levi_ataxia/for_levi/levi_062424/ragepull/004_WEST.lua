--[[mudlet
type: alias
name: WEST
hierarchy:
- Levi_Ataxia
- RAGEPULL
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bw$
command: ''
packageName: ''
]]--

if ataxia.vitals.rage >= 14 then

send("cq all;west;overwhelm "..bashtarget..";leap east")

end