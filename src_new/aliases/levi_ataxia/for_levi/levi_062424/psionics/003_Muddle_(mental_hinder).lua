--[[mudlet
type: alias
name: Muddle (mental hinder)
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
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