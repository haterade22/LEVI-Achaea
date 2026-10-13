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
elseif arg == "waterroute" or arg == "route" then
  -- v4.7.421: Tabethys's water route, the mode ww runs; this sets it without attacking.
  magi.offense.setMode("waterroute")
elseif arg == "glaciate" or arg:match("^glaciate%s") then
  -- v4.7.421: the water route glaciates a frozen target at or under this health (or of unknown
  -- health), else lays hypothermia first. off = always hypothermia first. Not saved: a reload
  -- puts it back to 100, as it does the arachnideye and webbomb toggles.
  local val = arg:match("^glaciate%s+(.-)$")
  local pct = val and tonumber(val:match("^%d+$") or "")
  if val == "off" then
    magi.offense.config.glaciateKillAt = false
  elseif pct and pct <= 100 then
    magi.offense.config.glaciateKillAt = pct
  elseif val then
    ataxiaEcho("Usage: mm glaciate N (a health percentage, 0-100) | mm glaciate off")
    return
  end
  local killAt = magi.offense.config.glaciateKillAt
  ataxiaEcho("Water route glaciate first: " .. (killAt and ("at " .. killAt .. "% health or less, or unknown health")
    or "off (hypothermia first)"))
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
elseif arg == "storm" then
  if magi.storm then
    local modes = {"city", "all", "priority"}
    local current = magi.storm.mode or "city"
    local idx = table.index_of(modes, current) or 0
    local next = modes[(idx % #modes) + 1]
    magi.storm.setMode(next)
  else
    ataxiaEcho("Stormhammer system not loaded.")
  end
else
  ataxiaEcho("Magi modes: fire | water | lock | salve | group | waterroute (or route; ww runs it)")
  ataxiaEcho("Commands: mm debug | mm vibes | mm reset | mm arach | mm web | mm storm | mm glaciate N|off | mm (status)")
end
