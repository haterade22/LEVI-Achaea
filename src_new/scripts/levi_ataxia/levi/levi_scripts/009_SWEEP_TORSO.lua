--[[mudlet
type: script
name: SWEEP TORSO
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- MONK
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function sweeptorso()

local atk = combatQueue()

if tLimbs.T < 100 then
need_prep_torso = true
else 
need_prep_torso = false
end


if tAffs.shield then
need_raze = true
else 
need_raze = false
end


if need_prep_torso then

atk = atk.."unwield all;dismount;assess "..target..";combo "..target.." swk hkp hkp"

end


send("queue addclear free "..atk)

end
