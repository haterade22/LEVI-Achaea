--[[mudlet
type: script
name: RIGHT LEG
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

function rightleg()

local atk = combatQueue()

if tLimbs.RL < 100 then
need_prep_right_leg = true
else 
need_prep_right_leg = false
end

if tAffs.shield then
need_raze = true
else 
need_raze = false
end


if need_raze then

atk = atk.."unwield all;dismount;assess "..target..";combo "..target.." rhk hfp right hfp right"

end

if need_prep_right_leg then

atk = atk.."unwield all;dismount;assess "..target..";combo "..target.." snk right hfp right hfp right"

end


send("queue addclear free "..atk)

end
