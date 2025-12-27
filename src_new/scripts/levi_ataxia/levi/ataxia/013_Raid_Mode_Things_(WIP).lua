--[[mudlet
type: script
name: Raid Mode Things (WIP)
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- System-related
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function ataxia_raidEcho(text)
  cecho("\n<a_cyan>(<a_magenta>ataxia<a_cyan>): <DodgerBlue>"..text)
end

function ataxia_raidHelp()
  local settings = {
    ["on|off"] = "Toggle using raid mode.",
    ["fullsense"] = "Fullsense reporting to party.",
    ["mindnet"] = "Announce mindnet for enemies.",
    ["target"] = "Call out target changes.",
  }
  
  ataxia_raidEcho("The following are possible settings for 'raid mode' stuff.")
  ataxia_raidEcho("Note: announces will always call to party where applicable.")
  cecho("\n ")
  
  for setting, desc in pairs(settings) do
    if setting == "on|off" then
      cecho("\n - "..(ataxia.settings.raid.enabled and "<green>" or "<red>")..setting.."       -  <LightSkyBlue>"..desc)
    else
      cecho("\n - "..(ataxia.settings.raid[setting] and "<green>" or "<red>")..setting..string.rep(" ", 12-string.len(setting)).." -  <LightSkyBlue>"..desc)
    end
  end
  cecho("\n ")
  send(" ")
end

function ataxia_raidToggle(choice)
  if ataxia.settings.raid[choice] then
    ataxia.settings.raid[choice] = false
  else
    ataxia.settings.raid[choice] = true
  end
  ataxia_raidEcho( (ataxia.settings.raid[choice] and "<green>Enabled" or "<red>Disabled").." <DodgerBlue>party reporting for "..choice..".")
end

function ataxia_raidMode(option)
  if not ataxia.settings.raid then return false end
  if not ataxia.settings.raid.enabled then return false end
  
  if ataxia.settings.raid[option] then
    return true
  else
    return false
  end
end