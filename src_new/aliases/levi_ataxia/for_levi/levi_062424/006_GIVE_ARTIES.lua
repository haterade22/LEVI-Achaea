--[[mudlet
type: alias
name: GIVE ARTIES
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
regex: ^givearties$
command: ''
packageName: ''
]]--

send("remove pendant398551;remove bracelets83145;remove belt404134;remove ring;give ring to "..puptarget..";give 398551 to " .. puptarget .. ";give 83145 to " .. puptarget .. ";give 404134 to " ..puptarget)