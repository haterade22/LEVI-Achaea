--[[mudlet
type: alias
name: BUY CREDITS
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
regex: ^cr (\d+) (\d+)$
command: ''
packageName: ''
]]--

send("clearqueue all;g pouch from kitbag;g gold from pouch;credits buy "..matches[2].." at "..matches[3]..";put gold in tophat")
