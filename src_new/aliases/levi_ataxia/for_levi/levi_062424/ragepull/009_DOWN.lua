--[[mudlet
type: alias
name: DOWN
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- RAGEPULL
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bd$
command: ''
packageName: ''
]]--

if ataxia.vitals.rage >= 14 then

send("cq all;down;overwhelm "..bashtarget..";leap up")

end