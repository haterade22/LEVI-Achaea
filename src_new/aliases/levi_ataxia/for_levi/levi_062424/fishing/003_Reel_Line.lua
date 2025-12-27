--[[mudlet
type: alias
name: Reel Line
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
regex: ^afish rl$
command: ''
packageName: ''
]]--

if not ataxia.fishing then
	ataxiaEcho("Fishing variables do not exist. Use afish init to fix this.")
else
	ataxiaEcho("Stopping fishing.")
	ataxia.fishing.enabled = false
	send("reel line")
end