--[[mudlet
type: alias
name: Psi Blast (Need three mentals and unwoven mind)
hierarchy:
- Levi_Ataxia
- Classes
- Psion
- Psionics
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^pbl$
command: ''
packageName: ''
]]--

if (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and not svo.affl.paralysis then
send("cq all;psi blast " ..target)
end