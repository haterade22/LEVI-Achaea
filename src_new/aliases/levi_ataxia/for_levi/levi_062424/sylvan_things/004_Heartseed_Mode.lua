--[[mudlet
type: alias
name: Heartseed Mode
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Installation / Configuration
- Sylvan Things
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^hseed$
command: ''
packageName: ''
]]--

if not ataxiaTemp.heartseedMode then
	ataxiaTemp.heartseedMode = true
	ataxiaEcho("Heartseed mode enabled.")
else
	ataxiaTemp.heartseedMode = nil
	ataxiaEcho("Heartseed mode disabled.") 
	
	ataxia_restorePrio("damagedleftleg")
	ataxia_restorePrio("damagedrightleg")
	ataxia_restorePrio("mangledleftleg")
	ataxia_restorePrio("mangledrightleg")
	ataxia_restorePrio("damagedleftarm")
	ataxia_restorePrio("damagedrightarm")
	ataxia_restorePrio("mangledleftarm")
	ataxia_restorePrio("mangledrightarm")
end