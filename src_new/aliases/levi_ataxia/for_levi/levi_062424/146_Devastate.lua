--[[mudlet
type: alias
name: Devastate
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- Knight
- RUNIE
- 2H
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^d(aa|ll)$
command: ''
packageName: ''
]]--

if matches[2] == "aa" and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- exploit
send("cq all|stand|stand|wield bastard|grip|devastate " ..target.. " arms epseth|battlefury upset " ..target)
elseif matches[2] == "aa" and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then -- exploit/clumsiness
send("cq all|stand|stand|wield bastard|grip|discipline|devastate " ..target.. " arms epseth|battlefury upset " ..target)

elseif matches[2] == "ll" and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- exploit
send("cq all|stand|stand|wield bastard|grip|devastate " ..target.. " legs epteth|battlefury upset " ..target)
elseif matches[2] == "ll" and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then -- exploit/clumsiness
send("cq all|stand|stand|wield bastard|grip|discipline|devastate " ..target.. " legs epteth|battlefury upset " ..target)
end