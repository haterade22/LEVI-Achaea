local person = multimatches[1][4]
local maybemiss = multimatches[3][1]

if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  ignoreThirdPerson = true

    moveCursor(0, getLineNumber()-1)
   -- tarAffed("crushedthroat")
    moveCursorEnd()
    lastLimbAttack = "dwbWhirl"
 -- if partyrelay then send("pt "..target..": crushedthroat") end
      
end


 
local damage = tonumber(multimatches[3][1])
   ataxiaTables.limbData.dwbWhirl = damage
   ataxiaTables.limbData.dwbFWhirl = damage
   ataxiaTables.limbData.dwbMWhirl = damage
