--[[mudlet
type: alias
name: ^telereport
hierarchy:
- Levi_Ataxia
- Classes
- Monk
- Telepathy Reporting
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^telereport
command: ''
packageName: ''
]]--

if teleannounce == "activated" then
	teleannounce = "deactivated" 
	cecho("\n<brown>Your telepathy will no longer be announced to your party.")
else
	teleannounce = "activated"
	cecho("\n<dark_sea_green>Your telepathy will be announced to your party.")
end