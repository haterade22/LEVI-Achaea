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
    ["mindnet"] = "Announce mindnet to party: non-citizens, in any area. Works without raid on.",
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

-- Should mindnet tell the party about this player? `raid mindnet` off stops every party call.
-- raid on and Annwyn call everyone; Mhaldor calls its city enemies even out of a party (as before).
-- Otherwise: only in a party, only a player who is not us, not an ally and not of our city.
-- An unknown city is called: a stranger is the player a mindnet exists to catch.
-- ataxia.channels is GMCP Comm.Channel.List: it lists `party` while in one, and the caption of
-- `ct` is our city. Not read yet = call: the cost is one refused pt, and silence is the old fault.
function ataxia_mindnetTellParty(name, area)
  local raid = ataxia.settings.raid or {}
  if raid.mindnet == false then return false end
  if raid.enabled or area == "Annwyn" then return true end
  if area == "Mhaldor" and table.contains(ataxiaNDB.cityEnemies, name) then return true end
  local channels = ataxia.channels
  if channels and not channels.party then return false end
  local person = name:title()
  local me = (gmcp.Char and gmcp.Char.Status and gmcp.Char.Status.name) or ""
  if person == me:title() then return false end
  if ataxiaTemp.allies and table.contains(ataxiaTemp.allies, person) then return false end
  return ataxiaNDB_getCitizenship(person) ~= (channels and channels.ct)
end