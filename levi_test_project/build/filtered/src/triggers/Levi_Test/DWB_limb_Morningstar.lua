ataxiaTemp.lastLimbHit = multimatches[1][2]
cecho("THIS WORKS")
cecho("THIS WORKS")
local person = multimatches[1][3]

if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  if removeAffV3 then removeAffV3("shield") end
  ignoreThirdPerson = true

    moveCursor(0, getLineNumber()-1)
    moveCursorEnd()
    --lastLimbAttack = "dwbMWhirl"
    lastLimbAttack = "dwbWhirl"

      
end

local damage = tonumber(multimatches[3][1])
   ataxiaTables.limbData.dwbWhirl = damage
 
msdamage = tonumber(multimatches[3][1])

ataxiaTables.limbData.dwbMWhirl = msdamage
