--[[mudlet
type: alias
name: Seebalances
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^aconfig seebalances(?: (on|off))?$
command: ''
packageName: ''
]]--

-- `aconfig seebalances`      -- show the setting.
-- `aconfig seebalances on`   -- save it and send CONFIG SEEBALANCES YES now; it is sent at every
--                               login (login/001). The game then prints `Balance used: 2.8s.` and
--                               `Equilibrium used: 3.40s.`, so every fight log holds the true
--                               costs (kb/raw/live/seebalances_2026-11-01.txt).
-- `aconfig seebalances off`  -- stop sending it (the default); the game keeps whatever it has.
local arg = matches[2]
if arg then
	ataxia.settings.seebalances = (arg == "on")
	ataxia_saveSettings(false)
	if ataxia.settings.seebalances then
		send("config seebalances yes", false)
	end
end
local v = ataxia.settings.seebalances
ataxiaEcho("See balances: " .. (v and "<green>on<NavajoWhite> (sent at login)" or "<red>off<NavajoWhite> (not sent)"))
if not v then
	ataxiaEcho("The game keeps its own setting. <white>config seebalances no<NavajoWhite> turns it off there.")
end
