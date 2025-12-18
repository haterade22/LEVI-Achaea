-- unnamed > For Levi > Levi_062424 > mudlet-mapper_24 > Mudlet Mapper > mm Mapping > mmp.saveOptions

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