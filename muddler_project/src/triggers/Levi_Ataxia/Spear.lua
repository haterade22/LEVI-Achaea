local person = multimatches[1][2]
if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  lastLimbAttack = "tekuraSPP"
  
    local damage = tonumber(multimatches[3][1])
  if ataxiaTables.limbData.tekuraUCP == 14 then ataxiaTables.limbData.tekuraUCP = math.floor(damage*1.05) end
  if ataxiaTables.limbData.tekuraHFP == 14 then ataxiaTables.limbData.tekuraHFP = damage end
  if ataxiaTables.limbData.tekuraHKP == 14 then ataxiaTables.limbData.tekuraHKP = damage end
end