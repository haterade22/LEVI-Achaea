-- unnamed > For Levi > mudlet-mapper > Mudlet Mapper > mm Mapping > mmp_load_options

function mmp_load_options()
	local loadTable = mmp_load_locks()

	if loadTable.options then
		for k, v in pairs(loadTable.options) do
			mmp.settings:setOption(k, v, true)
		end
	end
end

function mmp_load_locks()
	local loadTable = {}

	if string.char(getMudletHomeDir():byte()) == "/" then _sep = "/" else  _sep = "\\" end
	local loadFile = getMudletHomeDir() ..  _sep .. "mapper.options.lua"

    if io.exists(loadFile) then table.load(loadFile, loadTable) end

	if loadTable.locked_areas then
		mmp.locked = loadTable.locked_areas
	end

    local lockRoom, getAreaRooms = lockRoom, getAreaRooms
	for area in pairs(mmp.locked) do
		local rooms = getAreaRooms(area)
		for _, roomid in pairs(rooms or {}) do
			lockRoom(roomid, true)
		end
	end

	return loadTable
end