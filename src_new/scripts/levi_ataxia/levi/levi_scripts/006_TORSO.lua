--[[mudlet
type: script
name: TORSO
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

function monktorso()

local atk = combatQueue()

if tLimbs.T < 200 then
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

atk = atk.."unwield all;dismount;assess "..target..";combo "..target.." sdk hkp hkp;hrs"

end


send("queue addclear free "..atk)

end
