--[[mudlet
type: alias
name: Show Changelog
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Other stuff
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^changelog$
command: ''
packageName: ''
]]--

if ataxia_changeLog then
	ataxia_changeLog()
else
	cecho("\n<firebrick>Changelog function not available.")
end