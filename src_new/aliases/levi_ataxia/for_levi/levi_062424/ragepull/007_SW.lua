--[[mudlet
type: alias
name: SW
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- RAGEPULL
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bsw$
command: ''
packageName: ''
]]--

if ataxia.vitals.rage >= 14 then

send("cq all;sw;overwhelm "..bashtarget..";leap ne")

end