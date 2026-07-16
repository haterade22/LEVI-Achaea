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

-- Report the key we actually wrote to, not gmcp's area: in Mnemosyne the key is "" (and
-- under the incurable-dementia boon gmcp names a hallucinated real area), so echoing the
-- raw area would claim we configured somewhere we didn't touch.
local key = matches[2]:lower()
local areaKey = ataxiaBasher_areaKey()
ataxiaBasher.targetList[areaKey].keyword = key
ataxia_Echo("Set the keyword for denizens in "..(areaKey ~= "" and areaKey or "the Mnemosyne").." to "..key..".")
ataxia_saveSettings(false)