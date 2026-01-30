ataxiaTemp.lastLimbHit = multimatches[1][2]
cecho("THIS WORKS")
local person = multimatches[1][4]
local maybemiss = multimatches[3][1]

if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  ignoreThirdPerson = true

    moveCursor(0, getLineNumber()-1)
   
    moveCursorEnd()
    --lastLimbAttack = "dwbFWhirl"
    lastLimbAttack = "dwbWhirl"
 
      
end

local damage = tonumber(multimatches[3][1])
   ataxiaTables.limbData.dwbWhirl = damage
 
fldamage = tonumber(multimatches[3][1])
   ataxiaTables.limbData.dwbFWhirl = fldamage
   
