--[[mudlet
type: alias
name: SHOP ENTRY
hierarchy:
- Levi_Ataxia
- General
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^shopin$
command: ''
packageName: ''
]]--

send("g pouch from kitbag;g key from pouch;unlock door down;open door down;down;put key in pouch;put pouch in kitbag")