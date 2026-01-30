local person = multimatches[1][2]
local maybemiss = multimatches[3][1]

if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  ignoreThirdPerson = true

    moveCursor(0, getLineNumber()-1)
    tarAffed("asthma")
    moveCursorEnd()
    lastLimbAttack = "shikLivestrike"

end
  if partyrelay then send("pt "..target..": asthma")
      end

local damage = tonumber(multimatches[3][1])
   ataxiaTables.limbData.shikLivestrike = damage
