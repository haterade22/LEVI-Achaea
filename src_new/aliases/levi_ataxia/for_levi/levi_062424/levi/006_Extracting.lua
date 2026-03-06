--[[mudlet
type: alias
name: Extracting
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^abextm?$
command: ''
packageName: ''
]]--

if not matches[1]:find("m") then
	if ataxiaBasher.enabled then
		disable_extractor()
	else
		enable_extractor()
	end
else
	if ataxiaBasher.enabled then
		disable_extractor()
	else
		enable_extractorm()
	end
end

