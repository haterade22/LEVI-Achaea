--[[mudlet
type: alias
name: BEHEAD
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- General
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bh$
command: ''
packageName: ''
]]--

send("curing off")
ataxiaEcho("System has been "..(ataxia.settings.paused and "<red>paused." or "<green>unpaused."))
send("clearqueue all")
send("setalias kickass unwield shield/wield longsword left/behead "..target)
send("queue addclear free kickass")
