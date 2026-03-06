--[[mudlet
type: alias
name: UP
hierarchy:
- Levi_Ataxia
- RAGEPULL
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bu$
command: ''
packageName: ''
]]--

if ataxia.vitals.rage >= 14 then

send("cq all;up;overwhelm "..bashtarget..";leap down")

end