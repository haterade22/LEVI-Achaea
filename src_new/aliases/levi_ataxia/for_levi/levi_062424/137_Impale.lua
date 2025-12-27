--[[mudlet
type: alias
name: Impale
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- Knight
- Infernal
- 2H
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^ip$
command: ''
packageName: ''
]]--

if (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- exploit
send("cq all|stand|stand|wield bastard|grip|envenom bastard with epteth|battlefury focus speed|impale " ..target)
elseif (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then -- exploit/clumsiness
send("cq all|stand|stand|wield bastard|grip|envenom bastard with epteth|discipline|battlefury focus speed|impale " ..target)
end