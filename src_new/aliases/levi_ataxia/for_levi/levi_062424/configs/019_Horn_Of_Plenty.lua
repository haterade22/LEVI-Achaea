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
-- `horn auto`     -- show the current setting.
local arg = matches[2]
if arg == "on" or arg == "off" then
	ataxia.settings.hornAuto = (arg == "on")
	ataxia_saveSettings(false)
	ataxiaEcho("Auto-feed from the horn of plenty is now "
		.. (ataxia.settings.hornAuto and "<green>on" or "<red>off") .. "<reset>.")
elseif arg == "auto" then
	ataxiaEcho("Auto-feed from the horn of plenty: "
		.. ((ataxia.settings.hornAuto ~= false) and "<green>on" or "<red>off") .. "<reset>.")
else
	ataxia_hornFeed("manual", true)
end
