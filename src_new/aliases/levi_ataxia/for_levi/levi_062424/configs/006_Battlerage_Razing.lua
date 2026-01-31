--[[mudlet
type: alias
name: Battlerage Razing
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
regex: ^bash rageraze (on|off)$
command: ''
packageName: ''
]]--

local class = gmcp.Char.Status.class:title()
get_Battlerage()
if not ataxiaBasher.battlerage[class].raze then
	ataxiaEcho("Battlerage razing not supported for this class, sorry.")
	return
end


if matches[2] == "on" then
	ataxiaBasher.rageraze = true
else
	ataxiaBasher.rageraze = false
end
ataxiaEcho("Battlerage razing has been "..(ataxiaBasher.rageraze == true and "<green>Enabled." or "<red>Disabled."))