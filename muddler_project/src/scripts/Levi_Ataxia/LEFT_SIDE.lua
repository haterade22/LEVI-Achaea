function leftside()
local atk = combatQueue()

if tAffs.shield == true then

atk = atk.."terran magnet rise;wield shield;terran crunch "..target



elseif ataxia.vitals.shaping == 4 and tLimbs.LL < 100
 then
 targetlimb = "left leg"
atk = atk.."terran magnet rise;wield shield;assess "..target..";manifest quake;terran powderise "..target.." "..targetlimb


elseif ataxia.vitals.shaping < 4 and tLimbs.LL < 100 then
targetlimb = "left leg"

atk = atk.."terran magnet rise;wield shield;assess "..target..";terran powderise "..target.." "..targetlimb



end

send("terran magnet rise;queue addclear free "..atk)
end