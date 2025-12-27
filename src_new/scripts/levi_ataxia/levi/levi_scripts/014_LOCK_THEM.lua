--[[mudlet
type: script
name: LOCK THEM
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- MONK
- SHIKUDO
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function lock_base_attack()

formswaplock()

local atk = combatQueue()
   

  if shikudo[1] == "sweep" then
  
  atk = atk.."wield staff489282;dismount;assess "..target..";combo "..target.." "..shikudo[1].." "..shikudo[2]
 
elseif


shikudo[1] == "dispatch" then
  
  atk = atk.."wield staff489282;dismount;assess "..target..";dispatch "..target.." "..form[1]
 
 elseif ataxia.vitals.form == "Oak" and rightarmpreppedRUK and leftarmpreppedRUK and rightlegpreppedKUR and leftlegpreppedKUR then

  atk = atk.."wield staff489282;dismount;assess "..target..";combo "..target.." "..shikudo[1].." "..shikudo[2]


elseif ataxia.vitals.form == "Gaital" and leftarmpreppedRUK and rightlegpreppedKUR and leftlegpreppedKUR and
(tLimbs.RA + ataxiaTables.limbData.shikRuku + ataxiaTables.limbData.shikRuku >=  100)

 then
 
  atk = atk.."wield staff489282;dismount;assess "..target..";combo "..target.." "..shikudo[1].." "..shikudo[2]

 
 else

atk = atk.."wield staff489282;dismount;assess "..target..";combo "..target.." "..shikudo[1].." "..shikudo[2].." "..shikudo[3]
 
end
 
if ataxia.vitals.form ~= form[1] then

send("cq all;transition to the "..form[1].." form")

else

send("queue addclear freestand " ..atk)



end
end