ataxia.settings.raid = ataxia.settings.raid or {enabled = false}
local options = {"mindnet", "fullsense", "target"}
local choice = matches[2]:lower()

if choice == "on" then
  ataxia.settings.raid.enabled = true
  ataxia_raidEcho("Systems enabled for raid mode.")
elseif choice == "off" then
  ataxia.settings.raid.enabled = false
  ataxia_raidEcho("Systems disabled for raid mode.")
elseif choice == "help" then
  ataxia_raidHelp()
elseif table.contains(options, choice) then
  ataxia_raidToggle(choice)
else
  ataxia_raidEcho("Invalid option. See 'raid help' for information.")
end

ataxia_saveSettings(false)