--[[mudlet
type: alias
name: WEAR ARTIES
hierarchy:
- Levi_Ataxia
- General
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^weararties$
command: ''
packageName: ''
]]--

local pendant = ataxia.getArtefact("pendant") or "pendant"
local bracelet = ataxia.getArtefact("bracelet") or "bracelets"
local belt = ataxia.getArtefact("belt") or "belt"
send("wear "..belt..";wear "..pendant..";wear "..bracelet)