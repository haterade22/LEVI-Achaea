--[[mudlet
type: alias
name: Set Culling Blade Keyword
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Lists
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^cbkey (\w+)$
command: ''
packageName: ''
]]--

local key = matches[2]:lower()
ataxiaBasher.targetList[gmcp.Room.Info.area].keyword = key
ataxia_Echo("Set the keyword for denizens in "..gmcp.Room.Info.area.." to "..key..".")
ataxia_saveSettings(false)