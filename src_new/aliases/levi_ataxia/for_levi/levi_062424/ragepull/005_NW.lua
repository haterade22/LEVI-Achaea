--[[mudlet
type: alias
name: NW
hierarchy:
- Levi_Ataxia
- RAGEPULL
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bnw$
command: ''
packageName: ''
]]--

if ataxia.vitals.rage >= 14 then

send("cq all;nw;overwhelm "..bashtarget..";leap se")

end