--[[mudlet
type: alias
name: Horn Of Plenty
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^horn(?: (auto|on|off|floor(?: \S+)?|hp(?: \S+)?))?$
command: ''
packageName: ''
]]--

-- `horn`          -- probe the horn of plenty, take the first item, eat it (now).
-- `horn on|off`   -- toggle the automatic feed on starvation lines (default on).
-- `horn auto`     -- show the current settings.
-- `horn floor <n>` -- Healing Metabolism: % of max mana that must remain after SATIATION's 100
--                     mana (default 30, v4.7.452).
-- `horn hp <n>`    -- Healing Metabolism: cast SATIATION only below this % of max health
--                     (default 75, v4.7.454).
local arg = matches[2]
local floorArg = arg and arg:match("^floor%s*(%S*)$")
local hpArg = arg and arg:match("^hp%s*(%S*)$")
if hpArg then
	local n = tonumber(hpArg)
	if not n then
		ataxiaEcho("Usage: horn hp <percent>  (currently "
			.. tostring(ataxia.settings.satiationHpAt or 75) .. "%).")
		return
	end
	ataxia.settings.satiationHpAt = math.max(1, math.min(100, math.floor(n)))
	ataxia_saveSettings(false)
	ataxiaEcho("Healing Metabolism: SATIATION is cast below <green>" .. ataxia.settings.satiationHpAt
		.. "%<reset> health.")
elseif floorArg then
	local n = tonumber(floorArg)
	if not n then
		ataxiaEcho("Usage: horn floor <percent>  (currently "
			.. tostring(ataxia.settings.satiationManaFloor or 30) .. "%).")
		return
	end
	ataxia.settings.satiationManaFloor = math.max(0, math.min(95, math.floor(n)))
	ataxia_saveSettings(false)
	ataxiaEcho("Healing Metabolism: SATIATION keeps <green>" .. ataxia.settings.satiationManaFloor
		.. "%<reset> of max mana in reserve.")
elseif arg == "on" or arg == "off" then
	ataxia.settings.hornAuto = (arg == "on")
	ataxia_saveSettings(false)
	ataxiaEcho("Auto-feed from the horn of plenty is now "
		.. (ataxia.settings.hornAuto and "<green>on" or "<red>off") .. "<reset>.")
elseif arg == "auto" then
	ataxiaEcho("Auto-feed from the horn of plenty: "
		.. ((ataxia.settings.hornAuto ~= false) and "<green>on" or "<red>off") .. "<reset>."
		.. "  Healing Metabolism SATIATION: below " .. tostring(ataxia.settings.satiationHpAt or 75)
		.. "% health, mana floor " .. tostring(ataxia.settings.satiationManaFloor or 30) .. "%.")
else
	ataxia_hornFeed("manual", true)
end
