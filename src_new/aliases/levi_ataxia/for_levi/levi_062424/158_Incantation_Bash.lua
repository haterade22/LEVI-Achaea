--[[mudlet
type: alias
name: Incantation Bash
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
regex: ^bash incant$
command: ''
packageName: ''
]]--

if not ataxiaBasher.dragonIncant then
	ataxiaBasher.dragonIncant = true
	ataxiaEcho("Will bash using incantation in dragon instead of gut.")
else
	ataxiaBasher.dragonIncant = false
	ataxiaEcho("Will bash using gut in dragon instead of incantation.")
end