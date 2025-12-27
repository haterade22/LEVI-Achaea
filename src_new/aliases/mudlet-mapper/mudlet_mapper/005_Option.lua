--[[mudlet
type: alias
name: Option
hierarchy:
- mudlet-mapper
- Mudlet Mapper
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^mconfig( (\w+) (.*))?$
command: ''
packageName: ''
]]--

if not matches[2] then
	mmp.settings:showAllOptions(mmp.game)
	return
end

local val = matches[4]
if val == "true" or val == "yes" or val == "on" then val = true end
if val == "false" or val == "no" or val == "off" then val = false end
local numberVal = tonumber(val)
val = numberVal and numberVal or val
mmp.settings:setOption(matches[3], val)