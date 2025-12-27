--[[mudlet
type: alias
name: Vaulting
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Installation / Configuration
- Toggles/Settings/Etc.
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^(vault|mount) (\d+)$
command: ''
packageName: ''
]]--

ataxia.mountid = tonumber(matches[3])
local opt = matches[2]
sendAll(
	("curing usevault "..(opt == "mount" and "no" or "yes")),
	("curing mount "..(ataxia.mountid == 0 and "clear" or ataxia.mountid)),
false)

ataxia_saveSettings(false)