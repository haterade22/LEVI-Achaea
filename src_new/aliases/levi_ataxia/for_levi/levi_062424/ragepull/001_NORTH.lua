--[[mudlet
type: alias
name: NORTH
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- RAGEPULL
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bn$
command: ''
packageName: ''
]]--

if ataxia.vitals.rage >= 14 then

send("cq all;north;overwhelm "..bashtarget..";leap south")

end