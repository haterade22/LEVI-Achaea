--[[mudlet
type: alias
name: Grab City Enemies
hierarchy:
- Levi_Ataxia
- Ataxia
- NDB
- Actions
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^cityenemies$
command: ''
packageName: ''
]]--

enableTrigger("City Enemies Capture")
send("cityenemies",false)