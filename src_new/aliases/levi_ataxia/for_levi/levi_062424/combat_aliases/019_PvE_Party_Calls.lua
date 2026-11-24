--[[mudlet
type: alias
name: PvE Party Calls
hierarchy:
- Levi_Ataxia
- Combat
- Combat Aliases
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^pvecalls(?: (on|off))?$
command: ''
packageName: ''
]]--

-- `pvecalls` toggles, `pvecalls on|off` sets (v4.7.516). Whether our TARGET and BATTLERAGE calls
-- (and the block call) go to party chat while we hunt denizens. Off by default; PvP is not affected.
-- Saved as ataxia.settings.pvePartyCalls (nil = off). The rule: ataxia_partyCallAllowed (ataxia/016).
ataxia.settings = ataxia.settings or {}
local want = matches[2]
if want == "on" then
	ataxia.settings.pvePartyCalls = true
elseif want == "off" then
	ataxia.settings.pvePartyCalls = false
else
	ataxia.settings.pvePartyCalls = not (ataxia.settings.pvePartyCalls == true)
end
if ataxia_saveSettings then ataxia_saveSettings() end
if ataxia.settings.pvePartyCalls then
	ataxiaEcho("PvE party calls ON: target, battlerage and block calls go to party while bashing.")
else
	ataxiaEcho("PvE party calls OFF: no target, battlerage or block calls to party while bashing. PvP is unchanged.")
end
