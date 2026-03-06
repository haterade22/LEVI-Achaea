--[[mudlet
type: alias
name: Show Changelog
hierarchy:
- Levi_Ataxia
- Ataxia
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