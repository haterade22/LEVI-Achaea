--[[mudlet
type: alias
name: disembowel
hierarchy:
- Levi_Ataxia
- Classes
- Knight
- RUNIE
- 2H
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^dis$
command: ''
packageName: ''
]]--

if (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- exploit
send("cq all|stand|stand|wield bastard|grip|disembowel " ..target)
elseif (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then -- exploit/clumsiness
send("cq all|stand|stand|wield bastard|grip|discipline|disembowel " ..target)
end