--[[mudlet
type: alias
name: Change Roomshorten Setting
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Autobashing
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^aconfig roomshorten (off|normal|notmanual)$
command: ''
packageName: ''
]]--

--Off disables the room shorten all together.
--Normal sets it back to how it is by default.
--Notmanual will only shorten when manual mode is off.
local opts = {
	off = "Disabled condensing of room info when bashing.",
	normal = "Set room condensing back to normal.",
	notmanual = "Room info will only be condensed when not in manual mode.",

}
ataxia.settings.roomshorten = matches[2]
ataxia_Echo(opts[matches[2]])