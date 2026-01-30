local person = multimatches[1][2]
if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  lastLimbAttack = "tekuraUCP"

  local damage = tonumber(multimatches[3][1])
  if ataxiaTables.limbData.tekuraSPP == 14 then ataxiaTables.limbData.tekuraSPP = math.floor(damage*0.952) end
  if ataxiaTables.limbData.tekuraHKP == 14 then ataxiaTables.limbData.tekuraHKP = math.floor(damage*0.952) end
  if ataxiaTables.limbData.tekuraHFP == 14 then ataxiaTables.limbData.tekuraHFP = math.floor(damage*0.952) end  
end