--[[mudlet
type: alias
name: Two Hand Weapon
hierarchy:
- Levi_Ataxia
- For Levi
- levi_062424
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
regex: ^bash twohand(?:\s+(\w+))?$
]]--

-- `bash twohand [status|auto|hammer|bastard|reset]` -- the Two Handed weapon for normal rounds
-- (basher/015, v4.7.455). Arc and bisect always use the bastard sword; normal rounds use the
-- weapon with the higher measured DPS, or the one pinned here.
local arg = (matches[2] or "status"):lower()

if arg == "auto" or arg == "hammer" or arg == "warhammer" or arg == "bastard" or arg == "sword" then
	local mode = (arg == "hammer" or arg == "warhammer") and "warhammer"
		or ((arg == "bastard" or arg == "sword") and "bastard") or "auto"
	ataxiaBasher.twoHandMode = mode
	ataxiaEcho("<gold>Two Handed normal rounds<reset> -> <white>" .. mode .. "<reset>"
		.. ((mode == "auto") and " (the weapon with the higher measured DPS)" or " (pinned)") .. ".")
	if ataxia_saveSettings then ataxia_saveSettings() end
elseif arg == "reset" then
	if ataxiaBasher_twoHandReset then ataxiaBasher_twoHandReset() end
	ataxiaEcho("<gold>Two Handed DPS ledger<reset> cleared. Both weapons sample again.")
	if ataxia_saveSettings then ataxia_saveSettings() end
elseif ataxiaBasher_twoHandReport then
	ataxiaEcho("<gold>Two Handed weapon DPS<reset> (normal rounds only):")
	for _, line in ipairs(ataxiaBasher_twoHandReport()) do
		cecho("\n  <white>" .. line)
	end
	cecho("\n  <DimGrey>bash twohand auto|hammer|bastard|reset\n")
end
