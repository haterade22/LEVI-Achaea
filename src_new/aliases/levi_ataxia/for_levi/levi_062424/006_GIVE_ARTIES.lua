--[[mudlet
type: alias
name: GIVE ARTIES
hierarchy:
- Levi_Ataxia
- General
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^givearties$
command: ''
packageName: ''
]]--

local pendant = ataxia.getArtefact("pendant") or "pendant"
local bracelet = ataxia.getArtefact("bracelet") or "bracelets"
local belt = ataxia.getArtefact("belt") or "belt"
send("remove "..pendant..";remove "..bracelet..";remove "..belt..";remove ring;give ring to "..puptarget..";give "..pendant.." to "..puptarget..";give "..bracelet.." to "..puptarget..";give "..belt.." to "..puptarget)