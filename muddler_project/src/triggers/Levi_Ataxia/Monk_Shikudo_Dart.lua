local person = multimatches[1][3]
local maybemiss = multimatches[3][1]

if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  ignoreThirdPerson = true

     
    lastLimbAttack = "shikDart"

     
end
 



local damage = tonumber(multimatches[3][1])
   ataxiaTables.limbData.shikDart = damage
