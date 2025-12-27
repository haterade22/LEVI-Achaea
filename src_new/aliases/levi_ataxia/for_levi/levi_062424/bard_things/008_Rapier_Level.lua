--[[mudlet
type: alias
name: Rapier Level
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Installation / Configuration
- Bard Things
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^rapier (\d+)$
command: ''
packageName: ''
]]--

--Automatically turns on symphony if it's not already enabled.
if not ataxia_isClass("bard") then
	ataxiaEcho("Class is not currently bard.")
	return
end

ataxia.bardStuff.rapierLevel = "L"..tonumber(matches[2])
ataxiaEcho("Rapier level set to: L"..matches[2])

ataxia_saveSettings(false)