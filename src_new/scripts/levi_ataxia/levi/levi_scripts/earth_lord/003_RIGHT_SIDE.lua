--[[mudlet
type: script
name: RIGHT SIDE
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

function rightside()
local atk = combatQueue()

if tAffs.shield == true then

atk = atk.."terran magnet rise;wield shield;terran crunch "..target



elseif ataxia.vitals.shaping == 4 and tLimbs.RL < 100
 then
 targetlimb = "right leg"
atk = atk.."terran magnet rise;wield shield;assess "..target..";manifest quake;terran powderise "..target.." "..targetlimb


elseif ataxia.vitals.shaping < 4 and tLimbs.RL < 100 then
targetlimb = "right leg"

atk = atk.."terran magnet rise;wield shield;assess "..target..";terran powderise "..target.." "..targetlimb



end

send("terran magnet rise;queue addclear free "..atk)
end