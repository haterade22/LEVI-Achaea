local person = multimatches[1][2]
if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  if removeAffV3 then removeAffV3("shield") end
  lastLimbAttack = "tekuraMNK"
  
  local damage = tonumber(multimatches[3][1])
  if ataxiaTables.limbData.tekuraSDK == 25 then ataxiaTables.limbData.tekuraSNK = math.floor(damage*1.2) end
  if ataxiaTables.limbData.tekuraWWK == 25 then ataxiaTables.limbData.tekuraWWK = damage end
  if ataxiaTables.limbData.tekuraSNK == 25 then ataxiaTables.limbData.tekuraSNK = damage end  
end