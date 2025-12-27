--[[mudlet
type: script
name: mmp.saveOptions
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- mm Mapping
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
eventHandlers:
- sysExitEvent
]]--

function mmp.saveOptions()
	local saveTable = {
		locked_areas = mmp.locked,
		options = mmp.settings:getAllOptions()
	}
  local _sep
	if string.char(getMudletHomeDir():byte()) == "/" then _sep = "/" else  _sep = "\\" end
	local saveFile = getMudletHomeDir() ..  _sep .. "mapper.options.lua"

	table.save(saveFile, saveTable)
end