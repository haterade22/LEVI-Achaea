--[[mudlet
type: alias
name: DW Debug Toggle
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- DEPTHSWALKER
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^dwd$
command: ''
packageName: ''
]]--

depthswalker.config.debugEcho = not depthswalker.config.debugEcho
if ataxiaEcho then
    ataxiaEcho("[DW] Debug echo: " .. (depthswalker.config.debugEcho and "ON" or "OFF"))
end
