local person = multimatches[1][2]
if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  if removeAffV3 then removeAffV3("shield") end
  lastLimbAttack = "tekuraHFP"

  local damage = tonumber(multimatches[3][1])
  if ataxiaTables.limbData.tekuraUCP == 14 then ataxiaTables.limbData.tekuraUCP = math.floor(damage*1.05) end
  if ataxiaTables.limbData.tekuraSPP == 14 then ataxiaTables.limbData.tekuraSPP = damage end
  if ataxiaTables.limbData.tekuraHKP == 14 then ataxiaTables.limbData.tekuraHKP = damage end
end