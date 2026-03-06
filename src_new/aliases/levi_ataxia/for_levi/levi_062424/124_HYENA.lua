--[[mudlet
type: alias
name: HYENA
hierarchy:
- Levi_Ataxia
- Classes
- Knight
- RUNIE
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^hy$
command: ''
packageName: ''
]]--

send("cq all;hyena recall;hyena track "..target..";order hyena attack "..target)