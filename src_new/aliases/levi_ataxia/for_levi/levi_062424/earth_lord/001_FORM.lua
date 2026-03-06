--[[mudlet
type: alias
name: FORM
hierarchy:
- Levi_Ataxia
- Classes
- Earth Lord
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^earth$
command: ''
packageName: ''
]]--

send("clearqueue all;prevail")
expandAlias("mconfig gallop false")
ataxia.settings.paused = true
ataxiaEcho("System has been "..(ataxia.settings.paused and "<red>paused." or "<green>unpaused."))
shape = 0