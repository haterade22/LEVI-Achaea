--[[mudlet
type: alias
name: Cast Line
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Fishing
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^afish cl (\w+)$
command: ''
packageName: ''
]]--

if not ataxia.fishing then
	ataxiaEcho("Fishing variables do not exist. Use afish init to fix this.")
else
	ataxia.fishing.enabled = true
	ataxia.fishing.count = 0
	ataxia.fishing.direction = matches[2]:lower()
	ataxiaEcho("Started fishing.")
	ataxia.fishing.enabled = true
	send("cast line "..ataxia.fishing.direction)
end