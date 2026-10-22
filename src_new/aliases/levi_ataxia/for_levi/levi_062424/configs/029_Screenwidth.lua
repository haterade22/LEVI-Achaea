--[[mudlet
type: alias
name: Screenwidth
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^aconfig screenwidth(?: (\d+|off))?$
command: ''
packageName: ''
]]--

-- `aconfig screenwidth`          -- show the setting.
-- `aconfig screenwidth <width>`  -- save it and send CONFIG SCREENWIDTH now; it is sent at every
--                                   login (login/001). 0 = the game never splits a line, which
--                                   long trigger patterns need (v4.7.441).
-- `aconfig screenwidth off`      -- stop sending it; the game keeps whatever it has.
local arg = matches[2]
if arg then
	-- `false`, not nil: a nil is "missing" and the load-time check would put 0 back.
	if arg == "off" then
		ataxia.settings.screenwidth = false
	else
		ataxia.settings.screenwidth = tonumber(arg)
	end
	ataxia_saveSettings(false)
	if tonumber(ataxia.settings.screenwidth) then
		send("config screenwidth " .. ataxia.settings.screenwidth, false)
	end
end
local v = ataxia.settings.screenwidth
ataxiaEcho("Screen width: " .. (tonumber(v) and ("<green>" .. v .. "<NavajoWhite> (sent at login)") or "<red>off<NavajoWhite> (not sent)"))
if tonumber(v) and tonumber(v) > 0 then
	ataxiaEcho("<red>Warning:<NavajoWhite> the game will split long lines; triggers with long patterns can miss them.")
end
