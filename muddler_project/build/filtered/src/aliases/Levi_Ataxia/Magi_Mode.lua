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
else
  ataxiaEcho("Magi modes: fire | water | lock | salve | group")
  ataxiaEcho("Commands: mm debug | mm vibes | mm reset | mm (status)")
end
