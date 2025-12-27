--[[mudlet
type: alias
name: NE
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- RAGEPULL
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bne$
command: ''
packageName: ''
]]--

if ataxia.vitals.rage >= 14 then

send("cq all;ne;overwhelm "..bashtarget..";leap sw")

end