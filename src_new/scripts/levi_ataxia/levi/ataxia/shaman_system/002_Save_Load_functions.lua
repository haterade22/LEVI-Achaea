--[[mudlet
type: script
name: Save/Load functions
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Shaman System
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function shaman.save()
	local temp_shaman = deepcopy(shaman)
	temp_shaman.spiritlore.attunements = {}
	temp_shaman.spiritlore.bindings = {}
	temp_shaman.spiritlore.tether = ""
	if string.char(getMudletHomeDir():byte()) == "/" then _sep = "/" else  _sep = "\\" end
	local saveFile = getMudletHomeDir() ..  _sep .. "shaman_profile.lua"

	table.save(saveFile, temp_shaman)

	-- Profile backup
	_ataxia_backup = _ataxia_backup or {}
	_ataxia_backup.shaman = deepcopy(temp_shaman)

	shecho("Settings saved.")
end

function shaman.load()
	if string.char(getMudletHomeDir():byte()) == "/" then _sep = "/" else  _sep = "\\" end
	local loadFile = getMudletHomeDir() ..  _sep .. "shaman_profile.lua"

	if io.exists(loadFile) then
		table.load(loadFile, shaman)
	elseif _ataxia_backup and _ataxia_backup.shaman then
		for k, v in pairs(_ataxia_backup.shaman) do shaman[k] = v end
		shecho("Settings restored from profile backup.")
	end
	shecho("Settings loaded.")
end