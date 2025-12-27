--[[mudlet
type: script
name: TORSO PATH
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- EARTH LORD
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function torsopath()
 limbtable() 
local atk = combatQueue()

if tAffs.shield == true then

atk = atk.."terran magnet rise;wield shield;terran crunch "..target


elseif shape == 4
and tLimbs.T >= 100
 then

targetlimb = "torso"


atk = atk.."terran magnet rise;wield shield;assess "..target..";terran calcify "..target.." torso;terran squeeze "..target


elseif shape == 4 and tLimbs.T == 63 then
targetlimb = "torso"


atk = atk.."terran magnet rise;wield shield;assess "..target..";terran calcify "..target.." torso;terran powderise "..target.." "..targetlimb

elseif shape == 4 and tLimbs.T == 84 then
targetlimb = "torso"


atk = atk.."terran magnet rise;wield shield;assess "..target..";terran calcify "..target.." torso;terran powderise "..target.." "..targetlimb

elseif tLimbs.T == 84 and shape < 4 then

if ataxiaTemp.parriedLimb == "right arm" then
targetlimb = "left arm"
else 
targetlimb = "right arm"
end

atk = atk.."terran magnet rise;wield shield;assess "..target..";terran powderise "..target.." "..targetlimb



elseif tLimbs.T >= 100 and shape < 4 then

if ataxiaTemp.parriedLimb == "right arm" then
targetlimb = "left arm"
else 
targetlimb = "right arm"
end

atk = atk.."terran magnet rise;wield shield;assess "..target..";terran powderise "..target.." "..targetlimb


 elseif shape == 4



and tLimbs.T < 200 then


atk = atk.."terran magnet rise;wield shield;assess "..target..";manifest quake;terran powderise "..target.." "..targetlimb



elseif shape < 4



and tLimbs.T < 200 then


targetlimb = "torso"


atk = atk.."terran magnet rise;wield shield;assess "..target..";terran powderise "..target.." "..targetlimb






end

send("terran magnet rise;queue addclear free "..atk)
end