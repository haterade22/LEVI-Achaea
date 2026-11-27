--[[mudlet
type: alias
name: Treaties
hierarchy:
- Levi_Ataxia
- Classes
- Mage
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^treaties$
command: ''
packageName: ''
]]--

if ataxiaTreaty_start then ataxiaTreaty_start() else ataxiaEcho("Treaties: the treaty script is not loaded.") end
