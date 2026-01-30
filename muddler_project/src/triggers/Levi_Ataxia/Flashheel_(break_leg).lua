local person = multimatches[1][3]
local maybemiss = multimatches[3][1]
ataxiaTemp.lastLimbHit = multimatches[1][3]

if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  moveCursor(0, getLineNumber()-1)
  tarAffed("broken"..multimatches[1][2].."leg")
  moveCursorEnd()
  lastLimbAttack = "shikFlashheel"
end

local damage = tonumber(multimatches[3][1])
   ataxiaTables.limbData.shikFlashheel = damage
