local person = multimatches[1][2]
if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  lastLimbAttack = "tekuraHKP"
  
    local damage = tonumber(multimatches[3][1])
  if ataxiaTables.limbData.tekuraUCP == 14 then ataxiaTables.limbData.tekuraUCP = math.floor(damage*1.05) end
  if ataxiaTables.limbData.tekuraSPP == 14 then ataxiaTables.limbData.tekuraSPP = damage end
  if ataxiaTables.limbData.tekuraHFP == 14 then ataxiaTables.limbData.tekuraHFP = damage end
end