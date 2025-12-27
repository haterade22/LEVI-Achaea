--[[mudlet
type: alias
name: Manually Parry
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Combat Aliases
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^t?p(h|tt|rl|ll|la|ra|c|l|r)$
command: ''
packageName: ''
]]--

local limbs = {h = "head", tt = "torso" , rl = "right leg", ll = "left leg", ra = "right arm", la = "left arm",
	c = "center", l = "left", r = "r"
}
if ataxia.parry ~= "manual" then
	ataxia.parry = "manual"
	ataxiaEcho("Parrying method changed to manual.")
end
send((matches[1]:find("tp") and "true" or "").."parry "..limbs[matches[2]],false)
	