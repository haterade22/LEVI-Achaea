local person = multimatches[1][2]
local maybemiss = multimatches[3][1]

if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  if removeAffV3 then removeAffV3("shield") end
  ignoreThirdPerson = true

    moveCursor(0, getLineNumber()-1)
    tarAffed("crushedthroat")
    if applyAffV3 then applyAffV3("crushedthroat") end
    moveCursorEnd()
    lastLimbAttack = "shikNeedle"
  if partyrelay then send("pt "..target..": crushedthroat")
      end
end
 
local damage = tonumber(multimatches[3][1])
   ataxiaTables.limbData.shikNeedle = damage
