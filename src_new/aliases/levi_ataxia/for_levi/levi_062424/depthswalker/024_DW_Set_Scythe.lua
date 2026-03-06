--[[mudlet
type: alias
name: DW Set Scythe
hierarchy:
- Levi_Ataxia
- Classes
- Depthswalker
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^dwscythe (.+)$
command: ''
packageName: ''
]]--

depthswalker.config.scytheId = matches[2]
if ataxiaEcho then
    ataxiaEcho("[DW] Scythe ID set to: " .. matches[2])
end
