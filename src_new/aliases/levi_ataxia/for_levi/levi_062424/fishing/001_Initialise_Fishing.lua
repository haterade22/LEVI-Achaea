--[[mudlet
type: alias
name: Initialise Fishing
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
regex: ^afish init$
command: ''
packageName: ''
]]--

ataxia.fishing = {
	bait = "shrimp",
	type = "normal",
	direction = "n",
	enabled = false,
	count = 0,
}
ataxiaEcho("Fishing variables obtained.")