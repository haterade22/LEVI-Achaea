--[[mudlet
type: script
name: RIGHT ARM
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

function rightarm()

local atk = combatQueue()

if tLimbs.RA < 100 then
need_prep_right_arm = true
else 
need_prep_right_arm = false
end

if tAffs.shield then
need_raze = true
else 
need_raze = false
end



if need_prep_right_arm then

atk = atk.."unwield all;dismount;assess "..target..";combo "..target.." swk spp right spp right"

end


send("queue addclear free "..atk)

end
