--[[mudlet
type: script
name: Sentinel-specific
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Combat
- Offensive Things
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function haveAnimal(what)
	if table.contains(sAnimals, what) then
		return true
	else
		return false
	end
end