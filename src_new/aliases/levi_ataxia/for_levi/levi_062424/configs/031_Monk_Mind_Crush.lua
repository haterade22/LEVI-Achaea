--[[mudlet
type: alias
name: Monk Mind Crush
hierarchy:
- Levi_Ataxia
- For Levi
- levi_062424
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
regex: ^bash mindcrush(?:\s+(\w+))?$
]]--

-- `bash mindcrush [status|auto|on|off]` -- the int monk's MIND CRUSH eq rider (basher/002,
-- ataxiaBasher_monkMindCrush, v4.7.457). Auto = intelligence above strength in the last STAT read.
local arg = (matches[2] or "status"):lower()

if arg == "auto" or arg == "on" or arg == "off" then
	ataxiaBasher.monkMindCrush = (arg ~= "auto") and arg or nil
	if ataxia_saveSettings then ataxia_saveSettings() end
end
local mode = ataxiaBasher.monkMindCrush or "auto"
local live = ataxiaBasher_monkIntSpec and ataxiaBasher_monkIntSpec()
ataxiaEcho("<gold>Monk MIND CRUSH rider<reset> -> <white>" .. tostring(mode) .. "<reset> ("
	.. (live and "<green>on" or "<red>off") .. "<reset> now)."
	.. ((mode == "auto") and " Auto reads intelligence and strength from STAT." or ""))
