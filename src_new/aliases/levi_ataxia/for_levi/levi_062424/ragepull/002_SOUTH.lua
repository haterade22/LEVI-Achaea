--[[mudlet
type: alias
name: SOUTH
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- RAGEPULL
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bs$
command: ''
packageName: ''
]]--

if ataxia.vitals.rage >= 14 then

send("cq all;south;overwhelm "..bashtarget..";leap north")

end