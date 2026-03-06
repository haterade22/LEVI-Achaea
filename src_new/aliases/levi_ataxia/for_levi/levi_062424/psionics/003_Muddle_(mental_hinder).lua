--[[mudlet
type: alias
name: Muddle (mental hinder)
hierarchy:
- Levi_Ataxia
- Classes
- Psion
- Psionics
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^pmud$
command: ''
packageName: ''
]]--

if (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and not svo.affl.paralysis then
send("cq all;psi muddle " ..target)
end