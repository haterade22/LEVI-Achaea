--[[mudlet
type: alias
name: Show Colours
hierarchy:
- Levi_Ataxia
- Ataxia
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^colours (\d+)$
command: ''
packageName: ''
]]--

-- Mudlet's function is showColors (mudlet-lua/lua/GUIUtils.lua, 5.1.1); there is no showColours,
-- so this threw. A number argument is the column count.
showColors(tonumber(matches[2]))


--lua showColors()