--[[mudlet
type: alias
name: Highlight Toggle
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Ataxia NDB
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^anhl$
command: ''
packageName: ''
]]--

if ataxiaNDB.highlightNames then
	--Remove any highlights, and turn off the toggle.
	ataxiaNDB.highlightNames = false
	ataxiaNDB_Unhighlight()
	ataxiaEcho("Disabled name highlighting.")
else
	--Begin highlighting again, and enable them all.
	ataxiaNDB.highlightNames = true
	ataxiaNDB_loadHighlights()
	ataxiaEcho("Enabled name highlighting.")
end