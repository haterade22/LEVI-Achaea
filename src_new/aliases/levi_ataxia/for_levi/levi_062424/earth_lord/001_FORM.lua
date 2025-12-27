--[[mudlet
type: alias
name: FORM
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- EARTH LORD
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