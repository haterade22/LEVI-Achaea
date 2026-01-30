local person = multimatches[1][2]
local maybemiss = multimatches[3][1]



if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  ignoreThirdPerson = true
  if ataxiaTemp.shikCombo then
    lastLimbAttack = "shikRisingkick"
  end
end

local damage = tonumber(multimatches[3][1])
   ataxiaTables.limbData.shikRisingkick = damage
