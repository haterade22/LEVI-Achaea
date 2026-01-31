ataxiaTemp.lastLimbHit = multimatches[1][3]

if isTargeted(multimatches[1][2]) then
  lastLimbAttack = "dragonRend"
  moveCursor(0, getLineNumber()-1)
  tarAffed(envenomList[1])
  table.remove(envenomList, 1)
end
