local person = multimatches[1][2]
local maybemiss = multimatches[3][1]



if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  if removeAffV3 then removeAffV3("shield") end
  ignoreThirdPerson = true

    moveCursor(0, getLineNumber()-1)
    tarAffed("dizziness")
    if applyAffV3 then applyAffV3("dizziness") end
    moveCursorEnd()
    lastLimbAttack = "shikHiru"

end
if partyrelay and tAffs.prone then send("pt "..target..": dizziness confusion")
elseif partyrelay and not tAffs.prone then send("pt "..target..": dizziness")
      end
local damage = tonumber(multimatches[3][1])
   ataxiaTables.limbData.shikHiru = damage
