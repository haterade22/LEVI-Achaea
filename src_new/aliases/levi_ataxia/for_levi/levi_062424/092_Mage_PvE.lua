--[[mudlet
type: alias
name: Mage PvE
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- Artefacts
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^magepve$
command: ''
packageName: ''
]]--

send("trait select quick-witted confirm;trait select fully fit confirm;trait select marksman confirm;trait select lucky confirm;trait select master contemplator confirm;trait select decorated confirm;trait select brilliance confirm;trait select in service confirm")

tempTimer(2,[[send("pry armour embrasure 1;pry armour embrasure 2;pry armour embrasure 3;insert paragon361796 into armour embrasure 1;insert paragon343178 into armour embrasure 2;insert paragon514466 into armour embrasure 3")]])  