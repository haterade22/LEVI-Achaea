--[[mudlet
type: alias
name: Set debug mode
hierarchy:
- mudlet-mapper
- Mudlet Mapper
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^(?:mdg|mdebug) (on|off)$
command: ''
packageName: ''
]]--

if matches[2] == "on" then
  mmp.debug = true
else
  mmp.debug = false
end

mmp.echo("Debug & performance telemetry "..(mmp.debug and "enabled" or "disabled")..".")