local person = multimatches[1][2]
if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  lastLimbAttack = "tekuraSDK"
  
  local damage = tonumber(multimatches[3][1])
  if ataxiaTables.limbData.tekuraSNK == 25 then ataxiaTables.limbData.tekuraSNK = math.floor(damage*0.834) end
  if ataxiaTables.limbData.tekuraMNK == 25 then ataxiaTables.limbData.tekuraMNK = math.floor(damage*0.834) end
  if ataxiaTables.limbData.tekuraWWK == 25 then ataxiaTables.limbData.tekuraWWK = math.floor(damage*0.834) end
end