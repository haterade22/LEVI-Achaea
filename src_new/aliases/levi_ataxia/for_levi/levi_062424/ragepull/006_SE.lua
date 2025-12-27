--[[mudlet
type: alias
name: SE
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- RAGEPULL
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bse$
command: ''
packageName: ''
]]--

if ataxia.vitals.rage >= 14 then

send("cq all;se;overwhelm "..bashtarget..";leap nw")

end