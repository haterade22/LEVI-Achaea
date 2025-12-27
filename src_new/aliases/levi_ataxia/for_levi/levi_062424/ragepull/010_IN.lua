--[[mudlet
type: alias
name: IN
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- RAGEPULL
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bin$
command: ''
packageName: ''
]]--

if ataxia.vitals.rage >= 14 then

send("cq all;in;overwhelm "..bashtarget..";leap out")

end