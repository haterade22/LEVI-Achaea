--[[mudlet
type: alias
name: NE
hierarchy:
- Levi_Ataxia
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