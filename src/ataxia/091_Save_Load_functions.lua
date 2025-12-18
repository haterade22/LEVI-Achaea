-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > Shaman System > Save/Load functions

function shaman.save()
	local temp_shaman = deepcopy(shaman)
	temp_shaman.spiritlore.attunements = {}
	temp_shaman.spiritlore.bindings = {}
	temp_shaman.spiritlore.tether = ""
	if string.char(getMudletHomeDir():byte()) == "/" then _sep = "/" else  _sep = "\\" end
	local saveFile = getMudletHomeDir() ..  _sep .. "shaman_profile.lua"

	table.save(saveFile, temp_shaman)
	shecho("Settings saved.")
end

function shaman.load()
	if string.char(getMudletHomeDir():byte()) == "/" then _sep = "/" else  _sep = "\\" end
	local loadFile = getMudletHomeDir() ..  _sep .. "shaman_profile.lua"

    if io.exists(loadFile) then table.load(loadFile, shaman) end
	shecho("Settings loaded.")
end