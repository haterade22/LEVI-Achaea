--[[mudlet
type: alias
name: Treaties Stop
hierarchy:
- Levi_Ataxia
- Classes
- Mage
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^treaties stop$
command: ''
packageName: ''
]]--

if ataxiaTreaty_stop then ataxiaTreaty_stop("stopped by you") else ataxiaEcho("Treaties: the treaty script is not loaded.") end
