--[[mudlet
type: alias
name: Bash Curing Profile
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^aconfig bashcuring ?(\w+)?$
command: ''
packageName: ''
]]--

-- aconfig bashcuring            -- status
-- aconfig bashcuring install    -- one-time server-side setup (writes the `bash` curingset)
-- aconfig bashcuring show       -- print the PvE deltas, pvp -> bash
-- aconfig bashcuring on|off     -- auto-switching on basher enable/disable
-- aconfig bashcuring sets       -- what the GAME says exists (curingsets)

local sub = (matches[2] or ""):lower()

if sub == "sets" then
	ataxia_curingsetReport()
elseif sub == "install" then
	ataxia_bashProfileInstall()
elseif sub == "show" then
	ataxia_bashProfileShow()
elseif sub == "on" or sub == "off" then
	ataxia_bashProfileToggle(sub)
elseif sub == "" or sub == "status" then
	ataxia_bashProfileStatus()
else
	ataxiaEcho("Usage: aconfig bashcuring [install|show|on|off|status|sets]")
end
