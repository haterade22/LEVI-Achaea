local person = multimatches[1][2]
local maybemiss = multimatches[3][1]


if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  if removeAffV3 then removeAffV3("shield") end
  ignoreThirdPerson = true

    moveCursor(0, getLineNumber()-1)
    tarAffed("addiction")
    if applyAffV3 then applyAffV3("addiction") end
    moveCursorEnd()
    lastLimbAttack = "shikJinzuku"
 if partyrelay then send("pt "..target..": addiction")
      end
end

local damage = tonumber(multimatches[3][1])
   ataxiaTables.limbData.shikJinzuku = damage
