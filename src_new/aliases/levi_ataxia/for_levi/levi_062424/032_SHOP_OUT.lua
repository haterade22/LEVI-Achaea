--[[mudlet
type: alias
name: SHOP OUT
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
regex: ^shopout$
command: ''
packageName: ''
]]--

send("g pouch from kitbag;g key from pouch;unlock door up;open door up;up;put key in pouch;put pouch in kitbag")