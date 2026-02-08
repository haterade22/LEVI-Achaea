local person = multimatches[1][2]
local maybemiss = multimatches[3][1]



if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  if removeAffV3 then removeAffV3("shield") end
  ignoreThirdPerson = true

    moveCursor(0, getLineNumber()-1)
    tarAffed("anorexia", "stuttering")
    if applyAffV3 then applyAffV3("anorexia"); applyAffV3("stuttering") end
    moveCursorEnd()
    lastLimbAttack = "shikHiraku"

end
if partyrelay then send("pt "..target..": anorexia stuttering")
      end
local damage = tonumber(multimatches[3][1])
   ataxiaTables.limbData.shikHiraku = damage
