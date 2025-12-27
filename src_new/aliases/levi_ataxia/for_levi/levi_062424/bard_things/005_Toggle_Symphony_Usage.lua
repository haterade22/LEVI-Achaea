--[[mudlet
type: alias
name: Toggle Symphony Usage
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
regex: ^symph$
command: ''
packageName: ''
]]--

if not ataxia_isClass("bard") then
	ataxiaEcho("Class is not currently bard.")
	return
end

if ataxia.bardStuff.symphony then
	ataxiaEcho("Symphony usage disabled.")
	ataxia.bardStuff.symphony = false
else
	ataxiaEcho("Symphony usage enabled.")
	ataxia.bardStuff.symphony = true
end

ataxia_saveSettings(false)