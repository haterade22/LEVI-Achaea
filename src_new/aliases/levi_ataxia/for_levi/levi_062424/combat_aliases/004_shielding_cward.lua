--[[mudlet
type: alias
name: shielding/cward
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
regex: ^(cwd|ts)$
command: ''
packageName: ''
]]--

local atk = combatQueue()
local p1, p2, p3 = "", "", ""

if ataxia_isClass("magi") then
	atk = atk..(matches[2] == "ts" and "touch shield" or "curseward")
elseif ataxia_isClass("priest") then
	atk = atk..(matches[2] == "ts" and "angel aura" or "curseward")
else
	atk = atk..(matches[2] == "ts" and "touch shield" or "curseward")
end

send("queue addclear freestand " ..atk)