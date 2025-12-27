--[[mudlet
type: key
name: enable systems
hierarchy:
- Levi_Ataxia
- Levitax
- Movement/Bashing
attributes:
  isActive: 'yes'
  isFolder: 'no'
keyCode: 16777264
keyModifier: 0
command: ''
packageName: ''
]]--

if not ataxiaBasher.enabled then
	ataxiaBasher_areabash()
else
	ataxiaBasher_areaoff()
end