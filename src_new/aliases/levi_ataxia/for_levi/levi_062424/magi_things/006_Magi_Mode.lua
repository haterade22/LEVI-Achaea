--[[mudlet
type: alias
name: Magi Mode
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Magi Things
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^mm\s*(.*)$
command: ''
packageName: ''
]]--

local arg = matches[2]:lower():trim()

if arg == "" then
  magi.offense.status()
elseif arg == "fire" or arg == "water" or arg == "lock" or arg == "salve" or arg == "group" then
  magi.offense.setMode(arg)
elseif arg == "debug" then
  magi.offense.state = magi.offense.state or {}
  magi.offense.state.debug = not magi.offense.state.debug
  ataxiaEcho("Magi debug: " .. (magi.offense.state.debug and "ON" or "OFF"))
elseif arg == "vibes" then
  magi.offense.setupVibes()
elseif arg == "reset" then
  magi.offense.reset()
  ataxiaEcho("Magi offense state reset")
elseif arg == "arachnideye" or arg == "arach" then
  magi.offense.config.useArachnideye = not magi.offense.config.useArachnideye
  ataxiaEcho("Arachnideye: " .. (magi.offense.config.useArachnideye and "ON" or "OFF"))
elseif arg == "webbomb" or arg == "web" then
  magi.offense.config.useWebbomb = not magi.offense.config.useWebbomb
  ataxiaEcho("Webbomb: " .. (magi.offense.config.useWebbomb and "ON" or "OFF"))
else
  ataxiaEcho("Magi modes: fire | water | lock | salve | group")
  ataxiaEcho("Commands: mm debug | mm vibes | mm reset | mm arach | mm web | mm (status)")
end
