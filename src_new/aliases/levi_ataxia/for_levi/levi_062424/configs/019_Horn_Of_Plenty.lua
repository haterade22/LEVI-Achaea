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
regex: ^horn(?: (auto|on|off))?$
command: ''
packageName: ''
]]--

-- `horn`          -- probe the horn of plenty, take the first item, eat it (now).
-- `horn on|off`   -- toggle the automatic feed on starvation lines (default on).
-- `horn auto`     -- show the current settings.
-- `horn poll <n|off>` -- Healing Metabolism upkeep: seconds a SCORE hunger reading may be stale
--                        before a kill asks for a fresh one (default 300; off = never ask).
local arg = matches[2]
local pollArg = arg and arg:match("^poll%s*(%S*)$")
if pollArg then
	if pollArg == "off" or pollArg == "0" then
		ataxia.settings.satiatePoll = 0
	elseif tonumber(pollArg) then
		ataxia.settings.satiatePoll = math.max(30, math.floor(tonumber(pollArg)))
	else
		ataxiaEcho("Usage: horn poll <seconds|off>  (currently "
			.. tostring(ataxia.settings.satiatePoll or 300) .. ").")
		return
	end
	ataxia_saveSettings(false)
	ataxiaEcho("Healing Metabolism SCORE check on a kill: "
		.. ((ataxia.settings.satiatePoll or 0) > 0
			and ("every <green>" .. ataxia.settings.satiatePoll .. "s<reset> of stale reading")
			or "<red>off<reset>") .. ".")
elseif arg == "on" or arg == "off" then
	ataxia.settings.hornAuto = (arg == "on")
	ataxia_saveSettings(false)
	ataxiaEcho("Auto-feed from the horn of plenty is now "
		.. (ataxia.settings.hornAuto and "<green>on" or "<red>off") .. "<reset>.")
elseif arg == "auto" then
	ataxiaEcho("Auto-feed from the horn of plenty: "
		.. ((ataxia.settings.hornAuto ~= false) and "<green>on" or "<red>off") .. "<reset>."
		.. "  Healing Metabolism SCORE check: "
		.. (((ataxia.settings.satiatePoll or 300) > 0)
			and ("every " .. (ataxia.settings.satiatePoll or 300) .. "s of stale reading")
			or "off") .. ".")
else
	ataxia_hornFeed("manual", true)
end
