--[[mudlet
type: alias
name: EAST
hierarchy:
- Levi_Ataxia
- RAGEPULL
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^be$
command: ''
packageName: ''
]]--

if ataxia.vitals.rage >= 14 then

send("cq all;east;overwhelm "..bashtarget..";leap west")

end