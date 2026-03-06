local person = multimatches[1][3]
local maybemiss = multimatches[3][1]
ataxiaTemp.lastLimbHit = multimatches[1][3]

if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  if removeAffV3 then removeAffV3("shield") end
  moveCursor(0, getLineNumber()-1)
  tarAffed("broken"..multimatches[1][2].."leg")
  if applyAffV3 then applyAffV3("broken"); applyAffV3("leg") end
  moveCursorEnd()
  lastLimbAttack = "shikFlashheel"
end

local damage = tonumber(multimatches[3][1])
   ataxiaTables.limbData.shikFlashheel = damage
