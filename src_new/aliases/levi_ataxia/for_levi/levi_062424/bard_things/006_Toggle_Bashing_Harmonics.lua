--[[mudlet
type: alias
name: Toggle Bashing Harmonics
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
regex: ^bharms$
command: ''
packageName: ''
]]--

--Automatically turns on symphony if it's not already enabled.
if not ataxia_isClass("bard") then
	ataxiaEcho("Class is not currently bard.")
	return
end

if ataxia.bardStuff.bashHarms then
	ataxia.bardStuff.bashHarms = false
	ataxiaEcho("Bashing harmonics disabled.")
else
	ataxia.bardStuff.bashHarms = true
	ataxia.bardStuff.symphony = true
	ataxiaEcho("Bashing harmonics enabled.")
end

ataxia_saveSettings(false)