--[[mudlet
type: alias
name: Tree-Blackout
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
regex: ^aconfig treeblackout$
command: ''
packageName: ''
]]--

if not ataxiaBasher.treeblackout then
	ataxiaBasher.treeblackout = true
	ataxiaEcho("Will try to use tree tattoo when we get hit with blackout while bashing.")
else
	ataxiaBasher.treeblackout = false
	ataxiaEcho("Won't try to use tree tattoo when we get hit with blackout while bashing.")
end