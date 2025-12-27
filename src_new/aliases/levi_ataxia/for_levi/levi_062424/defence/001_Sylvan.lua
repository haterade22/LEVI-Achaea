--[[mudlet
type: alias
name: Sylvan
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- Defence
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^sy(l|ll)$
command: ''
packageName: ''
]]--

if matches[2] == "l" then
send("curing priority damagedrightleg 26;curing priority damagedleftleg 26")
end
if matches[2] == "ll" then
send("curing priority damagedrightleg 4;curing priority damagedleftleg 4")
end
