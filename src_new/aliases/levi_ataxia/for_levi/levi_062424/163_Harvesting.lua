--[[mudlet
type: alias
name: Harvesting
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Autobashing
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^abharm?$
command: ''
packageName: ''
]]--

if not matches[1]:find("m") then
	if ataxiaBasher.enabled then
		disable_harvester()
	else
		enable_harvester()
	end
else
	if ataxiaBasher.enabled then
		disable_harvester()
	else
		enable_harvesterm()
	end
end

