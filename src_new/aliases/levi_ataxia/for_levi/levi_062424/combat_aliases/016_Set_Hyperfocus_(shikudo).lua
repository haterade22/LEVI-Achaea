--[[mudlet
type: alias
name: Set Hyperfocus (shikudo)
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
regex: ^(hf|hyper|hyperf|hyperfocus) (head|torso|left arm|right arm|left leg|right leg|rl|ll|la|ra|h|t)$
command: ''
packageName: ''
]]--

enableTrigger("Hyperfocus Detection")

local short = {rl = "right leg", ll = "left leg", t = "torso", h = "head", ra = "right arm", la = "left arm"}
local limb = (short[matches[3]] or matches[3])

send("queue addclear free hyperfocus "..limb,false)