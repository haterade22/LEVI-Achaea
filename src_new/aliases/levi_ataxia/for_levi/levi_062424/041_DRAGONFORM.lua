--[[mudlet
type: alias
name: DRAGONFORM
hierarchy:
- Levi_Ataxia
- Classes
- Dragon
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^dra$
command: ''
packageName: ''
]]--

send("clearqueue all;tell impastus come here;dragonform")
expandAlias("mconfig gallop false")
expandAlias("mconfig gare true")
ataxia.settings.paused = true
ataxiaEcho("System has been "..(ataxia.settings.paused and "<red>paused." or "<green>unpaused."))